package librarylocal

import "time"

func reachedStage(value int64, thresholds []int64) int64 {
	var stage int64
	for _, threshold := range thresholds {
		if value < threshold {
			break
		}
		stage++
	}
	return stage
}

// ClaimNormal uses current owning Hero growth, never automatically claims on read.
func (f HeroFacts) ClaimNormal(rule NormalCollectionRule, quality, star int64, now time.Time) (HeroFacts, bool, error) {
	if err := f.Validate(); err != nil {
		return HeroFacts{}, false, err
	}
	if err := rule.Validate(); err != nil {
		return HeroFacts{}, false, err
	}
	if quality <= 0 || star <= 0 || f.QualityStage > int64(len(rule.QualityThresholds)) || f.StarStage > int64(len(rule.StarThresholds)) {
		return HeroFacts{}, false, ErrInvalidFacts
	}
	q, s := reachedStage(quality, rule.QualityThresholds), reachedStage(star, rule.StarThresholds)
	if q <= f.QualityStage && s <= f.StarStage {
		return f, false, nil
	}
	if q > f.QualityStage {
		f.QualityStage = q
	}
	if s > f.StarStage {
		f.StarStage = s
	}
	f.StateVersion++
	f.UpdatedAt = now
	return f, true, f.Validate()
}
func (f HeroFacts) NormalContribution(rule NormalCollectionRule) (Contribution, error) {
	if f.Validate() != nil || rule.Validate() != nil || f.QualityStage > int64(len(rule.QualityHundredths)) || f.StarStage > int64(len(rule.StarHundredths)) {
		return Contribution{}, ErrUnqualified
	}
	out := Contribution{AttrID: rule.AttrID}
	if f.QualityStage > 0 {
		out.Hundredths += rule.QualityHundredths[f.QualityStage-1]
	}
	if f.StarStage > 0 {
		out.Hundredths += rule.StarHundredths[f.StarStage-1]
	}
	return out, nil
}
func (f PlayerFacts) ClaimSpecial(rule SpecialCollectionRule, ownedSourceIDs map[int64]bool, now time.Time) (PlayerFacts, bool, error) {
	if err := f.Validate(); err != nil {
		return PlayerFacts{}, false, err
	}
	if rule.ID < 1 || rule.ID > SpecialClaimCount || rule.Type != 1 || len(rule.RequiredSourceIDs) == 0 || rule.Contribution.AttrID <= 0 || rule.Contribution.Hundredths < 0 {
		return PlayerFacts{}, false, ErrUnqualified
	}
	if f.SpecialClaims[rule.ID-1] {
		return f, false, nil
	}
	for _, id := range rule.RequiredSourceIDs {
		if id <= 0 || !ownedSourceIDs[id] {
			return PlayerFacts{}, false, ErrUnqualified
		}
	}
	f.SpecialClaims[rule.ID-1] = true
	f.StateVersion++
	f.UpdatedAt = now
	return f, true, f.Validate()
}
