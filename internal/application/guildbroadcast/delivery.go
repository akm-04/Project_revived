package guildbroadcast

import (
	"context"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/guildcore"
	gb "gxb.local/backend/v2/internal/domain/guildbroadcast"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/obligation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type Delivery struct {
	Timed   gen.TimedRunner
	Reads   tx.Runner
	Store   AckStore
	Sources ImmutableSourceReader
	Target  Target
}

func terminalMatches(b gb.Binding, p gb.TargetProof) bool {
	return b.Validate() == nil && p.Validate() == nil && b.SourceID == p.SourceID && b.RecipientID == p.RecipientID && b.State == p.State && b.TargetReceiptID == p.ReceiptID && b.MailID == p.MailID && b.WireID == p.WireID
}
func (v Delivery) valid() bool {
	return v.Timed.Runner.DB != nil && v.Reads.DB != nil && v.Store != nil && v.Sources.Store != nil && v.Sources.Receipts != nil && v.Sources.Content != nil && v.Target != nil
}
func (v Delivery) committedProof(c context.Context, t tx.Tx, id ids.UUID, pid identity.PlayerID) (gb.Source, gb.TargetProof, error) {
	s, _, e := v.Sources.ReadGuildBroadcastMailSourceTx(c, t, id, pid)
	if e != nil {
		return s, gb.TargetProof{}, e
	}
	p, ok, e := v.Target.ReadGuildBroadcastProofTx(c, t, id, pid)
	if e != nil {
		return s, p, e
	}
	fp, e := s.Fingerprint()
	if e != nil || !ok || p.Validate() != nil || p.SourceID != id || p.RecipientID != pid || p.SourceFingerprint != fp {
		return s, p, ErrConflict
	}
	return s, p, nil
}

type ackResolver struct {
	D   Delivery
	ID  ids.UUID
	PID identity.PlayerID
}

func (r ackResolver) ResolveTimed(c context.Context, request gen.TimedResolutionRequest) (tx.Resolution, error) {
	terminal := false
	_, e := r.D.Reads.Run(c, request.Operation.Operation(), guildcore.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		_, p, e := r.D.committedProof(c, sc.Tx, r.ID, r.PID)
		if e != nil {
			return e
		}
		b, ok, e := r.D.Store.ReadBindingTx(c, sc.Tx, r.ID, r.PID)
		if e != nil {
			return e
		}
		if !ok {
			return ErrConflict
		}
		if b.State == gb.Pending {
			return nil
		}
		if !terminalMatches(b, p) {
			return ErrConflict
		}
		terminal = true
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
func (v Delivery) Deliver(c context.Context, id ids.UUID, pid identity.PlayerID) error {
	if !v.valid() || id.IsZero() || !pid.Valid() {
		return ErrConflict
	}
	// An error/UNKNOWN from the target never allows source ACK. A crash here
	// leaves PENDING; replay of the exact reference proves the same Mail receipt.
	target, e := v.Target.Materialize(c, id, pid)
	if e != nil {
		return e
	}
	if target.Validate() != nil {
		return ErrConflict
	}
	var source gb.Source
	_, e = v.Reads.Run(c, source.Operation, guildcore.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		var e error
		source, _, e = v.Sources.ReadGuildBroadcastMailSourceTx(c, sc.Tx, id, pid)
		return e
	})
	if e != nil {
		return e
	}
	_, _, e = v.Timed.Run(c, source.Operation, guildcore.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, ackResolver{v, id, pid}, func(c context.Context, sc gen.TimedScope) error {
		_, p, e := v.committedProof(c, sc.Tx, id, pid)
		if e != nil {
			return e
		}
		if p != target {
			return ErrConflict
		}
		b, ok, e := v.Store.LockBindingTx(c, sc.Tx, id, pid)
		if e != nil {
			return e
		}
		if !ok {
			return ErrConflict
		}
		if b.State != gb.Pending {
			if !terminalMatches(b, p) {
				return ErrConflict
			}
			return nil
		}
		return v.Store.AcknowledgeBindingTx(c, sc.Tx, p, sc.Operation.DecisionAt())
	})
	return e
}
func (v Delivery) HandleObligation(c context.Context, o obligation.Obligation) error {
	c, cancel := context.WithTimeout(c, 30*time.Second)
	defer cancel()
	id, pid, e := DecodeMailObligation(o)
	if e != nil {
		return e
	}
	return v.Deliver(c, id, pid)
}
