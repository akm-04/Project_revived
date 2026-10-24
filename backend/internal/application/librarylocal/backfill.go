package librarylocal

import (
	"context"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	library "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type BackfillHeroPort interface {
	ListHeroRootPlayerIDsTx(context.Context, tx.Queryer) ([]identity.PlayerID, error)
	ListHeroesTx(context.Context, tx.Queryer, identity.PlayerID) ([]character.Hero, error)
}
type BackfillLibraryPort interface {
	EnsurePlayerRootTx(context.Context, tx.Tx, identity.PlayerID, time.Time) error
	BackfillMissingHeroTx(context.Context, tx.Tx, character.HeroRef, time.Time) (bool, error)
}
type Backfiller struct {
	Heroes  BackfillHeroPort
	Library BackfillLibraryPort
}

// PlayerTx requires the caller's complete Character/Library lock plan and a
// stable transaction scope. It creates missing facts only; no reads synthesize facets.
func (b Backfiller) PlayerTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, now time.Time) (int, error) {
	if b.Heroes == nil || b.Library == nil || t == nil || !pid.Valid() || now.IsZero() {
		return 0, library.ErrUnqualified
	}
	if e := b.Library.EnsurePlayerRootTx(ctx, t, pid, now); e != nil {
		return 0, e
	}
	heroes, e := b.Heroes.ListHeroesTx(ctx, t, pid)
	if e != nil {
		return 0, e
	}
	created := 0
	for _, h := range heroes {
		if h.PlayerID != pid || h.ValidatePersistent() != nil {
			return 0, library.ErrUnqualified
		}
		added, e := b.Library.BackfillMissingHeroTx(ctx, t, h.Ref(), now)
		if e != nil {
			return 0, e
		}
		if added {
			created++
		}
	}
	return created, nil
}

// RunBackfill is an explicit owning deployment transition. Startup/read paths
// never call it. Each population/root pair is locked before missing inserts.
func RunBackfill(ctx context.Context, timed gen.TimedRunner, heroes interface {
	BackfillHeroPort
	LockRootTx(context.Context, tx.Tx, identity.PlayerID) (character.HeroRoot, error)
}, library interface {
	BackfillLibraryPort
	LockRootTx(context.Context, tx.Tx, identity.PlayerID) (library.PlayerFacts, error)
}, op operation.Context) error {
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
	for _, pid := range players {
		_, res, e = timed.Run(ctx, op, Profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(ctx context.Context, sc gen.TimedScope) error {
			if _, e := heroes.LockRootTx(ctx, sc.Tx, pid); e != nil {
				return e
			}
			if e := library.EnsurePlayerRootTx(ctx, sc.Tx, pid, sc.Operation.DecisionAt()); e != nil {
				return e
			}
			if _, e := library.LockRootTx(ctx, sc.Tx, pid); e != nil {
				return e
			}
			_, e := (Backfiller{Heroes: heroes, Library: library}).PlayerTx(ctx, sc.Tx, pid, sc.Operation.DecisionAt())
			return e
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
