package librarylocal

import (
	"slices"
	"time"
)

// ActUnlocked matches library_amour's act_id sets: every stage whose favor
// threshold has been reached opens its acts.
func (c Catalog) ActUnlocked(actID, favor int64) bool {
	if actID < 1 || actID > ActCount {
		return false
	}
	for _, stage := range c.Stages {
		if favor < stage.Favor {
			continue
		}
		if slices.Contains(stage.ActIDs, actID) {
			return true
		}
	}
	return false
}

// AwardAct raises favor by the act's library_act amour, clamped to the live cap.
// A hero already at the cap keeps its favor but the once-only award still records.
func (f HeroFacts) AwardAct(rule ActRule, now time.Time) (HeroFacts, bool, error) {
	if err := f.Validate(); err != nil {
		return HeroFacts{}, false, err
	}
	if rule.Validate() != nil || rule.ID < 1 || rule.ID > ActCount {
		return HeroFacts{}, false, ErrUnqualified
	}
	if f.Favor >= FavorLimit || rule.Amour == 0 {
		return f, false, nil
	}
	next := f
	next.Favor = min(f.Favor+rule.Amour, FavorLimit)
	next.StateVersion++
	next.UpdatedAt = now
	return next, true, next.Validate()
}
