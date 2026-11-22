//go:build postgres

package postgres

import (
	"context"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type oneTx struct{}

func (oneTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) { return nil, nil }
func (oneTx) QueryRow(context.Context, string, ...any) tx.Row             { return errorRow{} }
func (oneTx) Commit(context.Context) error                                { return nil }
func (oneTx) Rollback(context.Context) error                              { return nil }

type oneTxDB struct{}

func (oneTxDB) Begin(context.Context, tx.Options) (tx.Tx, error) { return oneTx{}, nil }

// C1-2: in strict mode a transaction body cannot take a second pooled connection; outside a body nothing changes.
func TestPoolRefusesNestedAcquisitionInStrictMode(t *testing.T) {
	strict := strictOneConnection
	strictOneConnection = true
	t.Cleanup(func() { strictOneConnection = strict })
	pool := &Pool{}
	profile := tx.Profile{Name: "C1_2_TEST", AcquireTimeout: time.Second, LockTimeout: time.Second, StatementTimeout: time.Second, TransactionTimeout: time.Second, CleanupTimeout: time.Second, ReconcileTimeout: time.Second, OperationTimeout: 2 * time.Second}
	op := operation.Context{ID: ids.UUID{1}, StartedAt: time.Unix(1, 0).UTC(), EntropySeed: [32]byte{9}}
	_, err := tx.Runner{DB: oneTxDB{}}.Run(context.Background(), op, profile, tx.Options{Isolation: tx.ReadCommitted}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, _ tx.Scope) error {
		if _, e := pool.Begin(ctx, tx.Options{}); !errors.Is(e, ErrNestedAcquire) {
			t.Fatalf("Begin inside a body: %v", e)
		}
		if e := pool.QueryRow(ctx, "SELECT 1").Scan(); !errors.Is(e, ErrNestedAcquire) {
			t.Fatalf("QueryRow inside a body: %v", e)
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	if e := nestedAcquire(context.Background()); e != nil {
		t.Fatalf("outside a body: %v", e)
	}
}
