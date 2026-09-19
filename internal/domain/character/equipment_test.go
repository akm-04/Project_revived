package character

import "testing"

func TestEquipmentRecipeEdgeRequiresOneBasedPositiveOrdinal(t *testing.T) {
	base := EquipmentRecipeEdge{ParentItemID: 20001014, ComponentItemID: 50001003, ComponentCount: 1}
	if err := base.Validate(); err == nil {
		t.Fatal("ordinal zero accepted")
	}
	base.Ordinal = 1
	if err := base.Validate(); err != nil {
		t.Fatalf("ordinal one rejected: %v", err)
	}
}

func TestHeroEquipmentSlotsNormalVsFutureSuperRange(t *testing.T) {
	future := HeroEquipmentSlots{0, 1, 2, 0, 9, 0}
	if err := future.Validate(); err != nil {
		t.Fatalf("nonnegative future Super state rejected: %v", err)
	}
	if err := future.ValidateNormal(); err == nil {
		t.Fatal("Normal-Hero validation accepted enhancement values")
	}
	ordinary := HeroEquipmentSlots{1, 0, 1, 1, 0, 0}
	if err := ordinary.ValidateNormal(); err != nil {
		t.Fatal(err)
	}
	bad := HeroEquipmentSlots{-1, 0, 0, 0, 0, 0}
	if err := bad.Validate(); err == nil {
		t.Fatal("negative slot accepted")
	}
}

func TestHeroFumoSlotsAndPolicies(t *testing.T) {
	if err := (HeroFumoSlots{0, 1, 2, 3, 4, 5}).Validate(); err != nil {
		t.Fatal(err)
	}
	if err := (HeroFumoSlots{0, -1}).Validate(); err == nil {
		t.Fatal("negative Fumo accepted")
	}
	target := HeroFumoTarget{ItemID: 20001016, ThresholdIncrements: []int64{20}, TotalCap: 20, ManaPerFumo: 120, StageDeltaByAttr: []map[int64]string{{1: "6"}}}
	if err := target.Validate(); err != nil {
		t.Fatal(err)
	}
	target.TotalCap = 21
	if err := target.Validate(); err == nil {
		t.Fatal("cap mismatch accepted")
	}
	for _, typ := range []int64{1, 2, 4, 5, 6} {
		if err := (HeroFumoMaterial{ItemID: 1, ItemType: typ, Moneng: 1}).Validate(); err != nil {
			t.Fatalf("type %d: %v", typ, err)
		}
	}
	if err := (HeroFumoMaterial{ItemID: 1, ItemType: 8, Moneng: 1}).Validate(); err == nil {
		t.Fatal("Pet equipment material accepted")
	}
}

func TestPetEquipmentSlotsAreBinary(t *testing.T) {
	if err := (PetEquipmentSlots{1, 0, 1}).Validate(); err != nil {
		t.Fatal(err)
	}
	for _, bad := range []PetEquipmentSlots{{-1, 0, 0}, {0, 2, 0}} {
		if err := bad.Validate(); err == nil {
			t.Fatalf("bad Pet equipment accepted: %#v", bad)
		}
	}
	if v, err := (PetEquipmentSlots{1, 0, 1}).Value(3); err != nil || v != 1 {
		t.Fatalf("value=%d err=%v", v, err)
	}
}
