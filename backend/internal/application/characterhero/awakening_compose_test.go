package characterhero

import (
	"context"
	"errors"
	"testing"

	"gxb.local/backend/v2/internal/domain/character"
)

func awakeningRecipeContent(primitive character.EquipmentPrimitive, edges []character.EquipmentRecipeEdge) equipmentOpContent {
	return equipmentOpContent{
		primitives: map[int64]character.EquipmentPrimitive{int64(primitive.ItemID): primitive},
		edges:      map[int64][]character.EquipmentRecipeEdge{int64(primitive.ItemID): edges},
	}
}

func TestAwakeningComposeRecipeScalesCouponsByItemNum(t *testing.T) {
	s := Service{Equipment: awakeningRecipeContent(
		character.EquipmentPrimitive{ItemID: 50001070, SourceItemType: 4, ComposeMana: 10000},
		[]character.EquipmentRecipeEdge{{ParentItemID: 50001070, Ordinal: 1, ComponentItemID: 60001057, ComponentCount: 60}},
	)}
	cost, err := s.awakeningComposeRecipe(context.Background(), nil, "rev", 50001070, 1)
	if err != nil {
		t.Fatal(err)
	}
	if len(cost.stacks) != 1 || cost.stacks[0].ItemID != 60001057 || cost.stacks[0].Amount != 60 || cost.mana != 10000 {
		t.Fatalf("one Small Skull cost=%+v", cost)
	}
	cost, err = s.awakeningComposeRecipe(context.Background(), nil, "rev", 50001070, 3)
	if err != nil {
		t.Fatal(err)
	}
	if len(cost.stacks) != 1 || cost.stacks[0].Amount != 180 || cost.mana != 30000 {
		t.Fatalf("three Small Skull cost=%+v", cost)
	}
}

func TestAwakeningComposeRecipeSumsRepeatedComponents(t *testing.T) {
	s := Service{Equipment: awakeningRecipeContent(
		character.EquipmentPrimitive{ItemID: 50001070, SourceItemType: 4},
		[]character.EquipmentRecipeEdge{
			{ParentItemID: 50001070, Ordinal: 1, ComponentItemID: 60001057, ComponentCount: 30},
			{ParentItemID: 50001070, Ordinal: 2, ComponentItemID: 60001057, ComponentCount: 30},
		},
	)}
	cost, err := s.awakeningComposeRecipe(context.Background(), nil, "rev", 50001070, 1)
	if err != nil {
		t.Fatal(err)
	}
	if len(cost.stacks) != 1 || cost.stacks[0].Amount != 60 || cost.mana != 0 {
		t.Fatalf("repeated component cost=%+v", cost)
	}
}

func TestAwakeningComposeRecipeRefusesNonAwakeningTargets(t *testing.T) {
	equipmentTarget := Service{Equipment: awakeningRecipeContent(
		character.EquipmentPrimitive{ItemID: 20001361, SourceItemType: 1},
		[]character.EquipmentRecipeEdge{{ParentItemID: 20001361, Ordinal: 1, ComponentItemID: 60001027, ComponentCount: 60}},
	)}
	if _, err := equipmentTarget.awakeningComposeRecipe(context.Background(), nil, "rev", 20001361, 1); !errors.Is(err, ErrAwakeningComposeUnqualified) {
		t.Fatalf("equipment target err=%v", err)
	}
	noRecipe := Service{Equipment: awakeningRecipeContent(
		character.EquipmentPrimitive{ItemID: 60001057, SourceItemType: 5},
		nil,
	)}
	if _, err := noRecipe.awakeningComposeRecipe(context.Background(), nil, "rev", 60001057, 1); !errors.Is(err, ErrAwakeningComposeUnqualified) {
		t.Fatalf("component target err=%v", err)
	}
}
