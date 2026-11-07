//go:build postgres

package playerdisplay_test

import "testing"

func TestI9_10HeroRecommendProcessStockMIDs(t *testing.T) {
	pool := pool(t)
	installed(t, pool)
	actor := bornActor(t, pool)
	api := startI9Process(t, pool, actor)

	status, body := api.post(2497, map[string]any{})
	if status != 200 {
		t.Fatalf("2497 status %d body %+v", status, body)
	}
	if subRankList, ok := body["sub_rank_list"].(map[string]any); !ok || len(subRankList) != 0 {
		t.Fatalf("2497 sub_rank_list %T %+v", body["sub_rank_list"], body["sub_rank_list"])
	}
	if totalRankList, ok := body["total_rank_list"].([]any); !ok || len(totalRankList) != 0 {
		t.Fatalf("2497 total_rank_list %T %+v", body["total_rank_list"], body["total_rank_list"])
	}

	status, body = api.post(2498, map[string]any{"table_id": int64(10001001)})
	if status != 200 || len(body) != 0 {
		t.Fatalf("2498 no-record status %d body %+v", status, body)
	}

	status, body = api.post(2497, map[string]any{"unexpected": true})
	if status != 400 {
		t.Fatalf("2497 extra-param status %d body %+v", status, body)
	}
	status, body = api.post(2498, map[string]any{})
	if status != 400 {
		t.Fatalf("2498 missing-table status %d body %+v", status, body)
	}
	status, body = api.post(2498, map[string]any{"table_id": int64(0)})
	if status != 400 {
		t.Fatalf("2498 nonpositive-table status %d body %+v", status, body)
	}

	api.stop()
	assertI9Journal(t, pool, actor, []int{2497, 2498})
}
