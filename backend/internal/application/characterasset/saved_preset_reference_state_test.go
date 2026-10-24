package characterasset

import (
	"testing"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
)

func TestSavedPresetReferenceStateAllowsEmptySet(t *testing.T) {
	s := SavedPresetReferenceState{PlayerID: identity.PlayerID(7), StateVersion: 3}
	if err := s.Validate(); err != nil {
		t.Fatal(err)
	}
}

func TestSavedPresetReferenceStateValidatesActorScope(t *testing.T) {
	pid := identity.PlayerID(7)
	pet := character.PetRef{PlayerID: pid, PetID: 9}
	s := SavedPresetReferenceState{PlayerID: pid, StateVersion: 4, Loadouts: []SavedPresetReferenceLoadout{{
		Heroes: []character.HeroRef{{PlayerID: pid, PartnerID: 1}, {PlayerID: pid, PartnerID: 2}},
		Pet:    &pet,
	}}}
	if err := s.Validate(); err != nil {
		t.Fatal(err)
	}

	bad := s.Clone()
	bad.Loadouts[0].Heroes[0].PlayerID = identity.PlayerID(8)
	if bad.Validate() == nil {
		t.Fatal("foreign Hero accepted")
	}
}

func TestSavedPresetReferenceStateCloneDeepCopies(t *testing.T) {
	pid := identity.PlayerID(7)
	pet := character.PetRef{PlayerID: pid, PetID: 9}
	s := SavedPresetReferenceState{PlayerID: pid, StateVersion: 4, Loadouts: []SavedPresetReferenceLoadout{{
		Heroes: []character.HeroRef{{PlayerID: pid, PartnerID: 1}},
		Pet:    &pet,
	}}}
	clone := s.Clone()
	clone.Loadouts[0].Heroes[0].PartnerID = 99
	clone.Loadouts[0].Pet.PetID = 88
	if s.Loadouts[0].Heroes[0].PartnerID != 1 || s.Loadouts[0].Pet.PetID != 9 {
		t.Fatalf("source mutated through clone: %+v", s)
	}
}
