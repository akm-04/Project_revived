//go:build postgres

package playerdisplay_test

import (
	"reflect"
	"testing"
	"time"
)

// shopSlotSignature is the frozen part of one reply item: the index order and
// the drawn (item, quantity, sell type) triple, without the derived price.
type shopSlotSignature struct {
	Index    int64
	ItemID   int64
	ItemNum  int64
	SellType int64
}

func shopSlotSignatures(t *testing.T, items []map[string]any) []shopSlotSignature {
	t.Helper()
	signatures := make([]shopSlotSignature, 0, len(items))
	for _, item := range items {
		index, indexOK := item["index"].(int64)
		itemID, itemIDOK := item["item_id"].(int64)
		itemNum, itemNumOK := item["item_num"].(int64)
		sellType, sellTypeOK := item["sell_type"].(int64)
		if !indexOK || !itemIDOK || !itemNumOK || !sellTypeOK {
			t.Fatalf("unfrozen item row: %#v", item)
		}
		signatures = append(signatures, shopSlotSignature{Index: index, ItemID: itemID, ItemNum: itemNum, SellType: sellType})
	}
	return signatures
}

// TestI911CShopStockEntropyNative pins the section 8 recipe through the
// production dispatcher: one operation seed and generation freeze one slot
// list, a reload of the same database reads it back unchanged, and a manual
// refresh under a different seed freezes the pinned different list.
func TestI911CShopStockEntropyNative(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	at := time.Date(2026, 11, 18, 12, 0, 0, 0, time.UTC)
	clock := &i911cFixedClock{at: at}
	a := i911cPlayer(t, p, revision)
	i911cScalar(t, p, a, "crystal", 1_000_000)

	first := i911cCompositionAt(p, a, clock)
	loaded := shopSlotSignatures(t, i911cLoad(t, first.Dispatcher, a, 1, at, 0x11))
	// These are pinned outputs of the first run, not values recomputed here.
	wantLoaded := []shopSlotSignature{{Index: 1, ItemID: 70001021, ItemNum: 3, SellType: 1},
		{Index: 2, ItemID: 60001018, ItemNum: 3, SellType: 1},
		{Index: 3, ItemID: 70001023, ItemNum: 1, SellType: 1},
		{Index: 4, ItemID: 60001034, ItemNum: 3, SellType: 1},
		{Index: 5, ItemID: 40001014, ItemNum: 1, SellType: 2},
		{Index: 6, ItemID: 50001001, ItemNum: 5, SellType: 1},
		{Index: 7, ItemID: 30001007, ItemNum: 3, SellType: 1},
		{Index: 8, ItemID: 30001004, ItemNum: 1, SellType: 1}}
	if !reflect.DeepEqual(loaded, wantLoaded) {
		t.Fatalf("first load slots drifted: %#v", loaded)
	}
	for position, signature := range loaded {
		if signature.Index != int64(position+1) {
			t.Fatalf("slot order is not group-then-row 1..N: %#v", loaded)
		}
	}

	// A new dispatcher reads the persisted generation instead of drawing again,
	// even though its operation seed differs.
	reloaded := i911cCompositionAt(p, a, clock)
	again := shopSlotSignatures(t, i911cLoad(t, reloaded.Dispatcher, a, 1, at, 0x22))
	if !reflect.DeepEqual(again, wantLoaded) {
		t.Fatalf("reload over the same database differs: %#v", again)
	}

	// Manual refresh (MID 34) draws generation 2 from a different operation seed.
	refreshed := i911cDispatchAt(t, first.Dispatcher, a, 34, map[string]any{"shop_type": int64(1)}, at, 0x33)
	if refreshed.HTTPStatus != 200 {
		t.Fatalf("MID 34: %+v", refreshed)
	}
	wantRefreshed := []shopSlotSignature{{Index: 1, ItemID: 70001021, ItemNum: 1, SellType: 1},
		{Index: 2, ItemID: 60001018, ItemNum: 1, SellType: 1},
		{Index: 3, ItemID: 70001027, ItemNum: 3, SellType: 1},
		{Index: 4, ItemID: 60001032, ItemNum: 1, SellType: 1},
		{Index: 5, ItemID: 40001004, ItemNum: 1, SellType: 1},
		{Index: 6, ItemID: 50001002, ItemNum: 10, SellType: 1},
		{Index: 7, ItemID: 170600006, ItemNum: 3, SellType: 1},
		{Index: 8, ItemID: 20001026, ItemNum: 3, SellType: 1}}
	manual := shopSlotSignatures(t, i911cItems(t, refreshed))
	if !reflect.DeepEqual(manual, wantRefreshed) {
		t.Fatalf("manual refresh slots drifted: %#v", manual)
	}
	if reflect.DeepEqual(manual, wantLoaded) {
		t.Fatalf("manual refresh reused the first generation: %#v", manual)
	}
	for position, signature := range manual {
		if signature.Index != int64(position+1) {
			t.Fatalf("refresh slot order is not group-then-row 1..N: %#v", manual)
		}
	}
}
