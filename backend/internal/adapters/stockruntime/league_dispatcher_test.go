package stockruntime

import (
	"context"
	"encoding/json"
	app "gxb.local/backend/v2/internal/application/championsleague"
	d "gxb.local/backend/v2/internal/domain/championsleague"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/replyconformance"
	"net/http"
	"testing"
	"time"
)

type leagueFake struct {
	last    app.Command
	calls   int
	pending bool
	records []d.Match
}

func (f *leagueFake) Execute(_ context.Context, _ identity.ActorContext, c app.Command, _ operation.Context) (app.Reply, error) {
	f.last = c
	f.calls++
	v := app.Reply{Info: d.InfoView{Player: d.Player{Season: 150, Group: 3, Points: 2000}, Rank: 1, At: time.Unix(1800000000, 0), Active: true, Defense: d.EnemyView{Heroes: []map[string]any{{"partner_id": int64(19)}}, Pet: map[string]any{"pet_id": int64(5)}, Lineup: d.Lineup{Heroes: []int64{19}, Pet: 5}}}, Enemy: d.EnemyView{Face: d.Face{ID: 200007}, Heroes: []map[string]any{{"partner_id": int64(19)}}}, Match: d.Match{SelfRows: []map[string]any{{"partner_id": int64(7)}}, EnemyRows: []map[string]any{{"partner_id": int64(19)}}, Win: true}, Report: []byte(`{"star":1}`), Honor: []d.SettlementRow{{Placement: d.Placement{Rank: 1}}}}
	v.Records = f.records
	if f.pending {
		v.Report = nil
	}
	return v, nil
}
func TestI9_12LeagueCanonicalConflictRefusal(t *testing.T) {
	response := failLeague(d.ErrConflict)
	if response.HTTPStatus != http.StatusConflict || response.Body["error_code"] != unprovenRefusalCode || response.Body["error_msg"] != "" {
		t.Fatalf("a real canonical conflict is 409/%d (I9_11_CLOCK_ROLLBACK_V1 K5), got %d %#v", unprovenRefusalCode, response.HTTPStatus, response.Body)
	}
}

func TestI7C5FLeagueSourceWireAndInstanceParsing(t *testing.T) {
	f := &leagueFake{}
	actor := actorForHTTP(t)
	s := LeagueDispatcher{Authority: httpAuthority{actor}, Service: f}
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
	defense := info["defense_info"].(map[string]any)
	if heroes, ok := defense["heros"].([]int64); !ok || len(heroes) != 1 || heroes[0] != 19 {
		t.Fatalf("2800 defense_info.heros = %#v, want owned ids", defense["heros"])
	}
	if defense["pet"] != int64(5) {
		t.Fatalf("2800 defense_info.pet = %#v, want the numeric pet id", defense["pet"])
	}
	replyconformance.Check(t, 2800, info)
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
	settledAt := time.Unix(1800000000, 0)
	f.records = []d.Match{{WireID: 321, Attacker: actor.PlayerID, Defender: 200007, SettledAt: &settledAt, Win: true, Delta: 18, SelfFace: d.Face{Name: "Attacker", Avatar: 11, Frame: 12, Level: 90, Conquer: 3, Loop: 4}, EnemyFace: d.Face{Name: "Defender", Avatar: 21, Frame: 22, Level: 80, Conquer: 2, Loop: 3}}}
	recordResponse := s.Dispatch(context.Background(), heroReq(t, 2803, map[string]any{}))
	rows, ok := recordResponse.JSON.([]map[string]any)
	if recordResponse.HTTPStatus != 200 || recordResponse.Body != nil || !ok || len(rows) != 1 {
		t.Fatal("records must be a top-level client row array", recordResponse)
	}
	if f.last.Kind != "RECORDS" {
		t.Fatal(f.last)
	}
	for _, field := range []string{"id", "is_attack", "win", "change_point", "time", "attack_name", "defend_name", "attack_avatar", "defend_avatar", "attack_avatar_frame", "defend_avatar_frame", "attack_lev", "defend_lev", "attack_conquer_lev", "defend_conquer_lev", "attack_conquer_loop_id", "defend_conquer_loop_id"} {
		if _, exists := rows[0][field]; !exists {
			t.Fatalf("client record field %q missing from %#v", field, rows[0])
		}
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
