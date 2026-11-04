package builtin

import "errors"

type BookInputCatalog struct {
	RecipePolicyID string             `json:"recipe_policy_id"`
	SchemaVersion  int                `json:"schema_version"`
	PolicyID       string             `json:"policy_id"`
	Buildings      []BookBuildingRule `json:"buildings"`
	Books          []BookRule         `json:"books"`
	Skills         []BookSkillRule    `json:"skills"`
	Costs          []BookCostRule     `json:"costs"`
}
type BookBuildingRule struct {
	Type, Level, Duration, RequiresType, RequiresLevel, CutTime, UpperLimit int64
	Resources                                                               map[string]int64
	Attributes                                                              [3]string
}
type BookRule struct {
	ID, Star, Type, Piece, PieceCount, SkillPage int64
	Skills                                       []int64
}
type BookSkillRule struct {
	ID, Book, Partner, CostClass, AttrID, ActionType int64
	Value                                            string
	Times, Prerequisites                             []int64
}
type BookCostRule struct {
	Level, Class int64
	Resources    map[string]int64
	Pages        int64
}

func (c BookInputCatalog) Validate() error {
	if c.RecipePolicyID != "C2D_FRAGMENT_RECIPES_V1" || c.PolicyID != "C2D_V1_BUILDING_SEEDS_AND_JOB_REFUNDS_V1" || len(c.Books) != 54 || len(c.Skills) != 399 || len(c.Costs) != 24 {
		return errors.New("book content: unqualified payload")
	}
	var expectedBuildings map[int64]int64
	switch c.SchemaVersion {
	case 1:
		expectedBuildings = map[int64]int64{1: 6, 3: 6, 4: 100}
	case 2:
		expectedBuildings = map[int64]int64{1: 6, 2: 8, 3: 6, 4: 100, 5: 5, 6: 5, 7: 5}
	default:
		return errors.New("book content: unqualified payload")
	}
	counts := map[int64]int64{}
	sourceKeys := map[[2]int64]bool{}
	for _, rule := range c.Buildings {
		key := [2]int64{rule.Type, rule.Level}
		if sourceKeys[key] {
			return errors.New("book content: unqualified payload")
		}
		sourceKeys[key] = true
		counts[rule.Type]++
	}
	if len(counts) != len(expectedBuildings) {
		return errors.New("book content: unqualified payload")
	}
	for buildingType, expected := range expectedBuildings {
		if counts[buildingType] != expected {
			return errors.New("book content: unqualified payload")
		}
	}
	return nil
}
