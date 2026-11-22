package course

import (
	"testing"
	"time"

	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
)

func giftBoxOperation(t *testing.T, seed byte) operation.Context {
	t.Helper()
	identifier, e := ids.NewUUID()
	if e != nil {
		t.Fatal(e)
	}
	var entropy [32]byte
	for index := range entropy {
		entropy[index] = seed + byte(index)
	}
	return operation.Context{ID: identifier, StartedAt: time.Unix(1700000000, 0).UTC(), EntropySeed: entropy}
}

func giftBoxRule() GiftBoxRule {
	return GiftBoxRule{ItemID: DailyGiftBoxItemID, DropboxID: 600003, Rolls: []GiftBoxDrop{
		{ID: 1, ItemID: 50001420, ItemNum: 1, Rate: 7500},
		{ID: 2, ItemID: 50001421, ItemNum: 1, Rate: 2000},
		{ID: 3, ItemID: 50001422, ItemNum: 1, Rate: 500},
		{ID: 4, ItemID: 50001423, ItemNum: 1, Rate: 0},
	}}
}

func TestGiftBoxRuleRollIsStableAndSelectsPositiveRate(t *testing.T) {
	rule := giftBoxRule()
	if e := rule.Validate(); e != nil {
		t.Fatal(e)
	}
	op := giftBoxOperation(t, 0)
	first, e := rule.Roll(op)
	if e != nil {
		t.Fatal(e)
	}
	for attempt := 0; attempt < 64; attempt++ {
		again, e := rule.Roll(op)
		if e != nil || again != first {
			t.Fatalf("roll changed: %+v %+v %v", first, again, e)
		}
	}
	if first.ItemID == 50001423 {
		t.Fatalf("zero-rate row selected: %+v", first)
	}
	if first.ID <= 0 || first.ItemNum <= 0 {
		t.Fatalf("invalid selection: %+v", first)
	}
}

func TestGiftBoxRuleValidateRejectsMalformedDropboxes(t *testing.T) {
	cases := map[string]func(*GiftBoxRule){
		"total":           func(r *GiftBoxRule) { r.Rolls[0].Rate = 7000 },
		"duplicate item":  func(r *GiftBoxRule) { r.Rolls[1].ItemID = r.Rolls[0].ItemID },
		"zero item num":   func(r *GiftBoxRule) { r.Rolls[0].ItemNum = 0 },
		"missing dropbox": func(r *GiftBoxRule) { r.DropboxID = 0 },
	}
	for name, mutate := range cases {
		rule := giftBoxRule()
		mutate(&rule)
		if rule.Validate() == nil {
			t.Fatalf("%s: accepted", name)
		}
	}
}
