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
	if c.RecipePolicyID != "C2D_FRAGMENT_RECIPES_V1" || c.SchemaVersion != 1 || c.PolicyID != "C2D_V1_BUILDING_SEEDS_AND_JOB_REFUNDS_V1" || len(c.Buildings) != 112 || len(c.Books) != 54 || len(c.Skills) != 399 || len(c.Costs) != 24 {
		return errors.New("book content: unqualified payload")
	}
	return nil
}
