package memoir

import (
	"errors"
	"gxb.local/backend/v2/internal/domain/campaign"
)

const ContractID = "I9_MEMOIR_V1"
const PolicyID = "I9_MEMOIR_PRIVATE_POLICY_V1"
const TeamLimit = 5
const ResultWindowSeconds = 3600

var (
	ErrInvalid     = errors.New("memoir invalid request")
	ErrRefused     = errors.New("memoir refused")
	ErrUnavailable = errors.New("memoir unavailable")
)

type Count struct {
	Kind   int64 `json:"kind"`
	Bounds []int `json:"bounds"`
}
type Floor struct {
	ID        int     `json:"id"`
	Energy    []int64 `json:"energy"`
	Scroll    []int64 `json:"scroll"`
	Gifts     []int64 `json:"gifts"`
	BoxScroll []int64 `json:"box_scroll"`
	Bosses    []int64 `json:"bosses"`
	Opponents []int   `json:"opponents"`
}
type Girl struct {
	ID     int64     `json:"id"`
	Scroll int64     `json:"scroll"`
	Fights [][]int64 `json:"fights"`
	Boxes  [][]int64 `json:"boxes"`
	Banned []int64   `json:"banned"`
}
type Boss struct {
	ID     int64 `json:"id"`
	Battle int64 `json:"battle"`
}
type Gift struct {
	ID    int64      `json:"id"`
	Box   int64      `json:"box"`
	Items [][2]int64 `json:"items"`
}
type Drop struct {
	Item   int64 `json:"item"`
	Amount int64 `json:"amount"`
	Rate   int64 `json:"rate"`
}
type Box struct {
	ID   int64  `json:"id"`
	Rows []Drop `json:"rows"`
}
type Catalog struct {
	Schema        int                 `json:"schema_version"`
	Contract      string              `json:"contract_id"`
	SourceArchive string              `json:"source_archive"`
	Columns       int                 `json:"columns"`
	Rows          int                 `json:"rows"`
	BigKey        int64               `json:"big_key"`
	SmallKey      int64               `json:"small_key"`
	Selected      []int64             `json:"selected"`
	Counts        []Count             `json:"counts"`
	Floors        []Floor             `json:"floors"`
	Girls         []Girl              `json:"girls"`
	Bosses        []Boss              `json:"bosses"`
	Gifts         []Gift              `json:"gifts"`
	Boxes         []Box               `json:"boxes"`
	Fights        map[int64][][]int64 `json:"fights"`
	ReviveCosts   []int64             `json:"revive_costs"`
	FinalGifts    []int64             `json:"final_gifts"`
}

