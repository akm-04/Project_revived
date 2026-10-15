package builtin

import "errors"

// Content DTO stays independent of domain packages. Owning adapter converts it.
type SpiritInputCatalog struct {
	SchemaVersion int                            `json:"schema_version"`
	PolicyID      string                         `json:"policy_id"`
	Tables        map[string][]map[string]string `json:"tables"`
}

func (c SpiritInputCatalog) Validate() error {
	if c.SchemaVersion != 1 || c.PolicyID != "C2H_SPIRIT_SOURCE_V1" || len(c.Tables["models"]) != 54 || len(c.Tables["equipment"]) != 378 || len(c.Tables["strengthen"]) != 90 || len(c.Tables["suits"]) != 11 || len(c.Tables["items"]) != 378 {
		return errors.New("spirit content: unqualified source payload")
	}
	return nil
}
