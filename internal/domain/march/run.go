// Package march owns Champion run state, not heroes, combat verdicts or value.
package march

import (
	"encoding/json"
	"errors"
	"fmt"
	"strconv"

	cd "gxb.local/backend/v2/internal/domain/combat"
)

const ContractID = "I9_MARCH_V1"
const PolicyID = "I9_MARCH_PRIVATE_POLICY_V1"
const Stages = 15

var (
	ErrInvalid     = errors.New("march: invalid parameter")
	ErrRefused     = errors.New("march: refused")
	ErrUnavailable = errors.New("march: unavailable")
)

type Status struct {
	Hero   int64   `json:"hero_id"`
	Player int64   `json:"player_id,omitempty"`
	Health int64   `json:"health"`
	HP     float64 `json:"hp"`
	MP     float64 `json:"mp"`
	Reborn int64   `json:"is_reborn"`
}

// Enemy is an immutable matched projection plus run-local attrition. Source
// player identity is provenance; these copies never mutate the other player.
type Enemy struct {
	TableID      int64                     `json:"table_id"`
	AvatarFrame  int64                     `json:"avatar_frame"`
	ConquerLevel int64                     `json:"conquer_lev"`
	ConquerLoop  int64                     `json:"conquer_loop_id"`
	Player       int64                     `json:"team_id"`
	Name         string                    `json:"name"`
	Level        int64                     `json:"level"`
	Avatar       int64                     `json:"avatar"`
	Robot        int64                     `json:"is_robot"`
	Heroes       map[string]map[string]any `json:"heroes"`
	Force        int64                     `json:"force"`
}

// Loan is the one borrowed girl a run holds to its end (I9_GUILD_RENTAL_V1 C12).
type Loan struct {
	Player int64 `json:"player_id"`
	Unit   int64 `json:"unit_id"`
}

type Run struct {
	Revision       string            `json:"revision"`
	Occurrence     string            `json:"occurrence"`
	ResetDay       int64             `json:"reset_day"`
	ResetUsed      bool              `json:"reset_used"`
	DrinkDay       int64             `json:"drink_day"`
	Drinks         int64             `json:"drinks"`
	Passed         int64             `json:"passed"`
	Won            bool              `json:"won"`
	Extra          bool              `json:"extra"`
	HasFight       bool              `json:"has_fight"`
	Advanced       bool              `json:"advanced"`
	Heroes         map[string]Status `json:"heroes"`
	Loan           *Loan             `json:"loan,omitempty"`
	Enemies        []Enemy           `json:"enemies"`
	Rewards        map[string][]any  `json:"rewards"`
	RecommendDay   int64             `json:"recommend_day"`
	Recommend      []int64           `json:"recommend"`
	Pending        string            `json:"pending"`
	Formation      []int64           `json:"formation"`
	BattleOrdinal  int64             `json:"battle_ordinal"`
	LastResult     json.RawMessage   `json:"last_result,omitempty"`
	LifetimeChests int64             `json:"lifetime_chests"`
	Version        int64             `json:"version"`
}

// Refresh only refreshes daily entitlements; it never discards an unfinished
// run or resurrects its dead girls. Reset is an explicit player command.
func (r *Run) Refresh(day int64) {
	if day > r.ResetDay {
		r.ResetDay, r.ResetUsed = day, false
	}
	if day > r.DrinkDay {
		r.DrinkDay, r.Drinks = day, 0
	}
}

func (r Run) NextStage() int64 { return r.Passed + 1 }
func (r Run) Generation() string {
	return fmt.Sprintf("%s/%d/%d", r.Occurrence, r.NextStage(), r.BattleOrdinal)
}
func (r Run) CanFight() bool { return r.Passed < Stages && !r.Won }
func (r Run) Alive(id int64) bool {
	s, ok := r.Heroes[strconv.FormatInt(id, 10)]
	return !ok || s.Health != 2
}

