package herorecommend

import (
	"context"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/identity"
)

const ReconcileProviderName = "I9_10_HERO_RECOMMEND"

// Reconciler refreshes the weekly snapshot for logical servers that own player
// roots. It is a derived-read provider: it never mutates a mode owner.
type Reconciler struct{ Service Service }

func (Reconciler) Name() string { return ReconcileProviderName }

func (r Reconciler) Reconcile(ctx context.Context, op gen.TimedOperation, limit int) (gen.ReconcileResult, error) {
	out := gen.ReconcileResult{Provider: r.Name()}
	if r.Service.Cohort == nil || r.Service.Fresh == nil {
		return out, nil
	}
	roots, err := r.Service.Cohort.ListPlayerRootsTx(ctx, r.Service.Fresh)
	if err != nil {
		return out, err
	}
	seen := map[identity.LogicalServerID]bool{}
	for _, root := range roots {
		if out.Scanned >= limit {
			break
		}
		if root.Validate() != nil || seen[root.LogicalServerID] {
			continue
		}
		seen[root.LogicalServerID] = true
		out.Scanned++
		if _, err := r.Service.ensureSnapshot(ctx, op.Operation(), root.LogicalServerID); err != nil {
			return out, err
		}
		out.Settled++
	}
	return out, nil
}
