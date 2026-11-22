package heroassets

import (
	"errors"
	"testing"

	"gxb.local/backend/v2/internal/domain/itemsenergy"
)

func testCatalog() itemsenergy.Catalog {
	refresh := map[int64]itemsenergy.RefreshCost{
		1: {ID: 1, BuySkillCost: 10},
		2: {ID: 2, BuySkillCost: 20},
	}
	for id := int64(3); id <= 330; id++ {
		refresh[id] = itemsenergy.RefreshCost{ID: id, BuySkillCost: 300}
	}
	vip := map[int64]itemsenergy.VIPRow{
		0:  {Level: 0, SkillBuy: 0, SkillMax: 10},
		1:  {Level: 1, SkillBuy: 0, SkillMax: 10},
		2:  {Level: 2, SkillBuy: 1, SkillMax: 10},
		15: {Level: 15, SkillBuy: 1, SkillMax: 80},
	}
	return itemsenergy.Catalog{
		Revision: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
		Gifts:    map[int64]itemsenergy.Gift{1: {ID: 1}},
		Dropboxes: map[int64]itemsenergy.Dropbox{
			1: {ID: 1},
		},
		DailyConsume: map[int64]itemsenergy.DailyConsume{
			1: {}, 2: {}, 3: {}, 4: {}, 5: {}, 6: {}, 7: {}, 8: {}, 9: {}, 10: {},
		},
		VIP: vip,
		Misc: itemsenergy.Misc{BuyEnergyNum: 120, EnergyMaxLimit: 500, MidasBase: 20000,
			MidasLevelIncrease: 100, MidasFloatUpBasisPoints: 500,
			MidasCritTypes: []int64{1}, MidasCritRates: []int64{100}},
		RefreshCost: refresh,
		Items: map[int64]itemsenergy.Item{
			SkillPointItemID: {ID: SkillPointItemID, SubType: SkillPointItemSubType, SkillPoint: 10, Stack: 999},
			7:                {ID: 7, SubType: 1, Stack: 99},
		},
	}
}

func TestSkillPointBuyCostClampsToLastRow(t *testing.T) {
	catalog := testCatalog()
	cases := []struct {
		ordinal int64
		want    int64
	}{
		{1, 10}, {2, 20}, {329, 300}, {330, 300}, {331, 300},
	}
	for _, tc := range cases {
		got, err := SkillPointBuyCost(catalog, tc.ordinal)
		if err != nil || got != tc.want {
			t.Fatalf("ordinal %d = %d, %v; want %d", tc.ordinal, got, err, tc.want)
		}
	}
	if _, err := SkillPointBuyCost(itemsenergy.Catalog{}, 1); !errors.Is(err, ErrContentMissing) {
		t.Fatalf("missing refresh row is not a permanent content refusal: %v", err)
	}
}

func TestSkillBuyGateFollowsVIPTable(t *testing.T) {
	catalog := testCatalog()
	for _, level := range []int64{0, 1} {
		if allowed, err := SkillBuyAllowed(catalog, level); err != nil || allowed {
			t.Fatalf("VIP %d allowed=%v err=%v", level, allowed, err)
		}
	}
	for _, level := range []int64{2, 15} {
		if allowed, err := SkillBuyAllowed(catalog, level); err != nil || !allowed {
			t.Fatalf("VIP %d allowed=%v err=%v", level, allowed, err)
		}
	}
	if _, err := SkillBuyAllowed(catalog, 3); !errors.Is(err, ErrContentMissing) {
		t.Fatalf("missing VIP row is not a permanent content refusal: %v", err)
	}
}

func TestSkillPointRulesReadTheTunedCatalog(t *testing.T) {
	catalog := testCatalog()
	for level := int64(3); level < 15; level++ {
		catalog.VIP[level] = itemsenergy.VIPRow{Level: level, SkillMax: 10}
	}
	tuned, err := catalog.Tune(itemsenergy.Tuning{
		BuySkillCost:         []int64{77},
		VipSkillBuy:          map[string]int64{"0": 1},
		SkillPointItemAmount: 25,
	})
	if err != nil {
		t.Fatal(err)
	}
	if cost, err := SkillPointBuyCost(tuned, 1); err != nil || cost != 77 {
		t.Fatalf("tuned ordinal 1 = %d, %v", cost, err)
	}
	if allowed, err := SkillBuyAllowed(tuned, 0); err != nil || !allowed {
		t.Fatalf("tuned VIP gate allowed=%v err=%v", allowed, err)
	}
	if gain, err := SkillPointItemGain(tuned, SkillPointItemID, 2); err != nil || gain != 50 {
		t.Fatalf("tuned item gain = %d, %v", gain, err)
	}
}

func TestSkillPointItemGain(t *testing.T) {
	catalog := testCatalog()
	if got, err := SkillPointItemGain(catalog, SkillPointItemID, 3); err != nil || got != 30 {
		t.Fatalf("gain = %d, %v", got, err)
	}
	for _, tc := range []struct {
		itemID, num int64
		want        error
	}{
		{7, 1, ErrUnsupportedItem},
		{SkillPointItemID, 0, ErrInvalid},
		{SkillPointItemID, 1000, ErrStaleState},
	} {
		if _, err := SkillPointItemGain(catalog, tc.itemID, tc.num); !errors.Is(err, tc.want) {
			t.Fatalf("item %d num %d error %v; want %v", tc.itemID, tc.num, err, tc.want)
		}
	}
}
