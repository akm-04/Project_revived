package championsleague

import (
	"context"
	"errors"
	gen "gxb.local/backend/v2/internal/application/generation"
	d "gxb.local/backend/v2/internal/domain/championsleague"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"time"
)

type Reconciler struct{ Service Service }

func (Reconciler) Name() string { return "champions-league" }
func (r Reconciler) Reconcile(c context.Context, timed gen.TimedOperation, limit int) (gen.ReconcileResult, error) {
	out := gen.ReconcileResult{Provider: r.Name()}
	s := r.Service
	if !s.ready() || limit < 1 || limit > gen.MaxReconcileBatch {
		return out, d.ErrUnavailable
	}
	op, e := s.pin(c, timed.Operation())
	if e != nil {
		return out, e
	}
	n, e := s.dueBatch(c, op, limit)
	out.Scanned = n
	out.Settled = n
	if e != nil {
		return out, e
	}
	if n >= limit {
		return out, nil
	}
	matches, e := s.Store.OpenTx(c, s.Fresh, limit-n)
	if e != nil {
		return out, e
	}
	for _, m := range matches {
		out.Scanned++
		a, ok, e := s.Combat.AttemptTx(c, s.Fresh, m.Attempt)
		if e != nil || !ok {
			return out, errors.Join(e, d.ErrConflict)
		}
		// A ready genuine resolution is settled after restart even if the request
		// deadline elapsed. Only an unavailable staged attempt is closed by expiry.
		if a.State == cd.Staged && a.Closable(timed.DecisionAt()) {
			e = s.terminal(c, m.ID, op, true)
		} else {
			_, e = s.finish(c, m, op, time.Millisecond)
		}
		if e != nil && !errors.Is(e, d.ErrPending) && !errors.Is(e, d.ErrRefused) {
			return out, e
		}
		next, found, e := s.Store.MatchTx(c, s.Fresh, m.ID)
		if e != nil || !found {
			return out, errors.Join(e, d.ErrConflict)
		}
		if next.Status == "FIGHTING" {
			out.Wakeups++
		} else {
			out.Settled++
		}
	}
	return out, nil
}
