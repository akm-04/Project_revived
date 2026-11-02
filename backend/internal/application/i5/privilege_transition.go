package i5

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

// PreparedPrivilegeTransition is an I5-owned locked effect. Apply cannot discover
// another lock or read a foreign owner. Commerce owns the before/after snapshots.
type PreparedPrivilegeTransition interface {
	Apply(context.Context, tx.Tx) error
}
type PrivilegeTransitionPort interface {
	PreparePrivilegeTransitionTx(context.Context, tx.Tx, identity.PlayerID, int64, int64, int64, time.Time) (PreparedPrivilegeTransition, error)
}
type PrivilegeTransitionOwner struct {
	Store   Store
	Content ContentRuntime
}
type preparedPrivilegeTransition struct {
	store    Store
	after    economy.TemporalState
	changed  bool
	player   identity.PlayerID
	at       time.Time
	openings []player.FunctionEligibility
	version  int64
}

func (p preparedPrivilegeTransition) Apply(c context.Context, t tx.Tx) error {
	if t == nil || p.store == nil {
		return errors.New("invalid prepared privilege effect")
	}
	if len(p.openings) > 0 {
		if _, e := insertOpeningsTx(c, p.store, t, p.player, p.version, p.openings, "i9-2:function-vip:v1", p.at); e != nil {
			return e
		}
	}
	if !p.changed {
		return nil
	}
	return p.store.SaveTemporalTx(c, t, p.after)
}

// prepareVIPOpeningsTx locks function state when the new VIP level opens kind-3 gates the player's level already meets (D91).
func (s PrivilegeTransitionOwner) prepareVIPOpeningsTx(c context.Context, t tx.Tx, pid identity.PlayerID, revision string, vip int64, at time.Time) ([]player.FunctionEligibility, int64, error) {
	progression, e := s.Store.ReadProgressionTx(c, t, pid)
	if e != nil {
		return nil, 0, e
	}
	policy, e := s.Content.ResolveFunctionGatePolicyTx(c, t, revision)
	if e != nil {
		return nil, 0, e
	}
	openings := levelAndVIPEligibility(policy, pid, progression.Level, vip, at)
	if len(openings) == 0 {
		return nil, 0, nil
	}
	version, e := s.Store.LockFunctionStateTx(c, t, pid)
	return openings, version, e
}
func (s PrivilegeTransitionOwner) PreparePrivilegeTransitionTx(c context.Context, t tx.Tx, pid identity.PlayerID, oldCap, newCap, newVIP int64, at time.Time) (PreparedPrivilegeTransition, error) {
	if s.Store == nil || s.Content == nil || t == nil || !pid.Valid() || oldCap < 0 || newCap < 0 || newVIP < 0 || at.IsZero() {
		return nil, economy.ErrInvalidTemporalPolicy
	}
	// Existing R5 bands, after the caller's I4 root315. Acquire both before any
	// Commerce mutation, including initial privilege-root insertion.
	if e := s.Store.LockEconomyOwnerTx(c, t, pid); e != nil {
		return nil, e
	}
	state, ok, e := s.Store.LockTemporalTx(c, t, pid, "skill_point")
	if e != nil {
		return nil, e
	}
	if !ok || state.Validate() != nil || state.UpdatedAt.After(at) || state.ContentRevision == "" {
		return nil, economy.ErrInvalidTemporalPolicy
	}
	rp, e := s.Content.ResolveResourceTx(c, t, state.ContentRevision, grant.Line{Kind: grant.Temporal, ResourceKey: "skill_point", Amount: 1})
	if e != nil {
		return nil, e
	}
	if rp.Descriptor == nil || rp.Descriptor.Revision != state.ContentRevision || rp.Descriptor.CapRule != "VIP_PLUS_MONTHLY_PRIVILEGE" || state.PolicyVersion != state.ContentRevision {
		return nil, economy.ErrInvalidTemporalPolicy
	}
	openings, version, e := s.prepareVIPOpeningsTx(c, t, pid, state.ContentRevision, newVIP, at)
	if e != nil {
		return nil, e
	}
	prepared := preparedPrivilegeTransition{store: s.Store, after: state, player: pid, at: at, openings: openings, version: version}
	if oldCap == newCap {
		return prepared, nil
	}
	oldPolicy := rp.Descriptor.FixedPolicy(oldCap)
	newPolicy := rp.Descriptor.FixedPolicy(newCap)
	// The accepted resource primitive settles OLD cap, preserves a running
	// remainder and rearms a paused/full balance only at this transition instant.
	after, e := state.ApplyLevelTransition(0, at, oldPolicy, newPolicy)
	if e != nil {
		return nil, e
	}
	prepared.after, prepared.changed = after, after.StateVersion != state.StateVersion
	return prepared, nil
}

var _ PrivilegeTransitionPort = PrivilegeTransitionOwner{}
