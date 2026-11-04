package builtin

import (
	"bytes"
	"encoding/json"
	"io"
	"os"
	"testing"

	"gxb.local/backend/v2/internal/content/combatcorpus"
)

func workshopScratchCatalog(t *testing.T) WorkshopInputCatalog {
	t.Helper()
	path := os.Getenv("GXB_I9_10A_SCRATCH_JSON")
	if path == "" {
		t.Skip("compiler scratch payload not supplied")
	}
	raw, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.DisallowUnknownFields()
	var catalog WorkshopInputCatalog
	if err := decoder.Decode(&catalog); err != nil {
		t.Fatalf("strict decode: %v", err)
	}
	if err := decoder.Decode(&struct{}{}); err != io.EOF {
		t.Fatalf("scratch payload has trailing content: %v", err)
	}
	return catalog
}

func TestWorkshopInputCatalogScratchQualification(t *testing.T) {
	catalog := workshopScratchCatalog(t)
	if err := catalog.Validate(); err != nil {
		t.Fatal(err)
	}
	if len(catalog.Desk) != 8 || len(catalog.Recycle) != 6 || len(catalog.Board) != 5 || len(catalog.Missions) != 273 || len(catalog.HeroProfiles) != 91 || len(catalog.Awards) != 29 || len(catalog.ItemRecipes) != 268 {
		t.Fatalf("unexpected workshop source counts: desk %d recycle %d board %d missions %d heroes %d awards %d recipes %d",
			len(catalog.Desk), len(catalog.Recycle), len(catalog.Board), len(catalog.Missions), len(catalog.HeroProfiles), len(catalog.Awards), len(catalog.ItemRecipes))
	}
	desk := catalog.Desk[7]
	if desk.Level != 8 || desk.CutMaketime != 25200 || len(desk.CraftableItemIDs) != 8 || desk.CraftableItemIDs[0] != 20001296 {
		t.Fatalf("desk level 8 mismatch: %+v", desk)
	}
	recycle := catalog.Recycle[2]
	if recycle.Level != 3 || recycle.EnergyLimit != 1000 || recycle.CutCostEnergy != "0.04" || recycle.CritUp != "0.1" || len(recycle.RecountItemIDs) != 45 {
		t.Fatalf("recycle level 3 mismatch: %+v", recycle)
	}
	board := catalog.Board[4]
	if board.Level != 5 || board.TaskLimit != 11 || board.GoldTask != 2 {
		t.Fatalf("notice board level 5 mismatch: %+v", board)
	}
	mission := catalog.Missions[0]
	if mission.ID != 10001 || mission.HeroName != "Aquaris" || mission.HeroID != 10001001 || mission.FightID != 9600101 || mission.Fighting != 2000 || mission.Duration != 21600 || mission.Deposit != 50000 {
		t.Fatalf("mission 10001 mismatch: %+v", mission)
	}
	if len(mission.EnemyIDs) != 5 || mission.EnemyIDs[0] != 80000080 || mission.MonsterStars[0] != 2 || mission.MonsterQualities[0] != 9 || mission.MonsterLevels[0] != 90 {
		t.Fatalf("mission 10001 enemy display mismatch: %+v", mission)
	}
	recipe := catalog.ItemRecipes[0]
	foundRecipe := false
	for _, candidate := range catalog.ItemRecipes {
		if candidate.ItemID == 20001222 {
			recipe = candidate
			foundRecipe = true
			break
		}
	}
	if !foundRecipe {
		t.Fatal("item recipe 20001222 missing")
	}
	if recipe.MakeTime != 468000 || recipe.ResolveEnergy != 1837 || len(recipe.MakeResourceIDs) != 3 || len(recipe.ResolveQuantities) != 3 {
		t.Fatalf("item recipe 20001222 mismatch: %+v", recipe)
	}
	if recipe.MakeResourceIDs[0] != 11 || recipe.MakeQuantities[0] != 14000 || recipe.ResolveResourceIDs[2] != 13 || recipe.ResolveQuantities[2] != 66 {
		t.Fatalf("item recipe 20001222 vectors mismatch: %+v", recipe)
	}
	if catalog.Misc.SaturationInit != 10000 || catalog.Misc.SaturationTimeSeconds != 15 || catalog.Misc.AccelerateItemID != 50005024 || catalog.Misc.AccelerateTimeSeconds != 300 || catalog.Misc.PetColorAccelerateTimeSeconds != 1800 || len(catalog.Misc.PetCostItemIDs) != 2 || catalog.Misc.PetCostItemIDs[0] != 50001086 || catalog.Misc.PetCostItemIDs[1] != 50001094 {
		t.Fatalf("workshop misc mismatch: %+v", catalog.Misc)
	}
	corpus, err := combatcorpus.Load()
	if err != nil {
		t.Fatal(err)
	}
	for _, rule := range catalog.Missions {
		if _, _, err := corpus.BattleLineup(rule.FightID); err != nil {
			t.Errorf("mission %d fight %d is not in the combat corpus: %v", rule.ID, rule.FightID, err)
		}
	}
}

