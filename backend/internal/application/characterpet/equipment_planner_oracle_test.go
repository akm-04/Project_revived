package characterpet

import (
	"encoding/json"
	"os"
	"path/filepath"
	"reflect"
	"slices"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
)

type petEqGeneratedPrimitives struct {
	Items []struct {
		ItemID, SourceType, RequiredLevel, ComposeMana int64
	} `json:"-"`
	RawItems []map[string]any `json:"items"`
	Edges    []struct {
		ParentID  int64 `json:"parent_item_id"`
		Ordinal   int64 `json:"ordinal"`
		Component int64 `json:"component_item_id"`
		Count     int64 `json:"component_count"`
	} `json:"recipe_edges"`
}

type petEqPrimitiveFile struct {
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

type petEqPositionFile struct {
	Positions []struct {
		TableID        int64  `json:"pet_table_id"`
		Color          int64  `json:"color"`
		Slot           int64  `json:"slot"`
		ItemID         int64  `json:"item_id"`
		Classification string `json:"classification"`
	} `json:"positions"`
}

type petEqHeroCoreFile struct {
	ExpRows []struct {
		Level    int64 `json:"level"`
		TotalExp int64 `json:"total_exp"`
	} `json:"exp_rows"`
}
type petEqProgressionFile struct {
	ExpRows []struct {
		Level    int64 `json:"level"`
		TotalExp int64 `json:"total_exp"`
	} `json:"exp_rows"`
	ExpItems []struct {
		ItemID int64 `json:"item_id"`
		Value  int64 `json:"exp_value"`
	} `json:"exp_items"`
}

func petEqReadJSON(t *testing.T, name string, out any) {
	t.Helper()
	b, err := os.ReadFile(filepath.Join("..", "..", "content", "builtin", "generated", name))
	if err != nil {
		t.Fatal(err)
	}
	if err := json.Unmarshal(b, out); err != nil {
		t.Fatal(err)
	}
}

func petEqOracle(t *testing.T) (map[int64]petEquipmentRecipeNode, map[[3]int64]character.PetEquipmentPosition, []character.EquipmentCompatibilityExpThreshold, []ExpThreshold, map[int64]int64) {
	t.Helper()
	var pf petEqPrimitiveFile
	var posf petEqPositionFile
	var hc petEqHeroCoreFile
	var pp petEqProgressionFile
	petEqReadJSON(t, "equipment_primitives_catalog.json", &pf)
	petEqReadJSON(t, "pet_equipment_catalog.json", &posf)
	petEqReadJSON(t, "hero_core_catalog.json", &hc)
	petEqReadJSON(t, "pet_progression_catalog.json", &pp)
	nodes := map[int64]petEquipmentRecipeNode{}
	for _, x := range pf.Items {
		nodes[x.ItemID] = petEquipmentRecipeNode{Primitive: character.EquipmentPrimitive{ItemID: character.EquipmentTemplateID(x.ItemID), SourceItemType: x.SourceType, RequiredLevel: x.RequiredLevel, ComposeMana: x.ComposeMana}}
	}
	for _, e := range pf.Edges {
		n := nodes[e.ParentID]
		n.Edges = append(n.Edges, character.EquipmentRecipeEdge{ParentItemID: character.EquipmentTemplateID(e.ParentID), Ordinal: e.Ordinal, ComponentItemID: character.EquipmentTemplateID(e.Component), ComponentCount: e.Count})
		nodes[e.ParentID] = n
	}
	positions := map[[3]int64]character.PetEquipmentPosition{}
	for _, x := range posf.Positions {
		positions[[3]int64{x.TableID, x.Color, x.Slot}] = character.PetEquipmentPosition{PetTableID: x.TableID, Color: x.Color, Slot: x.Slot, ItemID: character.EquipmentTemplateID(x.ItemID), Classification: character.PetEquipmentClassification(x.Classification)}
	}
	compat := make([]character.EquipmentCompatibilityExpThreshold, len(hc.ExpRows))
	for i, x := range hc.ExpRows {
		compat[i] = character.EquipmentCompatibilityExpThreshold{Level: x.Level, TotalExp: x.TotalExp}
	}
	real := make([]ExpThreshold, len(pp.ExpRows))
	for i, x := range pp.ExpRows {
		real[i] = ExpThreshold{Level: x.Level, TotalExp: x.TotalExp}
	}
	potions := map[int64]int64{}
	for _, x := range pp.ExpItems {
		potions[x.ItemID] = x.Value
	}
	return nodes, positions, compat, real, potions
}

func petEqLeafRequirements(item int64, nodes map[int64]petEquipmentRecipeNode, out map[int64]int64) {
	n := nodes[item]
	if len(n.Edges) == 0 {
		out[item]++
		return
	}
	for _, e := range n.Edges {
		for i := int64(0); i < e.ComponentCount; i++ {
			petEqLeafRequirements(int64(e.ComponentItemID), nodes, out)
		}
	}
}

func petEqRick(t *testing.T, equipped character.PetEquipmentSlots, level, exp int64) (character.Pet, [character.PetEquipmentSlotCount]character.PetEquipmentPosition, map[int64]petEquipmentRecipeNode, []character.EquipmentCompatibilityExpThreshold, []ExpThreshold, map[int64]int64) {
	t.Helper()
	nodes, posMap, compat, real, potions := petEqOracle(t)
	var pos [character.PetEquipmentSlotCount]character.PetEquipmentPosition
	for slot := int64(1); slot <= 3; slot++ {
		pos[slot-1] = posMap[[3]int64{10010001, 16, slot}]
	}
	now := time.Unix(100, 0).UTC()
	p := character.Pet{PlayerID: identity.PlayerID(7), PetID: 1, TableID: 10010001, OriginTableID: 10010001, Star: 1, Level: level, Exp: exp, Color: 16, Equipment: equipped, Skills: character.DefaultPetSkillLevels(), Birthday: 1, IsShow: true, CreationContentRevision: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", StateVersion: 1, CreatedAt: now, UpdatedAt: now}
	return p, pos, nodes, compat, real, potions
}

func TestPetOneKeyRickSharedReservationAndExactManaOracles(t *testing.T) {
	p, pos, nodes, compat, _, potions := petEqRick(t, character.PetEquipmentSlots{}, 100, 0)
	r79 := map[int64]int64{}
	r82 := map[int64]int64{}
	petEqLeafRequirements(80001079, nodes, r79)
	petEqLeafRequirements(80001082, nodes, r82)
	maxInv := map[int64]int64{}
	sumInv := map[int64]int64{}
	for id, n := range r79 {
		maxInv[id] = n
		sumInv[id] += n
	}
	for id, n := range r82 {
		if n > maxInv[id] {
			maxInv[id] = n
		}
		sumInv[id] += n
	}
	plan, err := planPetOneKeyEquipment(p, pos, nodes, petEquipmentPlanningSnapshot{PlayerLevel: 100, Mana: 1_000_000, Stacks: maxInv}, 100, compat, potions)
	if err != nil {
		t.Fatal(err)
	}
	if !slices.Equal(plan.Selected, []int64{2}) || plan.ManaDebit != 177000 {
		t.Fatalf("shared-shortage plan=%+v", plan)
	}
	sumInv[80001056] = 1
	plan, err = planPetOneKeyEquipment(p, pos, nodes, petEquipmentPlanningSnapshot{PlayerLevel: 100, Mana: 441000, Stacks: sumInv}, 100, compat, potions)
	if err != nil {
		t.Fatal(err)
	}
	if !slices.Equal(plan.Selected, []int64{2, 3}) || plan.ManaDebit != 441000 {
		t.Fatalf("exact-mana plan=%+v", plan)
	}
	plan, err = planPetOneKeyEquipment(p, pos, nodes, petEquipmentPlanningSnapshot{PlayerLevel: 100, Mana: 440999, Stacks: sumInv}, 100, compat, potions)
	if err != nil {
		t.Fatal(err)
	}
	if !slices.Equal(plan.Selected, []int64{2}) || plan.ManaDebit != 162000 {
		t.Fatalf("below-exact plan=%+v", plan)
	}
}

func TestPetOneKeyRejectedReservationDoesNotLeakToLaterSlot(t *testing.T) {
	p, pos, nodes, compat, _, potions := petEqRick(t, character.PetEquipmentSlots{}, 100, 0)
	inv := map[int64]int64{80001082: 1}
	plan, err := planPetOneKeyEquipment(p, pos, nodes, petEquipmentPlanningSnapshot{PlayerLevel: 100, Mana: 0, Stacks: inv}, 100, compat, potions)
	if err != nil {
		t.Fatal(err)
	}
	if !slices.Equal(plan.Selected, []int64{3}) || !reflect.DeepEqual(plan.StackDebits, map[int64]int64{80001082: 1}) {
		t.Fatalf("plan=%+v", plan)
	}
}

func TestPetOneKeyPartnerExpCompatibilityQuirkAppliesRealPetProgression(t *testing.T) {
	_, _, _, real, _ := petEqOracle(t)
	// Source Pet level-95 floor is real petExp totalExp(level-1).
	floor95 := real[93].TotalExp
	p, pos, nodes, compat, real, potions := petEqRick(t, character.PetEquipmentSlots{1, 1, 0}, 95, floor95)
	inv := map[int64]int64{80001082: 1, 50001089: 28}
	plan, err := planPetOneKeyEquipment(p, pos, nodes, petEquipmentPlanningSnapshot{PlayerLevel: 100, Mana: 0, Stacks: inv}, 100, compat, potions)
	if err != nil {
		t.Fatal(err)
	}
	if !slices.Equal(plan.Selected, []int64{3}) || plan.MaxEXPShortfall != 209000 || plan.PotionDebits[50001089] != 28 || plan.PotionEXPGranted != 210000 {
		t.Fatalf("compat plan=%+v floor95=%d", plan, floor95)
	}
	next, err := applyPetEquipmentPlan(p, plan, 100, real, operation.Context{StartedAt: time.Unix(101, 0).UTC()})
	if err != nil {
		t.Fatal(err)
	}
	if next.Level != 97 || next.Equipment[2] != 1 {
		t.Fatalf("real progression next=%+v", next)
	}
}

func TestPetOneKeyNoWorkAndZeroPotionDebit(t *testing.T) {
	p, pos, nodes, compat, _, potions := petEqRick(t, character.PetEquipmentSlots{1, 1, 1}, 100, 0)
	plan, err := planPetOneKeyEquipment(p, pos, nodes, petEquipmentPlanningSnapshot{PlayerLevel: 100, Mana: 0, Stacks: map[int64]int64{}}, 100, compat, potions)
	if err != nil {
		t.Fatal(err)
	}
	if !plan.noWork() || len(plan.StackDebits) != 0 || len(plan.PotionDebits) != 0 {
		t.Fatalf("no-work plan=%+v", plan)
	}
	p2, _, _, _, _, _ := petEqRick(t, character.PetEquipmentSlots{1, 0, 1}, 100, 0)
	plan, err = planPetOneKeyEquipment(p2, pos, nodes, petEquipmentPlanningSnapshot{PlayerLevel: 100, Mana: 0, Stacks: map[int64]int64{80001079: 1}}, 100, compat, potions)
	if err != nil {
		t.Fatal(err)
	}
	if len(plan.PotionDebits) != 0 || plan.PotionEXPGranted != 0 {
		t.Fatalf("zero-shortfall potions=%+v", plan)
	}
}
