package builtin

import (
	"encoding/json"
	"errors"
)

// Content validates the transport; the domain validates rules after pinned decoding.
type WorkplaceCatalog struct {
	Schema       int64             `json:"schema_version"`
	Contract     string            `json:"contract_id"`
	PolicyID     string            `json:"policy_id"`
	PolicySHA    string            `json:"policy_sha256"`
	Sources      map[string]string `json:"source_sha256"`
	Locations    []json.RawMessage `json:"locations"`
	Jobs         []json.RawMessage `json:"jobs"`
	Crew         []json.RawMessage `json:"crew"`
	Scrolls      []int64           `json:"scrolls"`
	ItemProducts map[int64]int64   `json:"item_products"`
	Formula      json.RawMessage   `json:"formula"`
	VIP          []json.RawMessage `json:"vip"`
	Policy       json.RawMessage   `json:"policy"`
}

func (c WorkplaceCatalog) Validate() error {
	if c.Schema != 1 || c.Contract != "I9_WORKPLACE_V1" || c.PolicyID != "I9_WORKPLACE_PRIVATE_POLICY_V1" || len(c.PolicySHA) != 64 || len(c.Sources) != 7 || len(c.Locations) != 6 || len(c.Jobs) != 35 || len(c.Crew) != 114 || len(c.Scrolls) != 109 || len(c.VIP) != 16 || !json.Valid(c.Formula) || !json.Valid(c.Policy) {
		return errors.New("workplace catalog profile")
	}
	return nil
}
