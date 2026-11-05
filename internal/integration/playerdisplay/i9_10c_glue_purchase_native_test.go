//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	"fmt"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/application/i5"
	dorm "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func gluePurchaseRequest(player identity.PlayerID, current operation.Context) i5.GluePurchaseRequest {
	return i5.GluePurchaseRequest{CrystalCost: 50, GlueAmount: 50, StartLimit: 300, Source: grant.SourceIdentity{Domain: "dorm-house", Operation: "buy-glue", BusinessKey: fmt.Sprint(int64(player)), Occurrence: current.ID.String(), PolicyVersion: "source-qualified"}}
}

func TestI910CGluePurchaseCounterAndValuesCommitTogether(t *testing.T) {
	database := pool(t)
	revision := installed(t, database)
	player := bornActor(t, database)
	service := dailyFloorService(database)
	owner := dormstore.Store{Queryer: database}
	catalog, err := (contentstore.Store{}).DormCatalogTx(ctx, database, revision)
	if err != nil || catalog.Glue == nil {
		t.Fatal(catalog.Glue, err)
	}
	current := opPinned(revision)
	if _, exists, err := owner.ReadGluePurchasesTx(ctx, database, player.PlayerID); err != nil || exists {
		t.Fatal("fresh optional counter", exists, err)
	}
	injected := errors.New("outer persistence failed")
	purchase := func(failure error) error {
		_, err := service.Runner.Run(ctx, current, i5.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(ctx context.Context, scope tx.Scope) error {
			if _, err := (i4store.PlayerRootLocker{}).LockPlayerRootsTx(ctx, scope.Tx, player.LogicalServerID, []identity.PlayerID{player.PlayerID}); err != nil {
				return err
			}
			if _, err := owner.LockRootTx(ctx, scope.Tx, player.PlayerID); err != nil {
				return err
			}
			stored, exists, err := owner.ReadGluePurchasesTx(ctx, scope.Tx, player.PlayerID)
			if err != nil {
				return err
			}
			var previous *dorm.GluePurchases
			if exists {
				previous = &stored
			}
			planned, cost, err := catalog.Glue.PlanPurchase(previous, player.PlayerID, 0, modes.Day(current.StartedAt), current.StartedAt)
			if err != nil {
				return err
			}
			request := gluePurchaseRequest(player.PlayerID, current)
			request.CrystalCost, request.GlueAmount, request.StartLimit = cost, catalog.Glue.PurchaseAmount, catalog.Glue.PurchaseStartLimit
			prepared, err := service.PrepareGluePurchaseTx(ctx, scope.Tx, player, request, current)
			if err != nil {
				return err
			}
			if _, err = service.ApplyGluePurchaseTx(ctx, scope.Tx, prepared); err != nil {
				return err
			}
			if err = owner.SaveGluePurchasesTx(ctx, scope.Tx, planned, stored.StateVersion); err != nil {
				return err
			}
			return failure
		})
		return err
	}
	before, _, err := (i5store.Store{}).ReadScalarTx(ctx, database, player.PlayerID, "crystal")
	if err != nil {
		t.Fatal(err)
	}
	if err = purchase(injected); !errors.Is(err, injected) {
		t.Fatal(err)
	}
	if _, exists, err := owner.ReadGluePurchasesTx(ctx, database, player.PlayerID); err != nil || exists {
		t.Fatal("counter rollback", exists, err)
	}
	after, _, err := (i5store.Store{}).ReadScalarTx(ctx, database, player.PlayerID, "crystal")
	if err != nil || before.Amount != after.Amount {
		t.Fatal("value rollback", before, after, err)
	}
	if err = purchase(nil); err != nil {
		t.Fatal(err)
	}
	stored, exists, err := owner.ReadGluePurchasesTx(ctx, database, player.PlayerID)
	if err != nil || !exists || stored.Count != 1 || stored.StateVersion != 1 {
		t.Fatal(stored, err)
	}
	if count, err := dorm.EffectiveGluePurchaseCount(&stored, player.PlayerID, modes.Day(current.StartedAt.Add(24*time.Hour)), current.StartedAt.Add(24*time.Hour)); err != nil || count != 0 {
		t.Fatal(count, err)
	}
	unchanged, _, err := owner.ReadGluePurchasesTx(ctx, database, player.PlayerID)
	if err != nil || unchanged != stored {
		t.Fatal("projection wrote counter", stored, unchanged, err)
	}
}

