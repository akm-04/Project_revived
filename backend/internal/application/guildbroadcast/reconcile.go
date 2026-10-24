package guildbroadcast

import (
	"context"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/guildcore"
	gb "gxb.local/backend/v2/internal/domain/guildbroadcast"
	"gxb.local/backend/v2/internal/foundation/obligation"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

const ReconcileProviderName = "GUILD_BROADCAST_PENDING_V1"
const DefaultReconcileBatch = 32
const DeliveryOperationBudget = 30 * time.Second

type ReconcileStore interface {
	ListDuePendingForUpdateTx(context.Context, tx.Tx, time.Time, int) ([]gb.Binding, error)
	ReschedulePendingTx(context.Context, tx.Tx, gb.Binding, time.Time) error
}
type Reconciler struct {
	Runner  tx.Runner
	Store   ReconcileStore
	Sources ImmutableSourceReader
	Enqueue obligation.Queue
}

func (v Reconciler) Name() string { return ReconcileProviderName }
func (v Reconciler) Reconcile(c context.Context, op gen.TimedOperation, limit int) (gen.ReconcileResult, error) {
	out := gen.ReconcileResult{Provider: v.Name()}
	if v.Runner.DB == nil || v.Store == nil || v.Sources.Store == nil || v.Sources.Receipts == nil || v.Sources.Content == nil || v.Enqueue == nil || op.Validate() != nil || limit < 1 || limit > gen.MaxReconcileBatch {
		return out, ErrConflict
	}
	c, cancel := context.WithTimeout(c, DeliveryOperationBudget)
	defer cancel()
	_, e := v.Runner.Run(c, op.Operation(), guildcore.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(c context.Context, sc tx.Scope) error {
		// Reset attempt counters; aborted insertions do not count as wakeups.
		out = gen.ReconcileResult{Provider: v.Name()}
		bindings, e := v.Store.ListDuePendingForUpdateTx(c, sc.Tx, op.DecisionAt(), limit)
		if e != nil {
			return e
		}
		if len(bindings) > limit {
			return ErrConflict
		}
		for _, b := range bindings {
			if b.State != gb.Pending || b.Validate() != nil || b.NextWakeupAt.After(op.DecisionAt()) || b.LastEnqueueAt.After(op.DecisionAt()) {
				return ErrConflict
			}
			_, current, e := v.Sources.ReadGuildBroadcastMailSourceTx(c, sc.Tx, b.SourceID, b.RecipientID)
			if e != nil {
				return e
			}
			if current != b {
				return ErrConflict
			}
			job, e := MailObligation(b.SourceID, b.RecipientID, op.DecisionAt())
			if e != nil {
				return e
			}
			if e = v.Enqueue.InsertTx(c, sc.Tx, job); e != nil {
				return e
			}
			if e = v.Store.ReschedulePendingTx(c, sc.Tx, b, op.DecisionAt()); e != nil {
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

type ReconcileHandler struct {
	Kernel     gen.ReconcileKernel
	Operations operation.Factory
	Batch      int
}

func (h ReconcileHandler) HandleObligation(c context.Context, o obligation.Obligation) error {
	if o.Kind != ReconcileKind || ValidateObligation(o) != nil || h.Operations.Clock == nil {
		return ErrConflict
	}
	c, cancel := context.WithTimeout(c, DeliveryOperationBudget)
	defer cancel()
	op, e := h.Operations.New(policy.Set{})
	if e != nil {
		return e
	}
	batch := h.Batch
	if batch == 0 {
		batch = DefaultReconcileBatch
	}
	_, e = h.Kernel.Run(c, op, batch)
	return e
}
