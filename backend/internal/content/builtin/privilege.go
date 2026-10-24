package builtin

import "errors"

type VIPThreshold struct {
	Level    int64 `json:"level"`
	Charge   int64 `json:"charge"`
	SkillCap int64 `json:"skill_cap"`
}
type PrivilegeCatalog struct {
	SchemaVersion int            `json:"schema_version"`
	PolicyID      string         `json:"policy_id"`
	Rows          []VIPThreshold `json:"rows"`
}

func (c PrivilegeCatalog) Validate() error {
	if c.SchemaVersion != 1 || c.PolicyID != "C4A_SRC64_VIP_THRESHOLDS_V1" || len(c.Rows) != 16 {
		return errors.New("privilege catalog profile")
	}
	for i, r := range c.Rows {
		if r.Level != int64(i) || r.Charge < 0 || r.SkillCap < 0 || i > 0 && r.Charge <= c.Rows[i-1].Charge {
			return errors.New("privilege threshold")
		}
	}
	if c.Rows[0].Charge != 0 || c.Rows[0].SkillCap != 10 {
		return errors.New("privilege baseline profile")
	}
	return nil
}
