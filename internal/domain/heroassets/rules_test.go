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
	return itemsenergy.Catalog{
		VIP: map[int64]itemsenergy.VIPRow{
			0:  {Level: 0, SkillBuy: 0, SkillMax: 10},
			1:  {Level: 1, SkillBuy: 0, SkillMax: 10},
			2:  {Level: 2, SkillBuy: 1, SkillMax: 10},
			15: {Level: 15, SkillBuy: 1, SkillMax: 80},
		},
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
	if _, err := SkillPointBuyCost(itemsenergy.Catalog{}, 1); !errors.Is(err, ErrUnavailable) {
		t.Fatalf("empty catalog did not refuse: %v", err)
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
	if _, err := SkillBuyAllowed(catalog, 3); !errors.Is(err, ErrUnavailable) {
		t.Fatalf("unknown VIP row did not refuse: %v", err)
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
