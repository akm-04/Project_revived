package builtin

import "errors"

// Owner-neutral immutable Content DTO. Domain adapters validate numerical rules.
type Expr struct {
	Op    string  `json:"op"`
	Value float64 `json:"value,omitempty"`
	Name  string  `json:"name,omitempty"`
	Args  []Expr  `json:"args,omitempty"`
}
type ModelRules struct {
	Rules           map[string][]Expr `json:"rules"`
	Force           map[string]Expr   `json:"force"`
	BasicForceLimit int               `json:"basic_force_limit"`
}
type Template struct {
	Model      string      `json:"model"`
	ID         int64       `json:"id"`
	HeroType   int         `json:"hero_type"`
	Initial    []float64   `json:"initial"`
	Growth     [][]float64 `json:"growth"`
	InitPower  float64     `json:"init_power"`
	SlotSkills []int64     `json:"slot_skills"`
	BuffSkill  []int64     `json:"buff_skill"`
}
type StatRuleCatalog struct {
	SchemaVersion int                   `json:"schema_version"`
	PolicyID      string                `json:"policy_id"`
	Models        map[string]ModelRules `json:"models"`
	Constants     map[string]float64    `json:"constants"`
	Templates     []Template            `json:"templates"`
	Attributes    []map[string]string   `json:"attributes"`
	Skills        []map[string]string   `json:"skills"`
	Buffs         []map[string]string   `json:"buffs"`
	AdapterScope  string                `json:"adapter_scope"`
}

func (c StatRuleCatalog) Validate() error {
	if c.SchemaVersion != 1 || c.PolicyID != "C3A_SRC64_MATERIALIZED_STAT_V1" || len(c.Models) != 3 || len(c.Templates) != 623 || len(c.Attributes) != 49 || len(c.Buffs) != 3335 || len(c.Skills) == 0 {
		return errors.New("stat content: unqualified catalog")
	}
	return nil
}
