package builtin

import "errors"

type ConquerInputCatalog struct {
	SchemaVersion int                            `json:"schema_version"`
	PolicyID      string                         `json:"policy_id"`
	Tables        map[string][]map[string]string `json:"tables"`
}

func (c ConquerInputCatalog) Validate() error {
	if c.SchemaVersion != 1 || c.PolicyID != "C2J_CONQUER_SOURCE_V1" || len(c.Tables["regions"]) != 5 || len(c.Tables["campaigns"]) != 56 || len(c.Tables["loops"]) != 8 {
		return errors.New("conquer content: unqualified source payload")
	}
	return nil
}
