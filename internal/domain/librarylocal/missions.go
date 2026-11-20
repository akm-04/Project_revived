package librarylocal

import (
	"slices"
	"time"
)

const (
	MissionProceed = 2
	MissionSuccess = 3
	MissionAwarded = 4
	GiftMissionID  = 1001
)

// UnlockedMissions is the union of library_amour mission sets whose favor
// threshold the hero has reached.
func (c Catalog) UnlockedMissions(favor int64) []int64 {
	ids := map[int64]bool{}
	for _, stage := range c.Stages {
		if favor < stage.Favor {
			continue
		}
		for _, id := range stage.MissionIDs {
			ids[id] = true
		}
	}
	out := make([]int64, 0, len(ids))
	for id := range ids {
		out = append(out, id)
	}
	slices.Sort(out)
	return out
}

// Advance moves one auto-accepted partner mission on its single stock producer.
func (f MissionFact) Advance(required int64, now time.Time) (MissionFact, bool, error) {
	if err := f.Validate(); err != nil {
		return MissionFact{}, false, err
	}
	if required <= 0 {
		return MissionFact{}, false, ErrUnqualified
	}
	if f.MissionState != MissionProceed || f.Process >= required {
		return f, false, nil
	}
	f.Process++
	if f.Process >= required {
		f.MissionState = MissionSuccess
	}
	f.UpdatedAt = now
	return f, true, f.Validate()
}

// Award marks one success row collected. The caller settles its amour in the
// same transaction, exactly once because the state is terminal.
func (f MissionFact) Award(now time.Time) (MissionFact, bool, error) {
	if err := f.Validate(); err != nil {
		return MissionFact{}, false, err
	}
	if f.MissionState != MissionSuccess {
		return f, false, nil
	}
	f.MissionState = MissionAwarded
	f.UpdatedAt = now
	return f, true, f.Validate()
}
