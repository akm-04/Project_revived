package builtin

import "errors"

// Content DTOs remain independent of domain packages; the owning adapter
// performs the typed domain conversion and deeper rule validation.
type ElementInputCatalog struct {
	SchemaVersion int                            `json:"schema_version"`
	PolicyID      string                         `json:"policy_id"`
	Tables        map[string][]map[string]string `json:"tables"`
}

func (c ElementInputCatalog) Validate() error {
	if c.SchemaVersion != 1 || c.PolicyID != "C2G_ELEMENT_SOURCE_V1" || len(c.Tables["equipment"]) != 80 || len(c.Tables["strengthen"]) != 11 || len(c.Tables["items"]) != 107 {
		return errors.New("element content: unqualified source payload")
	}
	return nil
}
