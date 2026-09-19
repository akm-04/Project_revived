package charactersavedpreset

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const SavedPresetReferenceGuardProviderID = "ca5.saved-presets"

// ReferenceGuardStore is the narrow CA5-4 persistence seam. It exposes only
// the saved-preset root lock and actor-qualified reference-existence reads.
type ReferenceGuardStore interface {
	LockSavedPresetRootTx(context.Context, tx.Tx, identity.PlayerID) (character.SavedPresetRoot, error)
	SavedPresetReferencesHeroTx(context.Context, tx.Queryer, identity.PlayerID, int64) (bool, error)
	SavedPresetReferencesPetTx(context.Context, tx.Queryer, identity.PlayerID, int64) (bool, error)
}

// SavedPresetReferenceGuard is actor-bound. A future destructive source owner
// constructs one for the actor whose source object it is considering removing,
// then composes its plan with every other enabled provider before mutation.
type SavedPresetReferenceGuard struct {
	Store    ReferenceGuardStore
	PlayerID identity.PlayerID
}

func (g SavedPresetReferenceGuard) ProviderID() string { return SavedPresetReferenceGuardProviderID }

func (g SavedPresetReferenceGuard) validate() error {
	if g.Store == nil || !g.PlayerID.Valid() {
		return characterasset.ErrInvalidReferenceGuard
	}
	return nil
}

func (g SavedPresetReferenceGuard) expectedPlan() (characterasset.ReferenceGuardPlan, error) {
	if err := g.validate(); err != nil {
		return characterasset.ReferenceGuardPlan{}, err
	}
	key, err := characterasset.SavedPresetRootLockKey(g.PlayerID)
	if err != nil {
		return characterasset.ReferenceGuardPlan{}, err
	}
	return characterasset.ReferenceGuardPlan{ProviderID: SavedPresetReferenceGuardProviderID, Locks: []lockkey.Key{key}}, nil
}

func (g SavedPresetReferenceGuard) validatePlan(plan characterasset.ReferenceGuardPlan) error {
	if err := g.validate(); err != nil {
		return err
	}
	if err := characterasset.ValidateReferenceGuardPlan(SavedPresetReferenceGuardProviderID, plan); err != nil {
		return characterasset.ErrInvalidReferenceGuard
	}
	expected, err := g.expectedPlan()
	if err != nil {
		return err
	}
	if len(plan.Locks) != 1 || lockkey.Compare(plan.Locks[0], expected.Locks[0]) != 0 {
		return characterasset.ErrInvalidReferenceGuard
	}
	return nil
}

func (g SavedPresetReferenceGuard) PreflightHeroRemovalTx(_ context.Context, _ tx.Queryer, ref character.HeroRef) (characterasset.ReferenceGuardPlan, error) {
	if err := g.validate(); err != nil || ref.Validate() != nil || ref.PlayerID != g.PlayerID {
		return characterasset.ReferenceGuardPlan{}, characterasset.ErrInvalidReferenceGuard
	}
	return g.expectedPlan()
}

func (g SavedPresetReferenceGuard) PreflightPetRemovalTx(_ context.Context, _ tx.Queryer, ref character.PetRef) (characterasset.ReferenceGuardPlan, error) {
	if err := g.validate(); err != nil || ref.Validate() != nil || ref.PlayerID != g.PlayerID {
		return characterasset.ReferenceGuardPlan{}, characterasset.ErrInvalidReferenceGuard
	}
	return g.expectedPlan()
}

func (g SavedPresetReferenceGuard) LockReferenceGuardKeyTx(ctx context.Context, t tx.Tx, key lockkey.Key) error {
	if err := g.validate(); err != nil || t == nil {
		return characterasset.ErrInvalidReferenceGuard
	}
	pid, err := characterasset.SavedPresetRootPlayerFromLockKey(key)
	if err != nil || pid != g.PlayerID {
		return characterasset.ErrInvalidReferenceGuard
	}
	root, err := g.Store.LockSavedPresetRootTx(ctx, t, pid)
	if err != nil {
		return err
	}
	if root.PlayerID != pid || root.Validate() != nil {
		return errors.New("saved preset: locked guard root identity mismatch")
	}
	return nil
}

func (g SavedPresetReferenceGuard) ValidateHeroRemovalLockedTx(ctx context.Context, t tx.Tx, ref character.HeroRef, plan characterasset.ReferenceGuardPlan) error {
	if t == nil || ref.Validate() != nil || ref.PlayerID != g.PlayerID {
		return characterasset.ErrInvalidReferenceGuard
	}
	if err := g.validatePlan(plan); err != nil {
		return err
	}
	used, err := g.Store.SavedPresetReferencesHeroTx(ctx, t, g.PlayerID, ref.PartnerID)
	if err != nil {
		return err
	}
	if used {
		return characterasset.ErrReferenceInUse
	}
	return nil
}

func (g SavedPresetReferenceGuard) ValidatePetRemovalLockedTx(ctx context.Context, t tx.Tx, ref character.PetRef, plan characterasset.ReferenceGuardPlan) error {
	if t == nil || ref.Validate() != nil || ref.PlayerID != g.PlayerID {
		return characterasset.ErrInvalidReferenceGuard
	}
	if err := g.validatePlan(plan); err != nil {
		return err
	}
	used, err := g.Store.SavedPresetReferencesPetTx(ctx, t, g.PlayerID, ref.PetID)
	if err != nil {
		return err
	}
	if used {
		return characterasset.ErrReferenceInUse
	}
	return nil
}

var _ characterasset.HeroRemovalGuard = SavedPresetReferenceGuard{}
var _ characterasset.PetRemovalGuard = SavedPresetReferenceGuard{}
