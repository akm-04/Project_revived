package characterasset

import (
	"testing"

	"gxb.local/backend/v2/internal/domain/character"
)

func TestPracticeContributionValidateRequiresFamilyReducerAndSortedSparseRows(t *testing.T) {
	base := PracticeContribution{
		Family: PracticeFamilyHero, OwnerID: 9, TableID: 1001, StateVersion: 3,
		ContentRevision: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
		Applied:         character.PracticeAttrs{1, 2, 3}, Reducer: PracticeReducerHeroAdditive,
		Contributions: []PracticeContributionEntry{{AttrType: 1, Value: 1}, {AttrType: 20, Value: 7}},
	}
	if err := base.Validate(); err != nil {
		t.Fatal(err)
	}

	bad := base
	bad.Reducer = PracticeReducerPetSourceOverwrite
	if err := bad.Validate(); err == nil {
		t.Fatal("Hero contribution accepted Pet reducer")
	}
	bad = base
	bad.Contributions = []PracticeContributionEntry{{AttrType: 2, Value: 1}, {AttrType: 2, Value: 2}}
	if err := bad.Validate(); err == nil {
		t.Fatal("duplicate attr type accepted")
	}
	bad = base
	bad.ContentRevision = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
	if err := bad.Validate(); err == nil {
		t.Fatal("non-canonical revision accepted")
	}
}
