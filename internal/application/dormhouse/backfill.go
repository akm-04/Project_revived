package dormhouse

import (
	"context"
	"errors"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/character"
	dorm "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

func Profile() tx.Profile {
	return tx.Profile{Name: "I7C2C_DORM_INPUTS", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 8 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 15 * time.Second}
}

type BackfillHeroPort interface {
	ListHeroRootPlayerIDsTx(context.Context, tx.Queryer) ([]identity.PlayerID, error)
	ListHeroesTx(context.Context, tx.Queryer, identity.PlayerID) ([]character.Hero, error)
	LockRootTx(context.Context, tx.Tx, identity.PlayerID) (character.HeroRoot, error)
}
type BackfillDormPort interface {
	EnsureRootTx(context.Context, tx.Tx, identity.PlayerID, string, time.Time) error
	EnsureHeroTx(context.Context, tx.Tx, character.HeroRef, time.Time) error
	LockRootTx(context.Context, tx.Tx, identity.PlayerID) (dorm.Root, error)
}

// Explicit owning deployment, never a read/startup repair. As with inherited
// Library backfill, this locks population/root before missing inserts. Deploy
// quiesces old writers before backfill/activation and then starts the new
// bootstrap/fresh-facet composition; fixtures do not qualify that choreography.
func RunBackfill(ctx context.Context, timed gen.TimedRunner, heroes BackfillHeroPort, owner BackfillDormPort, revision string, op operation.Context) error {
	if heroes == nil || owner == nil || !dorm.ValidRevision(revision) {
		return dorm.ErrUnqualified
	}
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
		return errors.New("dorm: unresolved backfill enumeration")
	}
	for _, pid := range players {
		_, res, e = timed.Run(ctx, op, Profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(ctx context.Context, scope gen.TimedScope) error {
			if _, e := heroes.LockRootTx(ctx, scope.Tx, pid); e != nil {
				return e
			}
			if e := owner.EnsureRootTx(ctx, scope.Tx, pid, revision, scope.Operation.DecisionAt()); e != nil {
				return e
			}
			if _, e := owner.LockRootTx(ctx, scope.Tx, pid); e != nil {
				return e
			}
			live, e := heroes.ListHeroesTx(ctx, scope.Tx, pid)
			if e != nil {
				return e
			}
			for _, h := range live {
				if h.PlayerID != pid || h.ValidatePersistent() != nil {
					return dorm.ErrUnqualified
				}
				if e = owner.EnsureHeroTx(ctx, scope.Tx, h.Ref(), scope.Operation.DecisionAt()); e != nil {
					return e
				}
			}
			return nil
		})
		if e != nil {
			return e
		}
		if res.Outcome != tx.DefiniteCommit {
			return errors.New("dorm: unresolved owner backfill; activation forbidden")
		}
	}
	return nil
}
