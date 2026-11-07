package builtin

import (
	"errors"
	"regexp"
	"strconv"
)

var errWorkshopInput = errors.New("workshop content: unqualified payload")

var workshopExactDecimal = regexp.MustCompile(`^(0|[1-9][0-9]*)(\.[0-9]+)?$`)

var workshopResourceIDs = map[int64]bool{1: true, 11: true, 12: true, 13: true, 14: true}

type WorkshopInputCatalog struct {
	SchemaVersion int                       `json:"schema_version"`
	Desk          []WorkshopDeskRule        `json:"desk"`
	Recycle       []WorkshopRecycleRule     `json:"recycle"`
	Board         []WorkshopBoardRule       `json:"board"`
	Missions      []WorkshopMissionRule     `json:"missions"`
	HeroProfiles  []WorkshopHeroProfileRule `json:"hero_profiles"`
	Awards        []WorkshopAwardRule       `json:"awards"`
	ItemRecipes   []WorkshopItemRecipeRule  `json:"item_recipes"`
	PetCrafting   []WorkshopPetCraftRule    `json:"pet_crafting"`
	Misc          WorkshopMiscRule          `json:"misc"`
}

type WorkshopDeskRule struct {
	Level            int64   `json:"level"`
	CutMaketime      int64   `json:"cut_maketime"`
	CraftableItemIDs []int64 `json:"craftable_item_ids"`
}

type WorkshopRecycleRule struct {
	Level          int64   `json:"level"`
	RecountItemIDs []int64 `json:"recount_item_ids"`
	EnergyLimit    int64   `json:"energy_limit"`
	CutCostEnergy  string  `json:"cut_cost_energy"`
	CritUp         string  `json:"crit_up"`
}

type WorkshopBoardRule struct {
	Level     int64 `json:"level"`
	TaskLimit int64 `json:"task_limit"`
	GoldTask  int64 `json:"gold_task"`
}

type WorkshopMissionRule struct {
	ID               int64   `json:"id"`
	HeroName         string  `json:"hero_name"`
	HeroID           int64   `json:"hero_id"`
	Name             string  `json:"name"`
	EnemyIDs         []int64 `json:"enemy_ids"`
	MonsterStars     []int64 `json:"monster_stars"`
	MonsterQualities []int64 `json:"monster_qualities"`
	MonsterLevels    []int64 `json:"monster_levels"`
	FightID          int64   `json:"fight_id"`
	Fighting         int64   `json:"fighting"`
	Duration         int64   `json:"duration"`
	Deposit          int64   `json:"deposit"`
}

type WorkshopHeroProfileRule struct {
	HeroID          int64   `json:"hero_id"`
	PartnerName     string  `json:"partner_name"`
	MissionIDs      []int64 `json:"mission_ids"`
	ForceThresholds []int64 `json:"force_thresholds"`
}

type WorkshopAwardRule struct {
	ID              int64   `json:"id"`
	Grade           int64   `json:"grade"`
	ItemID          int64   `json:"item_id"`
	ItemCount       int64   `json:"item_count"`
	MaterialIDs     []int64 `json:"material_ids"`
	MaterialAmounts []int64 `json:"material_amounts"`
	Gold            int64   `json:"gold"`
}

type WorkshopItemRecipeRule struct {
	ItemID             int64   `json:"item_id"`
	MakeResourceIDs    []int64 `json:"make_resource_ids"`
	MakeQuantities     []int64 `json:"make_quantities"`
	MakeTime           int64   `json:"make_time"`
	ResolveResourceIDs []int64 `json:"resolve_resource_ids"`
	ResolveQuantities  []int64 `json:"resolve_quantities"`
	ResolveEnergy      int64   `json:"resolve_energy"`
}

type WorkshopPetCraftRule struct {
	TableID int64     `json:"table_id"`
	Levels  [][]int64 `json:"levels"`
}

