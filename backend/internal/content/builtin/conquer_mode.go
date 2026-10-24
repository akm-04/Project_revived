package builtin

import (
	"encoding/json"
	"errors"
)

// ConquerModeCatalog is the deployment profile of conquer_mode_catalog.json;
// the Conquer School domain owns the full typed rules decoded from the stored payload.
type ConquerModeCatalog struct {
	SchemaVersion int               `json:"schema_version"`
	ContractID    string            `json:"contract_id"`
	PolicyID      string            `json:"policy_id"`
	Missions      []json.RawMessage `json:"missions"`
	Loops         []json.RawMessage `json:"loops"`
	BuyCosts      []int64           `json:"buy_costs"`
}

func (c ConquerModeCatalog) Validate() error {
	if c.SchemaVersion != 1 || c.ContractID != "C5E_CONQUER_SCHOOL_MODE_V1" || c.PolicyID != "C5E_CONQUER_PRIVATE_POLICY_V1" || len(c.Missions) != 56 || len(c.Loops) != 8 || len(c.BuyCosts) != 10 {
		return errors.New("conquer mode catalog profile")
	}
	return nil
}
