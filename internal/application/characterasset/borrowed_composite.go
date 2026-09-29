package characterasset

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"gxb.local/backend/v2/internal/domain/character"
)

var (
	ErrInvalidBorrowedCapabilityProvenance = errors.New("character asset: invalid borrowed capability provenance")
	ErrInvalidBorrowedReference            = errors.New("character asset: invalid borrowed actor reference")
)

// BorrowedCapabilityProvenance is opaque qualification evidence supplied by
// the owner of rental/mode policy. Character Asset preserves these values
// exactly and never interprets their provider-specific formats.
//
// This provenance is an internal V2 preservation/replay contract. It does not
// claim that the stock client or historical server exposed a capability token.
type BorrowedCapabilityProvenance struct {
	ProviderID        string
	ProviderRevision  string
	CapabilityRef     string
	CapabilityVersion string
}

func (p BorrowedCapabilityProvenance) Validate() error {
	for _, v := range []string{p.ProviderID, p.ProviderRevision, p.CapabilityRef, p.CapabilityVersion} {
		if strings.TrimSpace(v) == "" {
			return ErrInvalidBorrowedCapabilityProvenance
		}
	}
	return nil
}

// QualifiedBorrowedHeroReference identifies exact lender-owned Character state
// plus opaque upstream qualification provenance. ActorRef.PlayerID is the
// lender/owner; borrower and rental-policy state deliberately do not live here.
type QualifiedBorrowedHeroReference struct {
	ActorRef   character.HeroRef
	Capability BorrowedCapabilityProvenance
}

func (r QualifiedBorrowedHeroReference) Validate() error {
	if err := r.ActorRef.Validate(); err != nil {
		return fmt.Errorf("%w: Hero actor", ErrInvalidBorrowedReference)
	}
	if err := r.Capability.Validate(); err != nil {
		return err
	}
	return nil
}

// QualifiedBorrowedPetReference is the Pet equivalent of
// QualifiedBorrowedHeroReference.
type QualifiedBorrowedPetReference struct {
	ActorRef   character.PetRef
	Capability BorrowedCapabilityProvenance
}

func (r QualifiedBorrowedPetReference) Validate() error {
	if err := r.ActorRef.Validate(); err != nil {
		return fmt.Errorf("%w: Pet actor", ErrInvalidBorrowedReference)
	}
	if err := r.Capability.Validate(); err != nil {
		return err
	}
	return nil
}

// BorrowedHeroComposite is a read-only Character projection of exact
// lender-owned state. Qualification and rental business policy remain owned by
// the upstream provider/orchestrator.
type BorrowedHeroComposite struct {
	Origin             ActorOrigin
	QualifiedReference QualifiedBorrowedHeroReference
	Base               HeroBaseObservation
	Equipment          ProviderObservation[RawEquipmentState]
	Practice           ProviderObservation[PracticeContribution]
	Appearance         ProviderObservation[HeroAppearanceContribution]
}

// BorrowedPetComposite is the Pet equivalent of BorrowedHeroComposite.
type BorrowedPetComposite struct {
	Origin             ActorOrigin
	QualifiedReference QualifiedBorrowedPetReference
	Base               PetBaseObservation
	Equipment          ProviderObservation[RawEquipmentState]
	Practice           ProviderObservation[PracticeContribution]
	Appearance         ProviderObservation[PetAppearanceContribution]
}

func (c BorrowedHeroComposite) Validate() error {
	if c.Origin != ActorOriginBorrowed {
		return errors.New("character asset: invalid borrowed Hero composite origin")
	}
	if err := c.QualifiedReference.Validate(); err != nil {
		return err
	}
	if c.Base.Ref != c.QualifiedReference.ActorRef {
		return fmt.Errorf("%w: borrowed Hero base reference", ErrOwnedCompositeCoherence)
	}
	// CA8-3 owns the accepted per-reference Character coherence validator. The
	// temporary OWNED marker exists only to invoke that validator; it is never
	// emitted, persisted, or used to reparent the lender-owned actor.
	return (OwnedHeroComposite{
		Origin:     ActorOriginOwned,
		Base:       c.Base,
		Equipment:  c.Equipment,
		Practice:   c.Practice,
		Appearance: c.Appearance,
	}).Validate()
}

