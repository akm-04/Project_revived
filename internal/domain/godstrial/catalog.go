// Package godstrial owns Gods Trial progression and timed auto occurrences.
package godstrial

import (
	"errors"
	"gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/grant"
)

const ContractID = "I9_GODS_TRIAL_V1"
const PolicyID = "I9_GODS_TRIAL_PRIVATE_POLICY_V1"

var (
	ErrInvalid     = errors.New("gods trial invalid request")
	ErrRefused     = errors.New("gods trial refused")
	ErrUnavailable = errors.New("gods trial unavailable")
)

type Stage struct {
	ID        int64 `json:"id"`
	Day       int64 `json:"day"`
	Previous  int64 `json:"previous"`
	Level     int64 `json:"level"`
	Battle    int64 `json:"battle"`
	WinCost   int64 `json:"win_cost"`
	LoseCost  int64 `json:"lose_cost"`
	FirstBox  int64 `json:"first_box"`
	RepeatBox int64 `json:"repeat_box"`
	Open      bool  `json:"open"`
}
type Catalog struct {
	Schema      int                `json:"schema_version"`
	Contract    string             `json:"contract_id"`
	Stages      []Stage            `json:"stages"`
	Boxes       []campaign.DropBox `json:"boxes"`
	SpiritItems map[int64]bool     `json:"spirit_items"`
	AutoMinutes int64              `json:"auto_minutes"`
	AutoLimit   int64              `json:"auto_limit"`
	SoftLimit   int64              `json:"soft_limit"`
}

func (c Catalog) Validate() error {
	if c.Schema != 1 || c.Contract != ContractID || len(c.Stages) != 42 || len(c.Boxes) != 84 || len(c.SpiritItems) != 360 || c.AutoMinutes != 5 || c.AutoLimit != 10 || c.SoftLimit != 2000 {
		return ErrUnavailable
	}
	stages := map[int64]bool{}
	boxes := map[int64]campaign.DropBox{}
	for _, b := range c.Boxes {
		if b.ID <= 0 || len(b.Rows) == 0 {
			return ErrUnavailable
		}
		if _, ok := boxes[b.ID]; ok {
			return ErrUnavailable
		}
		boxes[b.ID] = b
		for _, r := range b.Rows {
			if r[0] <= 0 || r[1] < 0 {
				return ErrUnavailable
			}
			if !c.SpiritItems[r[0]] && r[0] != 50002148 && r[0] != 50002149 {
				return ErrUnavailable
			}
		}
	}
	levels := []int64{60, 70, 80, 90, 95, 100}
	for _, s := range c.Stages {
		tier := s.ID % 1000
		if s.Day < 1 || s.Day > 7 || s.ID/1000 != s.Day || tier < 1 || tier > 6 || s.Level != levels[tier-1] || s.Battle <= 0 || s.WinCost != 20 || s.LoseCost != 2 || stages[s.ID] || !s.Open {
			return ErrUnavailable
		}
		previous := s.ID - 1
		if tier == 1 {
			previous = 0
		}
		if s.Previous != previous {
			return ErrUnavailable
		}
		stages[s.ID] = true
		first, ok := boxes[s.FirstBox]
		if !ok {
			return ErrUnavailable
		}
		if _, ok = boxes[s.RepeatBox]; !ok {
			return ErrUnavailable
		}
		for _, r := range first.Rows {
			if r[1] <= 0 || r[1]%10000 != 0 {
				return ErrUnavailable
			}
		}
	}
	return nil
}
func (c Catalog) Stage(id int64) (Stage, bool) {
	for _, s := range c.Stages {
		if s.ID == id {
			return s, true
		}
	}
	return Stage{}, false
}
func (c Catalog) Drop(id int64, rng campaign.Uniform) []campaign.Item {
	for _, b := range c.Boxes {
		if b.ID == id {
			return campaign.DropRows(b.Rows, rng)
		}
	}
	return []campaign.Item{}
}
func (c Catalog) Lines(items []campaign.Item) []grant.Line {
	out := make([]grant.Line, 0, len(items))
	for _, i := range items {
		l := grant.Line{Kind: grant.StackItem, ItemID: i.ItemID, Amount: i.Num}
		if c.SpiritItems[i.ItemID] {
			l.Kind = grant.SpecializedDomain
			l.Domain = "spirit"
		}
		out = append(out, l)
	}
	return out
}
