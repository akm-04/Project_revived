package adventure

import (
	"context"

	gen "gxb.local/backend/v2/internal/application/generation"
	d "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Reconciler purges finished occurrences and expired co-op reports in bounded
// batches. It never advances an occurrence; a read only repairs delivery.
type Reconciler struct{ Service Mode }

func (Reconciler) Name() string { return "adventure" }

func (r Reconciler) Reconcile(c context.Context, timed gen.TimedOperation, limit int) (gen.ReconcileResult, error) {
	out := gen.ReconcileResult{Provider: r.Name()}
	s := r.Service
	if !s.ready() || limit < 1 || limit > gen.MaxReconcileBatch {
		return out, d.ErrUnavailable
	}
	var purged int64
	_, _, err := s.Timed.Run(c, timed.Operation(), profile(), tx.Options{Isolation: tx.Serializable}, retry(), nil, func(c context.Context, sc gen.TimedScope) error {
		at := sc.Operation.DecisionAt()
		var err error
		purged, err = s.Store.PurgeOccurrencesTx(c, sc.Tx, at.Add(-occurrenceRetention), int64(limit))
		if err != nil || purged >= int64(limit) {
			return err
		}
		reports, err := s.Store.PurgeExpiredReportsTx(c, sc.Tx, at, int64(limit)-purged)
		purged += reports
		return err
	})
	if err != nil {
		return out, err
	}
	out.Scanned, out.Settled = int(purged), int(purged)
	return out, nil
}
