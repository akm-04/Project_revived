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

	FriendFightMissionID = 1002
	RentalMissionID      = 1003
	ChampionMissionID    = 1004
	TeaPartyMissionID    = 1005
	PvPKillMissionID     = 1006
)

// PartnerMissionIDs are the missions advanced by another owner's settlement.
var PartnerMissionIDs = []int64{FriendFightMissionID, RentalMissionID, ChampionMissionID, TeaPartyMissionID, PvPKillMissionID}

// UnlockedMissions is the mission set of the stage that contains favor, using
// ActUnlocked's stage lookup: the amour column is the stage's upper bound.
func (c Catalog) UnlockedMissions(favor int64) []int64 {
	stage, ok := c.stageForFavor(favor)
	if !ok {
		return []int64{}
	}
	return slices.Clone(stage.MissionIDs)
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
