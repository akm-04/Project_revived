package socialpresence

import (
	"context"
	"errors"

	appgeneration "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const ReconcileProviderName = "I7A3_SOCIAL_PRESENCE"

type Reconciler struct {
	Runner  tx.Runner
	Store   Store
	Expired ExpiredPlayerStore
}

func (r Reconciler) Name() string { return ReconcileProviderName }

func (r Reconciler) Reconcile(ctx context.Context, timed appgeneration.TimedOperation, limit int) (appgeneration.ReconcileResult, error) {
	result := appgeneration.ReconcileResult{Provider: ReconcileProviderName}
	if r.Runner.DB == nil || r.Store == nil || r.Expired == nil || timed.Validate() != nil || limit <= 0 || limit > appgeneration.MaxReconcileBatch {
		return result, errors.New("social presence: invalid reconciler")
	}
	players, err := r.Expired.ExpiredPlayerIDs(ctx, timed.DecisionAt(), limit)
	if err != nil {
		return result, err
	}
	result.Scanned = len(players)
	for _, pid := range players {
		changed := false
		_, err := r.Runner.Run(ctx, timed.Operation(), DefaultProfile(), tx.Options{Isolation: tx.Serializable}, retryPolicy(), nil,
			func(txctx context.Context, scope tx.Scope) error {
				if err := r.Store.EnsureAndLockRootTx(txctx, scope.Tx, pid, timed.DecisionAt()); err != nil {
					return err
				}
				settled, err := r.Store.SettleExpiredTx(txctx, scope.Tx, pid, timed.DecisionAt())
				if err != nil {
					return err
				}
				if settled.MaxExpiredAt == nil || settled.HasLiveLease {
					return nil
				}
				changed, err = r.Store.AdvanceLastSeenTx(txctx, scope.Tx, pid, *settled.MaxExpiredAt, timed.DecisionAt())
				return err
			})
		if err != nil {
			return result, err
		}
		if changed {
			result.Settled++
		} else {
			result.Noops++
		}
	}
	return result, nil
}
