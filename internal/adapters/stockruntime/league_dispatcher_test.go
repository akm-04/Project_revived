package stockruntime

import (
	"context"
	"encoding/json"
	app "gxb.local/backend/v2/internal/application/championsleague"
	d "gxb.local/backend/v2/internal/domain/championsleague"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"testing"
	"time"
)

type leagueFake struct {
	last    app.Command
	calls   int
	pending bool
}

func (f *leagueFake) Execute(_ context.Context, _ identity.ActorContext, c app.Command, _ operation.Context) (app.Reply, error) {
	f.last = c
	f.calls++
	v := app.Reply{Info: d.InfoView{Player: d.Player{Season: 150, Group: 3, Points: 2000}, Rank: 1, At: time.Unix(1800000000, 0), Active: true}, Enemy: d.EnemyView{Face: d.Face{ID: 200007}, Heroes: []map[string]any{{"partner_id": int64(19)}}}, Match: d.Match{SelfRows: []map[string]any{{"partner_id": int64(7)}}, EnemyRows: []map[string]any{{"partner_id": int64(19)}}, Win: true}, Report: []byte(`{"star":1}`), Honor: []d.SettlementRow{{Placement: d.Placement{Rank: 1}}}}
	if f.pending {
		v.Report = nil
	}
	return v, nil
}
func TestI7C5FLeagueSourceWireAndInstanceParsing(t *testing.T) {
	f := &leagueFake{}
	s := LeagueDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: f}
	n := func(s string) json.Number { return json.Number(s) }
	call := func(mid uint16, p map[string]any) map[string]any {
		t.Helper()
		r := s.Dispatch(context.Background(), heroReq(t, mid, p))
		if r.HTTPStatus != 200 {
			t.Fatal(mid, r)
		}
		return r.Body
	}
	info := call(2800, map[string]any{})
	if info["stage"] != int64(1) || info["base_info"].(map[string]any)["season_count"] != int64(150) {
		t.Fatal("real season count", info)
	}
	enemy := call(2801, map[string]any{"enemy_id": n("200007")})
	if enemy["player_id"] != int64(200007) {
		t.Fatal(enemy)
	}
	fight := call(2802, map[string]any{"enemy_id": n("200007"), "formation": "7|8", "pet_id": n("9")})
	if f.last.Lineup.Heroes[0] != 7 || f.last.Lineup.Pet != 9 || fight["battle_report"].([]map[string]any)[0]["content"] != `{"star":1}` {
		t.Fatal("owned instances/report", fight)
	}
	f.pending = true
	retry := call(2802, map[string]any{"enemy_id": n("200007"), "formation": "7"})
	if retry["report_key"] != "" || len(retry["battle_report"].([]map[string]any)) != 0 {
		t.Fatal("pending retry", retry)
	}
	call(2803, map[string]any{})
	if f.last.Kind != "RECORDS" {
		t.Fatal(f.last)
	}
	if len(call(2803, map[string]any{"id": n("123")})) != 0 || f.last.RecordID != 123 {
		t.Fatal("expired replay")
	}
	call(2804, map[string]any{})
	if f.last.Kind != "CLAIM" {
		t.Fatal(f.last)
	}
	call(2805, map[string]any{"formation": ""})
	if f.last.Kind != "DEFENSE" || len(f.last.Lineup.Heroes) != 0 {
		t.Fatal("empty preference", f.last)
	}
	call(2806, map[string]any{"use_ori_rank": n("1")})
	if !f.last.UseOriginal {
		t.Fatal("prior choice")
	}
	r := s.Dispatch(context.Background(), heroReq(t, 2807, map[string]any{}))
	if r.HTTPStatus != 200 || len(r.JSON.([]map[string]any)) != 1 {
		t.Fatal("flat honor array", r)
	}
	before := f.calls
	for _, p := range []map[string]any{{"enemy_id": n("200007"), "formation": "7|7"}, {"enemy_id": n("200007"), "formation": []any{n("7")}}, {"enemy_id": n("200007"), "formation": "7", "is_win": n("1")}, {"enemy_id": n("200007"), "formation": "7", "battle_report": "forged"}, {"enemy_id": n("200007"), "formation": "9007199254740992"}} {
		if r := s.Dispatch(context.Background(), heroReq(t, 2802, p)); r.HTTPStatus == 200 {
			t.Fatal("spoof/malformed accepted", p)
		}
	}
	if f.calls != before {
		t.Fatal("invalid request reached owner")
	}
}