func gluePurchaseTransaction(service i5.Service, player identity.ActorContext, current operation.Context, afterApply error) error {
	_, err := service.Runner.Run(ctx, current, i5.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(ctx context.Context, scope tx.Scope) error {
		prepared, err := service.PrepareGluePurchaseTx(ctx, scope.Tx, player, gluePurchaseRequest(player.PlayerID, current), current)
		if err != nil {
			return err
		}
		if _, err = service.ApplyGluePurchaseTx(ctx, scope.Tx, prepared); err != nil {
			return err
		}
		return afterApply
	})
	return err
}

func TestI910CGluePurchaseNativeLimitRecoveryAndAtomicity(t *testing.T) {
	database := pool(t)
	revision := installed(t, database)
	player := actor(t, database)
	service := dailyFloorService(database)
	store := i5store.Store{Queryer: database}
	current := opPinned(revision)
	exec(t, database, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at) VALUES($1,'glue',299,1,$2)`, int64(player.PlayerID), current.StartedAt)
	if err := gluePurchaseTransaction(service, player, current, nil); err != nil {
		t.Fatal(err)
	}
	for key, expected := range map[string]int64{"crystal": 950, "glue": 349} {
		balance, exists, err := store.ReadScalarTx(ctx, database, player.PlayerID, key)
		if err != nil || !exists || balance.Amount != expected {
			t.Fatal(key, balance, err)
		}
	}
	if err := gluePurchaseTransaction(service, player, current, nil); !errors.Is(err, i5.ErrMaterialExchangeGrantAlreadySettled) {
		t.Fatal("inner receipt must prevent fresh debit", err)
	}
	if err := gluePurchaseTransaction(service, player, opPinned(revision), nil); !errors.Is(err, i5.ErrGluePurchaseLimit) {
		t.Fatal("start limit", err)
	}
	crystal, _, err := store.ReadScalarTx(ctx, database, player.PlayerID, "crystal")
	if err != nil || crystal.Amount != 950 {
		t.Fatal("refused purchase charged crystal", crystal, err)
	}

	missing := actor(t, database)
	current = opPinned(revision)
	injected := errors.New("outer Dorm counter failed")
	if err := gluePurchaseTransaction(service, missing, current, injected); !errors.Is(err, injected) {
		t.Fatal(err)
	}
	crystal, _, err = store.ReadScalarTx(ctx, database, missing.PlayerID, "crystal")
	if err != nil || crystal.Amount != 1000 {
		t.Fatal("rollback crystal", crystal, err)
	}
	if _, exists, err := store.ReadScalarTx(ctx, database, missing.PlayerID, "glue"); err != nil || exists {
		t.Fatal("rollback glue", exists, err)
	}
	if _, exists, err := store.ReadScalarDailyFloorTx(ctx, database, missing.PlayerID, "glue"); err != nil || exists {
		t.Fatal("rollback anchor", exists, err)
	}
	// Reusing the exact inner identity proves its receipt rolled back too.
	if err := gluePurchaseTransaction(service, missing, current, nil); err != nil {
		t.Fatal("retry after rollback", err)
	}
	glue, exists, err := store.ReadScalarTx(ctx, database, missing.PlayerID, "glue")
	if err != nil || !exists || glue.Amount != 150 {
		t.Fatal("missing scalar floor plus purchase", glue, err)
	}

	atLimit := actor(t, database)
	exec(t, database, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at) VALUES($1,'glue',300,1,clock_timestamp())`, int64(atLimit.PlayerID))
	if err := gluePurchaseTransaction(service, atLimit, opPinned(revision), nil); !errors.Is(err, i5.ErrGluePurchaseLimit) {
		t.Fatal("exact limit must refuse", err)
	}
	if _, exists, err := store.ReadScalarDailyFloorTx(ctx, database, atLimit.PlayerID, "glue"); err != nil || exists {
		t.Fatal("refused prepare persisted anchor", exists, err)
	}
}
