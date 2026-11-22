package ranking

import (
	"testing"

	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/ranking"
)

func boardRowsFixture(count int) ([]d.ScoreRow, map[identity.PlayerID]d.BoardPresentation) {
	rows := make([]d.ScoreRow, 0, count)
	profiles := map[identity.PlayerID]d.BoardPresentation{}
	for i := 1; i <= count; i++ {
		player := identity.PlayerID(1000 + i)
		rows = append(rows, d.ScoreRow{Player: player, Score: int64((count - i + 1) * 10)})
		profiles[player] = d.BoardPresentation{Player: player, Name: "Player", Level: 10, AvatarID: 110001001}
	}
	return rows, profiles
}

func rankInfo(wire map[string]any) map[string]any {
	return wire["rank_list"].([]map[string]any)[0]["rank_info"].(map[string]any)
}

func TestBoardRowsKeepOrderFieldsAndValueKey(t *testing.T) {
	rows, profiles := boardRowsFixture(3)
	out, e := BoardRows(rows, profiles, "score")
	if e != nil || len(out) != 3 {
		t.Fatal(out, e)
	}
	if out[0]["rank"] != int64(1) || out[2]["rank"] != int64(3) || out[0]["score"] != int64(30) || out[0]["player_id"] != int64(1001) || out[0]["player_name"] != "Player" || out[0]["conquer_loop_id"] != int64(0) {
		t.Fatal(out[0])
	}
	if _, e = BoardRows(rows[:1], map[identity.PlayerID]d.BoardPresentation{}, "score"); e == nil {
		t.Fatal("published a row without its canonical profile")
	}
}

func TestBoardListCarriesViewerRankAtOnePastThePageOrAbsent(t *testing.T) {
	rows, profiles := boardRowsFixture(3)
	out, e := BoardRows(rows, profiles, "score")
	if e != nil {
		t.Fatal(e)
	}
	cases := []struct {
		name string
		mine map[string]any
		rank int64
	}{
		{"viewer at one", map[string]any{"rank": int64(1), "score": int64(30)}, 1},
		{"viewer past the page", map[string]any{"rank": int64(8), "score": int64(7)}, 8},
		{"viewer without a row", map[string]any{}, 0},
	}
	for _, c := range cases {
		info := rankInfo(BoardList(d.GirlsBoard.SubType, out, c.mine))
		got := info["my_rank"].(map[string]any)
		if len(got) != len(c.mine) || (c.rank > 0 && got["rank"] != c.rank) || len(info["rank_info"].([]map[string]any)) != 3 {
			t.Fatalf("%s: %v", c.name, info)
		}
	}
	empty := rankInfo(BoardList(d.GirlsBoard.SubType, []map[string]any{}, map[string]any{}))
	if len(empty["rank_info"].([]map[string]any)) != 0 || len(empty["my_rank"].(map[string]any)) != 0 {
		t.Fatal(empty)
	}
}
