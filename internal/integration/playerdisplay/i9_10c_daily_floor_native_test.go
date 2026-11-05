//go:build postgres

package playerdisplay_test

import (
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/domain/economy"
	"sync"
	"testing"
	"time"

	"context"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func dailyFloorService(database *pg.Pool) i5.Service {
	store := i5store.Store{Queryer: database}
	return i5.Service{Runner: tx.Runner{DB: database}, Store: store, Content: contentstore.Store{Queryer: database}, Privileges: i5.BaselinePrivilegeProvider{}, Functions: i5.PetStarterFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{}, Backpack: store, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: database}, RedeemSecret: []byte("daily-floor-native-key-00000000000000")}
}
func floorOperation(revision string, at time.Time) operation.Context {
	operation := opPinned(revision)
	operation.StartedAt = at
	return operation
}
func TestI910CDailyFloorProjectionGrantSpendAndRollover(t *testing.T) {
	database := pool(t)
	revision := installed(t, database)
	player := actor(t, database)
	store := i5store.Store{Queryer: database}
	content := contentstore.Store{Queryer: database}
	at, err := (pg.AuthoritativeTime{Queryer: database}).Now(ctx)
	if err != nil {
		t.Fatal(err)
	}
	amount, err := i5.EffectiveScalarTx(ctx, database, store, content, player.PlayerID, "glue", at)
	if err != nil || amount != 100 {
		t.Fatal(amount, err)
	}
	var rows int
	if err = database.QueryRow(ctx, `SELECT count(*) FROM player_scalar_daily_floors WHERE player_id=$1`, int64(player.PlayerID)).Scan(&rows); err != nil || rows != 0 {
		t.Fatal("projection persisted anchor", rows, err)
	}
	operation := floorOperation(revision, at)
	plan := grant.Plan{PlayerID: player.PlayerID, Source: grant.SourceIdentity{Domain: "dorm-native", Operation: "credit", BusinessKey: fmt.Sprint(int64(player.PlayerID)), Occurrence: operation.ID.String(), PolicyVersion: "test-qualified-floor"}, Lines: []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "glue", Amount: 50}}}
	service := dailyFloorService(database)
	_, err = service.SettleGrantTx(ctx, nil, player, plan, operation, i5.GrantTxOptions{})
	// SettleGrantTx requires the caller's real transaction.
	if err == nil {
		t.Fatal("nil transaction accepted")
	}
	_, err = service.Runner.Run(ctx, operation, i5.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(ctx context.Context, scope tx.Scope) error {
		_, err := service.SettleGrantTx(ctx, scope.Tx, player, plan, operation, i5.GrantTxOptions{})
		return err
	})
	if err != nil {
		t.Fatal(err)
	}
	debit := func(amount int64, at time.Time) error {
		operation := floorOperation(revision, at)
		_, err := service.Runner.Run(ctx, operation, i5.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(ctx context.Context, scope tx.Scope) error {
			_, err := (i5.CrossOwner{Store: store, FloorPolicies: content}).DebitScalarTx(ctx, scope.Tx, player.PlayerID, "glue", amount, at)
			return err
		})
		return err
	}
	if err = debit(130, at.Add(time.Second)); err != nil {
		t.Fatal(err)
	}
	amount, err = i5.EffectiveScalarTx(ctx, database, store, content, player.PlayerID, "glue", at.Add(2*time.Second))
	if err != nil || amount != 20 {
		t.Fatal("same day refill", amount, err)
	}
	if err = debit(1, at.Add(24*time.Hour)); err != nil {
		t.Fatal(err)
	}
	amount, err = i5.EffectiveScalarTx(ctx, database, store, content, player.PlayerID, "glue", at.Add(24*time.Hour+time.Second))
	if err != nil || amount != 99 {
		t.Fatal("next day", amount, err)
	}
	var version int64
	if err = database.QueryRow(ctx, `SELECT state_version FROM player_scalar_daily_floors WHERE player_id=$1 AND resource_key='glue'`, int64(player.PlayerID)).Scan(&version); err != nil || version != 2 {
		t.Fatal("day anchor", version, err)
	}
	_, err = service.Runner.Run(ctx, operation, i5.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		_, err := service.SettleGrantTx(ctx, scope.Tx, player, plan, operation, i5.GrantTxOptions{})
		return err
	})
	if err != nil {
		t.Fatal("retained grant replay attempted stale floor", err)
	}
	amount, err = i5.EffectiveScalarTx(ctx, database, store, content, player.PlayerID, "glue", at.Add(24*time.Hour+2*time.Second))
	if err != nil || amount != 99 {
		t.Fatal("replayed grant credited again", amount, err)
	}
}
func TestI910CDailyFloorPrepareIsReadOnlyAndRollbackIsAtomic(t *testing.T) {
	database := pool(t)
	revision := installed(t, database)
	player := actor(t, database)
	store := i5store.Store{Queryer: database}
	service := dailyFloorService(database)
	at, err := (pg.AuthoritativeTime{Queryer: database}).Now(ctx)
	if err != nil {
		t.Fatal(err)
	}
	operation := floorOperation(revision, at)
	plan := grant.Plan{PlayerID: player.PlayerID, Source: grant.SourceIdentity{Domain: "dorm-native", Operation: "mixed", BusinessKey: fmt.Sprint(int64(player.PlayerID)), Occurrence: operation.ID.String(), PolicyVersion: "test-qualified-floor"}, Lines: []grant.Line{{Kind: grant.StackItem, ItemID: 50001046, Amount: 1}}}
	injected := errors.New("after floor and grant")
	_, err = service.Runner.Run(ctx, operation, i5.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		prepared, err := service.PrepareMaterialExchangeTx(ctx, scope.Tx, player, i5.MaterialExchangeRequest{Cost: i5.MaterialCost{Scalars: []i5.ScalarMaterialCost{{ResourceKey: "glue", Amount: 10}}}, Restoration: plan, AllowOverflowMail: true}, operation)
		if err != nil {
			return err
		}
		_, exists, err := store.ReadScalarTx(ctx, scope.Tx, player.PlayerID, "glue")
		if err != nil {
			return err
		}
		if exists {
			return errors.New("prepare wrote glue")
		}
		_, anchored, err := store.ReadScalarDailyFloorTx(ctx, scope.Tx, player.PlayerID, "glue")
		if err != nil {
			return err
		}
		if anchored {
			return errors.New("prepare wrote anchor")
		}
		if _, err = service.ApplyMaterialExchangeTx(ctx, scope.Tx, prepared); err != nil {
			return err
		}
		return injected
	})
	if !errors.Is(err, injected) {
		t.Fatal(err)
	}
	if _, exists, err := store.ReadScalarTx(ctx, database, player.PlayerID, "glue"); err != nil || exists {
		t.Fatal("rollback balance", exists, err)
	}
	if _, exists, err := store.ReadScalarDailyFloorTx(ctx, database, player.PlayerID, "glue"); err != nil || exists {
		t.Fatal("rollback anchor", exists, err)
	}
	var rows int
	if err = database.QueryRow(ctx, `SELECT count(*) FROM player_item_stacks WHERE player_id=$1`, int64(player.PlayerID)).Scan(&rows); err != nil || rows != 0 {
		t.Fatal("rollback grant", rows, err)
	}
}

