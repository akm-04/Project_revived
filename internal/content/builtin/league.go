package builtin

import (
	"encoding/json"
	"errors"
)

type LeagueCatalog struct {
	SchemaVersion int               `json:"schema_version"`
	ContractID    string            `json:"contract_id"`
	PolicyID      string            `json:"policy_id"`
	Daily         []json.RawMessage `json:"daily"`
	Final         []json.RawMessage `json:"final"`
	Schedule      []string          `json:"schedule"`
}

func (c LeagueCatalog) Validate() error {
	if c.SchemaVersion != 1 || c.ContractID != "C5F_CHAMPIONS_LEAGUE_MODE_V1" || c.PolicyID != "C5F_LEAGUE_PRIVATE_POLICY_V2" || len(c.Daily) != 90 || len(c.Final) != 30 || len(c.Schedule) != 50 {
		return errors.New("League catalog profile")
	}
	return nil
}
