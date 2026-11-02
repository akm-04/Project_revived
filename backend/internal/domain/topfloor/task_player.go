package topfloor

import "slices"

type TaskModePlayer struct {
	Player       Player `json:"player"`
	PeriodNumber int64  `json:"period_number"`
	Leader       int64  `json:"leader"`
}

func (player TaskModePlayer) Validate(period TaskModePeriod) error {
	if period.Validate() != nil || player.Player.Validate() != nil || player.PeriodNumber != period.Rotation.Number || player.Player.Server != period.Ladder.Server || player.Player.ContentRevision != period.Ladder.ContentRevision || player.Leader < 0 {
		return ErrConflict
	}
	if period.Rotation.Mode != TaskModeLeader && player.Leader != 0 {
		return ErrConflict
	}
	if len(player.Player.Defense) == 0 && player.Leader == 0 {
		return nil
	}
	if period.Rotation.Mode == TaskModeLeader && !slices.Contains(player.Player.Defense, player.Leader) {
		return ErrConflict
	}
	return nil
}
