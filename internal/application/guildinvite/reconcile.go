package guildinvite

import (
	"context"
	gen "gxb.local/backend/v2/internal/application/generation"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/obligation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

const ReconcileProviderName = "GUILD_INVITE_PENDING_V1"

type DueReference struct {
	ID         ids.UUID
	Marker     bool
	Last, Next time.Time
}
type ReconcileStore interface {
	ListDueInviteForUpdateTx(context.Context, tx.Tx, time.Time, int) ([]DueReference, error)
	RescheduleInviteTx(context.Context, tx.Tx, DueReference, time.Time) error
}
type Reconciler struct {
	Runner  tx.Runner
	Store   ReconcileStore
	Sources SourceReader
	Target  ProgressTarget
	Enqueue obligation.Queue
}

func (v Reconciler) Name() string { return ReconcileProviderName }
func (v Reconciler) Reconcile(c context.Context, op gen.TimedOperation, limit int) (gen.ReconcileResult, error) {
	out := gen.ReconcileResult{Provider: v.Name()}
	if v.Runner.DB == nil || v.Store == nil || v.Sources.Store == nil || v.Target == nil || v.Enqueue == nil || op.Validate() != nil || limit < 1 || limit > gen.MaxReconcileBatch {
		return out, gi.ErrEvidence
	}
	c, cancel := context.WithTimeout(c, 30*time.Second)
	defer cancel()
	_, e := v.Runner.Run(c, op.Operation(), ProgressProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(c context.Context, sc tx.Scope) error {
		out = gen.ReconcileResult{Provider: v.Name()}
		refs, e := v.Store.ListDueInviteForUpdateTx(c, sc.Tx, op.DecisionAt(), limit)
		if e != nil {
			return e
		}
		if len(refs) > limit {
			return gi.ErrEvidence
		}
		for _, ref := range refs {
			if ref.ID.IsZero() || ref.Next.After(op.DecisionAt()) || ref.Last.After(op.DecisionAt()) {
				return gi.ErrEvidence
			}
			var job obligation.Obligation
			if ref.Marker {
				m, e := v.Sources.ReadMarkerEvidenceTx(c, sc.Tx, ref.ID)
				if e != nil {
					return e
				}
				_, p, ok, e := v.Sources.Store.ReadMarkerTx(c, sc.Tx, ref.ID)
				if e != nil {
					return e
				}
				if !ok || p.Complete || p.LastEnqueueAt != ref.Last || p.NextWakeupAt != ref.Next {
					return gi.ErrEvidence
				}
				if p.CursorProof != nil {
					if e = v.Target.ValidateCoveredInviteInvalidationsTx(c, sc.Tx, m, p.CursorSerial, p.CursorProof.Request.Covered); e != nil {
						return e
					}
				}
				if e = v.Sources.ValidateCoveredEvidenceTx(c, sc.Tx, v.Target, m, p); e != nil {
					return e
				}
				job, e = MarkerObligation(ref.ID, op.DecisionAt())
				if e != nil {
					return e
				}
			} else {
				if _, e = v.Sources.ReadIssueEvidenceTx(c, sc.Tx, ref.ID); e != nil {
					return e
				}
				d, e := v.Sources.ReadIssueDeliveryEvidenceTx(c, sc.Tx, ref.ID)
				if e != nil {
					return e
				}
				if d.State != gi.Pending || d.LastEnqueueAt != ref.Last || d.NextWakeupAt != ref.Next {
					return gi.ErrEvidence
				}
				job, e = IssueObligation(ref.ID, op.DecisionAt())
				if e != nil {
					return e
				}
			}
			if e = v.Enqueue.InsertTx(c, sc.Tx, job); e != nil {
				return e
			}
			if e = v.Store.RescheduleInviteTx(c, sc.Tx, ref, op.DecisionAt()); e != nil {
				return e
			}
			out.Scanned++
			out.Wakeups++
		}
		return nil
	})
	if e != nil {
		return gen.ReconcileResult{Provider: v.Name()}, e
	}
	return out, nil
}
func (v Delivery) HandleObligation(c context.Context, o obligation.Obligation) error {
	id, e := DecodeObligation(o)
	if e != nil || o.Kind != IssueKind {
		return gi.ErrEvidence
	}
	return v.Deliver(c, id)
}
func (v Cleanup) HandleObligation(c context.Context, o obligation.Obligation) error {
	id, e := DecodeObligation(o)
	if e != nil || o.Kind != MarkerKind {
		return gi.ErrEvidence
	}
	return v.RunBatch(c, id, DefaultCleanupBatch)
}
