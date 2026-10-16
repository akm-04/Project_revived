package conquerschool

import (
	"context"
	"errors"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

func Profile() tx.Profile {
	return tx.Profile{Name: "I7C2J_CONQUER_FACTS", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 8 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 15 * time.Second}
}

type BackfillDirectory interface {
	ListPlayerRootsTx(context.Context, tx.Queryer) ([]playerroot.Root, error)
	playerroot.TxLocker
}
type UnknownInitializer interface {
	InsertLegacyUnknownTx(context.Context, tx.Tx, identity.PlayerID, string, operation.Context, time.Time) error
}

func RunBackfill(c context.Context, timed gen.TimedRunner, players BackfillDirectory, owner UnknownInitializer, rev string, op operation.Context) error {
	pin, ok := op.Policies.Get("content")
	if ok && pin != rev {
		return errors.New("conquer: backfill content mismatch")
	}
	if !ok {
		var e error
		op.Policies, e = policy.NewSet(append(op.Policies.Refs(), policy.Ref{Name: "content", Version: rev})...)
		if e != nil {
			return e
		}
	}
	var roots []playerroot.Root
	res, e := timed.Runner.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		var e error
		roots, e = players.ListPlayerRootsTx(c, sc.Tx)
		return e
	})
	if e != nil {
		return e
	}
	if res.Outcome != tx.DefiniteCommit {
		return errors.New("conquer: unresolved player enumeration")
	}
	for _, r := range roots {
		_, res, e = timed.Run(c, op, Profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(c context.Context, sc gen.TimedScope) error {
			if _, e := players.LockPlayerRootsTx(c, sc.Tx, r.LogicalServerID, []identity.PlayerID{r.PlayerID}); e != nil {
				return e
			}
			return owner.InsertLegacyUnknownTx(c, sc.Tx, r.PlayerID, rev, sc.Operation.Operation(), sc.Operation.DecisionAt())
		})
		if e != nil {
			return e
		}
		if res.Outcome != tx.DefiniteCommit {
			return errors.New("conquer: unresolved legacy marker")
		}
	}
	return nil
}
