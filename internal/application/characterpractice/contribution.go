package characterpractice

import (
	"errors"
	"math"
	"sort"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
)

func checkedContributionAdd(a, b int64) (int64, error) {
	if a < 0 || b < 0 || a > math.MaxInt64-b {
		return 0, errors.New("character practice: contribution overflow")
	}
	return a + b, nil
}

// ReduceAppliedPracticeContribution reproduces the source-qualified threshold
// semantics over already-applied owner state. Hero threshold awards accumulate
// duplicate targets; Pet threshold awards overwrite duplicates in source
// ordinal order. Raw Str/Wise/Agile axes are then added to award targets.
func ReduceAppliedPracticeContribution(family string, applied character.PracticeAttrs, thresholds []Threshold) (string, []characterasset.PracticeContributionEntry, error) {
	if err := applied.Validate(); err != nil {
		return "", nil, err
	}
	if len(thresholds) != len(applied) {
		return "", nil, errors.New("character practice: threshold cardinality mismatch")
	}
	var reducer string
	switch family {
	case characterasset.PracticeFamilyHero:
		reducer = characterasset.PracticeReducerHeroAdditive
	case characterasset.PracticeFamilyPet:
		reducer = characterasset.PracticeReducerPetSourceOverwrite
	default:
		return "", nil, errors.New("character practice: unsupported contribution family")
	}

	awards := map[int64]int64{}
	for i, row := range thresholds {
		if row.Ordinal != int64(i+1) || row.NeedValue < 0 || row.TargetAttrType < 0 || row.BonusValue < 0 {
			return "", nil, errors.New("character practice: corrupt threshold row")
		}
		if applied[i] < row.NeedValue || row.TargetAttrType == 0 || row.BonusValue == 0 {
			continue
		}
		if family == characterasset.PracticeFamilyHero {
			next, err := checkedContributionAdd(awards[row.TargetAttrType], row.BonusValue)
			if err != nil {
				return "", nil, err
			}
			awards[row.TargetAttrType] = next
		} else {
			awards[row.TargetAttrType] = row.BonusValue
		}
	}

	values := make(map[int64]int64, len(awards)+3)
	for k, v := range awards {
		values[k] = v
	}
	for i, raw := range applied {
		if raw == 0 {
			continue
		}
		attrType := int64(i + 1)
		next, err := checkedContributionAdd(values[attrType], raw)
		if err != nil {
			return "", nil, err
		}
		values[attrType] = next
	}

	keys := make([]int64, 0, len(values))
	for k, v := range values {
		if v > 0 {
			keys = append(keys, k)
		}
	}
	sort.Slice(keys, func(i, j int) bool { return keys[i] < keys[j] })
	out := make([]characterasset.PracticeContributionEntry, 0, len(keys))
	for _, k := range keys {
		out = append(out, characterasset.PracticeContributionEntry{AttrType: k, Value: values[k]})
	}
	return reducer, out, nil
}
