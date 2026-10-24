package heroevolution

import (
	"context"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sort"
	"time"
)

func Profile() tx.Profile {
	return tx.Profile{Name: "I7C2I_EVOLUTION_INPUTS", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 8 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 15 * time.Second}
}

type BackfillHeroPort interface {
	ListHeroRootPlayerIDsTx(context.Context, tx.Queryer) ([]identity.PlayerID, error)
	LockRootTx(context.Context, tx.Tx, identity.PlayerID) (character.HeroRoot, error)
	ListHeroesTx(context.Context, tx.Queryer, identity.PlayerID) ([]character.Hero, error)
	LockHeroByPartnerIDTx(context.Context, tx.Tx, identity.PlayerID, int64) (character.Hero, error)
}
type BackfillOwner interface {
	EnsureHeroTx(context.Context, tx.Tx, identity.PlayerID, int64, time.Time) error
}

func RunBackfill(ctx context.Context, timed gen.TimedRunner, heroes BackfillHeroPort, owner BackfillOwner, op operation.Context) error {
	if heroes == nil || owner == nil {
		return ErrUnavailable
	}
	var players []identity.PlayerID
	res, e := timed.Runner.Run(ctx, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, sc tx.Scope) error {
		var e error
		players, e = heroes.ListHeroRootPlayerIDsTx(ctx, sc.Tx)
		return e
	})
	if e != nil {
		return e
	}
	if res.Outcome != tx.DefiniteCommit {
		return ErrUnavailable
	}
	for _, p := range players {
		_, res, e := timed.Run(ctx, op, Profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(ctx context.Context, sc gen.TimedScope) error {
			if _, e := heroes.LockRootTx(ctx, sc.Tx, p); e != nil {
				return e
			}
			hs, e := heroes.ListHeroesTx(ctx, sc.Tx, p)
			if e != nil {
				return e
			}
			sort.Slice(hs, func(i, j int) bool { return hs[i].PartnerID < hs[j].PartnerID })
			for _, h := range hs {
				if _, e = heroes.LockHeroByPartnerIDTx(ctx, sc.Tx, p, h.PartnerID); e != nil {
					return e
				}
			}
			for _, h := range hs {
				if e = owner.EnsureHeroTx(ctx, sc.Tx, p, h.PartnerID, sc.Operation.DecisionAt()); e != nil {
					return e
				}
			}
			return nil
		})
		if e != nil {
			return e
		}
		if res.Outcome != tx.DefiniteCommit {
			return ErrUnavailable
		}
	}
	return nil
}
