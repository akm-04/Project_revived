package dormhouse

import (
	"errors"
	"testing"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	dorm "gxb.local/backend/v2/internal/domain/dormhouse"
)

func furnitureComposeCatalog() dorm.Catalog {
	return dorm.Catalog{
		FurnitureRecipes: map[int64]dorm.FurnitureRecipe{
			50031013: {ItemID: 50031013, Materials: []int64{50010002, 50010001}, Counts: []int64{24, 30}, Glue: 54, BlueprintItem: 50020013},
		},
		BlueprintRecipes: map[int64]dorm.BlueprintRecipe{
			50020013: {ItemID: 50020013, Pieces: []int64{50021013}, Counts: []int64{50}, Level: 100},
		},
	}
}

func TestFurnitureComposeCostScalesWithAmount(t *testing.T) {
	cost, err := planFurnitureCompose(furnitureComposeCatalog(), 50031013, 2, 100, 1)
	if err != nil {
		t.Fatal(err)
	}
	if len(cost.Stacks) != 2 || cost.Stacks[0] != (appi5.StackMaterialCost{ItemID: 50010002, Amount: 48}) || cost.Stacks[1].ItemID != 50010001 || cost.Stacks[1].Amount != 60 {
		t.Fatalf("stacks = %+v", cost.Stacks)
	}
	if len(cost.Scalars) != 1 || cost.Scalars[0].ResourceKey != "glue" || cost.Scalars[0].Amount != 108 {
		t.Fatalf("glue = %+v", cost.Scalars)
	}
	for _, stack := range cost.Stacks {
		if stack.ItemID == 50020013 {
			t.Fatal("blueprint was debited by the furniture cost")
		}
	}
}

func TestBlueprintComposeCostUsesPiecesWithoutGlue(t *testing.T) {
	cost, err := planFurnitureCompose(furnitureComposeCatalog(), 50020013, 3, 100, 0)
	if err != nil {
		t.Fatal(err)
	}
	if len(cost.Stacks) != 1 || cost.Stacks[0].ItemID != 50021013 || cost.Stacks[0].Amount != 150 {
		t.Fatalf("pieces = %+v", cost.Stacks)
	}
	if len(cost.Scalars) != 0 {
		t.Fatalf("blueprint compose charged glue: %+v", cost.Scalars)
	}
}

func TestFurnitureComposeRefusesLowLevel(t *testing.T) {
	if _, err := planFurnitureCompose(furnitureComposeCatalog(), 50031013, 1, 99, 1); !errors.Is(err, ErrFurnitureLevelTooLow) {
		t.Fatalf("err = %v", err)
	}
	if _, err := planFurnitureCompose(furnitureComposeCatalog(), 50020013, 1, 99, 0); !errors.Is(err, ErrFurnitureLevelTooLow) {
		t.Fatalf("blueprint err = %v", err)
	}
}

func TestFurnitureComposeRefusesMissingBlueprint(t *testing.T) {
	if _, err := planFurnitureCompose(furnitureComposeCatalog(), 50031013, 1, 100, 0); !errors.Is(err, ErrFurnitureBlueprintNotOwned) {
		t.Fatalf("err = %v", err)
	}
}

func TestFurnitureComposeRefusesUnknownRecipe(t *testing.T) {
	if _, err := planFurnitureCompose(furnitureComposeCatalog(), 999999, 1, 100, 1); !errors.Is(err, ErrFurnitureComposeUnqualified) {
		t.Fatalf("err = %v", err)
	}
	if _, err := planFurnitureCompose(furnitureComposeCatalog(), 50031013, 0, 100, 1); !errors.Is(err, ErrFurnitureComposeUnqualified) {
		t.Fatalf("zero amount err = %v", err)
	}
}
