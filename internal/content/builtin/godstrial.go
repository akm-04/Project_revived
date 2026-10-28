package builtin

import (
	"encoding/json"
	"errors"
)

type GodsTrialCatalog struct {
	Schema      int               `json:"schema_version"`
	Contract    string            `json:"contract_id"`
	Stages      []json.RawMessage `json:"stages"`
	Boxes       []json.RawMessage `json:"boxes"`
	SpiritItems map[int64]bool    `json:"spirit_items"`
}

func (c GodsTrialCatalog) Validate() error {
	if c.Schema != 1 || c.Contract != "I9_GODS_TRIAL_V1" || len(c.Stages) != 42 || len(c.Boxes) != 84 || len(c.SpiritItems) != 360 {
		return errors.New("gods trial catalog")
	}
	return nil
}