func TestI910CDailyFloorConcurrentMissingBalanceDoesNotDuplicateCredit(t *testing.T) {
	database := pool(t)
	revision := installed(t, database)
	player := actor(t, database)
	service := dailyFloorService(database)
	store := i5store.Store{Queryer: database}
	content := contentstore.Store{Queryer: database}
	at, err := (pg.AuthoritativeTime{Queryer: database}).Now(ctx)
	if err != nil {
		t.Fatal(err)
	}
	results := make(chan error, 2)
	var wait sync.WaitGroup
	for index := 0; index < 2; index++ {
		wait.Add(1)
		go func() {
			defer wait.Done()
			operation := floorOperation(revision, at)
			_, err := service.Runner.Run(ctx, operation, i5.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 8, RetryDefiniteAbort: true}, nil, func(ctx context.Context, scope tx.Scope) error {
				_, err := (i5.CrossOwner{Store: store, FloorPolicies: content}).DebitScalarTx(ctx, scope.Tx, player.PlayerID, "glue", 80, at)
				return err
			})
			results <- err
		}()
	}
	wait.Wait()
	close(results)
	successes, refusals := 0, 0
	for err := range results {
		if err == nil {
			successes++
		} else if errors.Is(err, economy.ErrInsufficientBalance) {
			refusals++
		} else {
			t.Fatal(err)
		}
	}
	if successes != 1 || refusals != 1 {
		t.Fatal(successes, refusals)
	}
	balance, exists, err := store.ReadScalarTx(ctx, database, player.PlayerID, "glue")
	if err != nil || !exists || balance.Amount != 20 {
		t.Fatal(balance, err)
	}
	anchor, exists, err := store.ReadScalarDailyFloorTx(ctx, database, player.PlayerID, "glue")
	if err != nil || !exists || anchor.StateVersion != 1 {
		t.Fatal(anchor, err)
	}
}
