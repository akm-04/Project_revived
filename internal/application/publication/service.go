package publication

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	pub "gxb.local/backend/v2/internal/domain/publication"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type Store interface {
	InstallTx(context.Context, tx.Tx, pub.Set, string) error
	SelectTx(context.Context, tx.Queryer, string, identity.LogicalServerID, time.Time) (pub.Set, bool, error)
	MarkerTx(context.Context, tx.Queryer, identity.PlayerID, ids.UUID) (bool, error)
	LockMarkerTx(context.Context, tx.Tx, identity.PlayerID, ids.UUID) error
	MarkTx(context.Context, tx.Tx, identity.PlayerID, ids.UUID, time.Time) error
}
type ActorFence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}
type Service struct {
	Timed       generation.TimedRunner
	Store       Store
	PlayerRoots playerroot.TxLocker
	Fence       ActorFence
	Evidence    tx.Queryer
}
type View = pub.View

var ErrUnavailable = errors.New("publication unavailable")

func profile() tx.Profile {
	return tx.Profile{Name: "publication", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 8 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 12 * time.Second}
}
func (s Service) Install(ctx context.Context, op operation.Context, c pub.Catalog) error {
	if s.Store == nil || s.Timed.Runner.DB == nil {
		return ErrUnavailable
	}
	sets := make([]pub.Set, len(c.Sets))
	digests := make([]string, len(c.Sets))
	var e error
	for i, v := range c.Sets {
		sets[i], digests[i], e = v.Canonical()
		if e != nil {
			return e
		}
	}
	_, e = s.Timed.Runner.Run(ctx, op, profile(), tx.Options{Isolation: tx.ReadCommitted}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(c context.Context, t tx.Scope) error {
		for i, v := range sets {
			if e := s.Store.InstallTx(c, t.Tx, v, digests[i]); e != nil {
				return e
			}
		}
		return nil
	})
	return e
}
func (s Service) Read(ctx context.Context, op operation.Context, family string, server identity.LogicalServerID, player identity.PlayerID) (View, error) {
	if s.Store == nil || s.Timed.Binder.Time == nil || s.Timed.Runner.DB == nil {
		return View{}, ErrUnavailable
	}
	if family != pub.Announcement && (!server.Valid() || !player.Valid()) {
		return View{}, pub.ErrInvalid
	}
	var v View
	_, _, e := s.Timed.Run(ctx, op, profile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, t generation.TimedScope) error {
		var e error
		v = View{HasRead: true}
		v.Set, v.Visible, e = s.Store.SelectTx(c, t.Tx, family, server, t.Operation.DecisionAt())
		if e != nil {
			return e
		}
		if v.Visible && family == pub.Picture {
			v.HasRead, e = s.Store.MarkerTx(c, t.Tx, player, v.Set.ID)
		}
		return e
	})
	if e != nil {
		return View{}, e
	}
	return v, nil
}

type markerBinding struct {
	bound    bool
	visible  bool
	set      ids.UUID
	player   identity.PlayerID
	store    Store
	evidence tx.Queryer
}

func (b *markerBinding) ResolveTimed(c context.Context, _ generation.TimedResolutionRequest) (tx.Resolution, error) {
	if !b.bound || !b.visible || b.evidence == nil {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	found, e := b.store.MarkerTx(c, b.evidence, b.player, b.set)
	if e != nil {
		return tx.Resolution{}, e
	}
	if found {
		return tx.Resolution{State: tx.ResolutionCommitted, Evidence: b.set}, nil
	}
	return tx.Resolution{State: tx.ResolutionUnknown}, nil
}

// Mark uses the current server-visible nonempty set. The stock command has no
// display-set ID: it cannot guarantee binding to a previously displayed popup.
func (s Service) Mark(ctx context.Context, op operation.Context, a identity.ActorContext) error {
	if s.Store == nil || s.Fence == nil || s.PlayerRoots == nil || s.Evidence == nil || !a.PlayerID.Valid() || !a.LogicalServerID.Valid() {
		return ErrUnavailable
	}
	b := &markerBinding{player: a.PlayerID, store: s.Store, evidence: s.Evidence}
	_, _, e := s.Timed.Run(ctx, op, profile(), tx.Options{Isolation: tx.ReadCommitted}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, AllowReplayAfterAuthoritativeNegative: false}, b, func(c context.Context, t generation.TimedScope) error {
		at := t.Operation.DecisionAt()
		if e := s.Fence.FenceActorTx(c, t.Tx, a, at); e != nil {
			return e
		}
		if _, e := s.PlayerRoots.LockPlayerRootsTx(c, t.Tx, a.LogicalServerID, []identity.PlayerID{a.PlayerID}); e != nil {
			return e
		}
		if !b.bound {
			v, ok, e := s.Store.SelectTx(c, t.Tx, pub.Picture, a.LogicalServerID, at)
			if e != nil {
				return e
			}
			b.set = v.ID
			b.visible = ok
			b.bound = true
		}
		if !b.visible {
			return nil
		}
		if _, e := MarkerLockKey(a.PlayerID, b.set); e != nil {
			return e
		}
		if _, e := MarkerCreationFence(a.PlayerID); e != nil {
			return e
		}
		// PlayerRoot315 is held. It serializes absence before Marker390 locks an existing row.
		if e := s.Store.LockMarkerTx(c, t.Tx, a.PlayerID, b.set); e != nil {
			return e
		}
		return s.Store.MarkTx(c, t.Tx, a.PlayerID, b.set, at)
	})
	return e
}
