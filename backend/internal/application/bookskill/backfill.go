package bookskill

import (
	"context"
	"errors"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

func Profile() tx.Profile {
	return tx.Profile{Name: "I7C2D_BOOK_INPUTS", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 8 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 15 * time.Second}
}

type BackfillHeroPort interface {
	ListHeroRootPlayerIDsTx(context.Context, tx.Queryer) ([]identity.PlayerID, error)
	LockRootTx(context.Context, tx.Tx, identity.PlayerID) (character.HeroRoot, error)
}
type BackfillPort interface {
	EnsureRootTx(context.Context, tx.Tx, identity.PlayerID, string, time.Time) error
}

func RunBackfill(ctx context.Context, timed gen.TimedRunner, heroes BackfillHeroPort, owner BackfillPort, rev string, op operation.Context) error {
	var players []identity.PlayerID
	res, e := timed.Runner.Run(ctx, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		var e error
		players, e = heroes.ListHeroRootPlayerIDsTx(ctx, scope.Tx)
		return e
	})
	if e != nil {
		return e
	}
	if res.Outcome != tx.DefiniteCommit {
		return errors.New("book: unresolved backfill enumeration")
	}
	for _, p := range players {
		_, r, e := timed.Run(ctx, op, Profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(ctx context.Context, sc gen.TimedScope) error {
			if _, e := heroes.LockRootTx(ctx, sc.Tx, p); e != nil {
				return e
			}
			return owner.EnsureRootTx(ctx, sc.Tx, p, rev, sc.Operation.DecisionAt())
		})
		if e != nil {
			return e
		}
		if r.Outcome != tx.DefiniteCommit {
			return errors.New("book: incomplete owning backfill")
		}
	}
	return nil
}
