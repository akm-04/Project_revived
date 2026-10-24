// Package socialfriendbase composes typed Social projection and FriendDM ports.
package socialfriendbase

import (
	"context"
	"errors"
	dm "gxb.local/backend/v2/internal/application/frienddm"
	gen "gxb.local/backend/v2/internal/application/generation"
	sp "gxb.local/backend/v2/internal/application/socialprojection"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Service struct {
	FriendDM   dm.Service
	Projection sp.Service
}

func (s Service) LoadBase(c context.Context, a identity.ActorContext, op operation.Context) (sp.Result, error) {
	if !dm.ActorValid(a) {
		return sp.Result{}, dm.ErrInvalid
	}
	for attempt := 0; attempt < 3; attempt++ {
		m, e := s.FriendDM.Preflight(c, a.PlayerID, op)
		if e != nil {
			return sp.Result{}, e
		}
		var private sp.Result
		_, result, e := s.FriendDM.Timed.Run(c, op, dm.Profile(), tx.Options{Isolation: tx.RepeatableRead}, dm.Retry(), projectionResolver{s.FriendDM, a.PlayerID}, func(c context.Context, sc gen.TimedScope) error {
			private = sp.Result{}
			known, ok, e := s.FriendDM.Store.FindProjection(c, sc.Tx, op.ID.String())
			if e != nil {
				return e
			}
			if ok && known.Recipient != a.PlayerID {
				return dm.ErrInvalid
			}
			plan := m
			if ok {
				plan.Rows = nil
			} // No historical sender locks or new drain for a known committed projection.
			privacy, e := s.FriendDM.LockPlanTx(c, sc.Tx, plan)
			if e != nil {
				return e
			}
			base, e := s.Projection.ReadBasePreparedTx(c, sc.Tx, a, privacy.RecipientRootPresent)
			if e != nil {
				return e
			}
			if ok {
				base.PrivateMessages = append([]dm.Projection{}, known.Messages...)
				private = base
				return nil
			}
			prepared, e := s.FriendDM.PrepareDrainTx(c, sc.Tx, m, privacy, op, sc.Operation.DecisionAt())
			if e != nil {
				return e
			}
			base.PrivateMessages = prepared.Messages()
			if e = s.FriendDM.ApplyDrainTx(c, sc.Tx, prepared); e != nil {
				return e
			}
			private = base
			return nil
		})
		if errors.Is(e, dm.ErrManifestChanged) {
			continue
		}
		if e != nil {
			return sp.Result{}, e
		}
		if result.Outcome != tx.DefiniteCommit {
			return sp.Result{}, dm.ErrUnavailable
		}
		return private, nil
	}
	return sp.Result{}, dm.ErrManifestChanged
}

type projectionResolver struct {
	s         dm.Service
	recipient identity.PlayerID
}

func (r projectionResolver) ResolveTimed(c context.Context, req gen.TimedResolutionRequest) (tx.Resolution, error) {
	receipt, ok, e := r.s.Store.FindProjection(c, r.s.Queryer, req.Operation.Operation().ID.String())
	if e != nil {
		return tx.Resolution{}, e
	}
	if ok && receipt.Recipient == r.recipient {
		return tx.Resolution{State: tx.ResolutionCommitted, Evidence: receipt.OperationID}, nil
	}
	return tx.Resolution{State: tx.ResolutionUnknown}, nil
}
func (s Service) LoadList(c context.Context, a identity.ActorContext, k sp.ListKind, op operation.Context) (sp.Result, error) {
	return s.Projection.LoadList(c, a, k, op)
}
func (s Service) Search(c context.Context, a identity.ActorContext, q sp.SearchQuery, op operation.Context) (sp.Result, error) {
	return s.Projection.Search(c, a, q, op)
}
func (s Service) Recommend(c context.Context, a identity.ActorContext, op operation.Context) (sp.Result, error) {
	return s.Projection.Recommend(c, a, op)
}
