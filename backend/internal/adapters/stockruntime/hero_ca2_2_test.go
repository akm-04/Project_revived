package stockruntime

import "testing"

func TestDecodeHeroExpItemsStrictSourceShape(t *testing.T) {
	got, err := decodeHeroExpItems([]any{
		map[string]any{"item_id": float64(50001001), "item_num": float64(2)},
		map[string]any{"item_id": float64(50001002), "item_num": float64(1)},
	})
	if err != nil || len(got) != 2 || got[0].ItemID != 50001001 || got[0].Count != 2 {
		t.Fatalf("got=%+v err=%v", got, err)
	}
	bad := []any{map[string]any{"item_id": float64(50001001), "item_num": float64(1), "invented": true}}
	if _, err := decodeHeroExpItems(bad); err == nil {
		t.Fatal("unknown source field accepted")
	}
	dup := []any{
		map[string]any{"item_id": float64(50001001), "item_num": float64(1)},
		map[string]any{"item_id": float64(50001001), "item_num": float64(1)},
	}
	if _, err := decodeHeroExpItems(dup); err == nil {
		t.Fatal("duplicate Hero EXP item accepted")
	}
}

func TestOnlyHeroParamsRejectsInventedFields(t *testing.T) {
	if !onlyHeroParams(map[string]any{"partner_id": 1}, "partner_id") {
		t.Fatal("qualified field rejected")
	}
	if onlyHeroParams(map[string]any{"partner_id": 1, "capacity": 999}, "partner_id") {
		t.Fatal("invented field accepted")
	}
}
