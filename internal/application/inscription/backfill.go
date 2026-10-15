package inscription

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
	return tx.Profile{Name: "I7C2F_COURSE_INPUTS", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 8 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 15 * time.Second}
}

type BackfillHeroPort interface {
	ListHeroRootPlayerIDsTx(context.Context, tx.Queryer) ([]identity.PlayerID, error)
	LockRootTx(context.Context, tx.Tx, identity.PlayerID) (character.HeroRoot, error)
	ListHeroesTx(context.Context, tx.Queryer, identity.PlayerID) ([]character.Hero, error)
}
type BackfillPort interface {
	EnsureRootTx(context.Context, tx.Tx, identity.PlayerID, string, time.Time) error
	EnsureHeroTx(context.Context, tx.Tx, identity.PlayerID, int64, time.Time) error
}

type CertificateSeedPort interface {
	EnsureInscriptionCertificatesTx(context.Context, tx.Tx, identity.PlayerID, string, time.Time) error
}

func RunBackfill(ctx context.Context, timed gen.TimedRunner, heroes BackfillHeroPort, owner BackfillPort, values CertificateSeedPort, rev string, op operation.Context) error {
	if heroes == nil || owner == nil || values == nil || len(rev) != 64 {
		return errors.New("inscription: invalid backfill scope")
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
		return errors.New("inscription: unresolved backfill enumeration")
	}
	for _, p := range players {
		_, r, e := timed.Run(ctx, op, Profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(ctx context.Context, sc gen.TimedScope) error {
			if _, e := heroes.LockRootTx(ctx, sc.Tx, p); e != nil {
				return e
			}
			if e := owner.EnsureRootTx(ctx, sc.Tx, p, rev, sc.Operation.DecisionAt()); e != nil {
				return e
			}
			hs, e := heroes.ListHeroesTx(ctx, sc.Tx, p)
			if e != nil {
				return e
			}
			for _, h := range hs {
				if e = owner.EnsureHeroTx(ctx, sc.Tx, p, h.PartnerID, sc.Operation.DecisionAt()); e != nil {
					return e
				}
			}
			return values.EnsureInscriptionCertificatesTx(ctx, sc.Tx, p, rev, sc.Operation.DecisionAt())
		})
		if e != nil {
			return e
		}
		if r.Outcome != tx.DefiniteCommit {
			return errors.New("inscription: incomplete owning backfill")
		}
	}
	return nil
}
