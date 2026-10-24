package characterasset

import (
	"context"
	"errors"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/foundation/ids"
)

const BattleCharacterContributionSchemaVersion = "ca8-7/v1"

var (
	ErrInvalidBattleCharacterScope        = errors.New("character asset: invalid battle character scope witness")
	ErrInvalidBattleCharacterContribution = errors.New("character asset: invalid battle character contribution")
)

// BattleCharacterScopeWitness records only the Character-side coherent read
// provenance that future BATTLE_STAT_PROVIDER_CORE/I8 needs to bind this
// contribution to one operation-scoped materialization. Battle policy, rules,
// entropy, final-stat compilation and CombatSnapshot identity remain outside
// CA8-7.
type BattleCharacterScopeWitness struct {
	SchemaVersion   string
	OperationID     ids.UUID
	ContentRevision string
	ObservedAt      time.Time
}

func (w BattleCharacterScopeWitness) Validate() error {
	if w.SchemaVersion != BattleCharacterContributionSchemaVersion ||
		w.OperationID.IsZero() ||
		ValidateExactRevisionID(w.ContentRevision) != nil ||
		w.ObservedAt.IsZero() ||
		w.ObservedAt.Location() != time.UTC {
		return ErrInvalidBattleCharacterScope
	}
	return nil
}

func battleCharacterScopeWitness(scope CoherentReadScope) (BattleCharacterScopeWitness, error) {
	if err := scope.Validate(); err != nil {
		return BattleCharacterScopeWitness{}, err
	}
	out := BattleCharacterScopeWitness{
		SchemaVersion:   BattleCharacterContributionSchemaVersion,
		OperationID:     scope.Operation.ID,
		ContentRevision: scope.ContentRevision,
		ObservedAt:      scope.ObservedAt.UTC(),
	}
	if err := out.Validate(); err != nil {
		return BattleCharacterScopeWitness{}, err
	}
	return out, nil
}

// OwnedHeroBattleContribution is the CA8-7 Character-owned contribution for
// one already-qualified owned Hero. Hero skill progression remains explicitly
// unavailable until a qualified producer exists; CA8-7 never fabricates skill
// values or promotes downstream consumer requiredness.
type OwnedHeroBattleContribution struct {
	Scope                 BattleCharacterScopeWitness
	Character             OwnedHeroComposite
	HeroSkillsDisposition ProviderDisposition
}

func (c OwnedHeroBattleContribution) Validate() error {
	if err := c.Scope.Validate(); err != nil {
		return err
	}
	if err := c.Character.Validate(); err != nil {
		return err
	}
	if c.Character.Origin != ActorOriginOwned || c.HeroSkillsDisposition != ProviderUnavailableUnqualified {
		return ErrInvalidBattleCharacterContribution
	}
	return nil
}

// OwnedPetBattleContribution is the Pet counterpart. Pet skill levels remain
// canonical CA3 base facts inside Character.Base.
type OwnedPetBattleContribution struct {
	Scope     BattleCharacterScopeWitness
	Character OwnedPetComposite
}

func (c OwnedPetBattleContribution) Validate() error {
	if err := c.Scope.Validate(); err != nil {
		return err
	}
	if err := c.Character.Validate(); err != nil {
		return err
	}
	if c.Character.Origin != ActorOriginOwned {
		return ErrInvalidBattleCharacterContribution
	}
	return nil
}

// BorrowedHeroBattleContribution preserves exact lender-owned Character state
// plus the opaque upstream capability provenance already accepted by CA8-4.
// Rental eligibility, cost and mode policy remain upstream concerns.
type BorrowedHeroBattleContribution struct {
	Scope                 BattleCharacterScopeWitness
	Character             BorrowedHeroComposite
	HeroSkillsDisposition ProviderDisposition
}

func (c BorrowedHeroBattleContribution) Validate() error {
	if err := c.Scope.Validate(); err != nil {
		return err
	}
	if err := c.Character.Validate(); err != nil {
		return err
	}
	if c.Character.Origin != ActorOriginBorrowed || c.HeroSkillsDisposition != ProviderUnavailableUnqualified {
		return ErrInvalidBattleCharacterContribution
	}
	return nil
}

// BorrowedPetBattleContribution is the Pet equivalent of the borrowed Hero
// contribution and retains the CA8-4 capability provenance unchanged.
type BorrowedPetBattleContribution struct {
	Scope     BattleCharacterScopeWitness
	Character BorrowedPetComposite
}