func (r *Run) ApplyReport(report cd.Report, drinks int64) error {
	if !r.CanFight() || r.Pending == "" || drinks < 0 || drinks > r.Drinks {
		return ErrRefused
	}
	alive := false
	for _, s := range report.Allies {
		if s.HP > 0 {
			alive = true
		}
	}
	if report.Win && !alive {
		return ErrRefused
	}
	for _, s := range report.Enemies {
		if report.Win && s.HP > 0 {
			return ErrRefused
		}
	}
	for _, s := range report.Allies {
		key := strconv.FormatInt(s.Identity, 10)
		if old, ok := r.Heroes[key]; ok && old.Health == 2 {
			return ErrRefused
		}
	}
	if r.Passed < 0 || int64(len(r.Enemies)) < r.NextStage() {
		return ErrInvalid
	}
	for _, s := range report.Enemies {
		if _, ok := r.Enemies[r.Passed].Heroes[strconv.FormatInt(s.Identity, 10)]; !ok {
			return ErrInvalid
		}
	}
	if r.Heroes == nil {
		r.Heroes = map[string]Status{}
	}
	// Combat has validated coverage, identity and numeric bounds before this call.
	for _, s := range report.Allies {
		health := int64(1)
		if s.HP <= 0 {
			health = 2
		}
		r.Heroes[strconv.FormatInt(s.Identity, 10)] = Status{Hero: s.Identity, Player: s.Player, Health: health, HP: s.HP, MP: s.MP, Reborn: s.Reborn}
	}
	if int64(len(r.Enemies)) < r.NextStage() {
		return ErrInvalid
	}
	enemy := &r.Enemies[r.Passed]
	for _, s := range report.Enemies {
		row, ok := enemy.Heroes[strconv.FormatInt(s.Identity, 10)]
		if !ok {
			return ErrInvalid
		}
		health := int64(1)
		if s.HP <= 0 {
			health = 2
		}
		row["health"], row["hp"], row["mp"], row["is_reborn"] = health, s.HP, s.MP, s.Reborn
	}
	r.Drinks -= drinks
	r.Won = report.Win
	r.Pending = ""
	r.Version++
	return nil
}

func (r *Run) AdvanceChest(stage int64) error {
	if !r.Won || stage != r.NextStage() || stage > Stages {
		return ErrRefused
	}
	r.Passed++
	r.Won = false
	r.LifetimeChests++
	r.Version++
	return nil
}

func (r Run) Cleared() int64 {
	if r.Won {
		return r.Passed + 1
	}
	return r.Passed
}
func (r Run) Projection() map[string]any {
	resets := int64(1)
	if r.ResetUsed {
		resets = 0
	}
	won, extra, fought := int64(0), int64(0), int64(0)
	if r.Won {
		won = 1
	}
	if r.Extra {
		extra = 1
	}
	if r.HasFight {
		fought = 1
	}
	recommended := ""
	for i, id := range r.Recommend {
		if i > 0 {
			recommended += "|"
		}
		recommended += strconv.FormatInt(id, 10)
	}
	rewards := make([]any, Stages)
	for i := range rewards {
		row := r.Rewards[strconv.Itoa(i+1)]
		if row == nil {
			row = []any{}
		}
		rewards[i] = row
	}
	statuses := map[string]any{}
	for k, s := range r.Heroes {
		statuses[k] = s
	}
	enemies := make([]map[string]any, 0, len(r.Enemies))
	for _, enemy := range r.Enemies {
		enemies = append(enemies, enemy.Wire())
	}
	return map[string]any{"map_info": map[string]any{"is_reborn": 0, "is_external_award": extra, "stage_done": won, "passed_stage": r.Passed, "resets_left": resets, "has_fight": fought, "power_drink": r.Drinks, "recommend_partners": recommended}, "hero_status": map[string]any{"self_list": statuses, "rent_list": r.rentList()}, "enemies": enemies, "rewards": rewards}
}

// rentList is the one borrowed girl's run-local health the team window shows.
func (r Run) rentList() map[string]any {
	if r.Loan == nil {
		return map[string]any{}
	}
	status, ok := r.Heroes[strconv.FormatInt(r.Loan.Unit, 10)]
	if !ok {
		return map[string]any{}
	}
	return map[string]any{"health": status.Health, "hp": status.HP, "mp": status.MP}
}

// Stock indexes heroes numerically in both MarchTeamInfo and result merges.
// Opponent instance identities are local slots; source_partner_id is provenance.
func (e Enemy) Rows() []map[string]any {
	rows := make([]map[string]any, 0, len(e.Heroes))
	for i := 1; i <= len(e.Heroes); i++ {
		rows = append(rows, e.Heroes[strconv.Itoa(i)])
	}
	return rows
}
func (e Enemy) Wire() map[string]any {
	return map[string]any{"table_id": e.TableID, "avatar_frame": e.AvatarFrame, "conquer_lev": e.ConquerLevel, "conquer_loop_id": e.ConquerLoop, "team_id": e.Player, "name": e.Name, "level": e.Level, "avatar": e.Avatar, "is_robot": e.Robot, "heroes": e.Rows(), "force": e.Force}
}
