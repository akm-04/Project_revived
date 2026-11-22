//go:build postgres

package restorestore_test

import (
	"context"
	"errors"
	"os"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/restorestore"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func restorePool(t *testing.T) *postgres.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_L3B_RESTORE_DSN")
	if dsn == "" {
		t.Fatal("GXB_L3B_RESTORE_DSN is required")
	}
	pool, err := postgres.Open(context.Background(), dsn, postgres.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	return pool
}

func closeOpenEpochs(t *testing.T, pool *postgres.Pool) {
	t.Helper()
	if _, err := pool.Raw().Exec(context.Background(), `UPDATE restore_epochs SET reconciled_at=now(), reconciliation_note='test cleanup' WHERE reconciled_at IS NULL`); err != nil {
		t.Fatal(err)
	}
}

func restoreLabel(t *testing.T) string {
	t.Helper()
	id, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	return "l3b-restore-" + id.String()
}

func insertEpoch(t *testing.T, pool *postgres.Pool, backup, operator string) restorestore.Epoch {
	t.Helper()
	transaction, err := pool.Begin(context.Background(), tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	epoch, err := (restorestore.Store{}).InsertTx(context.Background(), transaction, backup, operator)
	if err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(context.Background()); err != nil {
		t.Fatal(err)
	}
	return epoch
}

// An open epoch blocks the startup check; reconciling it clears the gate and
// keeps the operator's note.
func TestRestoreEpochOpenBlocksWritableAndReconcileClearsIt(t *testing.T) {
	ctx := context.Background()
	pool := restorePool(t)
	closeOpenEpochs(t, pool)
	store := restorestore.Store{}
	epoch := insertEpoch(t, pool, restoreLabel(t), "operator-restore")
	if epoch.Epoch <= 0 || epoch.ReconciledAt != nil || epoch.ReconciliationNote != "" {
		t.Fatalf("inserted epoch=%#v", epoch)
	}
	if err := store.CheckWritable(ctx, pool); !errors.Is(err, restorestore.ErrUnreconciledRestore) {
		t.Fatalf("open epoch startup check=%v want ErrUnreconciledRestore", err)
	}

	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	reconciled, err := store.ReconcileTx(ctx, transaction, epoch.Epoch, "operator-reconcile", "external payments reconciled")
	if err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if reconciled.ReconciledAt == nil || reconciled.ReconciliationNote != "external payments reconciled" {
		t.Fatalf("reconciled epoch=%#v", reconciled)
	}
	if open, err := store.OpenEpoch(ctx, pool); err != nil || open != nil {
		t.Fatalf("open epoch after reconcile=%v err=%v", open, err)
	}
	if err := store.CheckWritable(ctx, pool); err != nil {
		t.Fatalf("startup check after reconcile=%v", err)
	}
}

// A second reconcile of the same epoch is refused, so an operator cannot
// rewrite the reconciliation attestation.
func TestRestoreEpochSecondReconcileIsRefused(t *testing.T) {
	ctx := context.Background()
	pool := restorePool(t)
	closeOpenEpochs(t, pool)
	store := restorestore.Store{}
	epoch := insertEpoch(t, pool, restoreLabel(t), "operator-restore")
	for attempt := 0; attempt < 1; attempt++ {
		transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
		if err != nil {
			t.Fatal(err)
		}
		if _, err = store.ReconcileTx(ctx, transaction, epoch.Epoch, "operator-reconcile", "reconciled"); err != nil {
			t.Fatal(err)
		}
		if err = transaction.Commit(ctx); err != nil {
			t.Fatal(err)
		}
	}
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	if _, err = store.ReconcileTx(ctx, transaction, epoch.Epoch, "operator-reconcile", "again"); !errors.Is(err, kernelstore.ErrNoRows) {
		t.Fatalf("second reconcile=%v want no rows", err)
	}
}
