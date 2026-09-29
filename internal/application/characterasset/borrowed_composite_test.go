package characterasset

import (
	"context"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type borrowedHeroBaseSpy struct {
	calls     int
	gotPlayer identity.PlayerID
	gotActor  int64
	value     HeroBaseObservation
	err       error
}

func (s *borrowedHeroBaseSpy) HeroBaseObservationTx(_ context.Context, _ tx.Queryer, pid identity.PlayerID, partnerID int64) (HeroBaseObservation, error) {
	s.calls++
	s.gotPlayer = pid
	s.gotActor = partnerID
	return s.value, s.err
}

type borrowedPetBaseSpy struct {
	calls     int
	gotPlayer identity.PlayerID
	gotActor  int64
	value     PetBaseObservation
	err       error
}

func (s *borrowedPetBaseSpy) PetBaseObservationTx(_ context.Context, _ tx.Queryer, pid identity.PlayerID, petID int64) (PetBaseObservation, error) {
	s.calls++
	s.gotPlayer = pid
	s.gotActor = petID
	return s.value, s.err
}

func borrowedProvenanceFixture() BorrowedCapabilityProvenance {
	return BorrowedCapabilityProvenance{
		ProviderID:        "guild-rental.test",
		ProviderRevision:  "contract-v7",
		CapabilityRef:     "offer:player-1:actor-7",
		CapabilityVersion: "state-19",
	}
}

func qualifiedBorrowedHero(ref character.HeroRef) QualifiedBorrowedHeroReference {
	return QualifiedBorrowedHeroReference{ActorRef: ref, Capability: borrowedProvenanceFixture()}
}

func qualifiedBorrowedPet(ref character.PetRef) QualifiedBorrowedPetReference {
	p := borrowedProvenanceFixture()
	p.CapabilityRef = "offer:player-1:pet-8"
	return QualifiedBorrowedPetReference{ActorRef: ref, Capability: p}
}

func TestBorrowedCapabilityProvenanceRequiresEveryOpaqueField(t *testing.T) {
	base := borrowedProvenanceFixture()
	cases := map[string]func(*BorrowedCapabilityProvenance){
		"provider_id":        func(p *BorrowedCapabilityProvenance) { p.ProviderID = "" },
		"provider_revision":  func(p *BorrowedCapabilityProvenance) { p.ProviderRevision = "\t" },
		"capability_ref":     func(p *BorrowedCapabilityProvenance) { p.CapabilityRef = " " },
		"capability_version": func(p *BorrowedCapabilityProvenance) { p.CapabilityVersion = "\n" },
	}
	for name, mutate := range cases {
		t.Run(name, func(t *testing.T) {
			p := base
			mutate(&p)
			if !errors.Is(p.Validate(), ErrInvalidBorrowedCapabilityProvenance) {
				t.Fatalf("provenance unexpectedly valid: %+v", p)
			}
		})
	}
	if err := base.Validate(); err != nil {
		t.Fatalf("valid opaque provenance rejected: %v", err)
	}
}

func TestBorrowedQualificationFailsBeforeAnyOwnerRead(t *testing.T) {
	scope := ca83CoherentScope(t)

	heroOwned, heroRef := heroCompositeFixture(t)
	heroSpy := &borrowedHeroBaseSpy{value: heroOwned.HeroBase.(heroBaseFake).v}
	heroOwned.HeroBase = heroSpy
	heroBuilder := BorrowedCompositeBuilder{OwnerComposite: heroOwned}
	for _, q := range []QualifiedBorrowedHeroReference{
		{ActorRef: character.HeroRef{}, Capability: borrowedProvenanceFixture()},
		{ActorRef: heroRef, Capability: BorrowedCapabilityProvenance{}},
	} {
		heroSpy.calls = 0
		if _, err := heroBuilder.BorrowedHeroTx(context.Background(), scope, q); err == nil {
			t.Fatalf("invalid Hero qualification accepted: %+v", q)
		}
		if heroSpy.calls != 0 {
			t.Fatalf("Hero owner read occurred before qualification failed: calls=%d", heroSpy.calls)
		}
	}

	petOwned, petRef := petCompositeFixture(t)
	petSpy := &borrowedPetBaseSpy{value: petOwned.PetBase.(petBaseFake).v}
	petOwned.PetBase = petSpy
	petBuilder := BorrowedCompositeBuilder{OwnerComposite: petOwned}
	for _, q := range []QualifiedBorrowedPetReference{
		{ActorRef: character.PetRef{}, Capability: borrowedProvenanceFixture()},
		{ActorRef: petRef, Capability: BorrowedCapabilityProvenance{}},
	} {
		petSpy.calls = 0
		if _, err := petBuilder.BorrowedPetTx(context.Background(), scope, q); err == nil {
			t.Fatalf("invalid Pet qualification accepted: %+v", q)
		}
		if petSpy.calls != 0 {
			t.Fatalf("Pet owner read occurred before qualification failed: calls=%d", petSpy.calls)
		}
	}
}

func TestBorrowedHeroAndPetProjectionPreservesExactLenderIdentityAndProvenance(t *testing.T) {
	scope := ca83CoherentScope(t)

	heroOwned, heroRef := heroCompositeFixture(t)
	heroSpy := &borrowedHeroBaseSpy{value: heroOwned.HeroBase.(heroBaseFake).v}
	heroOwned.HeroBase = heroSpy
	heroQ := qualifiedBorrowedHero(heroRef)
	hero, err := (BorrowedCompositeBuilder{OwnerComposite: heroOwned}).BorrowedHeroTx(context.Background(), scope, heroQ)
	if err != nil {
		t.Fatal(err)
	}
	if hero.Origin != ActorOriginBorrowed || hero.QualifiedReference != heroQ || hero.Base.Ref != heroRef {
		t.Fatalf("Hero projection drift: %+v", hero)
	}
	if heroSpy.calls != 1 || heroSpy.gotPlayer != heroRef.PlayerID || heroSpy.gotActor != heroRef.PartnerID {
		t.Fatalf("Hero owner read identity = calls:%d player:%d actor:%d", heroSpy.calls, heroSpy.gotPlayer, heroSpy.gotActor)
	}

	petOwned, petRef := petCompositeFixture(t)
	petSpy := &borrowedPetBaseSpy{value: petOwned.PetBase.(petBaseFake).v}
	petOwned.PetBase = petSpy
	petQ := qualifiedBorrowedPet(petRef)
	pet, err := (BorrowedCompositeBuilder{OwnerComposite: petOwned}).BorrowedPetTx(context.Background(), scope, petQ)
	if err != nil {
		t.Fatal(err)
	}
	if pet.Origin != ActorOriginBorrowed || pet.QualifiedReference != petQ || pet.Base.Ref != petRef {
		t.Fatalf("Pet projection drift: %+v", pet)
	}
	if petSpy.calls != 1 || petSpy.gotPlayer != petRef.PlayerID || petSpy.gotActor != petRef.PetID {
		t.Fatalf("Pet owner read identity = calls:%d player:%d actor:%d", petSpy.calls, petSpy.gotPlayer, petSpy.gotActor)
	}
}

func TestBorrowedProjectionReusesCA83CoherenceGates(t *testing.T) {
	scope := ca83CoherentScope(t)
	heroCases := map[string]func(*OwnedCompositeBuilder){
		"equipment_state_version": func(b *OwnedCompositeBuilder) {
			f := b.HeroEquipment.(heroEquipFake)
			f.v.Value.StateVersion++
			b.HeroEquipment = f
		},
		"practice_content_revision": func(b *OwnedCompositeBuilder) {
			f := b.HeroPractice.(heroPracticeFake)
			f.v.Value.ContentRevision = "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
			b.HeroPractice = f
		},
		"appearance_observation_time": func(b *OwnedCompositeBuilder) {
			f := b.HeroAppearance.(heroAppearanceFake)
			f.v.Value.Appearance.ObservedAt = f.v.Value.Appearance.ObservedAt.Add(time.Second)
			b.HeroAppearance = f
		},
		"base_reference": func(b *OwnedCompositeBuilder) {
			f := b.HeroBase.(heroBaseFake)
			f.v.Ref.PartnerID++
			b.HeroBase = f
		},
	}
	for name, mutate := range heroCases {
		t.Run("hero_"+name, func(t *testing.T) {
			owned, ref := heroCompositeFixture(t)
			mutate(&owned)
			_, err := (BorrowedCompositeBuilder{OwnerComposite: owned}).BorrowedHeroTx(context.Background(), scope, qualifiedBorrowedHero(ref))
			if !errors.Is(err, ErrOwnedCompositeCoherence) {
				t.Fatalf("err=%v", err)
			}
		})
	}

	petCases := map[string]func(*OwnedCompositeBuilder){
		"equipment_state_version": func(b *OwnedCompositeBuilder) {
			f := b.PetEquipment.(petEquipFake)
			f.v.Value.StateVersion++
			b.PetEquipment = f
		},
		"appearance_observation_time": func(b *OwnedCompositeBuilder) {
			f := b.PetAppearance.(petAppearanceFake)
			f.v.Value.Appearance.ObservedAt = f.v.Value.Appearance.ObservedAt.Add(time.Second)
			b.PetAppearance = f
		},
		"base_reference": func(b *OwnedCompositeBuilder) {
			f := b.PetBase.(petBaseFake)
			f.v.Ref.PetID++
			b.PetBase = f
		},
	}
	for name, mutate := range petCases {
		t.Run("pet_"+name, func(t *testing.T) {
			owned, ref := petCompositeFixture(t)
			mutate(&owned)
			_, err := (BorrowedCompositeBuilder{OwnerComposite: owned}).BorrowedPetTx(context.Background(), scope, qualifiedBorrowedPet(ref))
			if !errors.Is(err, ErrOwnedCompositeCoherence) {
				t.Fatalf("err=%v", err)
			}
		})
	}
}

func TestBorrowedProjectionPreservesProviderDispositionAndHardErrors(t *testing.T) {
	scope := ca83CoherentScope(t)
	owned, ref := heroCompositeFixture(t)
	owned.HeroEquipment, owned.HeroPractice, owned.HeroAppearance = nil, nil, nil
	got, err := (BorrowedCompositeBuilder{OwnerComposite: owned}).BorrowedHeroTx(context.Background(), scope, qualifiedBorrowedHero(ref))
	if err != nil {
		t.Fatal(err)
	}
	if got.Equipment.Disposition != ProviderUnavailableUnqualified || got.Practice.Disposition != ProviderUnavailableUnqualified || got.Appearance.Disposition != ProviderUnavailableUnqualified {
		t.Fatalf("optional provider disposition drift: %+v", got)
	}

	owned, ref = heroCompositeFixture(t)
	f := owned.HeroEquipment.(heroEquipFake)
	f.v.Disposition = ProviderExplicitlyInactiveOrAbsent
	f.v.Value = RawEquipmentState{}
	owned.HeroEquipment = f
	got, err = (BorrowedCompositeBuilder{OwnerComposite: owned}).BorrowedHeroTx(context.Background(), scope, qualifiedBorrowedHero(ref))
	if err != nil || got.Equipment.Disposition != ProviderExplicitlyInactiveOrAbsent {
		t.Fatalf("explicit inactivity drift: got=%+v err=%v", got.Equipment, err)
	}

	owned, ref = heroCompositeFixture(t)
	f = owned.HeroEquipment.(heroEquipFake)
	f.v.Disposition = ProviderRequiredButUnavailable
	f.v.Value = RawEquipmentState{}
	owned.HeroEquipment = f
	if _, err := (BorrowedCompositeBuilder{OwnerComposite: owned}).BorrowedHeroTx(context.Background(), scope, qualifiedBorrowedHero(ref)); err == nil {
		t.Fatal("CA8-4 accepted consumer requiredness")
	}

	owned, ref = heroCompositeFixture(t)
	hard := errors.New("borrowed owner storage failure")
	owned.HeroEquipment = heroEquipFake{err: hard}
	if _, err := (BorrowedCompositeBuilder{OwnerComposite: owned}).BorrowedHeroTx(context.Background(), scope, qualifiedBorrowedHero(ref)); !errors.Is(err, hard) {
		t.Fatalf("hard provider error not propagated: %v", err)
	}
}

func TestBorrowedProjectionFailsClosedWhenLenderActorUnavailable(t *testing.T) {
	scope := ca83CoherentScope(t)

	heroOwned, heroRef := heroCompositeFixture(t)
	heroMissing := errors.New("lender Hero not found")
	heroSpy := &borrowedHeroBaseSpy{err: heroMissing}
	heroOwned.HeroBase = heroSpy
	heroGot, err := (BorrowedCompositeBuilder{OwnerComposite: heroOwned}).BorrowedHeroTx(context.Background(), scope, qualifiedBorrowedHero(heroRef))
	if !errors.Is(err, heroMissing) || heroGot.Origin != "" || heroGot.Base.Ref != (character.HeroRef{}) || heroGot.QualifiedReference != (QualifiedBorrowedHeroReference{}) {
		t.Fatalf("missing lender Hero fabricated projection: got=%+v err=%v", heroGot, err)
	}
	if heroSpy.calls != 1 || heroSpy.gotPlayer != heroRef.PlayerID || heroSpy.gotActor != heroRef.PartnerID {
		t.Fatalf("unexpected missing-Hero lookup: %+v", heroSpy)
	}

	petOwned, petRef := petCompositeFixture(t)
	petMissing := errors.New("lender Pet not found")
	petSpy := &borrowedPetBaseSpy{err: petMissing}
	petOwned.PetBase = petSpy
	petGot, err := (BorrowedCompositeBuilder{OwnerComposite: petOwned}).BorrowedPetTx(context.Background(), scope, qualifiedBorrowedPet(petRef))
	if !errors.Is(err, petMissing) || petGot.Origin != "" || petGot.Base.Ref != (character.PetRef{}) || petGot.QualifiedReference != (QualifiedBorrowedPetReference{}) {
		t.Fatalf("missing lender Pet fabricated projection: got=%+v err=%v", petGot, err)
	}
	if petSpy.calls != 1 || petSpy.gotPlayer != petRef.PlayerID || petSpy.gotActor != petRef.PetID {
		t.Fatalf("unexpected missing-Pet lookup: %+v", petSpy)
	}
}

func TestBorrowedHeroPreservesSuperHeroEquipmentSemantics(t *testing.T) {
	scope := ca83CoherentScope(t)
	owned, ref := heroCompositeFixture(t)
	bf := owned.HeroBase.(heroBaseFake)
	bf.v.Kind = character.SuperHero
	owned.HeroBase = bf
	ef := owned.HeroEquipment.(heroEquipFake)
	ef.v.Value.Family = "SUPER"
	owned.HeroEquipment = ef
	if _, err := (BorrowedCompositeBuilder{OwnerComposite: owned}).BorrowedHeroTx(context.Background(), scope, qualifiedBorrowedHero(ref)); err != nil {
		t.Fatalf("valid borrowed Super-Hero rejected: %v", err)
	}

	ef.v.Value.Family = "HERO"
	owned.HeroEquipment = ef
	if _, err := (BorrowedCompositeBuilder{OwnerComposite: owned}).BorrowedHeroTx(context.Background(), scope, qualifiedBorrowedHero(ref)); !errors.Is(err, ErrOwnedCompositeCoherence) {
		t.Fatalf("wrong Super-Hero family err=%v", err)
	}
}

func TestBorrowedCompositeReturnsDefensiveCopies(t *testing.T) {
	scope := ca83CoherentScope(t)
	owned, ref := heroCompositeFixture(t)
	appearance := owned.HeroAppearance.(heroAppearanceFake)
	expires := time.Unix(100, 0).UTC()
	appearance.v.Value.Appearance.Skins = []QualifiedSkinEntitlement{{ModelID: 2, ExpiresAt: &expires}}
	appearance.v.Value.Appearance.LIVE = []QualifiedLIVEState{{ModelID: 3}}
	owned.HeroAppearance = appearance

	builder := BorrowedCompositeBuilder{OwnerComposite: owned}
	first, err := builder.BorrowedHeroTx(context.Background(), scope, qualifiedBorrowedHero(ref))
	if err != nil {
		t.Fatal(err)
	}
	first.Equipment.Value.Slots[0].TemplateID = 999
	first.Appearance.Value.Appearance.Skins[0].ModelID = 999
	*first.Appearance.Value.Appearance.Skins[0].ExpiresAt = time.Unix(999, 0).UTC()

	second, err := builder.BorrowedHeroTx(context.Background(), scope, qualifiedBorrowedHero(ref))
	if err != nil {
		t.Fatal(err)
	}
	if second.Equipment.Value.Slots[0].TemplateID == 999 || second.Appearance.Value.Appearance.Skins[0].ModelID == 999 || second.Appearance.Value.Appearance.Skins[0].ExpiresAt.Unix() == 999 {
		t.Fatal("borrowed result aliases provider or previous result state")
	}
	if second.QualifiedReference != qualifiedBorrowedHero(ref) {
		t.Fatal("borrowed qualification provenance drifted across copies")
	}
}

func TestBorrowedPetCompositeReturnsDefensiveCopies(t *testing.T) {
	scope := ca83CoherentScope(t)
	owned, ref := petCompositeFixture(t)
	appearance := owned.PetAppearance.(petAppearanceFake)
	appearance.v.Value.Appearance.OwnedStyles = []int64{10, 20}
	appearance.v.Value.Appearance.ActiveStyle = 20
	owned.PetAppearance = appearance

	builder := BorrowedCompositeBuilder{OwnerComposite: owned}
	first, err := builder.BorrowedPetTx(context.Background(), scope, qualifiedBorrowedPet(ref))
	if err != nil {
		t.Fatal(err)
	}
	first.Equipment.Value.Slots[0].TemplateID = 999
	first.Appearance.Value.Appearance.OwnedStyles[0] = 999

	second, err := builder.BorrowedPetTx(context.Background(), scope, qualifiedBorrowedPet(ref))
	if err != nil {
		t.Fatal(err)
	}
	if second.Equipment.Value.Slots[0].TemplateID == 999 || second.Appearance.Value.Appearance.OwnedStyles[0] == 999 {
		t.Fatal("borrowed Pet result aliases provider or previous result state")
	}
	if second.QualifiedReference != qualifiedBorrowedPet(ref) {
		t.Fatal("borrowed Pet qualification provenance drifted across copies")
	}
}
