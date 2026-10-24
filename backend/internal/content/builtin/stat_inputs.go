package builtin

import "errors"

type StatInputCatalog struct {
	SchemaVersion int                            `json:"schema_version"`
	PolicyID      string                         `json:"policy_id"`
	Tables        map[string][]map[string]string `json:"tables"`
}

func (c StatInputCatalog) Validate() error {
	if c.SchemaVersion != 1 || c.PolicyID != "C3B_SRC64_NUMERIC_INPUT_V1" || len(c.Tables) != 6 || len(c.Tables["partner"]) != 555 || len(c.Tables["super_partner"]) != 14 || len(c.Tables["pet"]) != 54 || len(c.Tables["item"]) == 0 || len(c.Tables["skill"]) == 0 || len(c.Tables["enhance"]) == 0 {
		return errors.New("stat inputs: unqualified content")
	}
	return nil
}
