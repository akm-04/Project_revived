package publicprofile

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const ShowcaseReferenceGuardProviderID = "public-profile.showcase"

// Actor-bound stable315+391 reverse reference guard; absence never omits either lock.
type PublicProfileReferenceGuard struct {
	Store    ShowcaseStore
	Roots    Store
	Players  playerroot.TxLocker
	Server   identity.LogicalServerID
	PlayerID identity.PlayerID
}

func (g PublicProfileReferenceGuard) ProviderID() string { return ShowcaseReferenceGuardProviderID }

func (g PublicProfileReferenceGuard) validate() error {
	if g.Store == nil || g.Roots == nil || g.Players == nil || !g.Server.Valid() || !g.PlayerID.Valid() {
		return characterasset.ErrInvalidReferenceGuard
	}
	server, e := socialrelation.CanonicalServer(g.PlayerID)
	if e != nil || server != g.Server {
		return characterasset.ErrInvalidReferenceGuard
	}
	return nil
}

func (g PublicProfileReferenceGuard) expectedPlan() (characterasset.ReferenceGuardPlan, error) {
	if err := g.validate(); err != nil {
		return characterasset.ReferenceGuardPlan{}, err
	}
	key, err := RootLockKey(g.PlayerID)
	if err != nil {
		return characterasset.ReferenceGuardPlan{}, err
	}
	parent, err := playerroot.LockKey(g.PlayerID)
	if err != nil {
		return characterasset.ReferenceGuardPlan{}, err
	}
	return characterasset.ReferenceGuardPlan{ProviderID: ShowcaseReferenceGuardProviderID, Locks: []lockkey.Key{parent, key}}, nil
}

func (g PublicProfileReferenceGuard) validatePlan(plan characterasset.ReferenceGuardPlan) error {
	if err := g.validate(); err != nil {
		return err
	}
	if err := characterasset.ValidateReferenceGuardPlan(ShowcaseReferenceGuardProviderID, plan); err != nil {
		return characterasset.ErrInvalidReferenceGuard
	}
	expected, err := g.expectedPlan()
	if err != nil {
		return err
	}
	if len(plan.Locks) != 2 || lockkey.Compare(plan.Locks[0], expected.Locks[0]) != 0 || lockkey.Compare(plan.Locks[1], expected.Locks[1]) != 0 {
		return characterasset.ErrInvalidReferenceGuard
	}
	return nil
}

func (g PublicProfileReferenceGuard) PreflightHeroRemovalTx(_ context.Context, _ tx.Queryer, ref character.HeroRef) (characterasset.ReferenceGuardPlan, error) {
	if err := g.validate(); err != nil || ref.Validate() != nil || ref.PlayerID != g.PlayerID {
		return characterasset.ReferenceGuardPlan{}, characterasset.ErrInvalidReferenceGuard
	}
	return g.expectedPlan()
}

func (g PublicProfileReferenceGuard) PreflightPetRemovalTx(_ context.Context, _ tx.Queryer, ref character.PetRef) (characterasset.ReferenceGuardPlan, error) {
	if err := g.validate(); err != nil || ref.Validate() != nil || ref.PlayerID != g.PlayerID {
		return characterasset.ReferenceGuardPlan{}, characterasset.ErrInvalidReferenceGuard
	}
	return g.expectedPlan()
}

func (g PublicProfileReferenceGuard) LockReferenceGuardKeyTx(ctx context.Context, t tx.Tx, key lockkey.Key) error {
	if err := g.validate(); err != nil || t == nil {
		return characterasset.ErrInvalidReferenceGuard
	}
	expected, e := g.expectedPlan()
	if e != nil {
		return e
	}
	if lockkey.Compare(key, expected.Locks[0]) == 0 {
		roots, e := g.Players.LockPlayerRootsTx(ctx, t, g.Server, []identity.PlayerID{g.PlayerID})
		if e != nil {
			return e
		}
		if len(roots) != 1 || roots[0].PlayerID != g.PlayerID || roots[0].LogicalServerID != g.Server {
			return characterasset.ErrInvalidReferenceGuard
		}
		return nil
	}
	if lockkey.Compare(key, expected.Locks[1]) != 0 {
		return characterasset.ErrInvalidReferenceGuard
	}
	root, present, e := g.Roots.LockRootTx(ctx, t, g.PlayerID)
	if e != nil {
		return e
	}
	if present && (root.PlayerID != g.PlayerID || root.Validate() != nil) {
		return errors.New("showcase guard root identity mismatch")
	}

	return nil
}

func (g PublicProfileReferenceGuard) ValidateHeroRemovalLockedTx(ctx context.Context, t tx.Tx, ref character.HeroRef, plan characterasset.ReferenceGuardPlan) error {
	if t == nil || ref.Validate() != nil || ref.PlayerID != g.PlayerID {
		return characterasset.ErrInvalidReferenceGuard
	}
	if err := g.validatePlan(plan); err != nil {
		return err
	}
	used, err := g.Store.ReferencesHeroTx(ctx, t, g.PlayerID, ref.PartnerID)
	if err != nil {
		return err
	}
	if used {
		return characterasset.ErrReferenceInUse
	}
	return nil
}

func (g PublicProfileReferenceGuard) ValidatePetRemovalLockedTx(ctx context.Context, t tx.Tx, ref character.PetRef, plan characterasset.ReferenceGuardPlan) error {
	if t == nil || ref.Validate() != nil || ref.PlayerID != g.PlayerID {
		return characterasset.ErrInvalidReferenceGuard
	}
	if err := g.validatePlan(plan); err != nil {
		return err
	}
	used, err := g.Store.ReferencesPetTx(ctx, t, g.PlayerID, ref.PetID)
	if err != nil {
		return err
	}
	if used {
		return characterasset.ErrReferenceInUse
	}
	return nil
}

var _ characterasset.HeroRemovalGuard = PublicProfileReferenceGuard{}
var _ characterasset.PetRemovalGuard = PublicProfileReferenceGuard{}
