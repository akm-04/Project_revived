package i5

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// CurrentScalarProjectionPort returns transient current I5 owner state for a
// stock response. It is deliberately outside semantic receipts.
type CurrentScalarProjectionPort interface {
	CurrentScalar(context.Context, identity.PlayerID, string, operation.Context) (int64, error)
}

type ScalarProjectionStore interface {
	ReadScalarTx(context.Context, tx.Queryer, identity.PlayerID, string) (economy.ScalarBalance, bool, error)
}

type ScalarProjector struct {
	Runner tx.Runner
	Store  ScalarProjectionStore
}

var _ CurrentScalarProjectionPort = ScalarProjector{}

func scalarProjectionProfile() tx.Profile {
	return tx.Profile{Name: "I5_CURRENT_SCALAR_PROJECTION", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 8 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 2 * time.Second, OperationTimeout: 10 * time.Second}
}

func (p ScalarProjector) CurrentScalar(ctx context.Context, pid identity.PlayerID, key string, op operation.Context) (int64, error) {
	if p.Runner.DB == nil || p.Store == nil || !pid.Valid() || key == "" || op.ID.IsZero() || op.StartedAt.IsZero() {
		return 0, errors.New("i5 current scalar projection: invalid input")
	}
	var amount int64
	_, err := p.Runner.Run(ctx, op, scalarProjectionProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(txctx context.Context, scope tx.Scope) error {
		b, exists, err := p.Store.ReadScalarTx(txctx, scope.Tx, pid, key)
		if err != nil {
			return err
		}
		if exists {
			amount = b.Amount
		}
		return nil
	})
	return amount, err
}
