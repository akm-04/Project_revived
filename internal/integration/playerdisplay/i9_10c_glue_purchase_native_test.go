//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	"fmt"
	"testing"

	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func gluePurchaseRequest(player identity.PlayerID, current operation.Context) i5.GluePurchaseRequest {
	return i5.GluePurchaseRequest{CrystalCost: 50, GlueAmount: 50, StartLimit: 300, Source: grant.SourceIdentity{Domain: "dorm-house", Operation: "buy-glue", BusinessKey: fmt.Sprint(int64(player)), Occurrence: current.ID.String(), PolicyVersion: "source-qualified"}}
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
