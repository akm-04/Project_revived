package memoir

import (
	"gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/march"
	"math"
)

type EnemyCarry struct {
	Round    int                          `json:"round"`
	Statuses map[int64]combat.ActorStatus `json:"statuses"`
}
type Pending struct {
	Attempt    string          `json:"attempt"`
	Generation string          `json:"generation"`
	Revision   string          `json:"revision"`
	Grid       int             `json:"grid"`
	Kind       int64           `json:"kind"`
	FirstWave  int             `json:"first_wave"`
	Rewards    []campaign.Item `json:"rewards"`
	Formation  []int64         `json:"formation,omitempty"`
	Pet        int64           `json:"pet,omitempty"`
	Deadline   int64           `json:"deadline"`
}
type State struct {
	Occurrence  string                       `json:"occurrence"`
	Revision    string                       `json:"revision"`
	Girl        int64                        `json:"girl"`
	Floor       int                          `json:"floor"`
	Board       Board                        `json:"board"`
	ReviveTimes int                          `json:"revive_times"`
	Heroes      map[int64]combat.ActorStatus `json:"heroes"`
	Enemies     map[int]EnemyCarry           `json:"enemies"`
	Opponents   map[int]march.Enemy          `json:"opponents"`
	Drops       []campaign.Item              `json:"drops"`
	MaxFloor    map[int64]int                `json:"max_floor"`
	Sequence    int64                        `json:"sequence"`
	Pending     *Pending                     `json:"pending,omitempty"`
	LastGrid    int                          `json:"last_grid,omitempty"`
	LastResult  map[string]any               `json:"last_result,omitempty"`
}

func (state *State) Initialize() {
	if state.Heroes == nil {
		state.Heroes = map[int64]combat.ActorStatus{}
	}
	if state.Enemies == nil {
		state.Enemies = map[int]EnemyCarry{}
	}
	if state.Opponents == nil {
		state.Opponents = map[int]march.Enemy{}
	}
	if state.MaxFloor == nil {
		state.MaxFloor = map[int64]int{}
	}
	if state.Drops == nil {
		state.Drops = []campaign.Item{}
	}
}
func (state State) Active() bool { return state.Occurrence != "" }
func (state State) Alive(partner int64) bool {
	status, found := state.Heroes[partner]
	return !found || status.HP > 0
}
func (state *State) ApplyHeroes(statuses []combat.ActorStatus) {
	for _, status := range statuses {
		state.Heroes[status.Identity] = status
	}
}
func (state *State) Revive(partner int64, catalog Catalog) (int64, error) {
	if !state.Active() || partner <= 0 || state.Alive(partner) || state.Pending != nil {
		return 0, ErrRefused
	}
	if state.ReviveTimes < 0 || state.ReviveTimes >= len(catalog.ReviveCosts) {
		return 0, ErrRefused
	}
	cost := catalog.ReviveCosts[state.ReviveTimes]
	if cost <= 0 {
		return 0, ErrUnavailable
	}
	delete(state.Heroes, partner)
	state.ReviveTimes++
	return cost, nil
}
func (state *State) AppendDrops(items []campaign.Item) error {
	for _, item := range items {
		if item.ItemID <= 0 || item.Num <= 0 {
			return ErrUnavailable
		}
	}
	state.Drops = append(state.Drops, items...)
	return nil
}
func (state *State) Abandon() {
	maxima, sequence := state.MaxFloor, state.Sequence
	*state = State{MaxFloor: maxima, Sequence: sequence}
	state.Initialize()
}
func (state State) Validate() error {
	if state.Sequence < 0 || state.Sequence >= 9007199254740991 || state.ReviveTimes < 0 {
		return ErrUnavailable
	}
	if !state.Active() {
		return nil
	}
	if len(state.Revision) != 64 || state.Girl <= 0 || state.Floor < 1 || state.Floor > 3 || state.Board.Validate() != nil {
		return ErrUnavailable
	}
	for identity, status := range state.Heroes {
		if identity <= 0 || status.Identity != identity || status.HP < 0 || status.MP < 0 || status.MP > 1000 || math.IsNaN(status.HP) || math.IsNaN(status.MP) || math.IsInf(status.HP, 0) || math.IsInf(status.MP, 0) || status.Reborn < 0 || status.Reborn > 1 {
			return ErrUnavailable
		}
	}
	if state.Pending != nil && (state.Pending.Attempt == "" || state.Pending.Generation == "" || state.Pending.Grid < 1 || state.Pending.Grid > BoardCells) {
		return ErrUnavailable
	}
	return nil
}
