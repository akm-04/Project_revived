// Package petcampaign owns Sky Tower progress, distinct from Cloud Sky City.
package petcampaign

import (
	"errors"
	"fmt"
)

var (
	ErrInvalid     = errors.New("pet campaign invalid request")
	ErrRefused     = errors.New("pet campaign refused")
	ErrUnavailable = errors.New("pet campaign unavailable")
)

type Item struct {
	ID    int64 `json:"id"`
	Count int64 `json:"count"`
}
type Material struct {
	Mission int64 `json:"mission"`
	Item    int64 `json:"item"`
	Count   int64 `json:"count"`
}
type Floor struct {
	ID         int64      `json:"id"`
	Number     int64      `json:"number"`
	Type       int64      `json:"type"`
	Fight      int64      `json:"fight"`
	Level      int64      `json:"level"`
	Mana       int64      `json:"mana"`
	Rewards    []Item     `json:"rewards"`
	First      []Item     `json:"first"`
	VIPRewards []Item     `json:"vip_rewards"`
	VIPFirst   []Item     `json:"vip_first"`
	Materials  []Material `json:"materials"`
}
type Catalog struct {
	Schema        int64   `json:"schema_version"`
	Contract      string  `json:"contract_id"`
	Floors        []Floor `json:"floors"`
	LayerSeconds  int64   `json:"layer_seconds"`
	LayerCost     int64   `json:"layer_cost"`
	Ticket        int64   `json:"ticket"`
	UnlockTickets int64   `json:"unlock_tickets"`
	Raids         int64   `json:"raids"`
	PracticeMana  int64   `json:"practice_mana"`
	BuyPrices     []int64 `json:"buy_prices"`
	AwakePrices   []int64 `json:"awake_prices"`
}

func (c Catalog) Validate() error {
	if c.Schema != 1 || c.Contract != "I9_PET_CAMPAIGN_V1" || len(c.Floors) != 120 || c.LayerSeconds != 60 || c.LayerCost != 10 || c.Ticket != 50001328 || c.UnlockTickets != 10 || c.Raids != 3 || c.PracticeMana != 10000 || len(c.BuyPrices) != 330 || len(c.AwakePrices) != 16 {
		return ErrUnavailable
	}
	ids := map[int64]bool{}
	positions := map[string]bool{}
	for _, f := range c.Floors {
		limit := int64(100)
		if f.Type == 2 {
			limit = 20
		}
		key := fmt.Sprintf("%d:%d", f.Type, f.Number)
		if f.Type < 1 || f.Type > 2 || f.ID <= 0 || f.Fight <= 0 || f.Number < 1 || f.Number > limit || f.Level != 40 || f.Mana < 0 || ids[f.ID] || positions[key] {
			return ErrUnavailable
		}
		ids[f.ID] = true
		positions[key] = true
		for _, list := range [][]Item{f.Rewards, f.First, f.VIPRewards, f.VIPFirst} {
			for _, i := range list {
				if i.ID <= 0 || i.Count <= 0 {
					return ErrUnavailable
				}
			}
		}
		seen := map[int64]bool{}
		for _, m := range f.Materials {
			if f.Type != 1 || m.Mission <= 0 || m.Item <= 0 || m.Count != 1 || seen[m.Mission] {
				return ErrUnavailable
			}
			seen[m.Mission] = true
		}
	}
	for _, prices := range [][]int64{c.BuyPrices, c.AwakePrices} {
		for _, p := range prices {
			if p <= 0 {
				return ErrUnavailable
			}
		}
	}
	return nil
}
func (c Catalog) Floor(kind, number int64) (Floor, bool) {
	for _, f := range c.Floors {
		if f.Type == kind && f.Number == number {
			return f, true
		}
	}
	return Floor{}, false
}
func (c Catalog) ByID(id int64) (Floor, bool) {
	for _, f := range c.Floors {
		if f.ID == id {
			return f, true
		}
	}
	return Floor{}, false
}
func (f Floor) Award(first, vip bool) []Item {
	items := f.Rewards
	if first {
		items = f.First
	}
	if vip {
		items = f.VIPRewards
		if first {
			items = f.VIPFirst
		}
	}
	return append([]Item{}, items...)
}
