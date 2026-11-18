package shop

import (
	"encoding/hex"
	"reflect"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/foundation/operation"
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
		Tunables:    Tunables{StoneSubstituteItem: 50001427, CubeCurrencyItem: 50002072, DiscountMillionths: 600000, MonthCardMillionths: 550000, LevelPoolRows: 100},
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

// C9 pins the whole entropy recipe: the derived stream bytes, the slot order and
// the group/row draws are fixed for one operation seed and generation.
func TestStockScheduleIsPinnedForAFixedOperationSeed(t *testing.T) {
	catalog := testCatalog()
	op := operation.Context{EntropySeed: [32]byte{0x11, 0x22, 0x33, 0x44}}
	derived := op.Derive(EntropyLabel, 1)
	if got := hex.EncodeToString(derived[:]); got != "e3495524cc75f508888641565354e53dfb9196b24edf4b69ab7c8b2d70ed76a0" {
		t.Fatalf("derived stream drifted: %s", got)
	}
	slots, err := catalog.Generate(catalog.Shops[1], 10, combat.NewStream(derived))
	if err != nil {
		t.Fatal(err)
	}
	want := []StockSlot{
		{Index: 1, ItemID: 50000002, ItemNum: 1, SellType: 2, SellPrice: 50},
		{Index: 2, ItemID: 50000001, ItemNum: 2, SellType: 1, SellPrice: 100},
	}
	if !reflect.DeepEqual(slots, want) {
		t.Fatalf("slot schedule drifted: %#v", slots)
	}
	second, err := catalog.Generate(catalog.Shops[1], 10, combat.NewStream(op.Derive(EntropyLabel, 1)))
	if err != nil || !reflect.DeepEqual(slots, second) {
		t.Fatalf("same seed and generation differs: %#v %#v %v", slots, second, err)
	}
}

func TestGenerateFreezesTheSourceStoneID(t *testing.T) {
	catalog := testCatalog()
	catalog.Groups[100] = []Roll{{ItemID: 40001096, ItemNum: 2, SellType: 7, SellPrice: 10, StoneID: 40001096, Rate: 1}}
	catalog.Groups[101] = []Roll{{ItemID: 90001001, ItemNum: 1, SellType: 15, SellPrice: 5, StoneID: 90001001, Rate: 1}}
	slots, err := catalog.Generate(catalog.Shops[1], 10, combat.NewStream([32]byte{7}))
	if err != nil {
		t.Fatal(err)
	}
	for _, slot := range slots {
		if slot.SellType == 7 && slot.StoneID != 40001096 {
			t.Fatalf("sell_type 7 froze stone %d, want 40001096", slot.StoneID)
		}
		if slot.SellType == 15 && slot.StoneID != 90001001 {
			t.Fatalf("sell_type 15 froze stone %d, want 90001001", slot.StoneID)
		}
	}
	catalog.Groups[100] = []Roll{{ItemID: 50000001, ItemNum: 1, SellType: 1, SellPrice: 10, Rate: 1}}
	plain, err := catalog.Generate(catalog.Shops[1], 10, combat.NewStream([32]byte{7}))
	if err != nil {
		t.Fatal(err)
	}
	if plain[1].StoneID != 0 {
		t.Fatalf("non-stone row froze stone %d", plain[1].StoneID)
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
	negative := int64(-1)
	if err := ValidateTuning(catalog, Tuning{Rows: []TuningRow{{ShopType: 1, Index: 1, MaxBuys: &negative}}}); err != ErrOverlayInvalid {
		t.Fatal("negative cap accepted")
	}
	zero := int64(0)
	catalog.Tuning = Tuning{Rows: []TuningRow{{ShopType: 1, Index: 1, MaxBuys: &zero}}}
	if _, disabled := catalog.TunedSlot(1, StockSlot{Index: 1}); !disabled {
		t.Fatal("max_buys 0 did not lower the one-buy cap")
	}
	if _, disabled := catalog.TunedSlot(1, StockSlot{Index: 2}); disabled {
		t.Fatal("max_buys 0 disabled another row")
	}
	if err := ValidateTuning(testCatalog(), Tuning{Rows: []TuningRow{{ShopType: 1, Index: 1, StoneID: &zero}}}); err != ErrOverlayInvalid {
		t.Fatal("non-positive stone_id accepted")
	}
	stone := int64(50001427)
	catalog.Tuning = Tuning{Rows: []TuningRow{{ShopType: 1, Index: 2, StoneID: &stone}}}
	if slot, _ := catalog.TunedSlot(1, StockSlot{Index: 2, SellType: 7, StoneID: 40001096}); slot.StoneID != stone {
		t.Fatalf("stone_id override not applied: %d", slot.StoneID)
	}
	if slot, _ := catalog.TunedSlot(1, StockSlot{Index: 2, SellType: 1}); slot.StoneID != 0 {
		t.Fatal("stone_id override made a scalar-priced slot stone-priced")
	}
}
