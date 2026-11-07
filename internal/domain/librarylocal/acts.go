package librarylocal

import (
	"slices"
	"time"
)

// ActUnlocked uses the stage that contains the favor value. library_amour's
// amour column is the stage's upper bound (LibraryAmourTable.getCurrentId), and
// act_ids lists the acts that stage has open: favor 0 opens act 1, above 100
// act 2, above 300 act 3, above 800 act 4 (library_amour.lua:1-40).
func (c Catalog) ActUnlocked(actID, favor int64) bool {
	if actID < 1 || actID > ActCount || len(c.Stages) == 0 {
		return false
	}
	for _, stage := range c.Stages {
		if favor <= stage.Favor {
			return slices.Contains(stage.ActIDs, actID)
		}
	}
	return slices.Contains(c.Stages[len(c.Stages)-1].ActIDs, actID)
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
