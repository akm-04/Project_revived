//go:build postgres

package playerdisplay_test

import (
	"testing"

	"gxb.local/backend/v2/internal/adapters/stockruntime"
)

// rankInfoRowKeys are the row fields NewRankWindow.lua reads through
// getRankInfoByType/rankDelegate/addRankItem for subtype 34: identity and
// presentation (RankList.lua:153, NewRankWindow.lua:363-395,846-869) plus the
// comfort value (NewRankWindow.lua:831-832) and the page rank (:712-752).
var rankInfoRowKeys = []string{"player_id", "player_name", "level", "avatar_id", "avatar_frame_id", "conquer_lev", "conquer_loop_id", "comfort", "rank"}

func assertDormComfortInfo(t *testing.T, info map[string]any, wantRows int, wantMine bool) {
	t.Helper()
	rows, ok := info["rank_info"].([]map[string]any)
	if !ok || len(rows) != wantRows {
		t.Fatalf("rank rows = %#v, want %d", info["rank_info"], wantRows)
	}
	for i, row := range rows {
		for _, key := range rankInfoRowKeys {
			if _, present := row[key]; !present {
				t.Fatalf("row %d missing client-read key %q: %#v", i, key, row)
			}
		}
		if row["rank"] != int64(i+1) {
			t.Fatalf("row %d rank = %v", i, row["rank"])
		}
	}
	mine, ok := info["my_rank"].(map[string]any)
	if !ok {
		t.Fatalf("my_rank = %#v", info["my_rank"])
	}
	if wantMine {
		if mine["rank"] == nil || mine["score"] == nil {
			t.Fatalf("viewer my_rank = %#v", mine)
		}
		return
	}
	if len(mine) != 0 {
		t.Fatalf("viewer without a fact got my_rank %#v", mine)
	}
}

// TestI912DormRankMID301ServesTheStockWindow proves the reply the stock client
// needs for BUGS #125 through the production dispatcher and service: the
// rank_list nesting, every row field NewRankWindow reads, the viewer's own
// rank, an empty board, and a viewer with no dorm root. BUGS #125 reported the
// client stuck on its loading popup while MID 301 answered 200; this test shows
// the reply is complete and renderable on this base.
func TestI912DormRankMID301ServesTheStockWindow(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	server := rankingServer(t, p)
	first := rankingActor(t, p, server, true)
	second := rankingActor(t, p, server, true)
	noDorm := rankingActor(t, p, server, true)
	comfortRooms(t, p, first.PlayerID, revision, map[int64]int64{1: 30})
	comfortRooms(t, p, second.PlayerID, revision, map[int64]int64{1: 12, 2: 8})
	service := comfortRankingService(p)
	if service.Comfort == nil {
		t.Fatal("comfort provider is not composed")
	}
	dispatcher := stockruntime.RankingDispatcher{Authority: bearerAuthority{string(first.AccountUID): first, string(second.AccountUID): second, string(noDorm.AccountUID): noDorm}, Service: service}

	r7Dispatch(t, dispatcher, first)
	info := r7Dispatch(t, dispatcher, second)
	assertDormComfortInfo(t, info, 2, true)
	rows := info["rank_info"].([]map[string]any)
	if rows[0]["player_id"] != int64(first.PlayerID) || rows[0]["comfort"] != int64(30) || rows[1]["player_id"] != int64(second.PlayerID) || rows[1]["comfort"] != int64(20) {
		t.Fatalf("board order/values %#v", rows)
	}

	noDormInfo := r7Dispatch(t, dispatcher, noDorm)
	assertDormComfortInfo(t, noDormInfo, 2, false)

	emptyServer := rankingServer(t, p)
	emptyViewer := rankingActor(t, p, emptyServer, true)
	emptyDispatcher := stockruntime.RankingDispatcher{Authority: bearerAuthority{string(emptyViewer.AccountUID): emptyViewer}, Service: service}
	assertDormComfortInfo(t, r7Dispatch(t, emptyDispatcher, emptyViewer), 0, false)
}
