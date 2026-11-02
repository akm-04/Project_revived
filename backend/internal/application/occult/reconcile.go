package occult

import (
	"context"

	gen "gxb.local/backend/v2/internal/application/generation"
	d "gxb.local/backend/v2/internal/domain/occult"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Reconciler purges the report rows past their retention window in bounded
// batches; every other write belongs to a command.
type Reconciler struct{ Service Mode }

func (Reconciler) Name() string { return "occult" }

func (r Reconciler) Reconcile(c context.Context, timed gen.TimedOperation, limit int) (gen.ReconcileResult, error) {
	out := gen.ReconcileResult{Provider: r.Name()}
	s := r.Service
	if !s.ready() || limit < 1 || limit > gen.MaxReconcileBatch {
		return out, d.ErrUnavailable
	}
	var purged int64
	_, _, err := s.Timed.Run(c, timed.Operation(), profile(), tx.Options{Isolation: tx.Serializable}, retry(), nil, func(c context.Context, sc gen.TimedScope) error {
		var err error
		purged, err = s.Store.PurgeExpiredReportsTx(c, sc.Tx, sc.Operation.DecisionAt(), int64(limit))
		return err
	})
	if err != nil {
		return out, err
	}
	out.Scanned, out.Settled = int(purged), int(purged)
	return out, nil
}
