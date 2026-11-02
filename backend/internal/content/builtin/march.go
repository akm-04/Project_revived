package builtin

import (
	"encoding/json"
	"errors"
)

// MarchCatalog validates the transport profile here; the March domain checks
// its rules after strict decoding of the pinned content catalog.
type MarchCatalog struct {
	Schema          int64                 `json:"schema_version"`
	Contract        string                `json:"contract_id"`
	PolicyID        string                `json:"policy_id"`
	PolicySHA       string                `json:"policy_sha256"`
	Sources         map[string]string     `json:"source_sha256"`
	Advances        []json.RawMessage     `json:"advances"`
	Recommendations [][]int64             `json:"recommendations"`
	Pools           map[string][][3]int64 `json:"pools"`
	Misc            map[string]string     `json:"misc"`
	Milestones      []int64               `json:"milestones"`
	Policy          json.RawMessage       `json:"policy"`
}

func (c MarchCatalog) Validate() error {
	if c.Schema != 1 || c.Contract != "I9_MARCH_V1" || c.PolicyID != "I9_MARCH_PRIVATE_POLICY_V1" || len(c.PolicySHA) != 64 || len(c.Advances) != 36 || len(c.Recommendations) != 6 || len(c.Pools) != 8 || len(c.Milestones) != 4 || !json.Valid(c.Policy) {
		return errors.New("march catalog profile")
	}
	return nil
}
