package spirit

import (
	"context"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type BackpackSnapshot struct {
	Stacks  []economy.StackState
	Spirits []map[string]any
}

func (s Service) BackpackSnapshot(ctx context.Context, a identity.ActorContext, op operation.Context) (BackpackSnapshot, error) {
	bound, e := s.Timed.Binder.Bind(ctx, op)
	if e != nil {
		return BackpackSnapshot{}, e
	}
	body := BackpackSnapshot{}
	res, e := s.Reads.Run(ctx, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, sc tx.Scope) error {
		if e := s.Fence.FenceActorTx(ctx, sc.Tx, a, bound.DecisionAt()); e != nil {
			return e
		}
		rev, on, e := s.Content.SpiritInputsActiveTx(ctx, sc.Tx)
		if e != nil {
			return e
		}
		if !on {
			return ErrUnavailable
		}
		stacks, e := s.Values.ListStacksTx(ctx, sc.Tx, a.PlayerID)
		if e != nil {
			return e
		}
		for _, x := range stacks {
			if bound.DecisionAt().Before(x.UpdatedAt) {
				return ErrStale
			}
		}
		spirits, e := s.InventoryTx(ctx, sc.Tx, InputScope{a.PlayerID, rev, bound.DecisionAt()})
		if e != nil {
			return e
		}
		body = BackpackSnapshot{Stacks: stacks, Spirits: spirits}
		return nil
	})
	if e != nil {
		return BackpackSnapshot{}, e
	}
	if res.Outcome != tx.DefiniteCommit {
		return BackpackSnapshot{}, ErrUnavailable
	}
	return body, nil
}