func (c BorrowedPetComposite) Validate() error {
	if c.Origin != ActorOriginBorrowed {
		return errors.New("character asset: invalid borrowed Pet composite origin")
	}
	if err := c.QualifiedReference.Validate(); err != nil {
		return err
	}
	if c.Base.Ref != c.QualifiedReference.ActorRef {
		return fmt.Errorf("%w: borrowed Pet base reference", ErrOwnedCompositeCoherence)
	}
	return (OwnedPetComposite{
		Origin:     ActorOriginOwned,
		Base:       c.Base,
		Equipment:  c.Equipment,
		Practice:   c.Practice,
		Appearance: c.Appearance,
	}).Validate()
}

// BorrowedCompositeBuilder is a read-only projection over the accepted CA8-3
// owner-state composition path. The caller must qualify the opaque capability
// in its own coherent transaction before invoking these methods; CA8-4 neither
// revalidates rental policy nor opens another transaction.
type BorrowedCompositeBuilder struct {
	OwnerComposite OwnedCompositeBuilder
}

func (b BorrowedCompositeBuilder) BorrowedHeroTx(ctx context.Context, scope CoherentReadScope, ref QualifiedBorrowedHeroReference) (BorrowedHeroComposite, error) {
	if err := scope.Validate(); err != nil {
		return BorrowedHeroComposite{}, err
	}
	if err := ref.Validate(); err != nil {
		return BorrowedHeroComposite{}, err
	}
	owned, err := b.OwnerComposite.OwnedHeroTx(ctx, scope, ref.ActorRef)
	if err != nil {
		return BorrowedHeroComposite{}, err
	}
	out := BorrowedHeroComposite{
		Origin:             ActorOriginBorrowed,
		QualifiedReference: ref,
		Base:               owned.Base,
		Equipment:          owned.Equipment,
		Practice:           owned.Practice,
		Appearance:         owned.Appearance,
	}
	if err := out.Validate(); err != nil {
		return BorrowedHeroComposite{}, err
	}
	return out.clone(), nil
}

func (b BorrowedCompositeBuilder) BorrowedPetTx(ctx context.Context, scope CoherentReadScope, ref QualifiedBorrowedPetReference) (BorrowedPetComposite, error) {
	if err := scope.Validate(); err != nil {
		return BorrowedPetComposite{}, err
	}
	if err := ref.Validate(); err != nil {
		return BorrowedPetComposite{}, err
	}
	owned, err := b.OwnerComposite.OwnedPetTx(ctx, scope, ref.ActorRef)
	if err != nil {
		return BorrowedPetComposite{}, err
	}
	out := BorrowedPetComposite{
		Origin:             ActorOriginBorrowed,
		QualifiedReference: ref,
		Base:               owned.Base,
		Equipment:          owned.Equipment,
		Practice:           owned.Practice,
		Appearance:         owned.Appearance,
	}
	if err := out.Validate(); err != nil {
		return BorrowedPetComposite{}, err
	}
	return out.clone(), nil
}

func (c BorrowedHeroComposite) clone() BorrowedHeroComposite {
	out := c
	out.Equipment.Value = cloneRawEquipment(c.Equipment.Value)
	out.Practice.Value = clonePractice(c.Practice.Value)
	out.Appearance.Value = cloneHeroAppearance(c.Appearance.Value)
	return out
}

func (c BorrowedPetComposite) clone() BorrowedPetComposite {
	out := c
	out.Equipment.Value = cloneRawEquipment(c.Equipment.Value)
	out.Practice.Value = clonePractice(c.Practice.Value)
	out.Appearance.Value = clonePetAppearance(c.Appearance.Value)
	return out
}
