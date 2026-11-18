package shop

import (
	"reflect"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/combat"
)

func testCatalog() Catalog {
	return Catalog{
		Shops: map[int64]Shop{
			1: {Type: 1, FunctionID: 5, SlotNum: 2, RefreshType: 2, RefreshKey: "shop_cost", RefreshTimes: []int64{32400, 43200, 64800, 75600}, Table: "shop_item"},
			4: {Type: 4, FunctionID: 12, SlotNum: 1, RefreshType: 2, RefreshKey: "goblin_shop_cost", RefreshTimes: []int64{75600}, Table: "goblin"},
		},
		StockTables: map[string][]SourceRow{
			"shop_item": {
				{ID: 1, Slots: []SourceSlot{
					{Groups: []Group{{DropboxID: 100, Weight: 1}, {DropboxID: 101, Weight: 3}}},
					{Groups: []Group{{DropboxID: 100, Weight: 1}}},
				}},
			},
			"goblin": {
				{ID: 1, Slots: []SourceSlot{{Groups: []Group{{DropboxID: 200, Weight: 1}}}}},
			},
		},
		Groups: map[int64][]Roll{
			100: {{ItemID: 50000001, ItemNum: 2, SellType: 1, SellPrice: 100, Discount: 0, Rate: 1}},
			101: {{ItemID: 50000002, ItemNum: 1, SellType: 2, SellPrice: 50, Discount: 0, Rate: 1}},
			200: {{ItemID: 50000003, ItemNum: 1, SellType: 2, SellPrice: 200, Discount: 1, Rate: 1}},
		},
		RefreshCost: map[string][]int64{"shop_cost": {50, 100}, "goblin_shop_cost": {100}},
		Tunables:    Tunables{StoneCurrencyItem: 50001427, CubeCurrencyItem: 50002072, DiscountMillionths: 600000, MonthCardMillionths: 550000, LevelPoolRows: 100},
	}
}

func TestGenerateIsDeterministicPerStream(t *testing.T) {
	catalog := testCatalog()
	shop := catalog.Shops[1]
	first, err := catalog.Generate(shop, 10, combat.NewStream([32]byte{7}))
	if err != nil {
		t.Fatal(err)
	}
	second, err := catalog.Generate(shop, 10, combat.NewStream([32]byte{7}))
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(first, second) {
		t.Fatalf("same stream differs: %#v %#v", first, second)
	}
	if len(first) != 2 || first[0].Index != 1 || first[1].Index != 2 {
		t.Fatalf("slot indices are not contiguous: %#v", first)
	}
	for _, slot := range first {
		if slot.IsBuy != 0 || slot.BuyTimes != 0 {
			t.Fatalf("new slot is not unsold: %#v", slot)
		}
		if slot.ItemID <= 0 || slot.ItemNum <= 0 || slot.SellPrice <= 0 {
			t.Fatalf("unfrozen slot: %#v", slot)
		}
	}
}

func TestGenerateUsesTheLevelPoolRow(t *testing.T) {
	catalog := testCatalog()
	rows := make([]SourceRow, 0, 100)
	for id := int64(1); id <= 100; id++ {
		rows = append(rows, SourceRow{ID: id, Slots: []SourceSlot{{Groups: []Group{{DropboxID: 100, Weight: 1}}}}})
	}
	catalog.StockTables["pool"] = rows
	shop := Shop{Type: 1, SlotNum: 1, Table: "pool"}
	level, err := catalog.poolRow(shop, 250)
	if err != nil || level.ID != 100 {
		t.Fatalf("level 250 wanted row 100, got %d err %v", level.ID, err)
	}
	level, err = catalog.poolRow(shop, 0)
	if err != nil || level.ID != 1 {
		t.Fatalf("level 0 wanted row 1, got %d err %v", level.ID, err)
	}
}

