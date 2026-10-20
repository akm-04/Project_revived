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
type AchievementLevel struct {
	ID             int64      `json:"id"`
	PointCondition int64      `json:"point_condition"`
	Items          [][2]int64 `json:"items"`
}
type AchievementCatalog struct {
	SchemaVersion int                     `json:"schema_version"`
	PolicyID      string                  `json:"policy_id"`
	SelectedID    int64                   `json:"selected_id"`
	Rows          []AchievementDefinition `json:"rows"`
	Levels        []AchievementLevel      `json:"levels,omitempty"`
}

func (c AchievementCatalog) Validate() error {
	levelsPresent := c.SchemaVersion == 2 && len(c.Levels) == 10 || c.SchemaVersion == 1 && len(c.Levels) == 0
	if !levelsPresent || c.PolicyID != "C4B_MARRIED_POPULATION_TIER_FACTS_V1" || c.SelectedID != 100014 || len(c.Rows) != 33 {
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
	for i, l := range c.Levels {
		if l.ID != int64(i+1) || i == 0 && (l.PointCondition != 0 || len(l.Items) != 0) || i > 0 && (l.PointCondition <= c.Levels[i-1].PointCondition || len(l.Items) == 0) {
			return errors.New("achievement level")
		}
		for _, item := range l.Items {
			if item[0] <= 0 || item[1] <= 0 {
				return errors.New("achievement level item")
			}
		}
	}
	if c.Rows[13].Thresholds != [3]int64{1, 10, 20} || c.Rows[13].Daily != 0 {
		return errors.New("achievement selected profile")
	}
	return nil
}
