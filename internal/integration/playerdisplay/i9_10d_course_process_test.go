//go:build postgres

package playerdisplay_test

import "testing"

func TestI9_10DCourseProcessStockMIDs(t *testing.T) {
	p := pool(t)
	installed(t, p)
	actor := bornActor(t, p)
	api := startI9Process(t, p, actor)

	code, body := api.post(2139, map[string]any{})
	if code != 200 || i9Number(t, body["is_has_gift"]) != 1 {
		t.Fatalf("2139 status %d body %+v", code, body)
	}
	code, body = api.post(2141, map[string]any{"item_id": int64(50001418)})
	if code != 200 || i9Number(t, body["is_has_gift"]) != 0 || len(body["awards"].([]any)) != 1 {
		t.Fatalf("2141 status %d body %+v", code, body)
	}
	code, body = api.post(2141, map[string]any{"item_id": int64(50001418)})
	if code != 409 || body["error_code"] != float64(35028) {
		t.Fatalf("2141 spent day status %d body %+v", code, body)
	}
	code, body = api.post(2500, map[string]any{"table_id": int64(10001001)})
	if code != 200 {
		t.Fatalf("2500 status %d body %+v", code, body)
	}
	if list, ok := body["recommend_list"].([]any); !ok || len(list) != 0 {
		t.Fatalf("2500 recommend_list %T %+v", body["recommend_list"], body["recommend_list"])
	}
	code, body = api.post(2500, map[string]any{})
	if code != 400 {
		t.Fatalf("2500 missing table status %d body %+v", code, body)
	}

	api.stop()
	assertI9Journal(t, p, actor, []int{2139, 2141, 2500})
}
