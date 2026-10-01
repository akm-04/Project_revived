package characterasset

import (
	"context"
	"errors"
	"reflect"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
)

func TestBattleCharacterScopeWitnessUsesOnlyStableCharacterScope(t *testing.T) {
	scope := ca83CoherentScope(t)
	scope.ObservedAt = scope.ObservedAt.In(time.FixedZone("same-instant", 0))
	w, err := battleCharacterScopeWitness(scope)
	if err != nil {
		t.Fatal(err)
	}
	if w.SchemaVersion != BattleCharacterContributionSchemaVersion || w.OperationID != scope.Operation.ID || w.ContentRevision != scope.ContentRevision {
		t.Fatalf("scope witness drift: %+v", w)
	}
	if w.ObservedAt.Location() != time.UTC || !w.ObservedAt.Equal(scope.ObservedAt) {
		t.Fatalf("scope witness did not normalize stable instant to UTC: %+v", w.ObservedAt)
	}
}

func TestBattleContributionOwnedHeroAndPetReuseAcceptedComposite(t *testing.T) {
	scope := ca83CoherentScope(t)
	hb, href := heroCompositeFixture(t)
	pb, pref := petCompositeFixture(t)
	r := BattleCharacterContributionReader{Owned: &hb}

	hero, err := r.OwnedHeroTx(context.Background(), scope, href)
	if err != nil {
		t.Fatal(err)
	}
	if hero.Character.Origin != ActorOriginOwned || hero.Character.Base.Ref != href || hero.HeroSkillsDisposition != ProviderUnavailableUnqualified {
		t.Fatalf("unexpected owned Hero contribution: %+v", hero)
	}
	if hero.HeroSkillsDisposition.BlocksConsumer() {
		t.Fatal("CA8-7 promoted owned Hero skill unavailability to consumer-requiredness")
	}
	if hero.Scope.OperationID != scope.Operation.ID || hero.Scope.ContentRevision != scope.ContentRevision || !hero.Scope.ObservedAt.Equal(scope.ObservedAt) {
		t.Fatalf("owned Hero scope witness drift: %+v", hero.Scope)
	}

	r.Owned = &pb
	pet, err := r.OwnedPetTx(context.Background(), scope, pref)
	if err != nil {
		t.Fatal(err)
	}
	if pet.Character.Origin != ActorOriginOwned || pet.Character.Base.Ref != pref || pet.Character.Base.Skills != character.DefaultPetSkillLevels() {
		t.Fatalf("unexpected owned Pet contribution: %+v", pet)
	}
	if err := pet.Validate(); err != nil {
		t.Fatalf("valid owned Pet contribution rejected: %v", err)
	}
}

func TestBattleContributionBorrowedPreservesExactLenderAndCapability(t *testing.T) {
	scope := ca83CoherentScope(t)
	heroOwned, href := heroCompositeFixture(t)
	petOwned, pref := petCompositeFixture(t)

	heroBuilder := BorrowedCompositeBuilder{OwnerComposite: heroOwned}
	heroReader := BattleCharacterContributionReader{Borrowed: &heroBuilder}
	hq := qualifiedBorrowedHero(href)
	hero, err := heroReader.BorrowedHeroTx(context.Background(), scope, hq)
	if err != nil {
		t.Fatal(err)
	}
	if hero.Character.QualifiedReference != hq || hero.Character.Base.Ref != href || hero.HeroSkillsDisposition != ProviderUnavailableUnqualified {
		t.Fatalf("borrowed Hero provenance drift: %+v", hero)
	}
	if hero.HeroSkillsDisposition.BlocksConsumer() {
		t.Fatal("CA8-7 assigned borrowed Hero consumer requiredness")
	}

	petBuilder := BorrowedCompositeBuilder{OwnerComposite: petOwned}
	petReader := BattleCharacterContributionReader{Borrowed: &petBuilder}
	pq := qualifiedBorrowedPet(pref)
	pet, err := petReader.BorrowedPetTx(context.Background(), scope, pq)
	if err != nil {
		t.Fatal(err)
	}
	if pet.Character.QualifiedReference != pq || pet.Character.Base.Ref != pref {
		t.Fatalf("borrowed Pet provenance drift: %+v", pet)
	}
}