func (c BorrowedPetBattleContribution) Validate() error {
	if err := c.Scope.Validate(); err != nil {
		return err
	}
	if err := c.Character.Validate(); err != nil {
		return err
	}
	if c.Character.Origin != ActorOriginBorrowed {
		return ErrInvalidBattleCharacterContribution
	}
	return nil
}

// SyntheticHeroBattleContribution carries one operation-scoped TRIAL or
// NPC_TEMPLATE Character projection. Its feature payload remains opaque and
// schema-owned by the qualifying feature; CA8-7 does not reinterpret it into a
// universal stat formula.
type SyntheticHeroBattleContribution struct {
	Scope     BattleCharacterScopeWitness
	Character SyntheticHeroProjection
}

func (c SyntheticHeroBattleContribution) Validate() error {
	if err := c.Scope.Validate(); err != nil {
		return err
	}
	if err := c.Character.Validate(); err != nil {
		return err
	}
	if c.Character.Identity.Origin != ActorOriginTrial && c.Character.Identity.Origin != ActorOriginNPCTemplate {
		return ErrInvalidBattleCharacterContribution
	}
	if c.Scope.OperationID != c.Character.Identity.OperationID ||
		c.Scope.OperationID != c.Character.Provenance.QualifiedOperationID ||
		c.Scope.ContentRevision != c.Character.Provenance.ContentRevision ||
		!c.Scope.ObservedAt.Equal(c.Character.Provenance.QualifiedAt) {
		return fmt.Errorf("%w: synthetic Hero scope", ErrInvalidBattleCharacterContribution)
	}
	return nil
}

// SyntheticPetBattleContribution is the Pet equivalent of the synthetic Hero
// contribution.
type SyntheticPetBattleContribution struct {
	Scope     BattleCharacterScopeWitness
	Character SyntheticPetProjection
}

func (c SyntheticPetBattleContribution) Validate() error {
	if err := c.Scope.Validate(); err != nil {
		return err
	}
	if err := c.Character.Validate(); err != nil {
		return err
	}
	if c.Character.Identity.Origin != ActorOriginTrial && c.Character.Identity.Origin != ActorOriginNPCTemplate {
		return ErrInvalidBattleCharacterContribution
	}
	if c.Scope.OperationID != c.Character.Identity.OperationID ||
		c.Scope.OperationID != c.Character.Provenance.QualifiedOperationID ||
		c.Scope.ContentRevision != c.Character.Provenance.ContentRevision ||
		!c.Scope.ObservedAt.Equal(c.Character.Provenance.QualifiedAt) {
		return fmt.Errorf("%w: synthetic Pet scope", ErrInvalidBattleCharacterContribution)
	}
	return nil
}

// BattleCharacterContributionReader is the Character-side CA8-7 handoff to a
// future BATTLE_STAT_PROVIDER_CORE/I8 consumer. It delegates to accepted CA8
// materializers and introduces no final-stat, battle-policy or foreign-owner
// authority.
type BattleCharacterContributionReader struct {
	Owned    *OwnedCompositeBuilder
	Borrowed *BorrowedCompositeBuilder
}

func (r BattleCharacterContributionReader) OwnedHeroTx(ctx context.Context, scope CoherentReadScope, ref character.HeroRef) (OwnedHeroBattleContribution, error) {
	if r.Owned == nil {
		return OwnedHeroBattleContribution{}, ErrInvalidBattleCharacterContribution
	}
	witness, err := battleCharacterScopeWitness(scope)
	if err != nil {
		return OwnedHeroBattleContribution{}, err
	}
	if err := ref.Validate(); err != nil {
		return OwnedHeroBattleContribution{}, err
	}
	owned, err := r.Owned.OwnedHeroTx(ctx, scope, ref)
	if err != nil {
		return OwnedHeroBattleContribution{}, err
	}
	if owned.Origin != ActorOriginOwned || owned.Base.Ref != ref {
		return OwnedHeroBattleContribution{}, fmt.Errorf("%w: owned Hero coherence", ErrInvalidBattleCharacterContribution)
	}
	out := OwnedHeroBattleContribution{Scope: witness, Character: owned, HeroSkillsDisposition: ProviderUnavailableUnqualified}
	if err := out.Validate(); err != nil {
		return OwnedHeroBattleContribution{}, err
	}
	return out, nil
}

