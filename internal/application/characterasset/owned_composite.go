package characterasset

import (
	"context"
	"errors"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var (
	ErrOwnedCompositeUnavailable = errors.New("character asset: owned composite provider unavailable")
	ErrOwnedCompositeCoherence   = errors.New("character asset: owned composite coherence mismatch")
)

// ProviderObservation wraps one CA8-3 owner observation with local provider
// readiness. Consumer-specific requiredness is deliberately not assigned here.
type ProviderObservation[T any] struct {
	Disposition ProviderDisposition
	Value       T
}

func (o ProviderObservation[T]) ValidateCA83() error {
	if err := o.Disposition.Validate(); err != nil {
		return err
	}
	if o.Disposition == ProviderRequiredButUnavailable {
		return errors.New("character asset: CA8-3 may not assign consumer-requiredness")
	}
	return nil
}

// Provider interfaces below are observation seams only. Family packages adapt
// their accepted readers and explicit content-inactive sentinels to these
// package-neutral contracts, avoiding a characterasset -> owner-package cycle.
type HeroEquipmentObservationProvider interface {
	HeroEquipmentObservationTx(context.Context, tx.Queryer, identity.PlayerID, int64, string) (ProviderObservation[RawEquipmentState], error)
}
type PetEquipmentObservationProvider interface {
	PetEquipmentObservationTx(context.Context, tx.Queryer, identity.PlayerID, int64, string) (ProviderObservation[RawEquipmentState], error)
}
type HeroPracticeObservationProvider interface {
	HeroPracticeObservationTx(context.Context, tx.Queryer, identity.PlayerID, int64, string) (ProviderObservation[PracticeContribution], error)
}
type PetPracticeObservationProvider interface {
	PetPracticeObservationTx(context.Context, tx.Queryer, identity.PlayerID, int64, string) (ProviderObservation[PracticeContribution], error)
}
type HeroAppearanceObservationProvider interface {
	HeroAppearanceObservationTx(context.Context, tx.Queryer, identity.PlayerID, int64, string, time.Time) (ProviderObservation[HeroAppearanceContribution], error)
}
type PetAppearanceObservationProvider interface {
	PetAppearanceObservationTx(context.Context, tx.Queryer, identity.PlayerID, int64, string, time.Time) (ProviderObservation[PetAppearanceContribution], error)
}
type SavedPresetReferenceStateProvider interface {
	SavedPresetReferenceStateTx(context.Context, tx.Queryer, identity.PlayerID) (SavedPresetReferenceState, error)
}

type OwnedHeroComposite struct {
	Origin     ActorOrigin
	Base       HeroBaseObservation
	Equipment  ProviderObservation[RawEquipmentState]
	Practice   ProviderObservation[PracticeContribution]
	Appearance ProviderObservation[HeroAppearanceContribution]
}

type OwnedPetComposite struct {
	Origin     ActorOrigin
	Base       PetBaseObservation
	Equipment  ProviderObservation[RawEquipmentState]
	Practice   ProviderObservation[PracticeContribution]
	Appearance ProviderObservation[PetAppearanceContribution]
}

func (c OwnedHeroComposite) Validate() error {
	if c.Origin != ActorOriginOwned || c.Base.Validate() != nil {
		return errors.New("character asset: invalid owned Hero composite base")
	}
	if err := c.Equipment.ValidateCA83(); err != nil {
		return err
	}
	if err := c.Practice.ValidateCA83(); err != nil {
		return err
	}
	if err := c.Appearance.ValidateCA83(); err != nil {
		return err
	}
	if c.Equipment.Disposition == ProviderQualifiedActive {
		v := c.Equipment.Value
		if err := v.Validate(); err != nil || v.OwnerID != c.Base.Ref.PartnerID || v.StateVersion != c.Base.StateVersion {
			return fmt.Errorf("%w: Hero equipment", ErrOwnedCompositeCoherence)
		}
		wantFamily := "HERO"
		if c.Base.Kind == character.SuperHero {
			wantFamily = "SUPER"
		}
		if v.Family != wantFamily {
			return fmt.Errorf("%w: Hero equipment family", ErrOwnedCompositeCoherence)
		}
	}
	if c.Practice.Disposition == ProviderQualifiedActive {
		v := c.Practice.Value
		if err := v.Validate(); err != nil || v.Family != PracticeFamilyHero || v.OwnerID != c.Base.Ref.PartnerID || v.TableID != c.Base.TableID || v.StateVersion != c.Base.StateVersion {
			return fmt.Errorf("%w: Hero Practice identity", ErrOwnedCompositeCoherence)
		}
	}
	if c.Appearance.Disposition == ProviderQualifiedActive {
		v := c.Appearance.Value
		if err := v.Validate(); err != nil || v.OwnerID != c.Base.Ref.PartnerID || v.TableID != c.Base.TableID || v.OriginTableID != c.Base.OriginTableID || v.Appearance.OwnerStateVersion != c.Base.StateVersion {
			return fmt.Errorf("%w: Hero appearance identity", ErrOwnedCompositeCoherence)
		}
	}
	return nil
}

func (c OwnedPetComposite) Validate() error {
	if c.Origin != ActorOriginOwned || c.Base.Validate() != nil {
		return errors.New("character asset: invalid owned Pet composite base")
	}
	if err := c.Equipment.ValidateCA83(); err != nil {
		return err
	}
	if err := c.Practice.ValidateCA83(); err != nil {
		return err
	}
	if err := c.Appearance.ValidateCA83(); err != nil {
		return err
	}
	if c.Equipment.Disposition == ProviderQualifiedActive {
		v := c.Equipment.Value
		if err := v.Validate(); err != nil || v.Family != "PET" || v.OwnerID != c.Base.Ref.PetID || v.StateVersion != c.Base.StateVersion {
			return fmt.Errorf("%w: Pet equipment", ErrOwnedCompositeCoherence)
		}
	}
	if c.Practice.Disposition == ProviderQualifiedActive {
		v := c.Practice.Value
		if err := v.Validate(); err != nil || v.Family != PracticeFamilyPet || v.OwnerID != c.Base.Ref.PetID || v.TableID != c.Base.TableID || v.StateVersion != c.Base.StateVersion {
			return fmt.Errorf("%w: Pet Practice identity", ErrOwnedCompositeCoherence)
		}
	}
	if c.Appearance.Disposition == ProviderQualifiedActive {
		v := c.Appearance.Value
		if err := v.Validate(); err != nil || v.OwnerID != c.Base.Ref.PetID || v.TableID != c.Base.TableID || v.OriginTableID != c.Base.OriginTableID || v.Appearance.OwnerStateVersion != c.Base.StateVersion {
			return fmt.Errorf("%w: Pet appearance identity", ErrOwnedCompositeCoherence)
		}
	}
	return nil
}

// OwnedCompositeBuilder composes immutable per-reference observations under a
// caller-owned CoherentReadScope. It never opens a transaction, writes owner
// state, resolves an entire roster, or assigns consumer-specific requiredness.
type OwnedCompositeBuilder struct {
	HeroBase       HeroBaseObservationProvider
	PetBase        PetBaseObservationProvider
	HeroEquipment  HeroEquipmentObservationProvider
	PetEquipment   PetEquipmentObservationProvider
	HeroPractice   HeroPracticeObservationProvider
	PetPractice    PetPracticeObservationProvider
	HeroAppearance HeroAppearanceObservationProvider
	PetAppearance  PetAppearanceObservationProvider
	SavedPresets   SavedPresetReferenceStateProvider
}

func (b OwnedCompositeBuilder) OwnedHeroTx(ctx context.Context, scope CoherentReadScope, ref character.HeroRef) (OwnedHeroComposite, error) {
	if err := scope.Validate(); err != nil || ref.Validate() != nil || b.HeroBase == nil {
		return OwnedHeroComposite{}, errors.New("character asset: invalid owned Hero composite request")
	}
	q := scope.Queryer()
	base, err := b.HeroBase.HeroBaseObservationTx(ctx, q, ref.PlayerID, ref.PartnerID)
	if err != nil {
		return OwnedHeroComposite{}, err
	}
	if base.Ref != ref {
		return OwnedHeroComposite{}, fmt.Errorf("%w: Hero base reference", ErrOwnedCompositeCoherence)
	}
	out := OwnedHeroComposite{Origin: ActorOriginOwned, Base: base}
	out.Equipment, err = b.heroEquipment(ctx, scope, ref)
	if err != nil {
		return OwnedHeroComposite{}, err
	}
	out.Practice, err = b.heroPractice(ctx, scope, ref)
	if err != nil {
		return OwnedHeroComposite{}, err
	}
	out.Appearance, err = b.heroAppearance(ctx, scope, ref)
	if err != nil {
		return OwnedHeroComposite{}, err
	}
	if out.Practice.Disposition == ProviderQualifiedActive && out.Practice.Value.ContentRevision != scope.ContentRevision {
		return OwnedHeroComposite{}, fmt.Errorf("%w: Hero Practice content revision", ErrOwnedCompositeCoherence)
	}
	if out.Appearance.Disposition == ProviderQualifiedActive {
		if out.Appearance.Value.ContentRevision != scope.ContentRevision {
			return OwnedHeroComposite{}, fmt.Errorf("%w: Hero appearance content revision", ErrOwnedCompositeCoherence)
		}
		if !out.Appearance.Value.Appearance.ObservedAt.Equal(scope.ObservedAt) {
			return OwnedHeroComposite{}, fmt.Errorf("%w: Hero appearance observation time", ErrOwnedCompositeCoherence)
		}
	}
	if err := out.Validate(); err != nil {
		return OwnedHeroComposite{}, err
	}
	return out.clone(), nil
}

func (b OwnedCompositeBuilder) OwnedPetTx(ctx context.Context, scope CoherentReadScope, ref character.PetRef) (OwnedPetComposite, error) {
	if err := scope.Validate(); err != nil || ref.Validate() != nil || b.PetBase == nil {
		return OwnedPetComposite{}, errors.New("character asset: invalid owned Pet composite request")
	}
	q := scope.Queryer()
	base, err := b.PetBase.PetBaseObservationTx(ctx, q, ref.PlayerID, ref.PetID)
	if err != nil {
		return OwnedPetComposite{}, err
	}
	if base.Ref != ref {
		return OwnedPetComposite{}, fmt.Errorf("%w: Pet base reference", ErrOwnedCompositeCoherence)
	}
	out := OwnedPetComposite{Origin: ActorOriginOwned, Base: base}
	out.Equipment, err = b.petEquipment(ctx, scope, ref)
	if err != nil {
		return OwnedPetComposite{}, err
	}
	out.Practice, err = b.petPractice(ctx, scope, ref)
	if err != nil {
		return OwnedPetComposite{}, err
	}
	out.Appearance, err = b.petAppearance(ctx, scope, ref)
	if err != nil {
		return OwnedPetComposite{}, err
	}
	if out.Practice.Disposition == ProviderQualifiedActive && out.Practice.Value.ContentRevision != scope.ContentRevision {
		return OwnedPetComposite{}, fmt.Errorf("%w: Pet Practice content revision", ErrOwnedCompositeCoherence)
	}
	if out.Appearance.Disposition == ProviderQualifiedActive {
		if out.Appearance.Value.ContentRevision != scope.ContentRevision {
			return OwnedPetComposite{}, fmt.Errorf("%w: Pet appearance content revision", ErrOwnedCompositeCoherence)
		}
		if !out.Appearance.Value.Appearance.ObservedAt.Equal(scope.ObservedAt) {
			return OwnedPetComposite{}, fmt.Errorf("%w: Pet appearance observation time", ErrOwnedCompositeCoherence)
		}
	}
	if err := out.Validate(); err != nil {
		return OwnedPetComposite{}, err
	}
	return out.clone(), nil
}

func (b OwnedCompositeBuilder) SavedPresetReferencesTx(ctx context.Context, scope CoherentReadScope, pid identity.PlayerID) (SavedPresetReferenceState, error) {
	if err := scope.Validate(); err != nil || !pid.Valid() || b.SavedPresets == nil {
		return SavedPresetReferenceState{}, errors.New("character asset: invalid saved-preset reference request")
	}
	out, err := b.SavedPresets.SavedPresetReferenceStateTx(ctx, scope.Queryer(), pid)
	if err != nil {
		return SavedPresetReferenceState{}, err
	}
	if err := out.Validate(); err != nil || out.PlayerID != pid {
		if err != nil {
			return SavedPresetReferenceState{}, err
		}
		return SavedPresetReferenceState{}, fmt.Errorf("%w: saved-preset owner", ErrOwnedCompositeCoherence)
	}
	return out.Clone(), nil
}

func unavailable[T any]() ProviderObservation[T] {
	return ProviderObservation[T]{Disposition: ProviderUnavailableUnqualified}
}
func (b OwnedCompositeBuilder) heroEquipment(ctx context.Context, s CoherentReadScope, ref character.HeroRef) (ProviderObservation[RawEquipmentState], error) {
	if b.HeroEquipment == nil {
		return unavailable[RawEquipmentState](), nil
	}
	return b.HeroEquipment.HeroEquipmentObservationTx(ctx, s.Queryer(), ref.PlayerID, ref.PartnerID, s.ContentRevision)
}
func (b OwnedCompositeBuilder) petEquipment(ctx context.Context, s CoherentReadScope, ref character.PetRef) (ProviderObservation[RawEquipmentState], error) {
	if b.PetEquipment == nil {
		return unavailable[RawEquipmentState](), nil
	}
	return b.PetEquipment.PetEquipmentObservationTx(ctx, s.Queryer(), ref.PlayerID, ref.PetID, s.ContentRevision)
}
func (b OwnedCompositeBuilder) heroPractice(ctx context.Context, s CoherentReadScope, ref character.HeroRef) (ProviderObservation[PracticeContribution], error) {
	if b.HeroPractice == nil {
		return unavailable[PracticeContribution](), nil
	}
	return b.HeroPractice.HeroPracticeObservationTx(ctx, s.Queryer(), ref.PlayerID, ref.PartnerID, s.ContentRevision)
}
func (b OwnedCompositeBuilder) petPractice(ctx context.Context, s CoherentReadScope, ref character.PetRef) (ProviderObservation[PracticeContribution], error) {
	if b.PetPractice == nil {
		return unavailable[PracticeContribution](), nil
	}
	return b.PetPractice.PetPracticeObservationTx(ctx, s.Queryer(), ref.PlayerID, ref.PetID, s.ContentRevision)
}
func (b OwnedCompositeBuilder) heroAppearance(ctx context.Context, s CoherentReadScope, ref character.HeroRef) (ProviderObservation[HeroAppearanceContribution], error) {
	if b.HeroAppearance == nil {
		return unavailable[HeroAppearanceContribution](), nil
	}
	return b.HeroAppearance.HeroAppearanceObservationTx(ctx, s.Queryer(), ref.PlayerID, ref.PartnerID, s.ContentRevision, s.ObservedAt)
}
func (b OwnedCompositeBuilder) petAppearance(ctx context.Context, s CoherentReadScope, ref character.PetRef) (ProviderObservation[PetAppearanceContribution], error) {
	if b.PetAppearance == nil {
		return unavailable[PetAppearanceContribution](), nil
	}
	return b.PetAppearance.PetAppearanceObservationTx(ctx, s.Queryer(), ref.PlayerID, ref.PetID, s.ContentRevision, s.ObservedAt)
}

func (c OwnedHeroComposite) clone() OwnedHeroComposite {
	out := c
	out.Equipment.Value = cloneRawEquipment(c.Equipment.Value)
	out.Practice.Value = clonePractice(c.Practice.Value)
	out.Appearance.Value = cloneHeroAppearance(c.Appearance.Value)
	return out
}
func (c OwnedPetComposite) clone() OwnedPetComposite {
	out := c
	out.Equipment.Value = cloneRawEquipment(c.Equipment.Value)
	out.Practice.Value = clonePractice(c.Practice.Value)
	out.Appearance.Value = clonePetAppearance(c.Appearance.Value)
	return out
}
func cloneRawEquipment(v RawEquipmentState) RawEquipmentState {
	v.Slots = append([]RawEquipmentSlot(nil), v.Slots...)
	v.SpiritRefs = append([]character.SpiritRef(nil), v.SpiritRefs...)
	return v
}
func clonePractice(v PracticeContribution) PracticeContribution {
	v.Contributions = append([]PracticeContributionEntry(nil), v.Contributions...)
	return v
}
func cloneHeroAppearance(v HeroAppearanceContribution) HeroAppearanceContribution {
	v.Appearance.Skins = append([]QualifiedSkinEntitlement(nil), v.Appearance.Skins...)
	for i := range v.Appearance.Skins {
		if v.Appearance.Skins[i].ExpiresAt != nil {
			t := *v.Appearance.Skins[i].ExpiresAt
			v.Appearance.Skins[i].ExpiresAt = &t
		}
	}
	v.Appearance.LIVE = append([]QualifiedLIVEState(nil), v.Appearance.LIVE...)
	return v
}
func clonePetAppearance(v PetAppearanceContribution) PetAppearanceContribution {
	v.Appearance.OwnedStyles = append([]int64(nil), v.Appearance.OwnedStyles...)
	return v
}
