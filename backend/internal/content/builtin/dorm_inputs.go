package builtin

import "errors"

// Content DTOs are pure data. Domain binding belongs to contentstore, keeping
// the accepted content/application boundary intact.
type DormInputCatalog struct {
	SchemaVersion                 int                     `json:"schema_version"`
	LoungePolicyID                string                  `json:"lounge_policy_id"`
	RandomKeyPolicyID             string                  `json:"random_key_policy_id"`
	OriginalServerPolicyRecovered bool                    `json:"original_server_policy_recovered"`
	ExchangeKeys                  []DormExchangeKey       `json:"exchange_keys"`
	Rooms                         []DormRoomRule          `json:"rooms"`
	Types                         []DormTypeRule          `json:"types"`
	Keys                          []DormKeyRule           `json:"keys"`
	Expansions                    []DormExpansionRule     `json:"expansions"`
	Furniture                     []DormFurnitureRule     `json:"furniture"`
	HeroEquipment                 []DormHeroEquipmentRule `json:"hero_equipment"`
	EquipmentItems                []DormEquipmentItemRule `json:"equipment_items"`
}
type DormExchangeKey struct {
	ItemID       int64 `json:"item_id"`
	CementPerKey int64 `json:"cement_per_key"`
}
type DormGrowthTier struct {
	Comfort      int64    `json:"comfort"`
	AttributesBP [3]int64 `json:"attributes_bp"`
}
type DormRoomRule struct {
	TableID       int64            `json:"table_id"`
	MainType      int64            `json:"main_type"`
	AttributeType int64            `json:"attribute_type"`
	Length        int64            `json:"length"`
	Width         int64            `json:"width"`
	Height        int64            `json:"height"`
	Dresser       int64            `json:"dresser"`
	Growth        []DormGrowthTier `json:"growth"`
}
type DormTypeRule struct {
	MainType     int64 `json:"main_type"`
	Residents    int64 `json:"residents"`
	MaxExpansion int64 `json:"max_expansion"`
}
type DormKeyRule struct {
	ItemID    int64   `json:"item_id"`
	MainType  int64   `json:"main_type"`
	Templates []int64 `json:"templates"`
}
type DormExpansionRule struct {
	Level           int64       `json:"level"`
	Area            int64       `json:"area"`
	Comfort         int64       `json:"comfort"`
	DurationSeconds int64       `json:"duration_seconds"`
	CostItems       []int64     `json:"cost_items"`
	CostCounts      []int64     `json:"cost_counts"`
	AttributesBP    [3][3]int64 `json:"attributes_bp"`
}
type DormFurnitureRule struct {
	ItemID      int64   `json:"item_id"`
	Comfort     int64   `json:"comfort"`
	Floor       int64   `json:"floor"`
	PaperItem   int64   `json:"paper_item"`
	CanRotate   bool    `json:"can_rotate"`
	CanPile     bool    `json:"can_pile"`
	CanBePile   bool    `json:"can_be_pile"`
	SpecialType int64   `json:"special_type"`
	Panels      []int64 `json:"panels"`
	Length      int64   `json:"length"`
	Width       int64   `json:"width"`
	Height      int64   `json:"height"`
	PileLimit   bool    `json:"pile_limit"`
	PileStart   []int64 `json:"pile_start"`
	PileEnd     []int64 `json:"pile_end"`
}
type DormHeroEquipmentRule struct {
	TemplateID int64    `json:"template_id"`
	Items      [5]int64 `json:"items"`
}
type DormEquipmentItemRule struct {
	ItemID        int64 `json:"item_id"`
	RequiredLevel int64 `json:"required_level"`
}

var errDormInput = errors.New("builtin: invalid selected Dorm input profile")

func (c DormInputCatalog) Validate() error {
	if c.SchemaVersion != 1 || c.LoungePolicyID != "C2C_LOUNGE_EXP_V1" || c.RandomKeyPolicyID != "C2C_RANDOM_KEY_V1" || c.OriginalServerPolicyRecovered || len(c.Rooms) != 16 || len(c.Types) != 4 || len(c.Keys) != 18 || len(c.Expansions) != 3 || len(c.Furniture) != 267 || len(c.HeroEquipment) != 568 {
		return errDormInput
	}
	rooms := map[int64]DormRoomRule{}
	furniture := map[int64]bool{}
	items := map[int64]bool{}
	types := map[int64]DormTypeRule{}
	for _, r := range c.Types {
		if r.MainType < 1 || r.MainType > 4 || types[r.MainType].MainType != 0 || r.Residents < 1 || r.MaxExpansion < 0 {
			return errDormInput
		}
		types[r.MainType] = r
	}
	for _, r := range c.Furniture {
		if r.ItemID <= 0 || furniture[r.ItemID] || r.Comfort < 0 || r.Floor < 0 || r.Floor > 3 || r.Length <= 0 || r.Width <= 0 || r.Height < 0 || len(r.Panels) == 0 {
			return errDormInput
		}
		if r.PileLimit && (len(r.PileStart) != 2 || len(r.PileEnd) != 2) {
			return errDormInput
		}
		furniture[r.ItemID] = true
	}
	for _, r := range c.Rooms {
		if r.TableID <= 0 || rooms[r.TableID].TableID != 0 || types[r.MainType].MainType == 0 || r.Length <= 0 || r.Width <= 0 || r.Height <= 0 || len(r.Growth) == 0 {
			return errDormInput
		}
		if r.MainType != 1 && !furniture[r.Dresser] {
			return errDormInput
		}
		last := int64(-1)
		for _, g := range r.Growth {
			if g.Comfort <= last {
				return errDormInput
			}
			last = g.Comfort
			for _, a := range g.AttributesBP {
				if a < 0 {
					return errDormInput
				}
			}
		}
		rooms[r.TableID] = r
	}
	seen := map[int64]bool{}
	for _, r := range c.Keys {
		if r.ItemID <= 0 || seen[r.ItemID] || len(r.Templates) == 0 || types[r.MainType].MainType == 0 {
			return errDormInput
		}
		seen[r.ItemID] = true
		for _, id := range r.Templates {
			if rooms[id].MainType != r.MainType {
				return errDormInput
			}
		}
	}
	if len(c.ExchangeKeys) != 14 {
		return errDormInput
	}
	exchangeSeen := map[int64]bool{}
	for _, r := range c.ExchangeKeys {
		if !seen[r.ItemID] || exchangeSeen[r.ItemID] || (r.CementPerKey != 25 && r.CementPerKey != 50) {
			return errDormInput
		}
		exchangeSeen[r.ItemID] = true
	}
	for i, r := range c.Expansions {
		if r.Level != int64(i+1) || r.Area <= 0 || r.Comfort <= 0 || r.DurationSeconds <= 0 || len(r.CostItems) != len(r.CostCounts) || len(r.CostItems) == 0 {
			return errDormInput
		}
		for j, id := range r.CostItems {
			if id <= 0 || r.CostCounts[j] <= 0 {
				return errDormInput
			}
		}
	}
	for _, r := range c.EquipmentItems {
		if r.ItemID <= 0 || items[r.ItemID] || r.RequiredLevel <= 0 {
			return errDormInput
		}
		items[r.ItemID] = true
	}
	seen = map[int64]bool{}
	for _, r := range c.HeroEquipment {
		if r.TemplateID <= 0 || seen[r.TemplateID] {
			return errDormInput
		}
		seen[r.TemplateID] = true
		for _, i := range r.Items {
			if !items[i] {
				return errDormInput
			}
		}
	}
	return nil
}
