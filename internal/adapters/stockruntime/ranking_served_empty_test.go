package stockruntime

import (
	"context"
	"net/http"
	"testing"
	"time"
)

func TestRankingMID301ServesDeclaredEmptyRankTabs(t *testing.T) {
	dispatcher := RankingDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: unusedBoardRankingFixture{}}
	for _, subtype := range []int64{5, 13, 14, 28, 29, 35, 36, 40, 41} {
		request := env(301, nil, time.Now().UTC())
		request.Envelope.Params["rank_types"] = []any{subtype}
		response := dispatcher.Dispatch(context.Background(), request)
		if response.HTTPStatus != http.StatusOK || response.Body["error_code"] != int64(0) {
			t.Fatalf("subtype %d: status %d body %v", subtype, response.HTTPStatus, response.Body)
		}
		list, ok := response.Body["rank_list"].([]map[string]any)
		if !ok || len(list) != 1 || list[0]["rank_type"] != subtype {
			t.Fatalf("subtype %d: rank_list %v", subtype, response.Body)
		}
		info, ok := list[0]["rank_info"].(map[string]any)
		if !ok {
			t.Fatalf("subtype %d: rank_info %v", subtype, list[0]["rank_info"])
		}
		rows, ok := info["rank_info"].([]map[string]any)
		if !ok || len(rows) != 0 {
			t.Fatalf("subtype %d: rows %#v", subtype, info["rank_info"])
		}
		mine, ok := info["my_rank"].(map[string]any)
		if !ok || len(mine) != 0 {
			t.Fatalf("subtype %d: my_rank %#v", subtype, info["my_rank"])
		}
	}
}

func TestRankingMID301StillRefusesUndeclaredSubtype(t *testing.T) {
	dispatcher := RankingDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: unusedBoardRankingFixture{}}
	request := env(301, nil, time.Now().UTC())
	request.Envelope.Params["rank_types"] = []any{int64(999)}
	response := dispatcher.Dispatch(context.Background(), request)
	if response.HTTPStatus != http.StatusConflict || response.Body["error_code"] != unprovenRefusalCode {
		t.Fatalf("status %d body %v", response.HTTPStatus, response.Body)
	}
}