type WorkshopMiscRule struct {
	CritParam                     string  `json:"event_centre_crit_param"`
	CritProportion                string  `json:"event_centre_crit_proportion"`
	SaturationInit                int64   `json:"event_centre_saturation_init"`
	SaturationTimeSeconds         int64   `json:"event_centre_saturation_time"`
	AccelerateItemID              int64   `json:"event_centre_accelerate_item"`
	AccelerateTimeSeconds         int64   `json:"event_centre_accelerate_time"`
	PetCostItemIDs                []int64 `json:"event_centre_pet_cost_item"`
	PetColorAccelerateTimeSeconds int64   `json:"event_centre_pet_color_accelerate_time"`
}

func (c WorkshopInputCatalog) Validate() error {
	if c.SchemaVersion != 1 || len(c.Desk) != 8 || len(c.Recycle) != 6 || len(c.Board) != 5 || len(c.Missions) != 273 || len(c.HeroProfiles) != 91 || len(c.Awards) != 29 || len(c.ItemRecipes) != 268 || len(c.PetCrafting) != 54 || c.Misc.Validate() != nil {
		return errWorkshopInput
	}
	if c.validateDesk() != nil || c.validateRecycle() != nil || c.validateBoard() != nil || c.validateMissions() != nil || c.validateHeroProfiles() != nil || c.validateAwards() != nil || c.validateItemRecipes() != nil || c.validatePetCrafting() != nil {
		return errWorkshopInput
	}
	return nil
}

func (c WorkshopInputCatalog) validateDesk() error {
	expectedItemCounts := []int{10, 9, 9, 8, 9, 5, 9, 8}
	seen := map[int64]bool{}
	for index, rule := range c.Desk {
		if rule.Level != int64(index+1) || rule.CutMaketime < 0 || len(rule.CraftableItemIDs) != expectedItemCounts[index] {
			return errWorkshopInput
		}
		for _, identifier := range rule.CraftableItemIDs {
			if identifier <= 0 || seen[identifier] {
				return errWorkshopInput
			}
			seen[identifier] = true
		}
	}
	return nil
}

func (c WorkshopInputCatalog) validateRecycle() error {
	expectedItemCounts := []int{45, 47, 45, 44, 45, 15}
	seen := map[int64]bool{}
	for index, rule := range c.Recycle {
		if rule.Level != int64(index+1) || rule.EnergyLimit < 0 || len(rule.RecountItemIDs) != expectedItemCounts[index] || !workshopExactDecimal.MatchString(rule.CutCostEnergy) || !workshopExactDecimal.MatchString(rule.CritUp) {
			return errWorkshopInput
		}
		for _, identifier := range rule.RecountItemIDs {
			if identifier <= 0 || seen[identifier] {
				return errWorkshopInput
			}
			seen[identifier] = true
		}
	}
	return nil
}

func (c WorkshopInputCatalog) validateBoard() error {
	expectedTaskLimits := []int64{6, 7, 8, 9, 11}
	expectedGoldTasks := []int64{0, 0, 0, 0, 2}
	for index, rule := range c.Board {
		if rule.Level != int64(index+1) || rule.TaskLimit != expectedTaskLimits[index] || rule.GoldTask != expectedGoldTasks[index] {
			return errWorkshopInput
		}
	}
	return nil
}

func (c WorkshopInputCatalog) validateMissions() error {
	missionIDs := map[int64]bool{}
	fightIDs := map[int64]bool{}
	for _, rule := range c.Missions {
		if rule.ID <= 0 || rule.HeroID <= 0 || rule.FightID <= 0 || rule.HeroName == "" || rule.Name == "" || rule.Fighting < 0 || rule.Duration < 0 || rule.Deposit < 0 || missionIDs[rule.ID] || fightIDs[rule.FightID] {
			return errWorkshopInput
		}
		missionIDs[rule.ID] = true
		fightIDs[rule.FightID] = true
		if len(rule.EnemyIDs) == 0 || len(rule.EnemyIDs) != len(rule.MonsterStars) || len(rule.EnemyIDs) != len(rule.MonsterQualities) || len(rule.EnemyIDs) != len(rule.MonsterLevels) {
			return errWorkshopInput
		}
		for index, identifier := range rule.EnemyIDs {
			if identifier <= 0 || rule.MonsterStars[index] <= 0 || rule.MonsterQualities[index] <= 0 || rule.MonsterLevels[index] <= 0 {
				return errWorkshopInput
			}
		}
	}
	return nil
}

