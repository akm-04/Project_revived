package characterpractice

import (
	"math"
	"testing"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
)

func contributionMap(rows []characterasset.PracticeContributionEntry) map[int64]int64 {
	out := map[int64]int64{}
	for _, r := range rows {
		out[r.AttrType] = r.Value
	}
	return out
}

func TestReduceAppliedPracticeContributionHeroAddsDuplicateTargetsAndRawAxes(t *testing.T) {
	thresholds := []Threshold{
		{Ordinal: 1, NeedValue: 100, TargetAttrType: 20, BonusValue: 7},
		{Ordinal: 2, NeedValue: 100, TargetAttrType: 20, BonusValue: 11},
		{Ordinal: 3, NeedValue: 100, TargetAttrType: 2, BonusValue: 13},
	}
	reducer, rows, err := ReduceAppliedPracticeContribution(characterasset.PracticeFamilyHero, character.PracticeAttrs{150, 160, 170}, thresholds)
	if err != nil {
		t.Fatal(err)
	}
	if reducer != characterasset.PracticeReducerHeroAdditive {
		t.Fatalf("reducer=%q", reducer)
	}
	got := contributionMap(rows)
	want := map[int64]int64{1: 150, 2: 173, 3: 170, 20: 18}
	if len(got) != len(want) {
		t.Fatalf("rows=%v", rows)
	}
	for k, v := range want {
		if got[k] != v {
			t.Fatalf("attr %d=%d want %d rows=%v", k, got[k], v, rows)
		}
	}
	for i := 1; i < len(rows); i++ {
		if rows[i-1].AttrType >= rows[i].AttrType {
			t.Fatalf("unsorted rows=%v", rows)
		}
	}
}

func TestReduceAppliedPracticeContributionPetOverwritesAwardsButAddsRawAxis(t *testing.T) {
	thresholds := []Threshold{
		{Ordinal: 1, NeedValue: 1, TargetAttrType: 2, BonusValue: 5},
		{Ordinal: 2, NeedValue: 1, TargetAttrType: 2, BonusValue: 9},
		{Ordinal: 3, NeedValue: 1, TargetAttrType: 20, BonusValue: 4},
	}
	_, rows, err := ReduceAppliedPracticeContribution(characterasset.PracticeFamilyPet, character.PracticeAttrs{1, 2, 3}, thresholds)
	if err != nil {
		t.Fatal(err)
	}
	got := contributionMap(rows)
	if got[2] != 11 {
		t.Fatalf("Pet raw+overwrite target=%d rows=%v", got[2], rows)
	}
	if got[20] != 4 {
		t.Fatalf("Pet target 20=%d", got[20])
	}
}

func TestReduceAppliedPracticeContributionFailsClosedOnShapeAndOverflow(t *testing.T) {
	if _, _, err := ReduceAppliedPracticeContribution(characterasset.PracticeFamilyHero, character.PracticeAttrs{}, []Threshold{{Ordinal: 1}}); err == nil {
		t.Fatal("threshold cardinality accepted")
	}
	bad := []Threshold{{Ordinal: 1, NeedValue: 0, TargetAttrType: 1, BonusValue: math.MaxInt64}, {Ordinal: 2}, {Ordinal: 3}}
	if _, _, err := ReduceAppliedPracticeContribution(characterasset.PracticeFamilyHero, character.PracticeAttrs{1, 0, 0}, bad); err == nil {
		t.Fatal("overflow accepted")
	}
}
