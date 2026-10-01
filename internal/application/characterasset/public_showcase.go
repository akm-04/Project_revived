package characterasset

import (
	"context"
	"errors"
	"fmt"

	"gxb.local/backend/v2/internal/domain/character"
)

var ErrPublicShowcaseCharacterRequest = errors.New("character asset: invalid public showcase character request")

// PublicHeroCharacterFacet is the Character-owned portion of one already-
// qualified owned Hero selected by a future public-profile/showcase consumer.
// It deliberately carries no public selection, privacy, wire, publication or
// final-stat authority.
type PublicHeroCharacterFacet struct {
	Origin                ActorOrigin
	Base                  HeroBaseObservation
	Equipment             ProviderObservation[RawEquipmentState]
	Practice              ProviderObservation[PracticeContribution]
	Appearance            ProviderObservation[HeroAppearanceContribution]
	HeroSkillsDisposition ProviderDisposition
}

// PublicPetCharacterFacet is the Character-owned portion of one already-
// qualified owned Pet selected by a future public-profile/showcase consumer.
// Pet Skills/Birthday/IsShow remain canonical Pet base facts.
type PublicPetCharacterFacet struct {
	Origin     ActorOrigin
	Base       PetBaseObservation
	Equipment  ProviderObservation[RawEquipmentState]
	Practice   ProviderObservation[PracticeContribution]
	Appearance ProviderObservation[PetAppearanceContribution]
}

// PublicShowcaseCharacterReader projects the minimum Character-owned facts
// needed by a future I7B public-profile/showcase composer. Selection/index
// resolution and consumer-specific provider requiredness remain outside CA8-6.
type PublicShowcaseCharacterReader struct {
	OwnerComposite *OwnedCompositeBuilder
}

func (r PublicShowcaseCharacterReader) HeroTx(ctx context.Context, scope CoherentReadScope, ref character.HeroRef) (PublicHeroCharacterFacet, error) {
	if r.OwnerComposite == nil {
		return PublicHeroCharacterFacet{}, ErrPublicShowcaseCharacterRequest
	}
	if err := scope.Validate(); err != nil {
		return PublicHeroCharacterFacet{}, err
	}
	if err := ref.Validate(); err != nil {
		return PublicHeroCharacterFacet{}, err
	}

	owned, err := r.OwnerComposite.OwnedHeroTx(ctx, scope, ref)
	if err != nil {
		return PublicHeroCharacterFacet{}, err
	}
	if owned.Origin != ActorOriginOwned || owned.Base.Ref != ref {
		return PublicHeroCharacterFacet{}, fmt.Errorf("%w: public showcase Hero", ErrOwnedCompositeCoherence)
	}

	return PublicHeroCharacterFacet{
		Origin:                owned.Origin,
		Base:                  owned.Base,
		Equipment:             owned.Equipment,
		Practice:              owned.Practice,
		Appearance:            owned.Appearance,
		HeroSkillsDisposition: ProviderUnavailableUnqualified,
	}, nil
}

func (r PublicShowcaseCharacterReader) PetTx(ctx context.Context, scope CoherentReadScope, ref character.PetRef) (PublicPetCharacterFacet, error) {
	if r.OwnerComposite == nil {
		return PublicPetCharacterFacet{}, ErrPublicShowcaseCharacterRequest
	}
	if err := scope.Validate(); err != nil {
		return PublicPetCharacterFacet{}, err
	}
	if err := ref.Validate(); err != nil {
		return PublicPetCharacterFacet{}, err
	}

	owned, err := r.OwnerComposite.OwnedPetTx(ctx, scope, ref)
	if err != nil {
		return PublicPetCharacterFacet{}, err
	}
	if owned.Origin != ActorOriginOwned || owned.Base.Ref != ref {
		return PublicPetCharacterFacet{}, fmt.Errorf("%w: public showcase Pet", ErrOwnedCompositeCoherence)
	}

	return PublicPetCharacterFacet{
		Origin:     owned.Origin,
		Base:       owned.Base,
		Equipment:  owned.Equipment,
		Practice:   owned.Practice,
		Appearance: owned.Appearance,
	}, nil
}
