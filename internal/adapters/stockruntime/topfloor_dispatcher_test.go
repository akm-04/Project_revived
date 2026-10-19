package stockruntime

import (
	"context"
	"encoding/json"
	"reflect"
	"testing"
	"time"

	app "gxb.local/backend/v2/internal/application/topfloor"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/operation"
)

type topFloorFake struct {
	start   app.StartCommand
	defense []int64
	pet     int64
	report  []byte
	calls   int
}

var topFloorRobot = d.Display{Occupant: d.Occupant{Robot: 7}, Rank: 9, Name: "Hoper Bao", Level: 6, AvatarID: 110001001, FrameID: 120001001, Heroes: []map[string]any{{"partner_id": int64(10001002), "table_id": int64(10001002)}}}

func (f *topFloorFake) Load(context.Context, identity.ActorContext, operation.Context) (app.ArenaView, error) {
	f.calls++
	at := time.Unix(1700000000, 0)
	return app.ArenaView{Player: d.Player{BestRank: 9, TicketsLeft: 4, Purchases: 1, LastMatchAt: &at, Defense: []int64{3}, Fights: 2}, Rank: 10, Enemies: []d.Display{topFloorRobot}, ServerTime: at}, nil
}
func (f *topFloorFake) Refresh(c context.Context, a identity.ActorContext, o operation.Context) (app.ArenaView, error) {
	return f.Load(c, a, o)
}
func (f *topFloorFake) SaveDefense(_ context.Context, _ identity.ActorContext, heroes []int64, pet int64, _ operation.Context) error {
	f.calls++
	f.defense, f.pet = heroes, pet
	return nil
}
func (f *topFloorFake) PreFight(context.Context, identity.ActorContext, int64) error { return nil }
func (f *topFloorFake) Start(_ context.Context, _ identity.ActorContext, r app.StartCommand, _ operation.Context) (app.FightView, error) {
	f.calls++
	f.start = r
	return app.FightView{Formation: []map[string]any{{"partner_id": int64(3)}}, Report: f.report, Win: true, AwardCrystal: 5, Enemy: topFloorRobot}, nil
}
func (f *topFloorFake) BuyTicket(context.Context, identity.ActorContext, operation.Context) (d.Player, error) {
	return d.Player{TicketsLeft: 5, Purchases: 1}, nil
}
func (f *topFloorFake) ResetTimer(context.Context, identity.ActorContext, operation.Context) (d.Player, error) {
	return d.Player{TicketsLeft: 3}, nil
}
func (f *topFloorFake) Records(context.Context, identity.ActorContext) ([]app.RecordView, error) {
	return []app.RecordView{{Record: d.Record{ID: 4, Attack: false, Win: false, At: time.Unix(1700000000, 0)}, Self: d.Display{Name: "me"}, Opponent: d.Display{Name: "them"}}}, nil
}
func (f *topFloorFake) Report(context.Context, string) ([]byte, error) { return f.report, nil }
func (f *topFloorFake) RecordInfo(context.Context, identity.ActorContext, int64) (app.RecordInfo, d.Record, error) {
	return app.RecordInfo{Opponent: topFloorRobot, AvengeType: 3}, d.Record{}, nil
}
func (f *topFloorFake) Formation(context.Context, identity.ActorContext, int64) (d.Display, error) {
	return topFloorRobot, nil
}

