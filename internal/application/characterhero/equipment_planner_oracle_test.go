package characterhero

import (
	"encoding/json"
	"os"
	"path/filepath"
	"reflect"
	"slices"
	"strconv"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
)

type plannerVectorFile struct {
	Vectors []struct {
		Name  string `json:"name"`
		Input struct {
			TableID      int64            `json:"table_id"`
			Color        int64            `json:"color"`
			Equipped     []int64          `json:"equipped"`
			PlayerLevel  int64            `json:"player_level"`
			HeroLevel    int64            `json:"hero_level"`
			HeroExpTotal int64            `json:"hero_exp_total"`
			Mana         int64            `json:"mana"`
			Inventory    map[string]int64 `json:"inventory"`
		} `json:"input"`
		Expected struct {
			Selected         []int64          `json:"selected"`
			StackDebits      map[string]int64 `json:"stack_debits"`
			ManaDebit        int64            `json:"mana_debit"`
			PotionDebits     map[string]int64 `json:"potion_debits"`
			PotionEXPGranted int64            `json:"potion_exp_granted"`
			MaxEXPShortfall  int64            `json:"max_exp_shortfall"`
		} `json:"expected"`
	} `json:"vectors"`
}

type generatedEquipmentCatalog struct {
	Items []struct {
		ItemID        int64 `json:"item_id"`
		SourceType    int64 `json:"source_item_type"`
		RequiredLevel int64 `json:"required_level"`
		ComposeMana   int64 `json:"compose_mana"`
	} `json:"items"`
	Edges []struct {
		ParentID  int64 `json:"parent_item_id"`
		Ordinal   int64 `json:"ordinal"`
		Component int64 `json:"component_item_id"`
		Count     int64 `json:"component_count"`
	} `json:"recipe_edges"`
}

type generatedHeroEquipmentCatalog struct {
	Positions []struct {
		TableID  int64 `json:"hero_table_id"`
		Color    int64 `json:"color"`
		Slot     int64 `json:"slot"`
		ItemID   int64 `json:"item_id"`
		Ordinary bool  `json:"ordinary_eligible"`
	} `json:"positions"`
}

type generatedHeroCoreCatalog struct {
	ExpRows []struct {
		Level    int64 `json:"level"`
		TotalExp int64 `json:"total_exp"`
	} `json:"exp_rows"`
	ExpItems []struct {
		ItemID int64 `json:"item_id"`
		Value  int64 `json:"exp_value"`
	} `json:"exp_items"`
}

type generatedPlayerProgression struct {
	Rows []struct {
		Level   int64 `json:"lev"`
		HeroCap int64 `json:"hero_lev"`
	} `json:"rows"`
}

func readJSONTest(t *testing.T, path string, out any) {
	t.Helper()
	b, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if err := json.Unmarshal(b, out); err != nil {
		t.Fatal(err)
	}
}

func stringMapToInt64(t *testing.T, in map[string]int64) map[int64]int64 {
	t.Helper()
	out := make(map[int64]int64, len(in))
	for k, v := range in {
		id, err := strconv.ParseInt(k, 10, 64)
		if err != nil {
			t.Fatal(err)
		}
		out[id] = v
	}
	return out
}

