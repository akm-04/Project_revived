package objective

import (
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"slices"
)

const AwakeningContract = "I9_AWAKENING_MISSIONS_V1"

var ErrAwakeningRefused = errors.New("awakening mission refused")

type AwakeDefinition struct {
	ID          int64   `json:"id"`
	Type        int64   `json:"type"`
	Stage       int64   `json:"stage"`
	Before      int64   `json:"before"`
	After       int64   `json:"after"`
	Previous    int64   `json:"previous"`
	Next        int64   `json:"next"`
	Target      int64   `json:"target"`
	Goal        int64   `json:"goal"`
	GoalTarget  int64   `json:"goal_target"`
	Item        int64   `json:"item"`
	Material    int64   `json:"material"`
	Routes      []int64 `json:"routes"`
	DeleteItems []int64 `json:"delete_items"`
	Display     bool    `json:"display"`
}

type AwakeDropRoute struct {
	Mission  int64 `json:"mission"`
	Campaign int64 `json:"campaign"`
	Type     int64 `json:"type"`
	Box      int64 `json:"box"`
	Item     int64 `json:"item"`
	Rate     int64 `json:"rate"`
}

type AwakeCatalog struct {
	PrivatePolicy        AwakePolicy       `json:"private_policy"`
	Definitions          []AwakeDefinition `json:"definitions"`
	Drops                []AwakeDropRoute  `json:"drops"`
	WishItem             int64             `json:"wish_item"`
	WishExcludedItems    []int64           `json:"wish_excluded_items"`
	WishExcludedMissions []int64           `json:"wish_excluded_missions"`
}

type AwakePolicy struct {
	ID                       string `json:"policy_id"`
	Version                  int    `json:"version"`
	FirstClearDelayDays      int64  `json:"first_clear_delay_days"`
	BloodResultWindowSeconds int64  `json:"blood_result_window_seconds"`
	GuardWitnessOnly         bool   `json:"guard_witness_only"`
}

func (c AwakeCatalog) Definition(id int64) (AwakeDefinition, bool) {
	for _, row := range c.Definitions {
		if row.ID == id {
			return row, true
		}
	}
	return AwakeDefinition{}, false
}

func (c AwakeCatalog) Validate() error {
	if len(c.Definitions) == 0 || c.WishItem <= 0 {
		return errors.New("awakening catalog missing")
	}
	seen := map[int64]AwakeDefinition{}
	for _, d := range c.Definitions {
		if d.ID <= 0 || d.Type < 1 || d.Type > 3 || (d.Stage != -1 && d.Stage != 1 && d.Stage != 2) || d.Stage == -1 && d.Type != 1 || d.Before <= 0 || d.After <= 0 || d.Previous < 0 || d.Next < 0 || d.Target <= 0 || d.Item < 0 || d.Material < 0 || d.Goal < 0 || d.Goal > 4 || d.GoalTarget < 0 {
			return errors.New("invalid awakening definition")
		}
		if _, exists := seen[d.ID]; exists {
			return errors.New("duplicate awakening definition")
		}
		for _, item := range d.DeleteItems {
			if item <= 0 {
				return errors.New("invalid awakening deletion")
			}
		}
		if d.Stage == 1 && (d.Item <= 0 || d.Next == 0) || d.Stage == 2 && (d.Next != 0 || d.Previous == 0) {
			return errors.New("invalid awakening stage topology")
		}
		seen[d.ID] = d
	}
	for _, d := range c.Definitions {
		if d.Previous > 0 && !(d.Type == 2 && d.Stage == 1) {
			if _, ok := seen[d.Previous]; !ok {
				return errors.New("missing awakening predecessor")
			}
		}
		if d.Stage == 1 {
			next, ok := seen[d.Next]
			if !ok || next.Type != d.Type || next.Before != d.Before || next.Stage != 2 {
				return errors.New("broken awakening stage chain")
			}
		}
	}
	for _, r := range c.Drops {
		d, ok := seen[r.Mission]
		if !ok || d.Stage != 1 || d.Type == 3 || r.Campaign <= 0 || r.Type < 1 || r.Type > 2 || r.Box <= 0 || r.Item <= 0 || r.Rate < 0 || r.Rate > 10000 || d.Type == 1 && !slices.Contains(d.Routes, r.Campaign) {
			return errors.New("invalid awakening drop route")
		}
	}
	return nil
}

func (c AwakeCatalog) WishAllowed(d AwakeDefinition) bool {
	return d.Type == 1 && d.Stage == 1 && d.Material > 0 && !slices.Contains(c.WishExcludedItems, d.Material) && !slices.Contains(c.WishExcludedMissions, d.ID)
}

type AwakeInstance struct {
	Mission    int64  `json:"mission"`
	Type       int64  `json:"type"`
	OwnerID    int64  `json:"owner_id"`
	Generation int64  `json:"generation"`
	Revision   string `json:"revision"`
	Count      int64  `json:"count"`
	Complete   bool   `json:"complete"`
}

func (s AwakeInstance) Validate() error {
	r, err := hex.DecodeString(s.Revision)
	if s.Mission <= 0 || s.Type < 1 || s.Type > 3 || s.OwnerID <= 0 || s.Generation <= 0 || s.Count < 0 || err != nil || len(r) != 32 || hex.EncodeToString(r) != s.Revision {
		return errors.New("invalid awakening occurrence")
	}
	return nil
}

