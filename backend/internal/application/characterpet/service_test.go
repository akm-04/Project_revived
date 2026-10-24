package characterpet

import (
	"context"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
)

type fakeStore struct {
	Store
	root character.PetRoot
	pets []character.Pet
	err  error
}

func (s fakeStore) ReadPetRoot(context.Context, identity.PlayerID) (character.PetRoot, error) {
	if s.err != nil {
		return character.PetRoot{}, s.err
	}
	return s.root, nil
}
func (s fakeStore) ListPets(context.Context, identity.PlayerID) ([]character.Pet, error) {
	if s.err != nil {
		return nil, s.err
	}
	return append([]character.Pet(nil), s.pets...), nil
}

type fakeAppearanceStore struct{ PetAppearanceStore }

func (fakeAppearanceStore) ListPetStyleEntitlements(context.Context, identity.PlayerID, int64) ([]character.PetStyleEntitlement, error) {
	return nil, nil
}

type fakeAppearanceContent struct {
	characterasset.AppearanceContent
}

func (fakeAppearanceContent) AppearanceActive(context.Context) (string, bool, error) {
	return "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", true, nil
}

func serviceFixture() (character.PetRoot, character.Pet) {
	now := time.Unix(100, 0).UTC()
	root := character.PetRoot{PlayerID: 7, NextPetID: 2, StateVersion: 1, CreatedAt: now, UpdatedAt: now}
	pet := character.Pet{PlayerID: 7, PetID: 1, TableID: 10030001, OriginTableID: 10030001, Star: 1, Level: 1, Exp: 0, Color: 1, Skills: character.DefaultPetSkillLevels(), Birthday: 1700000000, IsShow: false, CreationContentRevision: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", StateVersion: 1, CreatedAt: now, UpdatedAt: now}
	return root, pet
}

func TestRosterReturnsCanonicalRootAndPets(t *testing.T) {
	root, pet := serviceFixture()
	s := Service{Store: fakeStore{root: root, pets: []character.Pet{pet}}}
	gotRoot, gotPets, err := s.Roster(context.Background(), identity.ActorContext{PlayerID: 7})
	if err != nil {
		t.Fatal(err)
	}
	if gotRoot.NextPetID != 2 || len(gotPets) != 1 || gotPets[0].PetID != 1 {
		t.Fatalf("root=%+v pets=%+v", gotRoot, gotPets)
	}
}

func TestRosterFailsClosedOnMissingStoreOrCorruptPet(t *testing.T) {
	if _, _, err := (Service{}).Roster(context.Background(), identity.ActorContext{PlayerID: 7}); err == nil {
		t.Fatal("nil store accepted")
	}
	root, pet := serviceFixture()
	pet.CreationContentRevision = "bad"
	_, _, err := (Service{Store: fakeStore{root: root, pets: []character.Pet{pet}}}).Roster(context.Background(), identity.ActorContext{PlayerID: 7})
	if err == nil {
		t.Fatal("corrupt pet accepted")
	}
	want := errors.New("x")
	_, _, err = (Service{Store: fakeStore{err: want}}).Roster(context.Background(), identity.ActorContext{PlayerID: 7})
	if !errors.Is(err, want) {
		t.Fatalf("store error=%v", err)
	}
}

func TestRosterViewBindsDirectlyToAppearanceCapability(t *testing.T) {
	root, pet := serviceFixture()
	s := Service{
		Store:           fakeStore{root: root, pets: []character.Pet{pet}},
		AppearanceStore: fakeAppearanceStore{},
		Appearance:      fakeAppearanceContent{},
	}
	gotRoot, views, err := s.RosterView(context.Background(), identity.ActorContext{PlayerID: 7}, time.Unix(200, 0).UTC())
	if err != nil {
		t.Fatal(err)
	}
	if gotRoot.NextPetID != 2 || len(views) != 1 || views[0].Pet.PetID != 1 || views[0].Appearance.OwnerStateVersion != pet.StateVersion {
		t.Fatalf("root=%+v views=%+v", gotRoot, views)
	}
}