func TestBattleContributionSyntheticHeroAndPetPreserveQualifiedProfile(t *testing.T) {
	scope := ca83CoherentScope(t)
	payloadBytes := []byte{1, 2, 3, 4}
	heroSpec := QualifiedSyntheticHeroSpec{
		Origin: ActorOriginTrial, LocalKey: "academy:hero:2",
		Provenance: syntheticProvenanceFixture(scope), Base: syntheticHeroBaseFixture(),
		FeaturePayload: &SyntheticFeaturePayload{SchemaID: "academy.hero.character", SchemaRevision: "v3", Bytes: payloadBytes},
	}
	petSpec := QualifiedSyntheticPetSpec{
		Origin: ActorOriginNPCTemplate, LocalKey: "enemy:pet:1",
		Provenance: syntheticProvenanceFixture(scope), Base: syntheticPetBaseFixture(),
		FeaturePayload: &SyntheticFeaturePayload{SchemaID: "enemy.pet.character", SchemaRevision: "v1", Bytes: []byte("pet-profile")},
	}

	r := BattleCharacterContributionReader{}
	hero, err := r.SyntheticHero(scope, heroSpec)
	if err != nil {
		t.Fatal(err)
	}
	pet, err := r.SyntheticPet(scope, petSpec)
	if err != nil {
		t.Fatal(err)
	}
	if hero.Character.Identity.Origin != ActorOriginTrial || pet.Character.Identity.Origin != ActorOriginNPCTemplate {
		t.Fatalf("synthetic origins drifted: Hero=%+v Pet=%+v", hero.Character.Identity, pet.Character.Identity)
	}
	if hero.Scope.OperationID != hero.Character.Identity.OperationID || hero.Scope.OperationID != hero.Character.Provenance.QualifiedOperationID {
		t.Fatalf("synthetic Hero operation provenance drift: %+v", hero)
	}
	if pet.Scope.ContentRevision != pet.Character.Provenance.ContentRevision || !pet.Scope.ObservedAt.Equal(pet.Character.Provenance.QualifiedAt) {
		t.Fatalf("synthetic Pet scope provenance drift: %+v", pet)
	}

	payloadBytes[0] = 0xff
	heroSpec.FeaturePayload.Bytes[1] = 0xee
	if got := hero.Character.FeaturePayload.Bytes; !reflect.DeepEqual(got, []byte{1, 2, 3, 4}) {
		t.Fatalf("synthetic battle contribution aliases caller payload: %v", got)
	}
}

func TestBattleContributionRejectsInvalidDependenciesAndInputsBeforeMaterialization(t *testing.T) {
	scope := ca83CoherentScope(t)
	hb, href := heroCompositeFixture(t)
	pb, pref := petCompositeFixture(t)

	if _, err := (BattleCharacterContributionReader{}).OwnedHeroTx(context.Background(), scope, href); !errors.Is(err, ErrInvalidBattleCharacterContribution) {
		t.Fatalf("nil owned dependency err=%v", err)
	}
	if _, err := (BattleCharacterContributionReader{}).BorrowedHeroTx(context.Background(), scope, qualifiedBorrowedHero(href)); !errors.Is(err, ErrInvalidBattleCharacterContribution) {
		t.Fatalf("nil borrowed dependency err=%v", err)
	}

	badScope := scope
	badScope.ContentRevision = "not-a-revision"
	if _, err := (BattleCharacterContributionReader{Owned: &hb}).OwnedHeroTx(context.Background(), badScope, href); !errors.Is(err, ErrInvalidCoherentReadScope) {
		t.Fatalf("invalid scope err=%v", err)
	}
	if _, err := (BattleCharacterContributionReader{Owned: &pb}).OwnedPetTx(context.Background(), scope, character.PetRef{}); err == nil {
		t.Fatal("invalid Pet ref accepted")
	}
	if _, err := (BattleCharacterContributionReader{}).SyntheticHero(scope, QualifiedSyntheticHeroSpec{}); err == nil {
		t.Fatal("invalid synthetic Hero spec accepted")
	}
	_ = pref
}