func (catalog Catalog) Validate() error {
	if catalog.Schema != 1 || catalog.Contract != ContractID || len(catalog.SourceArchive) != 64 || catalog.Columns != 9 || catalog.Rows != 6 || catalog.BigKey != 50001400 || catalog.SmallKey != 50001401 || len(catalog.Selected) != 11 || len(catalog.Counts) != 6 || len(catalog.Floors) != 3 || len(catalog.Girls) != 11 || len(catalog.Bosses) != 6 || len(catalog.Gifts) != 9 || len(catalog.Boxes) != 75 || len(catalog.Fights) != 226 || len(catalog.ReviveCosts) != 330 || len(catalog.FinalGifts) != 3 {
		return ErrUnavailable
	}
	boxes := map[int64]bool{}
	count := 0
	for _, box := range catalog.Boxes {
		if box.ID <= 0 || boxes[box.ID] || len(box.Rows) == 0 {
			return ErrUnavailable
		}
		boxes[box.ID] = true
		for _, row := range box.Rows {
			if row.Item <= 0 || row.Amount <= 0 || row.Rate < 0 || row.Rate > 10000 {
				return ErrUnavailable
			}
			count++
		}
	}
	if count != 128 {
		return ErrUnavailable
	}
	for index, floor := range catalog.Floors {
		if floor.ID != index+1 || len(floor.Energy) != 3 || len(floor.Scroll) != 3 || len(floor.Gifts) != 2 || len(floor.BoxScroll) != 2 || len(floor.Bosses) != 2 || len(floor.Opponents) != 2 {
			return ErrUnavailable
		}
		for _, cost := range floor.Energy {
			if cost <= 0 {
				return ErrUnavailable
			}
		}
		for _, amount := range append(append([]int64{}, floor.Scroll...), floor.BoxScroll...) {
			if amount < 0 {
				return ErrUnavailable
			}
		}
		for _, identifier := range floor.Gifts {
			if _, found := catalog.Gift(identifier); !found {
				return ErrUnavailable
			}
		}
		for _, identifier := range floor.Bosses {
			if catalog.BossBattle(identifier) == 0 {
				return ErrUnavailable
			}
		}
	}
	selected := map[int64]bool{}
	for _, identifier := range catalog.Selected {
		if selected[identifier] {
			return ErrUnavailable
		}
		selected[identifier] = true
	}
	for _, girl := range catalog.Girls {
		if !selected[girl.ID] || girl.Scroll <= 0 || len(girl.Fights) != 3 || len(girl.Boxes) != 3 {
			return ErrUnavailable
		}
		delete(selected, girl.ID)
		for _, group := range girl.Fights {
			if len(group) == 0 {
				return ErrUnavailable
			}
			for _, identifier := range group {
				if len(catalog.Fights[identifier]) == 0 {
					return ErrUnavailable
				}
			}
		}
		for _, group := range girl.Boxes {
			if len(group) != 3 {
				return ErrUnavailable
			}
			for _, identifier := range group {
				if !boxes[identifier] {
					return ErrUnavailable
				}
			}
		}
	}
	if len(selected) != 0 {
		return ErrUnavailable
	}
	for _, gift := range catalog.Gifts {
		if !boxes[gift.Box] {
			return ErrUnavailable
		}
		for _, item := range gift.Items {
			if item[0] <= 0 || item[1] <= 0 {
				return ErrUnavailable
			}
		}
	}
	for _, identifier := range catalog.FinalGifts {
		if _, found := catalog.Gift(identifier); !found {
			return ErrUnavailable
		}
	}
	for _, cost := range catalog.ReviveCosts {
		if cost <= 0 {
			return ErrUnavailable
		}
	}
	for _, waves := range catalog.Fights {
		if len(waves) == 0 || len(waves) > 3 {
			return ErrUnavailable
		}
		for _, wave := range waves {
			if len(wave) == 0 {
				return ErrUnavailable
			}
			for _, identifier := range wave {
				if identifier <= 0 {
					return ErrUnavailable
				}
			}
		}
	}
	for _, count := range catalog.Counts {
		if count.Kind < 1 || count.Kind > 6 || len(count.Bounds) < 1 || len(count.Bounds) > 2 || count.Bounds[0] < 0 {
			return ErrUnavailable
		}
		if len(count.Bounds) == 2 && count.Bounds[1] < count.Bounds[0] {
			return ErrUnavailable
		}
	}
	return nil
}
func (catalog Catalog) Girl(identifier int64) (Girl, bool) {
	for _, girl := range catalog.Girls {
		if girl.ID == identifier {
			return girl, true
		}
	}
	return Girl{}, false
}
func (catalog Catalog) Gift(identifier int64) (Gift, bool) {
	for _, gift := range catalog.Gifts {
		if gift.ID == identifier {
			return gift, true
		}
	}
	return Gift{}, false
}
func (catalog Catalog) BossBattle(identifier int64) int64 {
	for _, boss := range catalog.Bosses {
		if boss.ID == identifier {
			return boss.Battle
		}
	}
	return 0
}
func (catalog Catalog) Draw(identifier int64, source campaign.Uniform) []campaign.Item {
	result := []campaign.Item{}
	for _, box := range catalog.Boxes {
		if box.ID != identifier {
			continue
		}
		for _, row := range box.Rows {
			for _, item := range campaign.DropRows([][2]int64{{row.Item, row.Rate}}, source) {
				item.Num *= row.Amount
				result = append(result, item)
			}
		}
	}
	return result
}
func (catalog Catalog) GiftItems(identifier int64, source campaign.Uniform) ([]campaign.Item, error) {
	gift, found := catalog.Gift(identifier)
	if !found {
		return nil, ErrUnavailable
	}
	result := catalog.Draw(gift.Box, source)
	for _, item := range gift.Items {
		result = append(result, campaign.Item{ItemID: item[0], Num: item[1]})
	}
	return result, nil
}
