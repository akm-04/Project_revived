//go:build postgres

package playerdisplay_test

import (
	"testing"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/shop"
	"gxb.local/backend/v2/internal/protocol/replyconformance"
)

func i912CourseBooksFunction(t *testing.T, p *pg.Pool, a identity.ActorContext, revision string) {
	t.Helper()
	exec(t, p, `INSERT INTO player_function_eligibility(player_id,function_id,content_revision,source_fact_key,eligible_at)VALUES($1,51,$2,$3,clock_timestamp()) ON CONFLICT DO NOTHING`,
		int64(a.PlayerID), revision, "i9-12-bookshop-native:51")
}

// R9: the Electives bookshop loads and sells its six slots repeatedly through
// the production dispatcher, never appears in MID 37 and cannot be refreshed.
func TestI912CourseBookshopNative(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	a := bornActor(t, p)
	i911cOpenFunctions(t, p, a, revision)
	i912CourseBooksFunction(t, p, a, revision)
	exec(t, p, `UPDATE player_progression SET level=100 WHERE player_id=$1`, int64(a.PlayerID))
	i911cScalar(t, p, a, "crystal", 1_000_000)
	dispatcher := i911cComposition(p, a).Dispatcher

	list := i911cDispatch(t, dispatcher, a, 37, map[string]any{})
	if list.HTTPStatus != 200 {
		t.Fatalf("MID 37: %+v", list)
	}
	served, _ := list.Body["list"].([]int64)
	for _, shopType := range served {
		if shopType == d.CourseBooksShopType {
			t.Fatalf("MID 37 lists the course bookshop: %v", served)
		}
	}

	load := i911cDispatch(t, dispatcher, a, 32, map[string]any{"shop_type": d.CourseBooksShopType})
	if load.HTTPStatus != 200 {
		t.Fatalf("MID 32 type 29: %+v", load)
	}
	replyconformance.Check(t, 32, load.Body)
	want := map[int64]struct {
		itemID int64
		price  int64
	}{
		1: {50001423, 2500},
		2: {50001420, 20},
		3: {50001418, 300},
		4: {50001421, 100},
		5: {50001419, 1500},
		6: {50001422, 500},
	}
	items := i911cItems(t, load)
	if len(items) != len(want) {
		t.Fatalf("type 29 slot count = %d, want %d", len(items), len(want))
	}
	for _, item := range items {
		index, _ := item["index"].(int64)
		expected, ok := want[index]
		if !ok {
			t.Fatalf("unexpected type 29 slot: %#v", item)
		}
		if item["item_id"] != expected.itemID || item["sell_price"] != expected.price ||
			item["item_num"] != int64(1) || item["sell_type"] != int64(2) || item["discount"] != int64(0) ||
			item["isbuy"] != int64(0) || item["buy_times"] != int64(0) {
			t.Fatalf("type 29 slot %d drift: %#v", index, item)
		}
	}

	before := i911cScalarAmount(t, p, a, "crystal")
	buy := i911cDispatch(t, dispatcher, a, 33, map[string]any{"shop_type": d.CourseBooksShopType, "index": int64(1)})
	if buy.HTTPStatus != 200 || buy.Body["isbuy"] != int64(0) || buy.Body["isBuy"] != int64(0) || buy.Body["buy_times"] != int64(1) {
		t.Fatalf("MID 33 first course book purchase: %+v", buy)
	}
	replyconformance.Check(t, 33, buy.Body)
	if after := i911cScalarAmount(t, p, a, "crystal"); after != before-2500 {
		t.Fatalf("first crystal debit %d -> %d, want %d", before, after, int64(2500))
	}

	repeat := i911cDispatch(t, dispatcher, a, 33, map[string]any{"shop_type": d.CourseBooksShopType, "index": int64(1)})
	if repeat.HTTPStatus != 200 || repeat.Body["isbuy"] != int64(0) || repeat.Body["buy_times"] != int64(2) {
		t.Fatalf("MID 33 repeat course book purchase: %+v", repeat)
	}
	if after := i911cScalarAmount(t, p, a, "crystal"); after != before-5000 {
		t.Fatalf("repeat crystal debit %d -> %d, want %d", before, after, int64(5000))
	}

	reload := i911cDispatch(t, dispatcher, a, 32, map[string]any{"shop_type": d.CourseBooksShopType})
	if reload.HTTPStatus != 200 {
		t.Fatalf("MID 32 reload: %+v", reload)
	}
	for _, item := range i911cItems(t, reload) {
		if item["index"] != int64(1) {
			continue
		}
		if item["isbuy"] != int64(0) || item["buy_times"] != int64(2) {
			t.Fatalf("reloaded slot 1 does not count repeats: %#v", item)
		}
	}

	refresh := i911cDispatch(t, dispatcher, a, 34, map[string]any{"shop_type": d.CourseBooksShopType})
	if refresh.HTTPStatus != 409 || refresh.Body["error_code"] != int64(35028) || refresh.Body["error_msg"] != "" {
		t.Fatalf("MID 34 type 29: %+v", refresh)
	}
}

// R9: shop type 29 opens only behind function 51.
func TestI912CourseBookshopRequiresFunction51Native(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := bornActor(t, p)
	i911cScalar(t, p, a, "crystal", 1_000_000)
	dispatcher := i911cComposition(p, a).Dispatcher

	load := i911cDispatch(t, dispatcher, a, 32, map[string]any{"shop_type": d.CourseBooksShopType})
	if load.HTTPStatus != 409 || load.Body["error_code"] != int64(35028) || load.Body["error_msg"] != "" {
		t.Fatalf("MID 32 type 29 without function 51: %+v", load)
	}
}
