package builtin

import (
	"encoding/json"
	"errors"
)

type PetCampaignCatalog struct {
	Schema   int64             `json:"schema_version"`
	Contract string            `json:"contract_id"`
	Floors   []json.RawMessage `json:"floors"`
}

func (c PetCampaignCatalog) Validate() error {
	if c.Schema != 1 || c.Contract != "I9_PET_CAMPAIGN_V1" || len(c.Floors) != 120 {
		return errors.New("pet campaign catalog")
	}
	return nil
}