func (c WorkshopInputCatalog) validateHeroProfiles() error {
	missions := map[int64]WorkshopMissionRule{}
	for _, rule := range c.Missions {
		missions[rule.ID] = rule
	}
	heroIDs := map[int64]bool{}
	missionIDs := map[int64]bool{}
	for _, rule := range c.HeroProfiles {
		if rule.HeroID <= 0 || rule.PartnerName == "" || heroIDs[rule.HeroID] || len(rule.MissionIDs) != 3 || len(rule.ForceThresholds) != 3 {
			return errWorkshopInput
		}
		heroIDs[rule.HeroID] = true
		for _, threshold := range rule.ForceThresholds {
			if threshold <= 0 {
				return errWorkshopInput
			}
		}
		for _, missionID := range rule.MissionIDs {
			mission, exists := missions[missionID]
			if !exists || mission.HeroID != rule.HeroID || missionIDs[missionID] {
				return errWorkshopInput
			}
			missionIDs[missionID] = true
		}
	}
	if len(missionIDs) != len(missions) {
		return errWorkshopInput
	}
	return nil
}

func (c WorkshopInputCatalog) validateAwards() error {
	awardIDs := map[int64]bool{}
	gradeCounts := map[int64]int{1: 0, 2: 0, 3: 0}
	for _, rule := range c.Awards {
		if rule.ID <= 0 || awardIDs[rule.ID] || rule.Grade < 1 || rule.Grade > 3 || rule.ItemCount < 0 || rule.Gold < 0 {
			return errWorkshopInput
		}
		awardIDs[rule.ID] = true
		gradeCounts[rule.Grade]++
		if rule.ItemID == 0 && rule.ItemCount != 0 {
			return errWorkshopInput
		}
		if rule.ItemID < 0 || (rule.ItemID > 0 && rule.ItemCount == 0) {
			return errWorkshopInput
		}
		if len(rule.MaterialIDs) != len(rule.MaterialAmounts) {
			return errWorkshopInput
		}
		sentinel := len(rule.MaterialIDs) == 1 && rule.MaterialIDs[0] == 0 && rule.MaterialAmounts[0] == 0
		if sentinel && rule.ItemID == 0 {
			return errWorkshopInput
		}
		if !sentinel {
			if len(rule.MaterialIDs) == 0 {
				if rule.ItemID == 0 {
					return errWorkshopInput
				}
				continue
			}
			for index, identifier := range rule.MaterialIDs {
				if !workshopResourceIDs[identifier] || rule.MaterialAmounts[index] <= 0 {
					return errWorkshopInput
				}
			}
		}
	}
	if gradeCounts[1] != 10 || gradeCounts[2] != 10 || gradeCounts[3] != 9 {
		return errWorkshopInput
	}
	return nil
}

func (c WorkshopInputCatalog) validateItemRecipes() error {
	itemIDs := map[int64]bool{}
	for _, rule := range c.ItemRecipes {
		if rule.ItemID <= 0 || itemIDs[rule.ItemID] || rule.MakeTime < 0 || rule.ResolveEnergy < 0 || len(rule.MakeResourceIDs) != len(rule.MakeQuantities) || len(rule.ResolveResourceIDs) != len(rule.ResolveQuantities) || (len(rule.MakeResourceIDs) == 0) != (rule.MakeTime == 0) || (len(rule.ResolveResourceIDs) == 0) != (rule.ResolveEnergy == 0) {
			return errWorkshopInput
		}
		if len(rule.MakeResourceIDs) == 0 && len(rule.ResolveResourceIDs) == 0 {
			return errWorkshopInput
		}
		itemIDs[rule.ItemID] = true
		for index, identifier := range rule.MakeResourceIDs {
			if identifier <= 0 || rule.MakeQuantities[index] <= 0 {
				return errWorkshopInput
			}
		}
		for index, identifier := range rule.ResolveResourceIDs {
			if identifier <= 0 || rule.ResolveQuantities[index] <= 0 {
				return errWorkshopInput
			}
		}
	}
	for _, rule := range c.Desk {
		for _, identifier := range rule.CraftableItemIDs {
			if !itemIDs[identifier] {
				return errWorkshopInput
			}
		}
	}
	for _, rule := range c.Recycle {
		for _, identifier := range rule.RecountItemIDs {
			if !itemIDs[identifier] {
				return errWorkshopInput
			}
		}
	}
	return nil
}