func TestOneKeyPlannerMatchesSealedPass536AdversarialVectors(t *testing.T) {
	var vf plannerVectorFile
	readJSONTest(t, filepath.Join("testdata", "ca4_2_planner_adversarial_vectors.json"), &vf)
	base := filepath.Join("..", "..", "content", "builtin", "generated")
	var eq generatedEquipmentCatalog
	var hm generatedHeroEquipmentCatalog
	var hc generatedHeroCoreCatalog
	var pp generatedPlayerProgression
	readJSONTest(t, filepath.Join(base, "equipment_primitives_catalog.json"), &eq)
	readJSONTest(t, filepath.Join(base, "hero_equipment_catalog.json"), &hm)
	readJSONTest(t, filepath.Join(base, "hero_core_catalog.json"), &hc)
	readJSONTest(t, filepath.Join(base, "player_progression.json"), &pp)

	nodes := make(map[int64]heroEquipmentRecipeNode, len(eq.Items))
	for _, x := range eq.Items {
		nodes[x.ItemID] = heroEquipmentRecipeNode{Primitive: character.EquipmentPrimitive{ItemID: character.EquipmentTemplateID(x.ItemID), SourceItemType: x.SourceType, RequiredLevel: x.RequiredLevel, ComposeMana: x.ComposeMana}}
	}
	for _, e := range eq.Edges {
		n := nodes[e.ParentID]
		n.Edges = append(n.Edges, character.EquipmentRecipeEdge{ParentItemID: character.EquipmentTemplateID(e.ParentID), Ordinal: e.Ordinal, ComponentItemID: character.EquipmentTemplateID(e.Component), ComponentCount: e.Count})
		nodes[e.ParentID] = n
	}
	positions := make(map[[3]int64]character.HeroEquipmentPosition, len(hm.Positions))
	for _, x := range hm.Positions {
		positions[[3]int64{x.TableID, x.Color, x.Slot}] = character.HeroEquipmentPosition{HeroTableID: x.TableID, Color: x.Color, Slot: x.Slot, ItemID: character.EquipmentTemplateID(x.ItemID), OrdinaryEligible: x.Ordinary}
	}
	thresholdsAll := make([]character.HeroExpThreshold, len(hc.ExpRows))
	for i, x := range hc.ExpRows {
		thresholdsAll[i] = character.HeroExpThreshold{Level: x.Level, TotalExp: x.TotalExp}
	}
	potionEXP := map[int64]int64{}
	for _, x := range hc.ExpItems {
		potionEXP[x.ItemID] = x.Value
	}
	playerCap := map[int64]int64{}
	for _, x := range pp.Rows {
		playerCap[x.Level] = x.HeroCap
	}

	now := time.Unix(100, 0).UTC()
	for _, v := range vf.Vectors {
		v := v
		t.Run(v.Name, func(t *testing.T) {
			var equips character.HeroEquipmentSlots
			if len(v.Input.Equipped) != character.HeroEquipmentSlotCount {
				t.Fatalf("equipped count=%d", len(v.Input.Equipped))
			}
			copy(equips[:], v.Input.Equipped)
			h := character.Hero{PlayerID: 7, PartnerID: 1, TableID: v.Input.TableID, OriginTableID: v.Input.TableID, Star: 1, Level: v.Input.HeroLevel, Exp: v.Input.HeroExpTotal, Color: v.Input.Color, Equipment: equips, CreationContentRevision: progRev, StateVersion: 1, CreatedAt: now, UpdatedAt: now}
			var pos [character.HeroEquipmentSlotCount]character.HeroEquipmentPosition
			for slot := int64(1); slot <= character.HeroEquipmentSlotCount; slot++ {
				pos[slot-1] = positions[[3]int64{h.TableID, h.Color, slot}]
			}
			cap := playerCap[v.Input.PlayerLevel]
			if cap <= 0 || int(cap) > len(thresholdsAll) {
				t.Fatalf("player cap=%d", cap)
			}
			inv := stringMapToInt64(t, v.Input.Inventory)
			got, err := planOneKeyEquipment(h, pos, nodes, heroEquipmentPlanningSnapshot{PlayerLevel: v.Input.PlayerLevel, Mana: v.Input.Mana, Stacks: inv}, cap, thresholdsAll[:cap], potionEXP)
			if err != nil {
				t.Fatal(err)
			}
			if !slices.Equal(got.Selected, v.Expected.Selected) {
				t.Fatalf("selected=%v want=%v", got.Selected, v.Expected.Selected)
			}
			if !reflect.DeepEqual(got.StackDebits, stringMapToInt64(t, v.Expected.StackDebits)) {
				t.Fatalf("stack debits=%v want=%v", got.StackDebits, v.Expected.StackDebits)
			}
			if !reflect.DeepEqual(got.PotionDebits, stringMapToInt64(t, v.Expected.PotionDebits)) {
				t.Fatalf("potion debits=%v want=%v", got.PotionDebits, v.Expected.PotionDebits)
			}
			if got.ManaDebit != v.Expected.ManaDebit || got.PotionEXPGranted != v.Expected.PotionEXPGranted || got.MaxEXPShortfall != v.Expected.MaxEXPShortfall {
				t.Fatalf("plan mana/exp=%+v want mana=%d potion_exp=%d shortfall=%d", got, v.Expected.ManaDebit, v.Expected.PotionEXPGranted, v.Expected.MaxEXPShortfall)
			}
		})
	}
}
