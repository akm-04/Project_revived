package builtin

import (
	"encoding/json"
	"errors"
)

// OneOnOneCatalog is the deployment profile of one_on_one_catalog.json; the
// OneOnOne domain owns the full typed rules decoded from the stored payload.
type OneOnOneCatalog struct {
	SchemaVersion int               `json:"schema_version"`
	ContractID    string            `json:"contract_id"`
	PolicyID      string            `json:"policy_id"`
	Levels        []json.RawMessage `json:"levels"`
	Rewards       []json.RawMessage `json:"rewards"`
	Titles        []json.RawMessage `json:"titles"`
}

func (c OneOnOneCatalog) Validate() error {
	if c.SchemaVersion != 1 || c.ContractID != "C5C_ONE_ON_ONE_MODE_V1" || c.PolicyID != "C5C_ONE_ON_ONE_PRIVATE_POLICY_V1" || len(c.Levels) != 5 || len(c.Rewards) != 30 || len(c.Titles) != 4 {
		return errors.New("one on one catalog profile")
	}
	return nil
}