func (r BattleCharacterContributionReader) OwnedPetTx(ctx context.Context, scope CoherentReadScope, ref character.PetRef) (OwnedPetBattleContribution, error) {
	if r.Owned == nil {
		return OwnedPetBattleContribution{}, ErrInvalidBattleCharacterContribution
	}
	witness, err := battleCharacterScopeWitness(scope)
	if err != nil {
		return OwnedPetBattleContribution{}, err
	}
	if err := ref.Validate(); err != nil {
		return OwnedPetBattleContribution{}, err
	}
	owned, err := r.Owned.OwnedPetTx(ctx, scope, ref)
	if err != nil {
		return OwnedPetBattleContribution{}, err
	}
	if owned.Origin != ActorOriginOwned || owned.Base.Ref != ref {
		return OwnedPetBattleContribution{}, fmt.Errorf("%w: owned Pet coherence", ErrInvalidBattleCharacterContribution)
	}
	out := OwnedPetBattleContribution{Scope: witness, Character: owned}
	if err := out.Validate(); err != nil {
		return OwnedPetBattleContribution{}, err
	}
	return out, nil
}

func (r BattleCharacterContributionReader) BorrowedHeroTx(ctx context.Context, scope CoherentReadScope, ref QualifiedBorrowedHeroReference) (BorrowedHeroBattleContribution, error) {
	if r.Borrowed == nil {
		return BorrowedHeroBattleContribution{}, ErrInvalidBattleCharacterContribution
	}
	witness, err := battleCharacterScopeWitness(scope)
	if err != nil {
		return BorrowedHeroBattleContribution{}, err
	}
	if err := ref.Validate(); err != nil {
		return BorrowedHeroBattleContribution{}, err
	}
	borrowed, err := r.Borrowed.BorrowedHeroTx(ctx, scope, ref)
	if err != nil {
		return BorrowedHeroBattleContribution{}, err
	}
	if borrowed.Origin != ActorOriginBorrowed || borrowed.QualifiedReference != ref {
		return BorrowedHeroBattleContribution{}, fmt.Errorf("%w: borrowed Hero coherence", ErrInvalidBattleCharacterContribution)
	}
	out := BorrowedHeroBattleContribution{Scope: witness, Character: borrowed, HeroSkillsDisposition: ProviderUnavailableUnqualified}
	if err := out.Validate(); err != nil {
		return BorrowedHeroBattleContribution{}, err
	}
	return out, nil
}

func (r BattleCharacterContributionReader) BorrowedPetTx(ctx context.Context, scope CoherentReadScope, ref QualifiedBorrowedPetReference) (BorrowedPetBattleContribution, error) {
	if r.Borrowed == nil {
		return BorrowedPetBattleContribution{}, ErrInvalidBattleCharacterContribution
	}
	witness, err := battleCharacterScopeWitness(scope)
	if err != nil {
		return BorrowedPetBattleContribution{}, err
	}
	if err := ref.Validate(); err != nil {
		return BorrowedPetBattleContribution{}, err
	}
	borrowed, err := r.Borrowed.BorrowedPetTx(ctx, scope, ref)
	if err != nil {
		return BorrowedPetBattleContribution{}, err
	}
	if borrowed.Origin != ActorOriginBorrowed || borrowed.QualifiedReference != ref {
		return BorrowedPetBattleContribution{}, fmt.Errorf("%w: borrowed Pet coherence", ErrInvalidBattleCharacterContribution)
	}
	out := BorrowedPetBattleContribution{Scope: witness, Character: borrowed}
	if err := out.Validate(); err != nil {
		return BorrowedPetBattleContribution{}, err
	}
	return out, nil
}

func (r BattleCharacterContributionReader) SyntheticHero(scope CoherentReadScope, spec QualifiedSyntheticHeroSpec) (SyntheticHeroBattleContribution, error) {
	witness, err := battleCharacterScopeWitness(scope)
	if err != nil {
		return SyntheticHeroBattleContribution{}, err
	}
	projection, err := MaterializeSyntheticHero(scope, spec)
	if err != nil {
		return SyntheticHeroBattleContribution{}, err
	}
	out := SyntheticHeroBattleContribution{Scope: witness, Character: projection}
	if err := out.Validate(); err != nil {
		return SyntheticHeroBattleContribution{}, err
	}
	return out, nil
}

func (r BattleCharacterContributionReader) SyntheticPet(scope CoherentReadScope, spec QualifiedSyntheticPetSpec) (SyntheticPetBattleContribution, error) {
	witness, err := battleCharacterScopeWitness(scope)
	if err != nil {
		return SyntheticPetBattleContribution{}, err
	}
	projection, err := MaterializeSyntheticPet(scope, spec)
	if err != nil {
		return SyntheticPetBattleContribution{}, err
	}
	out := SyntheticPetBattleContribution{Scope: witness, Character: projection}
	if err := out.Validate(); err != nil {
		return SyntheticPetBattleContribution{}, err
	}
	return out, nil
}
