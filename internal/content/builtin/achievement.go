package builtin

import "errors"

type AchievementDefinition struct {
	ID         int64    `json:"id"`
	Thresholds [3]int64 `json:"thresholds"`
	Points     [3]int64 `json:"points"`
	Daily      int      `json:"daily"`
	Hidden     int      `json:"hidden"`
	Stamp      int      `json:"stamp"`
}
type AchievementCatalog struct {
	SchemaVersion int                     `json:"schema_version"`
	PolicyID      string                  `json:"policy_id"`
	SelectedID    int64                   `json:"selected_id"`
	Rows          []AchievementDefinition `json:"rows"`
}

func (c AchievementCatalog) Validate() error {
	if c.SchemaVersion != 1 || c.PolicyID != "C4B_MARRIED_POPULATION_TIER_FACTS_V1" || c.SelectedID != 100014 || len(c.Rows) != 33 {
		return errors.New("achievement catalog profile")
	}
	for i, r := range c.Rows {
		if r.ID != 100001+int64(i) || r.Daily < 0 || r.Daily > 1 || r.Hidden < 0 || r.Hidden > 1 || r.Stamp < 0 || r.Stamp > 1 {
			return errors.New("achievement source row")
		}
		for j, v := range r.Thresholds {
			if v < 1 || j > 0 && v <= r.Thresholds[j-1] || r.Points[j] <= 0 {
				return errors.New("achievement tier")
			}
		}
	}
	if c.Rows[13].Thresholds != [3]int64{1, 10, 20} || c.Rows[13].Daily != 0 {
		return errors.New("achievement selected profile")
	}
	return nil
}
