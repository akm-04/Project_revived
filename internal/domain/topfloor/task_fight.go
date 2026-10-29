package topfloor

import "time"

type TaskModeFight struct {
	Fight        Fight            `json:"fight"`
	PeriodNumber int64            `json:"period_number"`
	Mode         int64            `json:"mode"`
	Formation    []map[string]any `json:"formation"`
	Enemy        Display          `json:"enemy"`
}

func (fight TaskModeFight) Validate() error {
	if fight.Fight.Validate() != nil || fight.PeriodNumber < 1 || fight.Mode < TaskModeSingle || fight.Mode > TaskModeCamp || len(fight.Formation) != len(fight.Fight.Formation) || fight.Enemy.Occupant != fight.Fight.Defender {
		return ErrConflict
	}
	return nil
}

type TaskModeRecord struct {
	Record       Record
	PeriodNumber int64
	Mode         int64
}
type TaskModeDefense struct {
	Heroes []int64 `json:"heroes"`
	Pet    int64   `json:"pet"`
	Leader int64   `json:"leader"`
}
type TaskModeDay struct {
	Settlement   DaySettlement
	PeriodNumber int64
}

func (catalog TaskModeCatalog) Calendar() Catalog {
	return Catalog{CutoffSeconds: taskModeCutoffSeconds, Rewards: catalog.Rewards}
}
func (catalog TaskModeCatalog) ScheduleFrom(at time.Time) ([]TaskModeRotation, error) {
	current, err := catalog.Rotation(at)
	if err != nil {
		return nil, err
	}
	next, err := catalog.Rotation(current.EndsAt)
	if err != nil {
		return nil, err
	}
	return []TaskModeRotation{current, next}, nil
}
