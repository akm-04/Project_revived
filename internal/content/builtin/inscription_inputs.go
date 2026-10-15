package builtin

import "errors"

type InscriptionInputCatalog struct {
	SchemaVersion int                            `json:"schema_version"`
	PolicyID      string                         `json:"policy_id"`
	Tables        map[string][]map[string]string `json:"tables"`
}

func (c InscriptionInputCatalog) Validate() error {
	if c.SchemaVersion != 1 || c.PolicyID != "C2F_RECONSTRUCTION_V1" || len(c.Tables["items"]) != 240 || len(c.Tables["inscription"]) != 23 || len(c.Tables["suits"]) != 12 || len(c.Tables["positions"]) != 3 || len(c.Tables["exchange_materials"]) != 3 {
		return errors.New("inscription content: unqualified payload")
	}
	return nil
}
