package herorecommend

import (
	"context"

	gen "gxb.local/backend/v2/internal/application/generation"
	d "gxb.local/backend/v2/internal/domain/herorecommend"
	"gxb.local/backend/v2/internal/domain/identity"
)

const ReconcileProviderName = "I9_10_HERO_RECOMMEND"

// Reconciler refreshes weekly snapshots by bounded logical-server pages. It is
// a derived-read provider: it never mutates a mode owner.
type Reconciler struct {
	Service      Service
	lastServerID identity.LogicalServerID
}

func (*Reconciler) Name() string { return ReconcileProviderName }

func (r *Reconciler) Reconcile(ctx context.Context, op gen.TimedOperation, limit int) (gen.ReconcileResult, error) {
	out := gen.ReconcileResult{Provider: r.Name()}
	if limit <= 0 || r.Service.Cohort == nil || r.Service.Fresh == nil {
		return out, nil
	}
	servers, err := r.Service.Cohort.ListLogicalServersAfterTx(ctx, r.Service.Fresh, r.lastServerID, limit)
	if err != nil {
		return out, err
	}
	if len(servers) == 0 && r.lastServerID.Valid() {
		r.lastServerID = 0
		servers, err = r.Service.Cohort.ListLogicalServersAfterTx(ctx, r.Service.Fresh, r.lastServerID, limit)
		if err != nil {
			return out, err
		}
	}
	for _, server := range servers {
		if !server.Valid() || server <= r.lastServerID {
			return out, d.ErrUnavailable
		}
		if _, err := r.Service.ensureSnapshot(ctx, op.Operation(), server); err != nil {
			return out, err
		}
		r.lastServerID = server
		out.Scanned++
		out.Settled++
	}
	return out, nil
}
