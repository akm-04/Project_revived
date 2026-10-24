package guildinvite

import (
	"context"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerroot"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

func ProgressProfile() tx.Profile {
	return tx.Profile{Name: "I7A8B_GUILD_PROGRESS", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 8 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 12 * time.Second}
}

type Delivery struct {
	Timed   gen.TimedRunner
	Reads   tx.Runner
	Store   Store
	Sources ImmutableReader
	Players playerroot.RecipientLocker
	Target  Target
}

func (v Delivery) valid() bool {
	return v.Timed.Runner.DB != nil && v.Timed.Binder.Time != nil && v.Reads.DB != nil && v.Store != nil && v.Sources != nil && v.Players != nil && v.Target != nil
}

func (v Delivery) proof(c context.Context, q tx.Queryer, id ids.UUID) (gi.Issue, gi.TargetProof, error) {
	s, e := v.Sources.ReadIssueEvidenceTx(c, q, id)
	if e != nil {
		return s, gi.TargetProof{}, e
	}
	p, ok, e := v.Target.ReadInviteTargetProofTx(c, q, id)
	if e != nil {
		return s, p, e
	}
	if !ok || p.Matches(s) != nil {
		return s, p, gi.ErrEvidence
	}
	return s, p, nil
}

type deliveryAckResolver struct {
	Delivery Delivery
	ID       ids.UUID
}

func (r deliveryAckResolver) ResolveTimed(c context.Context, _ gen.TimedResolutionRequest) (tx.Resolution, error) {
	terminal := false
	_, e := r.Delivery.Reads.Run(c, operation.Context{}, ProgressProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		_, p, e := r.Delivery.proof(c, sc.Tx, r.ID)
		if e != nil {
			return e
		}
		d, ok, e := r.Delivery.Store.ReadDeliveryTx(c, sc.Tx, r.ID)
		if e != nil {
			return e
		}
		if !ok || d.Matches(p) != nil {
			return gi.ErrEvidence
		}
		terminal = d.State != gi.Pending
		return nil
	})
	if e != nil {
		return tx.Resolution{}, e
	}
	if !terminal {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	return tx.Resolution{State: tx.ResolutionCommitted}, nil
}

// Acknowledge is separately callable for recovery/testing after a visible
// target commit. The supplied proof is reread, never accepted as caller truth.
func (v Delivery) Acknowledge(c context.Context, id ids.UUID, wanted gi.TargetProof) error {
	if !v.valid() || id.IsZero() || wanted.SourceID != id || wanted.Validate() != nil {
		return gi.ErrEvidence
	}
	var initial gi.Issue
	_, e := v.Reads.Run(c, operation.Context{}, ProgressProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		var e error
		initial, e = v.Sources.ReadIssueEvidenceTx(c, sc.Tx, id)
		return e
	})
	if e != nil {
		return e
	}
	_, _, e = v.Timed.Run(c, initial.Operation, ProgressProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, deliveryAckResolver{Delivery: v, ID: id}, func(c context.Context, sc gen.TimedScope) error {
		// The complete typed315 fence precedes the source350 ACK leaf. No Guild
		// root is retained, and no target command is executed under that leaf.
		if _, e := v.Players.LockBoundRecipientTx(c, sc.Tx, initial.Server, initial.Tuple.Recipient); e != nil {
			return e
		}
		s, p, e := v.proof(c, sc.Tx, id)
		if e != nil {
			return e
		}
		if p != wanted || p.Matches(s) != nil {
			return gi.ErrEvidence
		}
		d, ok, e := v.Store.LockDeliveryTx(c, sc.Tx, id)
		if e != nil {
			return e
		}
		if !ok || d.Matches(p) != nil {
			return gi.ErrEvidence
		}
		if d.State != gi.Pending {
			return nil
		}
		return v.Store.AcknowledgeDeliveryTx(c, sc.Tx, p, sc.Operation.DecisionAt())
	})
	return e
}

func (v Delivery) Deliver(c context.Context, id ids.UUID) error {
	if !v.valid() || id.IsZero() {
		return gi.ErrEvidence
	}
	c, cancel := context.WithTimeout(c, 30*time.Second)
	defer cancel()
	p, e := v.Target.Materialize(c, id)
	if e != nil {
		return e
	}
	return v.Acknowledge(c, id, p)
}
