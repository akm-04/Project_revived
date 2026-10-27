package petcampaign

import (
	"encoding/json"
	"gxb.local/backend/v2/internal/domain/grant"
	"strconv"
)

type Sweep struct {
	ID                   string
	Revision             string
	From, To, Start, Due int64
	Lines                []grant.Line
	Awards               []map[string]any
	Material             json.RawMessage `json:",omitempty"`
}
type Fight struct {
	ID                         string
	Revision                   string
	Kind, Floor, Pet, Deadline int64
	Formation                  []int64
	Lines                      []grant.Line
	Awards                     []map[string]any
	Material                   json.RawMessage `json:",omitempty"`
}
type State struct {
	Server                                                                                 int64
	Player                                                                                 int64
	Initialized                                                                            bool
	Day, Sequence, Current, Max, EliteMax, Selected, View, ResetLeft, SweepLeft, AwakeUsed int64
	Attained                                                                               int64
	LastObserved                                                                           int64
	EliteUsed, EliteBuys                                                                   map[int64]int64
	TestFormation                                                                          map[int64]string
	Sweep                                                                                  *Sweep
	Fight                                                                                  *Fight
	LastSweep, LastResult                                                                  map[string]any
	LastResultKind, LastResultFloor, LastResultPet                                         int64
}

func (s *State) Normalize(day, at int64) {
	if s.EliteUsed == nil {
		s.EliteUsed = map[int64]int64{}
	}
	if s.EliteBuys == nil {
		s.EliteBuys = map[int64]int64{}
	}
	if s.TestFormation == nil {
		s.TestFormation = map[int64]string{}
	}
	if !s.Initialized || day > s.Day {
		s.Initialized = true
		s.Day = day
		s.ResetLeft = 1
		s.AwakeUsed = 0
		s.EliteUsed = map[int64]int64{}
		s.EliteBuys = map[int64]int64{}
	}
	if s.View == 0 {
		s.View = 1
	}
	if at > s.LastObserved {
		s.LastObserved = at
	}
}
func New(day, at int64) State { s := State{SweepLeft: 1}; s.Normalize(day, at); return s }
func (s State) Normal() map[string]any {
	start := int64(0)
	if s.Sweep != nil {
		start = s.Sweep.Start
	}
	return map[string]any{"now_floor": s.Current, "max_floor": s.Max, "begin_sweep_time": start, "is_can_sweep": int64(1), "mission_sweep_times": s.AwakeUsed, "can_sweep_times": s.SweepLeft, "challenge_times": s.ResetLeft}
}
func (s State) Elite(c Catalog) map[string]any {
	buys, remaining := map[string]int64{}, map[string]int64{}
	for n := int64(1); n <= 20; n++ {
		k := strconv.FormatInt(n, 10)
		buys[k] = s.EliteBuys[n]
		remaining[k] = c.Raids*(1+s.EliteBuys[n]) - s.EliteUsed[n]
	}
	return map[string]any{"state": s.View, "now_floor": s.Selected, "max_floor": s.EliteMax, "mission_sweep_times": int64(0), "buy_info": buys, "sweep_info": remaining, "test_formation": s.TestFormation}
}
func (s State) Projection(c Catalog) map[string]any {
	open := int64(0)
	if s.Max == 100 {
		open = 1
	}
	return map[string]any{"normal": s.Normal(), "super": s.Elite(c), "is_super_open": open}
}
func (s *State) Reset() error {
	if s.Sweep != nil || s.ResetLeft <= 0 || s.Current == 0 {
		return ErrRefused
	}
	s.Current = 0
	s.ResetLeft--
	s.SweepLeft = 1
	s.Fight = nil
	return nil
}
func (s State) SweepInterval() (int64, int64, error) {
	if s.SweepLeft <= 0 || s.Current >= s.Max {
		return 0, 0, ErrRefused
	}
	return s.Current + 1, s.Max, nil
}
func (s Sweep) Cost(c Catalog, at int64) int64 {
	left := s.Due - at
	if left <= 0 {
		return 0
	}
	return (left + c.LayerSeconds - 1) / c.LayerSeconds * c.LayerCost
}
func (s *State) Win(kind, floor, at int64) error {
	if kind == 1 {
		if floor != s.Current+1 || floor > 100 {
			return ErrRefused
		}
		s.Current = floor
		if floor > s.Max {
			s.Max = floor
			s.Attained = at
		}
	} else if kind == 2 {
		if s.Max < 100 || floor < 1 || floor > s.EliteMax+1 || floor > 20 {
			return ErrRefused
		}
		if floor > s.EliteMax {
			s.EliteMax = floor
		}
		s.Selected = min(floor, 19)
	} else {
		return ErrInvalid
	}
	return nil
}
