package builtin

import (
	"encoding/json"
	"errors"
)

// ArenaCatalog is the deployment profile of arena_catalog.json; the Arena
// domain owns the full typed rules decoded from the stored payload.
type ArenaCatalog struct {
	SchemaVersion int               `json:"schema_version"`
	ContractID    string            `json:"contract_id"`
	PolicyID      string            `json:"policy_id"`
	Levels        []json.RawMessage `json:"levels"`
	Rewards       []json.RawMessage `json:"rewards"`
	Missions      []json.RawMessage `json:"missions"`
}

func (c ArenaCatalog) Validate() error {
	if c.SchemaVersion != 1 || c.ContractID != "C5D_ARENA_SEASON_MODE_V1" || c.PolicyID != "C5D_ARENA_PRIVATE_POLICY_V1" || len(c.Levels) != 26 || len(c.Rewards) != 26 || len(c.Missions) != 12 {
		return errors.New("arena catalog profile")
	}
	return nil
}
