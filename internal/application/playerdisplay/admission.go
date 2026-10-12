package playerdisplay

import (
	"context"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

func admissionMatches(j Admission, a identity.ActorContext, q Command, o operation.Context) bool {
	return j.Actor == a && j.Command == q && j.Operation.ID == o.ID && j.Operation.StartedAt.Equal(o.StartedAt) && j.Operation.EntropySeed == o.EntropySeed && j.Operation.Policies.Equal(o.Policies)
}

type admissionResolver struct {
	s  Service
	a  identity.ActorContext
	q  Command
	o  operation.Context
	at time.Time
}

func (r admissionResolver) Resolve(c context.Context, _ tx.ResolutionRequest) (tx.Resolution, error) {
	var j Admission
	var found bool
	res, e := r.s.Runner.Run(c, r.o, i5.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		if e := r.s.Fence.FenceActorTx(c, sc.Tx, r.a, r.at); e != nil {
			return e
		}
		var e error
		j, found, e = r.s.Store.ReadDisplayAdmissionTx(c, sc.Tx, r.o.ID.String(), false)
		return e
	})
	if e != nil {
		return tx.Resolution{}, e
	}
	if res.Outcome != tx.DefiniteCommit {
		return tx.Resolution{}, ErrUnresolved
	}
	if !found {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	if !admissionMatches(j, r.a, r.q, r.o) || j.State != "PENDING" {
		return tx.Resolution{}, ErrConflict
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: j}, nil
}
func (s Service) admit(c context.Context, a identity.ActorContext, q Command, o operation.Context, p player.DisplayCatalog, rev string, at time.Time) (Admission, bool, error) {
	out := Admission{Operation: o, Actor: a, Command: q, Revision: rev, DecisionAt: at, State: "PENDING"}
	needed := false
	blocked := false
	res, e := s.Runner.Run(c, o, i5.DefaultProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, admissionResolver{s, a, q, o, at}, func(c context.Context, sc tx.Scope) error {
		needed = false
		blocked = false
		if e := s.Fence.FenceActorTx(c, sc.Tx, a, at); e != nil {
			return e
		}
		if _, e := s.Players.LockPlayerRootsTx(c, sc.Tx, a.LogicalServerID, []identity.PlayerID{a.PlayerID}); e != nil {
			return e
		}
		prior, yes, e := s.Store.ReadDisplayAdmissionTx(c, sc.Tx, o.ID.String(), true)
		if e != nil {
			return e
		}
		if yes && !admissionMatches(prior, a, q, o) {
			return ErrConflict
		}
		if yes && prior.State != "PENDING" {
			return ErrUnresolved
		}
		pending, has, e := s.Store.PendingDisplayAdmissionTx(c, sc.Tx, a.PlayerID)
		if e != nil {
			return e
		}
		if has {
			if pending.Actor.AccountUID != a.AccountUID {
				return ErrConflict
			}
			_, receiptExists, e := s.Receipts.FindTx(c, sc.Tx, displayIdentity(a.PlayerID, pending.Command, pending.Operation))
			if e != nil {
				return e
			}
			if receiptExists {
				return ErrConflict
			}
			// Exclusive315 serializes every body and cancellation. A delayed old body
			// must recheck PENDING under315, so this is terminal negative proof, not a
			// generic receipt-miss inference. This request performs no new charge.
			if e = s.Store.SetDisplayAdmissionTx(c, sc.Tx, pending.Operation.ID.String(), "PENDING", "ABORTED"); e != nil {
				return e
			}
			blocked = true
			return nil
		}
		state, e := s.Store.ReadDisplayStateTx(c, sc.Tx, a.PlayerID, true)
		if e != nil {
			return e
		}
		if at.Before(state.Basis.Profile.UpdatedAt) {
			return ErrConflict
		}
		needed = q.Kind == "purchase" || q.Kind == "rename" && state.Basis.Profile.DisplayName != "" && state.Basis.Profile.DisplayName != q.Name
		if !needed {
			return nil
		}
		return s.Store.InsertDisplayAdmissionTx(c, sc.Tx, out)
	})
	if e != nil {
		return out, false, e
	}
	if res.Outcome != tx.DefiniteCommit {
		return out, false, ErrUnresolved
	}
	if blocked {
		return out, false, ErrUnresolved
	}
	if res.Evidence != nil {
		j, ok := res.Evidence.(Admission)
		if !ok {
			return out, false, ErrConflict
		}
		return j, true, nil
	}
	return out, needed, nil
}