func (c WorkshopInputCatalog) validatePetCrafting() error {
	recipes := map[int64]WorkshopItemRecipeRule{}
	for _, rule := range c.ItemRecipes {
		recipes[rule.ItemID] = rule
	}
	seen := map[int64]bool{}
	for _, rule := range c.PetCrafting {
		if rule.TableID <= 0 || seen[rule.TableID] || len(rule.Levels) != 5 {
			return errWorkshopInput
		}
		seen[rule.TableID] = true
		for _, level := range rule.Levels {
			if len(level) == 0 {
				return errWorkshopInput
			}
			for _, identifier := range level {
				recipe, exists := recipes[identifier]
				if !exists || identifier <= 0 || len(recipe.MakeResourceIDs) == 0 || recipe.MakeTime <= 0 {
					return errWorkshopInput
				}
			}
		}
	}
	return nil
}

var workshopCritProportion = regexp.MustCompile(`^(1|[1-9][0-9]*)(\.[0-9]+)?$`)

func (m WorkshopMiscRule) Validate() error {
	if !workshopExactDecimal.MatchString(m.CritParam) || !workshopCritProportion.MatchString(m.CritProportion) || m.SaturationInit <= 0 || m.SaturationTimeSeconds <= 0 || m.AccelerateItemID <= 0 || m.AccelerateTimeSeconds <= 0 || m.PetColorAccelerateTimeSeconds < 0 || len(m.PetCostItemIDs) != 2 || m.PetCostItemIDs[0] <= 0 || m.PetCostItemIDs[1] <= 0 || m.PetCostItemIDs[0] == m.PetCostItemIDs[1] {
		return errWorkshopInput
	}
	return nil
}

type AdministratorRule struct {
	Destination int64            `json:"destination"`
	Ordinal     int64            `json:"ordinal"`
	Credit      int64            `json:"credit"`
	Costs       map[string]int64 `json:"costs"`
}

type AdministratorLevelRule struct {
	Level  int64   `json:"level"`
	Unlock []int64 `json:"unlock"`
}

type AdministratorInputCatalog struct {
	SchemaVersion int                      `json:"schema_version"`
	Rules         []AdministratorRule      `json:"rules"`
	LevelUnlocks  []AdministratorLevelRule `json:"level_unlocks"`
}

var administratorDestinations = map[int64]bool{11: true, 12: true, 13: true}

func (c AdministratorInputCatalog) Validate() error {
	if c.SchemaVersion != 1 || len(c.Rules) != 180 || len(c.LevelUnlocks) != 5 {
		return errWorkshopInput
	}
	seenRules := map[[2]int64]bool{}
	for _, rule := range c.Rules {
		key := [2]int64{rule.Destination, rule.Ordinal}
		if !administratorDestinations[rule.Destination] || rule.Ordinal < 1 || rule.Ordinal > 60 || seenRules[key] || rule.Credit <= 0 || len(rule.Costs) != 4 {
			return errWorkshopInput
		}
		seenRules[key] = true
		for currency, amount := range rule.Costs {
			identifier, parseErr := strconv.ParseInt(currency, 10, 64)
			if parseErr != nil || !workshopResourceIDs[identifier] && identifier != 2 || identifier == rule.Destination || amount <= 0 {
				return errWorkshopInput
			}
		}
	}
	for index, level := range c.LevelUnlocks {
		if level.Level != int64(index+1) || len(level.Unlock) == 0 {
			return errWorkshopInput
		}
		seen := map[int64]bool{}
		for _, identifier := range level.Unlock {
			if !workshopResourceIDs[identifier] && identifier != 2 || seen[identifier] {
				return errWorkshopInput
			}
			seen[identifier] = true
		}
	}
	if len(c.LevelUnlocks[4].Unlock) != 5 {
		return errWorkshopInput
	}
	return nil
}