func TestBattleContributionValidationFailsClosedOnRequirednessAndScopeDrift(t *testing.T) {
	scope := ca83CoherentScope(t)
	hb, href := heroCompositeFixture(t)
	hero, err := (BattleCharacterContributionReader{Owned: &hb}).OwnedHeroTx(context.Background(), scope, href)
	if err != nil {
		t.Fatal(err)
	}
	badHero := hero
	badHero.HeroSkillsDisposition = ProviderRequiredButUnavailable
	if !errors.Is(badHero.Validate(), ErrInvalidBattleCharacterContribution) {
		t.Fatalf("consumer-required Hero skill disposition accepted: %v", badHero.Validate())
	}
	badHero = hero
	badHero.Scope.SchemaVersion = "ca8-7/v2"
	if !errors.Is(badHero.Validate(), ErrInvalidBattleCharacterScope) {
		t.Fatalf("wrong schema accepted: %v", badHero.Validate())
	}

	spec := QualifiedSyntheticHeroSpec{
		Origin: ActorOriginTrial, LocalKey: "trial:1",
		Provenance: syntheticProvenanceFixture(scope), Base: syntheticHeroBaseFixture(),
	}
	synthetic, err := (BattleCharacterContributionReader{}).SyntheticHero(scope, spec)
	if err != nil {
		t.Fatal(err)
	}
	badSynthetic := synthetic
	badSynthetic.Scope.ContentRevision = "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
	if !errors.Is(badSynthetic.Validate(), ErrInvalidBattleCharacterContribution) {
		t.Fatalf("synthetic scope drift accepted: %v", badSynthetic.Validate())
	}
}

func TestBattleContributionOwnedCompositeRemainsImmutableByCopy(t *testing.T) {
	scope := ca83CoherentScope(t)
	builder, ref := heroCompositeFixture(t)
	r := BattleCharacterContributionReader{Owned: &builder}
	first, err := r.OwnedHeroTx(context.Background(), scope, ref)
	if err != nil {
		t.Fatal(err)
	}
	second, err := r.OwnedHeroTx(context.Background(), scope, ref)
	if err != nil {
		t.Fatal(err)
	}
	if len(first.Character.Equipment.Value.Slots) == 0 || len(second.Character.Equipment.Value.Slots) == 0 {
		t.Fatal("fixture missing equipment slots")
	}
	first.Character.Equipment.Value.Slots[0].TemplateID = 999999
	if second.Character.Equipment.Value.Slots[0].TemplateID == 999999 {
		t.Fatal("battle contribution aliases a prior materialized composite")
	}
}

func TestBattleContributionBorrowedCompositeRemainsImmutableByCopy(t *testing.T) {
	scope := ca83CoherentScope(t)
	owned, ref := heroCompositeFixture(t)
	borrowed := BorrowedCompositeBuilder{OwnerComposite: owned}
	reader := BattleCharacterContributionReader{Borrowed: &borrowed}
	q := qualifiedBorrowedHero(ref)

	first, err := reader.BorrowedHeroTx(context.Background(), scope, q)
	if err != nil {
		t.Fatal(err)
	}
	second, err := reader.BorrowedHeroTx(context.Background(), scope, q)
	if err != nil {
		t.Fatal(err)
	}
	if len(first.Character.Equipment.Value.Slots) == 0 || len(second.Character.Equipment.Value.Slots) == 0 {
		t.Fatal("fixture missing borrowed equipment slots")
	}
	first.Character.Equipment.Value.Slots[0].TemplateID = 999999
	if second.Character.Equipment.Value.Slots[0].TemplateID == 999999 {
		t.Fatal("borrowed battle contribution aliases a prior materialized handoff")
	}

	fixture := borrowed.OwnerComposite.HeroEquipment.(heroEquipFake)
	fixture.v.Value.Slots[0].TemplateID = 777777
	borrowed.OwnerComposite.HeroEquipment = fixture
	if first.Character.Equipment.Value.Slots[0].TemplateID == 777777 {
		t.Fatal("later lender fixture edit rewrote an already materialized borrowed handoff")
	}
}

func TestBattleContributionPropagatesAcceptedCompositeCoherenceFailure(t *testing.T) {
	scope := ca83CoherentScope(t)
	owned, ref := heroCompositeFixture(t)
	appearance := owned.HeroAppearance.(heroAppearanceFake)
	appearance.v.Value.Appearance.ObservedAt = appearance.v.Value.Appearance.ObservedAt.Add(time.Second)
	owned.HeroAppearance = appearance
	_, err := (BattleCharacterContributionReader{Owned: &owned}).OwnedHeroTx(context.Background(), scope, ref)
	if !errors.Is(err, ErrOwnedCompositeCoherence) {
		t.Fatalf("accepted composite coherence failure not propagated: %v", err)
	}
}