func TestI7C5BTopFloorWireShapes(t *testing.T) {
	f := &topFloorFake{}
	dispatcher := TopFloorDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: f}
	n := func(v string) json.Number { return json.Number(v) }
	call := func(mid uint16, p map[string]any) map[string]any {
		t.Helper()
		r := dispatcher.Dispatch(context.Background(), heroReq(t, mid, p))
		if r.HTTPStatus != 200 {
			t.Fatal(mid, r)
		}
		return r.Body
	}
	load := call(272, map[string]any{})
	for _, key := range []string{"rank", "best_rank", "defense", "left_time", "buy_num", "last_match_time", "update_count", "enemies", "pet_id", "server_time", "ban_hero_id", "is_ban_open", "set_formation_time", "fight_times"} {
		if _, ok := load[key]; !ok {
			t.Fatal("LOAD_ARENA missing", key)
		}
	}
	enemy := load["enemies"].([]map[string]any)[0]
	if enemy["table_id"] != int64(7) || enemy["player_name"] != "Hoper Bao" || load["last_match_time"] != int64(1700000000) {
		t.Fatal("enemy row", enemy)
	}
	if _, ok := call(273, map[string]any{})["enemies"]; !ok {
		t.Fatal("player list")
	}
	call(278, map[string]any{"heroIDs": []any{n("3"), n("4")}, "pet_id": n("2")})
	if !reflect.DeepEqual(f.defense, []int64{3, 4}) || f.pet != 2 {
		t.Fatal("defense", f.defense)
	}
	pending := call(280, map[string]any{"formation": "3|4", "enemy_id": n("7"), "is_avenge": n("0"), "campaign_type": n("3"), "campaign_id": n("0")})
	if !reflect.DeepEqual(f.start, app.StartCommand{Formation: []int64{3, 4}, Enemy: 7}) || len(pending["battle_report"].([]map[string]any)) != 0 {
		t.Fatal("pending start", f.start, pending)
	}
	f.report = []byte(`{"star":1}`)
	done := call(280, map[string]any{"formation": n("3"), "enemy_id": n("7"), "is_avenge": n("1")})
	if done["battle_report"].([]map[string]any)[0]["content"] != `{"star":1}` || done["is_win"] != int64(1) || done["award_crystal"] != int64(5) || done["enemy_formation"].(map[string]any)["is_robot"] != true || !f.start.Avenge {
		t.Fatal("finished start", done)
	}
	if call(281, map[string]any{})["left_time"] != int64(5) || call(288, map[string]any{})["last_match_time"] != int64(0) {
		t.Fatal("tickets")
	}
	record := call(289, map[string]any{})["records"].([]map[string]any)[0]
	if record["attack_name"] != "them" || record["defend_name"] != "me" || record["is_attack"] != int64(0) {
		t.Fatal("defense record sides", record)
	}
	if call(290, map[string]any{"player_id": n("1"), "report_key": "k"})["report"] == nil {
		t.Fatal("report")
	}
	f.report = nil
	if len(call(290, map[string]any{"player_id": n("1"), "report_key": "k"})) != 0 {
		t.Fatal("expired report must be empty")
	}
	if call(293, map[string]any{"id": n("4")})["records"].(map[string]any)["avenge_type"] != int64(3) || call(291, map[string]any{"other_player_id": n("100007")})["table_id"] != int64(7) {
		t.Fatal("record info / formation")
	}
	call(294, map[string]any{"enemy_id": n("7")})
	before := f.calls
	for _, bad := range []struct {
		mid uint16
		p   map[string]any
	}{{280, map[string]any{"formation": "3|x", "enemy_id": n("7")}}, {280, map[string]any{"formation": "3", "enemy_id": n("7"), "campaign_type": n("9")}}, {280, map[string]any{"formation": "3"}}, {278, map[string]any{"heroIDs": "3"}}, {272, map[string]any{"rank": n("1")}}} {
		if r := dispatcher.Dispatch(context.Background(), heroReq(t, bad.mid, bad.p)); r.HTTPStatus != 400 {
			t.Fatal("invalid request accepted", bad, r)
		}
	}
	if f.calls != before {
		t.Fatal("invalid request reached the owner")
	}
	if r := dispatcher.Dispatch(context.Background(), heroReq(t, 292, map[string]any{"table_id": n("1")})); r.HTTPStatus != 400 {
		t.Fatal("seal hero must stay closed", r)
	}
}
