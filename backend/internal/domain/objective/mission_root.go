package objective

import (
	"errors"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
)

const MissionRootLockRank uint16 = 610
const MissionRootLockOwner = "i5.00-objective"

var ErrStaleMissionDay = errors.New("mission decision predates materialized day")

type MissionRoot struct {
	PlayerID        identity.PlayerID
	Day             int64
	Week            int64
	DayHuoyue       int64
	WeekHuoyue      int64
	DayAward        []int64
	WeekAward       []int64
	BattlepassScore int64
	StateVersion    int64
}

func NewMissionRoot(player identity.PlayerID, at time.Time) (MissionRoot, error) {
	if !player.Valid() || at.IsZero() {
		return MissionRoot{}, errors.New("mission root requires player and authoritative time")
	}
	return MissionRoot{PlayerID: player, Day: modes.Day(at), Week: modes.WeekStart(at), DayAward: []int64{}, WeekAward: []int64{}, StateVersion: 1}, nil
}

func (r MissionRoot) Validate() error {
	if !r.PlayerID.Valid() || r.DayHuoyue < 0 || r.WeekHuoyue < 0 || r.BattlepassScore < 0 || r.StateVersion < 1 || modes.WeekStart(modes.DayBegins(r.Day)) != r.Week {
		return errors.New("invalid mission root")
	}
	return nil
}

func (r MissionRoot) Rollover(at time.Time) (MissionRoot, bool, error) {
	if err := r.Validate(); err != nil {
		return MissionRoot{}, false, err
	}
	if at.IsZero() {
		return MissionRoot{}, false, errors.New("mission rollover requires authoritative time")
	}
	day, week := modes.Day(at), modes.WeekStart(at)
	if day < r.Day {
		return MissionRoot{}, false, ErrStaleMissionDay
	}
	if day == r.Day {
		return r, false, nil
	}
	r.Day, r.DayHuoyue, r.DayAward = day, 0, []int64{}
	if week != r.Week {
		r.Week, r.WeekHuoyue, r.WeekAward = week, 0, []int64{}
	}
	r.StateVersion++
	return r, true, nil
}
