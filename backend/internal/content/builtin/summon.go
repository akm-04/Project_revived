package builtin

import (
	"encoding/json"
	"errors"
)

// SummonCatalog is the deployment profile of summon_catalog.json; the summon
// domain owns the full typed rules decoded from the stored payload.
type SummonCatalog struct {
	SchemaVersion int               `json:"schema_version"`
	ContractID    string            `json:"contract_id"`
	PolicyID      string            `json:"policy_id"`
	Buttons       []json.RawMessage `json:"buttons"`
	Pools         []json.RawMessage `json:"pools"`
	Heroes        []json.RawMessage `json:"heroes"`
	SoulCaskets   []json.RawMessage `json:"soul_caskets"`
	MagicHeroes   []int64           `json:"magic_heroes"`
}

func (c SummonCatalog) Validate() error {
	if c.SchemaVersion != 1 || c.ContractID != "I9_GACHA_V1" || c.PolicyID != "I9_GACHA_PRIVATE_POLICY_V1" || len(c.Buttons) != 14 || len(c.Pools) != 18 || len(c.Heroes) != 291 || len(c.SoulCaskets) == 0 || len(c.MagicHeroes) == 0 {
		return errors.New("summon catalog profile")
	}
	return nil
}