func TestPriceAppliesDiscountAndMonthCard(t *testing.T) {
	catalog := testCatalog()
	discounted := StockSlot{SellPrice: 333, Discount: 1}
	if price, err := catalog.Price(discounted, 1, false); err != nil || price != 199 {
		t.Fatalf("0.6 floor of 333 = %d err %v, want 199", price, err)
	}
	if price, err := catalog.Price(discounted, 4, true); err != nil || price != 183 {
		t.Fatalf("0.55 floor of 333 = %d err %v, want 183", price, err)
	}
	if price, err := catalog.Price(discounted, 4, false); err != nil || price != 199 {
		t.Fatalf("no card outside the two merchant types = %d err %v", price, err)
	}
	if price, err := catalog.Price(StockSlot{SellPrice: 300, Discount: 1}, 5, true); err != nil || price != 165 {
		t.Fatalf("black market card price = %d err %v, want 165", price, err)
	}
	if price, err := catalog.Price(StockSlot{SellPrice: 300}, 13, true); err != nil || price != 300 {
		t.Fatalf("plain price = %d err %v", price, err)
	}
}

func TestNeedsScheduledRerollAcrossMarksAndDay(t *testing.T) {
	shop := testCatalog().Shops[1]
	gmt8 := time.FixedZone("GMT+8", 8*3600)
	at := time.Date(2026, 11, 18, 10, 0, 0, 0, gmt8)
	day, mark := ScheduledMark(shop, at)
	if mark != 1 {
		t.Fatalf("10:00 GMT+8 passed %d marks, want 1", mark)
	}
	if NeedsScheduledReroll(shop, Stock{ScheduleDay: day, ScheduleMark: 1, Slots: []StockSlot{{Index: 1}}}, at) {
		t.Fatal("current generation rerolled before the next mark")
	}
	if !NeedsScheduledReroll(shop, Stock{ScheduleDay: day, ScheduleMark: 0, Slots: []StockSlot{{Index: 1}}}, at) {
		t.Fatal("a generation before the 09:00 mark must reroll")
	}
	if !NeedsScheduledReroll(shop, Stock{ScheduleDay: day - 1, ScheduleMark: 4, Slots: []StockSlot{{Index: 1}}}, at) {
		t.Fatal("a generation from the previous game day must reroll")
	}
	noSchedule := Shop{Type: 7}
	if NeedsScheduledReroll(noSchedule, Stock{ScheduleDay: 0, ScheduleMark: 0, Slots: []StockSlot{{Index: 1}}}, at) {
		t.Fatal("a type with refresh_time 0 has no schedule")
	}
}

func TestValidateTuningRefusesUnknownAndInvalidRows(t *testing.T) {
	catalog := testCatalog()
	price := int64(0)
	valid := Tuning{Revision: "1", Digest: "d", Rows: []TuningRow{{ShopType: 1, Index: 2, SellPrice: &price}}}
	if err := ValidateTuning(catalog, valid); err != ErrOverlayInvalid {
		t.Fatalf("non-positive price accepted: %v", err)
	}
	good := int64(10)
	if err := ValidateTuning(catalog, Tuning{Rows: []TuningRow{{ShopType: 1, Index: 2, SellPrice: &good}}}); err != nil {
		t.Fatalf("valid overlay refused: %v", err)
	}
	if err := ValidateTuning(catalog, Tuning{Rows: []TuningRow{{ShopType: 9, Index: 1}}}); err != ErrOverlayInvalid {
		t.Fatal("unknown shop type accepted")
	}
	if err := ValidateTuning(catalog, Tuning{Rows: []TuningRow{{ShopType: 1, Index: 3}}}); err != ErrOverlayInvalid {
		t.Fatal("out-of-range index accepted")
	}
	two := int64(2)
	if err := ValidateTuning(catalog, Tuning{Rows: []TuningRow{{ShopType: 1, Index: 1, MaxBuys: &two}}}); err != ErrOverlayInvalid {
		t.Fatal("raised cap accepted")
	}
}
