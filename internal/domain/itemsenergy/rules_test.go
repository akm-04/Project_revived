package itemsenergy

import (
	"errors"
	"testing"
)

func testCatalog() Catalog {
	return Catalog{
		Revision: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
		Items: map[int64]Item{
			50000001: {ID: 50000001, Type: 4, SubType: 5, Stack: 999, Energy: 50, Gifts: []int64{100}},
			50000002: {ID: 50000002, Type: 4, SubType: 1, Stack: 999, Mana: 7},
			50000003: {ID: 50000003, Type: 4, SubType: 1, Stack: 999, Crystal: 3},
			50000004: {ID: 50000004, Type: 4, SubType: 12, Stack: 999, MagicEnergy: 10, MagicDust: 2},
			50000005: {ID: 50000005, Type: -1, Stack: 0},
			50000006: {ID: 50000006, Type: 1, Stack: 0},
			50000007: {ID: 50000007, Type: 4, SubType: 1, Stack: 999},
		},
		Gifts: map[int64]Gift{
			100: {ID: 100, Items: []int64{50000002}, ItemNums: []int64{3}, Drops: []int64{200}, Crystal: 5},
			101: {ID: 101, Items: []int64{50000005}, ItemNums: []int64{1}},
			102: {ID: 102, Items: []int64{50000006}, ItemNums: []int64{1}},
			103: {ID: 103, Items: []int64{50000007}, ItemNums: []int64{1}, LuckyCoin: 1},
			104: {ID: 104, Items: []int64{50000007}, ItemNums: []int64{1}, Equip: "17001|1"},
		},
		Dropboxes: map[int64]Dropbox{
			200: {ID: 200, Rolls: []DropRoll{{ID: 1, ItemID: 50000003, ItemNum: 2, Rate: 1, RollType: 1}}},
			201: {ID: 201, Rolls: []DropRoll{{ID: 1, ItemID: 50000002, ItemNum: 1, Rate: 1, RollType: 1}, {ID: 2, ItemID: 50000003, ItemNum: 1, Rate: 3, RollType: 1}}},
		},
		VIP: map[int64]VIPRow{
			0:  {Level: 0, NumEnergy: 1, NumMidas: 1},
			15: {Level: 15, NumEnergy: 16, NumMidas: 300},
		},
		Monthly:     MonthlyPrivilege{NumEnergy: 4, NumMidas: 30},
		RefreshCost: map[int64]RefreshCost{1: {ID: 1, BuyEnergyCost: 50, BuyManaCost: 10, BuyManaRatioMillionths: 1000000}},
		Misc: Misc{BuyEnergyNum: 120, EnergyMaxLimit: 500, MidasBase: 20000, MidasLevelIncrease: 100,
			MidasFloatUpBasisPoints: 500, MidasCritTypes: []int64{1, 2}, MidasCritRates: []int64{9000, 1000}},
		DailyConsume: map[int64]DailyConsume{1: {ID: 1, Cost: 50, Num: 1, Value: 1}},
	}
}

type sequenceUniform []uint64

func (s sequenceUniform) Uniform(n uint64) uint64 {
	value := s[0]
	if value >= n {
		value = n - 1
	}
	return value
}

func TestSellAndItemUseRules(t *testing.T) {
	catalog := testCatalog()
	item := catalog.Items[50000002]
	key, unit, ok := SellUnitPrice(item)
	if !ok || key != "mana" || unit != 7 {
		t.Fatalf("sell price = %s %d %v", key, unit, ok)
	}
	if _, _, ok := SellUnitPrice(catalog.Items[50000007]); ok {
		t.Fatal("zero-price item is sellable")
	}
	if _, _, ok := SellUnitPrice(catalog.Items[50000005]); ok {
		t.Fatal("entity item is sellable")
	}
	if _, _, ok := SellUnitPrice(catalog.Items[50000006]); ok {
		t.Fatal("zero-stack item is sellable")
	}
	if gain, err := EnergyItemGain(catalog.Items[50000001], 2); err != nil || gain != 100 {
		t.Fatalf("energy gain = %d %v", gain, err)
	}
	if _, err := EnergyItemGain(item, 1); !errors.Is(err, ErrRefused) {
		t.Fatalf("non-energy item accepted: %v", err)
	}
	lines, err := MagicItemGrants(catalog.Items[50000004], 2)
	if err != nil || len(lines) != 2 || lines[0].Amount != 20 || lines[1].Amount != 4 {
		t.Fatalf("magic grants = %+v %v", lines, err)
	}
	if _, err := MagicItemGrants(item, 1); !errors.Is(err, ErrRefused) {
		t.Fatalf("non-magic item accepted: %v", err)
	}
}