func (s AwakeInstance) Wire(going bool) map[string]any {
	active, complete, count := int64(0), int64(0), int64(0)
	if going {
		active, count = 1, s.Count
		if s.Complete {
			complete = 1
		}
	}
	return map[string]any{"table_id": s.Mission, "awake_type": s.Type, "is_open": int64(1), "is_going": active, "is_complete": complete, "is_reward": int64(0), "count": count}
}

func AwakeChannel(kind int64) string {
	switch kind {
	case 1:
		return "awake_mission_"
	case 2:
		return "twice_awake_mission_"
	case 3:
		return "pet_awake_mission_"
	}
	return ""
}

type AwakeReplay struct {
	Mission    int64           `json:"mission"`
	Generation int64           `json:"generation"`
	Body       json.RawMessage `json:"body"`
}

type AwakeRoot struct {
	Version        int64                  `json:"version"`
	NextGeneration int64                  `json:"next_generation"`
	Active         [3]AwakeInstance       `json:"active"`
	Replays        map[string]AwakeReplay `json:"replays"`
}

func NewAwakeRoot() AwakeRoot {
	return AwakeRoot{Version: 1, NextGeneration: 1, Replays: map[string]AwakeReplay{}}
}

func (s AwakeRoot) Validate() error {
	if s.Version < 1 || s.NextGeneration < 1 || len(s.Replays) > 9 {
		return errors.New("invalid awakening root")
	}
	for i, a := range s.Active {
		if a.Mission == 0 {
			if a != (AwakeInstance{}) {
				return errors.New("partial awakening occurrence")
			}
			continue
		}
		if a.Validate() != nil || a.Type != int64(i+1) || a.Generation >= s.NextGeneration {
			return errors.New("invalid active awakening occurrence")
		}
	}
	for key, r := range s.Replays {
		validKey := false
		for _, action := range []string{"open", "cancel", "claim"} {
			for kind := int64(1); kind <= 3; kind++ {
				validKey = validKey || key == fmt.Sprintf("%s:%d", action, kind)
			}
		}
		if !validKey || r.Mission <= 0 || r.Generation <= 0 || r.Generation >= s.NextGeneration || !json.Valid(r.Body) || len(r.Body) > 65536 {
			return errors.New("invalid awakening replay")
		}
	}
	return nil
}

func (s *AwakeRoot) Open(d AwakeDefinition, owner int64, revision string) (AwakeInstance, error) {
	if s.Validate() != nil || d.Type < 1 || d.Type > 3 || d.Stage != 1 || s.Active[d.Type-1].Mission != 0 || s.NextGeneration == math.MaxInt64 {
		return AwakeInstance{}, ErrAwakeningRefused
	}
	a := AwakeInstance{Mission: d.ID, Type: d.Type, OwnerID: owner, Generation: s.NextGeneration, Revision: revision}
	if err := a.Validate(); err != nil {
		return a, err
	}
	s.NextGeneration++
	s.Active[d.Type-1] = a
	return a, nil
}

func (s AwakeRoot) Current(kind, id int64) (AwakeInstance, error) {
	if kind < 1 || kind > 3 {
		return AwakeInstance{}, ErrAwakeningRefused
	}
	a := s.Active[kind-1]
	if a.Mission != id || a.Validate() != nil {
		return a, ErrAwakeningRefused
	}
	return a, nil
}

func (s *AwakeRoot) Complete(kind, id, generation, count int64) error {
	a, e := s.Current(kind, id)
	if e != nil || a.Generation != generation || count <= 0 {
		return ErrAwakeningRefused
	}
	a.Count = count
	a.Complete = true
	s.Active[kind-1] = a
	return nil
}

func (s *AwakeRoot) Cancel(kind, id int64) (AwakeInstance, error) {
	a, e := s.Current(kind, id)
	if e != nil {
		return a, e
	}
	s.Active[kind-1] = AwakeInstance{}
	return a, nil
}

func (s *AwakeRoot) Claim(c AwakeCatalog, kind, id int64) (AwakeInstance, AwakeInstance, error) {
	a, e := s.Current(kind, id)
	if e != nil || !a.Complete {
		return a, AwakeInstance{}, ErrAwakeningRefused
	}
	d, ok := c.Definition(id)
	if !ok || d.Type != kind || a.Count < d.Target {
		return a, AwakeInstance{}, ErrAwakeningRefused
	}
	next := AwakeInstance{}
	if d.Next > 0 {
		n, ok := c.Definition(d.Next)
		if !ok || n.Type != kind || n.Stage != 2 {
			return a, next, ErrAwakeningRefused
		}
		next = a
		next.Mission = n.ID
		next.Count = 0
		next.Complete = false
	}
	s.Active[kind-1] = next
	return a, next, nil
}

func (s *AwakeRoot) Remember(action string, a AwakeInstance, body map[string]any) error {
	if s.Replays == nil {
		s.Replays = map[string]AwakeReplay{}
	}
	raw, e := json.Marshal(body)
	if e != nil {
		return e
	}
	s.Replays[fmt.Sprintf("%s:%d", action, a.Type)] = AwakeReplay{a.Mission, a.Generation, raw}
	return s.Validate()
}

func (s AwakeRoot) Replay(action string, kind, id int64) (map[string]any, bool, error) {
	r, ok := s.Replays[fmt.Sprintf("%s:%d", action, kind)]
	if !ok || r.Mission != id {
		return nil, false, nil
	}
	var body map[string]any
	e := json.Unmarshal(r.Body, &body)
	return body, true, e
}
