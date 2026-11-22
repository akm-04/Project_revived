package course

import (
	"context"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// recommendRead answers 2500 with an empty recommendation list: no stock
// selection rule is recovered, and the callback needs the key to be present.
func (s Service) recommendRead(ctx context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	out := map[string]any{"recommend_list": []any{}}
	_, result, e := s.Timed.Run(ctx, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, sc gen.TimedScope) error {
		return s.Fence.FenceActorTx(ctx, sc.Tx, a, sc.Operation.DecisionAt())
	})
	if e != nil {
		return nil, e
	}
	if result.Outcome != tx.DefiniteCommit {
		return nil, ErrUnavailable
	}
	return out, nil
}
