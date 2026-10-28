package godstrial

import (
	"gxb.local/backend/v2/internal/domain/grant"
	"slices"
	"strconv"
)

type Fight struct {
	ID, Revision, Provider  string
	Campaign, Pet, Deadline int64
	Formation               []int64
	Lines                   []grant.Line
}
type Auto struct {
	ID, Revision, Provider      string
	Campaign, Times, Start, Due int64
	Lines                       []grant.Line
}
type State struct {
	Player, Server, Sequence, LastObserved int64
	Wins                                   map[int64]int64
	Fight                                  *Fight
	Auto                                   *Auto
	LastResult                             map[string]any
	LastFight                              *Fight
	LastStar                               int64
	LastAuto                               map[string]any
}

func (s *State) Normalize(at int64) error {
	if at < s.LastObserved {
		return ErrRefused
	}
	s.LastObserved = at
	if s.Wins == nil {
		s.Wins = map[int64]int64{}
	}
	return nil
}
func Weekday(day int64) int64 { return ((day+3)%7+7)%7 + 1 }
func (s State) Open(stage Stage, day, level int64) bool {
	return stage.Open && stage.Day == Weekday(day) && level >= stage.Level && (stage.Previous == 0 || s.Wins[stage.Previous] > 0)
}
func (s State) Base() map[string]any {
	if s.Auto == nil {
		return map[string]any{"auto_campaign": int64(0), "auto_times": int64(0), "auto_start_time": int64(0)}
	}
	return map[string]any{"auto_campaign": s.Auto.Campaign, "auto_times": s.Auto.Times, "auto_start_time": s.Auto.Start}
}
func (s State) Info(c Catalog, day, level int64) map[string]any {
	infos := map[string]any{}
	for _, stage := range c.Stages {
		if stage.Day == Weekday(day) {
			open := int64(0)
			if s.Open(stage, day, level) {
				open = 1
			}
			infos[strconv.FormatInt(stage.ID, 10)] = map[string]any{"is_open": open, "win_count": s.Wins[stage.ID]}
		}
	}
	return map[string]any{"base_info": s.Base(), "campaign_infos": infos, "day": Weekday(day), "day_info": map[string]any{}}
}
func SameFight(f *Fight, campaign, pet int64, formation []int64) bool {
	return f != nil && f.Campaign == campaign && f.Pet == pet && slices.Equal(f.Formation, formation)
}
