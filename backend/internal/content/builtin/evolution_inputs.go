package builtin

import "errors"

// Owner-neutral Content DTO; CharacterHero's adapter validates its domain catalog.
type EvolutionInputCatalog struct {
	SchemaVersion int                            `json:"schema_version"`
	PolicyID      string                         `json:"policy_id"`
	Tables        map[string][]map[string]string `json:"tables"`
}

func (c EvolutionInputCatalog) Validate() error {
	if c.SchemaVersion != 1 || c.PolicyID != "C2I_STONE_SOURCE_V1" || len(c.Tables["stages"]) != 3 || len(c.Tables["tickets"]) != 2 || len(c.Tables["heroes"]) != 569 {
		return errors.New("evolution content: unqualified source payload")
	}
	return nil
}