func TestWorkshopInputCatalogRejectsMalformedScratch(t *testing.T) {
	base := workshopScratchCatalog(t)
	tests := []struct {
		name   string
		mutate func(*WorkshopInputCatalog)
	}{
		{"unknown schema", func(c *WorkshopInputCatalog) { c.SchemaVersion = 2 }},
		{"empty desk item list", func(c *WorkshopInputCatalog) {
			c.Desk = append([]WorkshopDeskRule(nil), c.Desk...)
			c.Desk[0].CraftableItemIDs = nil
		}},
		{"duplicate recycle item", func(c *WorkshopInputCatalog) {
			c.Recycle = append([]WorkshopRecycleRule(nil), c.Recycle...)
			c.Recycle[0].RecountItemIDs = append([]int64(nil), c.Recycle[0].RecountItemIDs...)
			c.Recycle[0].RecountItemIDs[1] = c.Recycle[0].RecountItemIDs[0]
		}},
		{"malformed recycle decimal", func(c *WorkshopInputCatalog) {
			c.Recycle = append([]WorkshopRecycleRule(nil), c.Recycle...)
			c.Recycle[1].CutCostEnergy = "0.0.4"
		}},
		{"zero board task limit", func(c *WorkshopInputCatalog) {
			c.Board = append([]WorkshopBoardRule(nil), c.Board...)
			c.Board[0].TaskLimit = 0
		}},
		{"duplicate mission id", func(c *WorkshopInputCatalog) {
			c.Missions = append([]WorkshopMissionRule(nil), c.Missions...)
			c.Missions[1].ID = c.Missions[0].ID
		}},
		{"unaligned enemy display", func(c *WorkshopInputCatalog) {
			c.Missions = append([]WorkshopMissionRule(nil), c.Missions...)
			c.Missions[0].MonsterStars = c.Missions[0].MonsterStars[:2]
		}},
		{"negative mission duration", func(c *WorkshopInputCatalog) {
			c.Missions = append([]WorkshopMissionRule(nil), c.Missions...)
			c.Missions[0].Duration = -1
		}},
		{"duplicate hero profile", func(c *WorkshopInputCatalog) {
			c.HeroProfiles = append([]WorkshopHeroProfileRule(nil), c.HeroProfiles...)
			c.HeroProfiles[1].HeroID = c.HeroProfiles[0].HeroID
		}},
		{"hero profile short thresholds", func(c *WorkshopInputCatalog) {
			c.HeroProfiles = append([]WorkshopHeroProfileRule(nil), c.HeroProfiles...)
			c.HeroProfiles[0].ForceThresholds = c.HeroProfiles[0].ForceThresholds[:2]
		}},
		{"mission claimed by two heroes", func(c *WorkshopInputCatalog) {
			c.HeroProfiles = append([]WorkshopHeroProfileRule(nil), c.HeroProfiles...)
			c.HeroProfiles[1].MissionIDs = append([]int64(nil), c.HeroProfiles[1].MissionIDs...)
			c.HeroProfiles[1].MissionIDs[0] = c.HeroProfiles[0].MissionIDs[0]
		}},
		{"duplicate award id", func(c *WorkshopInputCatalog) {
			c.Awards = append([]WorkshopAwardRule(nil), c.Awards...)
			c.Awards[1].ID = c.Awards[0].ID
		}},
		{"unaligned award materials", func(c *WorkshopInputCatalog) {
			c.Awards = append([]WorkshopAwardRule(nil), c.Awards...)
			c.Awards[0].MaterialAmounts = c.Awards[0].MaterialAmounts[:1]
		}},
		{"unaligned recipe vectors", func(c *WorkshopInputCatalog) {
			c.ItemRecipes = append([]WorkshopItemRecipeRule(nil), c.ItemRecipes...)
			for index := range c.ItemRecipes {
				if len(c.ItemRecipes[index].MakeQuantities) > 1 {
					c.ItemRecipes[index].MakeQuantities = c.ItemRecipes[index].MakeQuantities[:1]
					break
				}
			}
		}},
		{"recipe make vector without time", func(c *WorkshopInputCatalog) {
			c.ItemRecipes = append([]WorkshopItemRecipeRule(nil), c.ItemRecipes...)
			for index := range c.ItemRecipes {
				if len(c.ItemRecipes[index].MakeResourceIDs) > 0 {
					c.ItemRecipes[index].MakeTime = 0
					break
				}
			}
		}},
		{"single pet cost item", func(c *WorkshopInputCatalog) {
			c.Misc.PetCostItemIDs = c.Misc.PetCostItemIDs[:1]
		}},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			catalog := base
			test.mutate(&catalog)
			if err := catalog.Validate(); err == nil {
				t.Fatal("malformed workshop input catalog qualified")
			}
		})
	}
}
