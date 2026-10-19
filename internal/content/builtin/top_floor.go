package builtin

import (
	"encoding/json"
	"errors"
)

// TopFloorCatalog is the deployment profile of top_floor_catalog.json; the
// Top Floor domain owns the full typed rules decoded from the stored payload.
type TopFloorCatalog struct {
	SchemaVersion int               `json:"schema_version"`
	ContractID    string            `json:"contract_id"`
	PolicyID      string            `json:"policy_id"`
	Rewards       []json.RawMessage `json:"rewards"`
	Robots        []json.RawMessage `json:"robots"`
	RobotHeroes   []json.RawMessage `json:"robot_heroes"`
}

func (c TopFloorCatalog) Validate() error {
	if c.SchemaVersion != 1 || c.ContractID != "C5B_TOP_FLOOR_MODE_V1" || c.PolicyID != "C5B_TOP_FLOOR_PRIVATE_POLICY_V1" || len(c.Rewards) != 30 || len(c.Robots) != 10325 || len(c.RobotHeroes) != 2805 {
		return errors.New("top floor catalog profile")
	}
	return nil
}
