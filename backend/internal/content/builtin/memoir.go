package builtin

import (
	"encoding/json"
	"errors"
)

type MemoirCatalog struct {
	Schema      int                        `json:"schema_version"`
	Contract    string                     `json:"contract_id"`
	Columns     int                        `json:"columns"`
	Rows        int                        `json:"rows"`
	Floors      []json.RawMessage          `json:"floors"`
	Girls       []json.RawMessage          `json:"girls"`
	Bosses      []json.RawMessage          `json:"bosses"`
	Gifts       []json.RawMessage          `json:"gifts"`
	Boxes       []json.RawMessage          `json:"boxes"`
	Fights      map[string]json.RawMessage `json:"fights"`
	ReviveCosts []int64                    `json:"revive_costs"`
}

func (catalog MemoirCatalog) Validate() error {
	if catalog.Schema != 1 || catalog.Contract != "I9_MEMOIR_V1" || catalog.Columns != 9 || catalog.Rows != 6 || len(catalog.Floors) != 3 || len(catalog.Girls) != 11 || len(catalog.Bosses) != 6 || len(catalog.Gifts) != 9 || len(catalog.Boxes) != 75 || len(catalog.Fights) != 226 || len(catalog.ReviveCosts) != 330 {
		return errors.New("memoir source catalog shape")
	}
	return nil
}
