//go:build postgres

package kernelstore_test

import (
	"context"
	"os"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestStoredReceiptReadsBackOperationID(t *testing.T) {
	dsn := os.Getenv("GXB_KERNELSTORE_RECEIPT_DSN")
	if dsn == "" {
		t.Skip("GXB_KERNELSTORE_RECEIPT_DSN required")
	}
	ctx, cancel := context.WithTimeout(context.Background(), time.Minute)
	defer cancel()
	pool, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Second, ApplicationName: "r8-4b-receipt-operation"})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)

	op, err := (operation.Factory{Clock: clock.Fixed{T: time.Unix(1700000000, 123456000).UTC()}}).New(policy.Set{})
	if err != nil {
		t.Fatal(err)
	}
	identity := receipt.Identity{OwnerKind: "player", OwnerKey: "99999900001", Domain: "r8-4b-probe", Operation: "probe", SemanticKey: op.ID.String()}
	fingerprint, err := receipt.FingerprintRequest(map[string]any{"probe": true})
	if err != nil {
		t.Fatal(err)
	}
	created, err := receipt.New(op, identity, "R8_4B_PROBE", "gxb.r8-4b.probe.v1", []byte(`{"probe":true}`), fingerprint)
	if err != nil {
		t.Fatal(err)
	}

	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	result, err := (kernelstore.Store{}).PutTx(ctx, transaction, created)
	if err != nil {
		t.Fatal(err)
	}
	if !result.Inserted {
		t.Fatal("receipt was not inserted")
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		_, _ = pool.Raw().Exec(ctx, `DELETE FROM gxb_operation_receipts WHERE receipt_id=$1`, created.ID.String())
	})

	stored, found, err := (kernelstore.Store{}).FindTx(ctx, pool, identity)
	if err != nil {
		t.Fatal(err)
	}
	if !found {
		t.Fatal("stored receipt not found")
	}
	if stored.OperationID != op.ID {
		t.Fatalf("stored operation id=%s want %s", stored.OperationID, op.ID)
	}
}