func TestGoldenHandPipeline(t *testing.T) {
	catalog := testCatalog()
	mana, crit, cost, err := catalog.MidasMana(1, 1, 1, sequenceUniform{0, 0})
	if err != nil || mana != 20100 || crit != 1 || cost != 10 {
		t.Fatalf("single = %d %d %d %v", mana, crit, cost, err)
	}
	mana, crit, cost, err = catalog.MidasMana(1, 1, 10, sequenceUniform{0, 0})
	if err != nil || mana != 201000 || crit != 1 || cost != 10 {
		t.Fatalf("tenfold = %d %d %d %v", mana, crit, cost, err)
	}
	tenfoldCost, err := catalog.TenfoldCost(1)
	if err != nil || tenfoldCost != 60 {
		t.Fatalf("tenfold cost = %d %v", tenfoldCost, err)
	}
	allowance, err := catalog.MidasAllowance(15, true)
	if err != nil || allowance != 330 {
		t.Fatalf("midas allowance = %d %v", allowance, err)
	}
	energyAllowance, err := catalog.EnergyBuyAllowance(15, true)
	if err != nil || energyAllowance != 20 {
		t.Fatalf("energy allowance = %d %v", energyAllowance, err)
	}
}

func TestBoxResolutionAndFailClosed(t *testing.T) {
	catalog := testCatalog()
	plan, err := catalog.ResolveBox(50000001, 100, 2)
	if err != nil || len(plan.Units) != 2 || len(plan.Units[0]) != 1 {
		t.Fatalf("resolve = %+v %v", plan, err)
	}
	rewards, err := catalog.GiftRewards(plan.Gift, plan.Num)
	if err != nil || len(rewards.Stacks) != 1 || rewards.Stacks[0].Amount != 6 || rewards.Scalars[0].Amount != 10 {
		t.Fatalf("fixed rewards = %+v %v", rewards, err)
	}
	roll, err := catalog.DrawDrop(plan.Units[0][0], sequenceUniform{0})
	if err != nil || roll.ItemID != 50000003 || roll.ItemNum != 2 {
		t.Fatalf("draw = %+v %v", roll, err)
	}
	if roll, err := catalog.DrawDrop(catalog.Dropboxes[201], sequenceUniform{2}); err != nil || roll.ID != 2 {
		t.Fatalf("weighted draw = %+v %v", roll, err)
	}
	hero, err := catalog.GiftRewards(catalog.Gifts[101], 1)
	if err != nil || len(hero.Heroes) != 1 || hero.Heroes[0] != 50000005 {
		t.Fatalf("hero reward = %+v %v", hero, err)
	}
	for giftID := int64(102); giftID <= 104; giftID++ {
		if _, err := catalog.GiftRewards(catalog.Gifts[giftID], 1); !errors.Is(err, ErrRefused) {
			t.Fatalf("gift %d was not refused fail-closed: %v", giftID, err)
		}
	}
	if _, err := catalog.ResolveBox(50000001, 999, 1); !errors.Is(err, ErrRefused) {
		t.Fatalf("foreign gift id accepted: %v", err)
	}
	if _, err := catalog.ResolveBox(50000001, 100, 1000); !errors.Is(err, ErrRefused) {
		t.Fatalf("stack overflow accepted: %v", err)
	}
}

type recordingUniform struct {
	script []uint64
	calls  []uint64
}

func (r *recordingUniform) Uniform(n uint64) uint64 {
	r.calls = append(r.calls, n)
	value := r.script[len(r.calls)-1]
	if value >= n {
		value = n - 1
	}
	return value
}

func TestBoxDrawScheduleIsUnitThenDropsOrder(t *testing.T) {
	catalog := testCatalog()
	catalog.Items[50000010] = Item{ID: 50000010, Type: 4, SubType: 1, Stack: 99, Gifts: []int64{300}}
	catalog.Gifts[300] = Gift{ID: 300, Items: []int64{50000002}, ItemNums: []int64{1}, Drops: []int64{201, 201}}
	plan, err := catalog.ResolveBox(50000010, 300, 2)
	if err != nil {
		t.Fatal(err)
	}
	stream := &recordingUniform{script: []uint64{0, 2, 2, 0}}
	rewards, err := catalog.RollBox(plan, stream)
	if err != nil {
		t.Fatal(err)
	}
	if len(stream.calls) != 4 {
		t.Fatalf("draw count = %d", len(stream.calls))
	}
	if rewards.Stacks[0].ItemID != 50000002 || rewards.Stacks[0].Amount != 2 {
		t.Fatalf("fixed stacks = %+v", rewards.Stacks)
	}
	drawn := rewards.Stacks[1:]
	want := []int64{50000002, 50000003, 50000003, 50000002}
	if len(drawn) != len(want) {
		t.Fatalf("drawn = %+v", drawn)
	}
	for index := range want {
		if drawn[index].ItemID != want[index] {
			t.Fatalf("draw %d = %d want %d (%+v)", index, drawn[index].ItemID, want[index], drawn)
		}
	}
}
