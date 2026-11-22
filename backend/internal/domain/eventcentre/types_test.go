package eventcentre

import (
	"math/big"
	"testing"
	"time"
)

func testCatalog() Catalog {
	return Catalog{
		Desk:        map[int64]DeskRule{1: {Level: 1, CutMaketime: 3600, Craftable: []int64{500}}, 2: {Level: 2, CutMaketime: 7200, Craftable: []int64{501}}},
		Recycle:     map[int64]RecycleRule{1: {Level: 1, EnergyLimit: 1000, CutCostEnergy: big.NewRat(4, 100), CritUp: new(big.Rat), Recount: []int64{100}}},
		Admin:       map[[2]int64]AdminRule{},
		AdminLevels: map[int64][]int64{1: {2}},
		Recipes: map[int64]Recipe{
			100: {ItemID: 100, ResolveEnergy: 10, Resolve: []ResourceAmount{{ID: 11, Amount: 5}, {ID: 12, Amount: 7}}},
			500: {ItemID: 500, MakeTime: 108000, Make: []ResourceAmount{{ID: 13, Amount: 53}}},
			501: {ItemID: 501, MakeTime: 10000, Make: []ResourceAmount{{ID: 13, Amount: 1}}},
		},
		PetCrafting: map[int64][][]int64{7: {{900}, {901}, {902}, {903}, {904}}},
		Misc:        Misc{SaturationInit: 10000, SaturationSeconds: 15, AccelerateItemID: 50005024, AccelerateSeconds: 300, PetColorAccelerateSeconds: 1800, CritParam: big.NewRat(1, 10), CritMultiplier: 2},
	}
}

func TestRecycleEnergyCostAndAwards(t *testing.T) {
	catalog := testCatalog()
	cost, err := catalog.RecycleEnergyCost(1, 100, 3)
	if err != nil || cost != 30 {
		t.Fatalf("energy cost = %d %v, want 30", cost, err)
	}
	if _, err = catalog.RecycleEnergyCost(1, 500, 1); err != ErrInvalid {
		t.Fatalf("non-recount item accepted: %v", err)
	}
	awards, err := catalog.RecycleAwards(100, 3)
	if err != nil || len(awards) != 2 || awards[0] != (ResourceAmount{ID: 11, Amount: 15}) || awards[1] != (ResourceAmount{ID: 12, Amount: 21}) {
		t.Fatalf("awards = %+v %v", awards, err)
	}
	chance, err := catalog.RecycleCritChance(1)
	if err != nil || chance.Cmp(big.NewRat(1, 10)) != 0 {
		t.Fatalf("crit chance = %v %v", chance, err)
	}
	limit, err := catalog.EnergyLimit(1)
	if err != nil || limit != 11000 {
		t.Fatalf("energy limit = %d %v", limit, err)
	}
}

func TestMakeDurationAndCrafting(t *testing.T) {
	catalog := testCatalog()
	if duration, err := catalog.MakeDuration(DeskBuilding, 2, 500, 1); err != nil || duration != 100800 {
		t.Fatalf("desk duration = %d %v", duration, err)
	}
	if duration, err := catalog.MakeDuration(PetRoomBuilding, 2, 500, 3); err != nil || duration != 104400 {
		t.Fatalf("pet duration = %d %v", duration, err)
	}
	if !catalog.Craftable(DeskBuilding, 2, 500, 0) || catalog.Craftable(DeskBuilding, 1, 501, 0) {
		t.Fatal("desk cumulative craft list is wrong")
	}
	if !catalog.Craftable(PetRoomBuilding, 2, 901, 7) || catalog.Craftable(PetRoomBuilding, 1, 901, 7) {
		t.Fatal("pet craft list is wrong")
	}
}

func TestRefundAndRecycleSettlement(t *testing.T) {
	job := &MakeJob{Duration: 100, Cost: []ResourceAmount{{ID: 13, Amount: 53}, {ID: 50001094, Amount: 5}}}
	refund, err := Refund(job, 50)
	if err != nil || len(refund) != 2 || refund[0] != (ResourceAmount{ID: 13, Amount: 26}) || refund[1] != (ResourceAmount{ID: 50001094, Amount: 2}) {
		t.Fatalf("refund = %+v %v", refund, err)
	}
	recycle := RecycleState{}
	at := time.Unix(120, 0).UTC()
	if err = SettleRecycle(&recycle, 11000, 15, at); err != nil || recycle.Energy != 11000 || !recycle.EnergyAt.Equal(at) {
		t.Fatalf("recycle initial energy = %+v %v", recycle, err)
	}
	recycle.Energy = 1000
	regenerated := at.Add(120 * time.Second)
	if err = SettleRecycle(&recycle, 11000, 15, regenerated); err != nil || recycle.Energy != 1008 || !recycle.EnergyAt.Equal(regenerated) {
		t.Fatalf("recycle regen = %+v %v", recycle, err)
	}
	if err = SettleRecycle(&recycle, 5, 15, regenerated.Add(time.Minute)); err != nil || recycle.Energy != 5 || !recycle.EnergyAt.Equal(regenerated.Add(time.Minute)) {
		t.Fatalf("recycle cap = %+v %v", recycle, err)
	}
}

func TestAdminKeyRoundTrip(t *testing.T) {
	for _, pair := range [][2]int64{{2, 11}, {13, 12}, {1, 13}, {11, 12}} {
		source, destination, ok := ParseAdminKey(AdminKey(pair[0], pair[1]))
		if !ok || source != pair[0] || destination != pair[1] {
			t.Fatalf("admin key %v -> %d %d %v", pair, source, destination, ok)
		}
	}
	if _, _, ok := ParseAdminKey("x"); ok {
		t.Fatal("malformed admin key accepted")
	}
}
