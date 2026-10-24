package characterasset

import (
	"context"
	"errors"
	"testing"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type modeGuildSavedSpy struct {
	calls int
	state SavedPresetReferenceState
	err   error
}

func (s *modeGuildSavedSpy) SavedPresetReferenceStateTx(context.Context, tx.Queryer, identity.PlayerID) (SavedPresetReferenceState, error) {
	s.calls++
	return s.state, s.err
}

func combinedModeGuildOwner(t *testing.T) (OwnedCompositeBuilder, character.HeroRef, character.PetRef) {
	t.Helper()
	heroOwned, heroRef := heroCompositeFixture(t)
	petOwned, petRef := petCompositeFixture(t)
	heroOwned.PetBase = petOwned.PetBase
	heroOwned.PetEquipment = petOwned.PetEquipment
	heroOwned.PetPractice = petOwned.PetPractice
	heroOwned.PetAppearance = petOwned.PetAppearance
	return heroOwned, heroRef, petRef
}

func TestModeGuildSavedPresetReferencesPreserveCA5StateAndDefensiveCopy(t *testing.T) {
	scope := ca83CoherentScope(t)
	h1 := character.HeroRef{PlayerID: 1, PartnerID: 7}
	h2 := character.HeroRef{PlayerID: 1, PartnerID: 8}
	pet := character.PetRef{PlayerID: 1, PetID: 9}
	provider := &modeGuildSavedSpy{state: SavedPresetReferenceState{
		PlayerID:     1,
		StateVersion: 44,
		Loadouts: []SavedPresetReferenceLoadout{
			{Heroes: []character.HeroRef{h1, h2, h1}, Pet: &pet},
			{Heroes: []character.HeroRef{h2}},
		},
	}}
	owned := &OwnedCompositeBuilder{SavedPresets: provider}
	reader := ModeGuildCharacterReader{Owned: owned}

	first, err := reader.SavedPresetReferencesTx(context.Background(), scope, 1)
	if err != nil {
		t.Fatal(err)
	}
	if first.PlayerID != 1 || first.StateVersion != 44 || len(first.Loadouts) != 2 {
		t.Fatalf("state=%+v", first)
	}
	if got := first.Loadouts[0].Heroes; len(got) != 3 || got[0] != h1 || got[1] != h2 || got[2] != h1 {
		t.Fatalf("ordered duplicate Hero refs drifted: %+v", got)
	}
	if first.Loadouts[0].Pet == nil || *first.Loadouts[0].Pet != pet || first.Loadouts[1].Pet != nil {
		t.Fatalf("optional Pet semantics drifted: %+v", first.Loadouts)
	}

	first.Loadouts[0].Heroes[0].PartnerID = 999
	first.Loadouts[0].Pet.PetID = 999
	first.Loadouts[1].Heroes[0].PartnerID = 999
	second, err := reader.SavedPresetReferencesTx(context.Background(), scope, 1)
	if err != nil {
		t.Fatal(err)
	}
	if second.Loadouts[0].Heroes[0] != h1 || second.Loadouts[1].Heroes[0] != h2 || second.Loadouts[0].Pet == nil || *second.Loadouts[0].Pet != pet {
		t.Fatal("CA8-8 saved-reference result aliases provider or previous result")
	}
	if provider.state.Loadouts[0].Heroes[0] != h1 || provider.state.Loadouts[0].Pet == nil || *provider.state.Loadouts[0].Pet != pet {
		t.Fatal("CA8-8 mutation escaped into CA5 provider state")
	}

	provider.state = SavedPresetReferenceState{PlayerID: 1, StateVersion: 45}
	empty, err := reader.SavedPresetReferencesTx(context.Background(), scope, 1)
	if err != nil {
		t.Fatal(err)
	}
	if empty.PlayerID != 1 || empty.StateVersion != 45 || len(empty.Loadouts) != 0 {
		t.Fatalf("accepted empty whole-state semantics drifted: %+v", empty)
	}
}

func TestModeGuildBorrowedHeroAndPetPreserveExactQualifiedProjection(t *testing.T) {
	scope := ca83CoherentScope(t)
	owned, heroRef, petRef := combinedModeGuildOwner(t)
	borrowed := &BorrowedCompositeBuilder{OwnerComposite: owned}
	reader := ModeGuildCharacterReader{Borrowed: borrowed}

	heroQ := qualifiedBorrowedHero(heroRef)
	hero, err := reader.BorrowedHeroTx(context.Background(), scope, heroQ)
	if err != nil {
		t.Fatal(err)
	}
	if hero.Origin != ActorOriginBorrowed || hero.QualifiedReference != heroQ || hero.Base.Ref != heroRef {
		t.Fatalf("Hero projection drifted: %+v", hero)
	}

	petQ := qualifiedBorrowedPet(petRef)
	pet, err := reader.BorrowedPetTx(context.Background(), scope, petQ)
	if err != nil {
		t.Fatal(err)
	}
	if pet.Origin != ActorOriginBorrowed || pet.QualifiedReference != petQ || pet.Base.Ref != petRef {
		t.Fatalf("Pet projection drifted: %+v", pet)
	}

	hero.Equipment.Value.Slots[0].TemplateID = 999
	pet.Equipment.Value.Slots[0].TemplateID = 999
	heroAgain, err := reader.BorrowedHeroTx(context.Background(), scope, heroQ)
	if err != nil {
		t.Fatal(err)
	}
	petAgain, err := reader.BorrowedPetTx(context.Background(), scope, petQ)
	if err != nil {
		t.Fatal(err)
	}
	if heroAgain.Equipment.Value.Slots[0].TemplateID == 999 || petAgain.Equipment.Value.Slots[0].TemplateID == 999 {
		t.Fatal("CA8-8 borrowed result aliases previous result")
	}
	if heroAgain.QualifiedReference != heroQ || petAgain.QualifiedReference != petQ {
		t.Fatal("opaque borrowed capability provenance drifted")
	}
}

func TestModeGuildRejectsInvalidDependenciesScopeAndTypedInputsBeforeRead(t *testing.T) {
	ctx := context.Background()
	scope := ca83CoherentScope(t)
	validSaved := SavedPresetReferenceState{PlayerID: 1, StateVersion: 1}
	savedSpy := &modeGuildSavedSpy{state: validSaved}
	owned := &OwnedCompositeBuilder{SavedPresets: savedSpy}

	if _, err := (ModeGuildCharacterReader{}).SavedPresetReferencesTx(ctx, scope, 1); !errors.Is(err, ErrModeGuildCharacterRequest) {
		t.Fatalf("nil owned dependency err=%v", err)
	}
	if _, err := (ModeGuildCharacterReader{Owned: owned}).SavedPresetReferencesTx(ctx, CoherentReadScope{}, 1); err == nil {
		t.Fatal("invalid coherent scope accepted")
	}
	if savedSpy.calls != 0 {
		t.Fatalf("saved provider read occurred before invalid scope rejection: %d", savedSpy.calls)
	}
	if _, err := (ModeGuildCharacterReader{Owned: owned}).SavedPresetReferencesTx(ctx, scope, 0); !errors.Is(err, ErrModeGuildCharacterRequest) {
		t.Fatalf("invalid player err=%v", err)
	}
	if savedSpy.calls != 0 {
		t.Fatalf("saved provider read occurred before invalid PlayerID rejection: %d", savedSpy.calls)
	}

	heroOwned, heroRef := heroCompositeFixture(t)
	heroBase := &borrowedHeroBaseSpy{value: heroOwned.HeroBase.(heroBaseFake).v}
	heroOwned.HeroBase = heroBase
	borrowed := &BorrowedCompositeBuilder{OwnerComposite: heroOwned}
	reader := ModeGuildCharacterReader{Borrowed: borrowed}
	if _, err := (ModeGuildCharacterReader{}).BorrowedHeroTx(ctx, scope, qualifiedBorrowedHero(heroRef)); !errors.Is(err, ErrModeGuildCharacterRequest) {
		t.Fatalf("nil borrowed dependency err=%v", err)
	}
	if _, err := reader.BorrowedHeroTx(ctx, CoherentReadScope{}, qualifiedBorrowedHero(heroRef)); err == nil {
		t.Fatal("borrowed Hero accepted invalid coherent scope")
	}
	if heroBase.calls != 0 {
		t.Fatalf("Hero owner read occurred before invalid scope rejection: %d", heroBase.calls)
	}
	if _, err := reader.BorrowedHeroTx(ctx, scope, QualifiedBorrowedHeroReference{ActorRef: character.HeroRef{}, Capability: borrowedProvenanceFixture()}); err == nil {
		t.Fatal("invalid borrowed Hero ActorRef accepted")
	}
	if _, err := reader.BorrowedHeroTx(ctx, scope, QualifiedBorrowedHeroReference{ActorRef: heroRef}); err == nil {
		t.Fatal("unqualified borrowed Hero accepted")
	}
	if heroBase.calls != 0 {
		t.Fatalf("Hero owner read occurred before qualification rejection: %d", heroBase.calls)
	}

	petOwned, petRef := petCompositeFixture(t)
	petBase := &borrowedPetBaseSpy{value: petOwned.PetBase.(petBaseFake).v}
	petOwned.PetBase = petBase
	petBorrowed := &BorrowedCompositeBuilder{OwnerComposite: petOwned}
	petReader := ModeGuildCharacterReader{Borrowed: petBorrowed}
	if _, err := (ModeGuildCharacterReader{}).BorrowedPetTx(ctx, scope, qualifiedBorrowedPet(petRef)); !errors.Is(err, ErrModeGuildCharacterRequest) {
		t.Fatalf("nil borrowed Pet dependency err=%v", err)
	}
	if _, err := petReader.BorrowedPetTx(ctx, scope, QualifiedBorrowedPetReference{ActorRef: character.PetRef{}, Capability: borrowedProvenanceFixture()}); err == nil {
		t.Fatal("invalid borrowed Pet ActorRef accepted")
	}
	if _, err := petReader.BorrowedPetTx(ctx, scope, QualifiedBorrowedPetReference{ActorRef: petRef}); err == nil {
		t.Fatal("unqualified borrowed Pet accepted")
	}
	if petBase.calls != 0 {
		t.Fatalf("Pet owner read occurred before qualification rejection: %d", petBase.calls)
	}
}

func TestModeGuildPropagatesOwnerErrorsAndFailsClosedOnOwnerMismatch(t *testing.T) {
	ctx := context.Background()
	scope := ca83CoherentScope(t)

	savedErr := errors.New("saved preset storage failure")
	savedSpy := &modeGuildSavedSpy{err: savedErr}
	reader := ModeGuildCharacterReader{Owned: &OwnedCompositeBuilder{SavedPresets: savedSpy}}
	if got, err := reader.SavedPresetReferencesTx(ctx, scope, 1); !errors.Is(err, savedErr) || got.PlayerID != 0 || got.StateVersion != 0 || len(got.Loadouts) != 0 {
		t.Fatalf("saved hard error fabricated result: got=%+v err=%v", got, err)
	}

	savedSpy.err = nil
	savedSpy.state = SavedPresetReferenceState{PlayerID: 2, StateVersion: 7}
	if got, err := reader.SavedPresetReferencesTx(ctx, scope, 1); !errors.Is(err, ErrOwnedCompositeCoherence) || got.PlayerID != 0 {
		t.Fatalf("saved owner mismatch did not fail closed: got=%+v err=%v", got, err)
	}

	heroOwned, heroRef := heroCompositeFixture(t)
	heroErr := errors.New("lender Hero unavailable")
	heroSpy := &borrowedHeroBaseSpy{err: heroErr}
	heroOwned.HeroBase = heroSpy
	heroReader := ModeGuildCharacterReader{Borrowed: &BorrowedCompositeBuilder{OwnerComposite: heroOwned}}
	if got, err := heroReader.BorrowedHeroTx(ctx, scope, qualifiedBorrowedHero(heroRef)); !errors.Is(err, heroErr) || got.Origin != "" || got.QualifiedReference != (QualifiedBorrowedHeroReference{}) {
		t.Fatalf("Hero hard error fabricated result: got=%+v err=%v", got, err)
	}

	petOwned, petRef := petCompositeFixture(t)
	petErr := errors.New("lender Pet unavailable")
	petSpy := &borrowedPetBaseSpy{err: petErr}
	petOwned.PetBase = petSpy
	petReader := ModeGuildCharacterReader{Borrowed: &BorrowedCompositeBuilder{OwnerComposite: petOwned}}
	if got, err := petReader.BorrowedPetTx(ctx, scope, qualifiedBorrowedPet(petRef)); !errors.Is(err, petErr) || got.Origin != "" || got.QualifiedReference != (QualifiedBorrowedPetReference{}) {
		t.Fatalf("Pet hard error fabricated result: got=%+v err=%v", got, err)
	}
}
