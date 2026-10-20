package stockruntime

import (
	"context"
	"encoding/json"
	"reflect"
	"testing"
	"time"

	app "gxb.local/backend/v2/internal/application/oneonone"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/oneonone"
	"gxb.local/backend/v2/internal/foundation/operation"
)

type oneOnOneFake struct {
	teams  []d.Team
	start  app.StartCommand
	closed bool
	calls  int
}

var oneOnOneRanked = d.Ranked{Standing: d.Standing{Player: 200007, Server: 2, Position: d.Position{Level: d.LevelSenior, Slot: 512, Points: 4700}}, Global: 512, InGroup: 12, ServerRank: 3}

func (f *oneOnOneFake) arena() d.ArenaView {
	at := time.Unix(1700000000, 0)
	return d.ArenaView{Player: d.Player{TriesLeft: 7, Purchases: 1, LastFightAt: &at, Mode: d.ModeNormal, Teams: []d.Team{{Heroes: []int64{3, 4}, Pet: 9}, {Heroes: []int64{5}}}}, Ranked: oneOnOneRanked, ServerTime: at}
}
func (f *oneOnOneFake) Load(context.Context, identity.ActorContext, operation.Context) (d.ArenaView, error) {
	f.calls++
	return f.arena(), nil
}
func (f *oneOnOneFake) ChangeTeams(_ context.Context, _ identity.ActorContext, teams []d.Team, _ operation.Context) error {
	f.calls++
	f.teams = teams
	return nil
}
func (f *oneOnOneFake) Match(context.Context, identity.ActorContext, operation.Context) ([]d.Entry, error) {
	return []d.Entry{{Face: d.Face{Player: 200007, Name: "rival", Level: 60}, Ranked: oneOnOneRanked}}, nil
}
func (f *oneOnOneFake) EnemyTeam(context.Context, identity.PlayerID) ([]d.TeamView, error) {
	return []d.TeamView{{Heroes: []map[string]any{{"table_id": int64(11001)}}}, {}}, nil
}
func (f *oneOnOneFake) Start(_ context.Context, _ identity.ActorContext, r app.StartCommand, _ operation.Context) (d.MatchView, error) {
	f.calls++
	f.start = r
	if f.closed {
		return d.MatchView{}, d.ErrClosedHours
	}
	return d.MatchView{Arena: f.arena(), ReportKeys: []string{"a", "", "c"}, Wins: []int64{1, 1}, Win: true}, nil
}
func (f *oneOnOneFake) Report(context.Context, string) ([]byte, error) {
	return []byte(`{"star":1}`), nil
}
func (f *oneOnOneFake) DefenseReportKeys(context.Context, identity.ActorContext) ([]string, error) {
	return []string{"k1"}, nil
}
func (f *oneOnOneFake) BuyTimes(context.Context, identity.ActorContext, operation.Context) (d.Player, error) {
	return d.Player{TriesLeft: 10, Purchases: 2}, nil
}
func (f *oneOnOneFake) Records(context.Context, identity.ActorContext) ([]d.RecordView, error) {
	return []d.RecordView{{Record: d.Record{ID: 5, Win: true, Mode: d.ModePromotion, At: time.Unix(1700000000, 0)}, Attacker: d.Face{Player: 100001}, Defender: d.Face{Player: 200007}}}, nil
}
func (f *oneOnOneFake) ResetTime(context.Context, identity.ActorContext, operation.Context) (d.Player, error) {
	return d.Player{TriesLeft: 7}, nil
}
func (f *oneOnOneFake) RecordDetail(_ context.Context, id int64) (d.RecordDetail, error) {
	if id == 404 {
		return d.RecordDetail{}, d.ErrRefused
	}
	return d.RecordDetail{ReportKeys: []string{"a"}, Wins: []int64{1}, Attack: []d.TeamView{{}}, Defense: []d.TeamView{{}}}, nil
}

func TestI7C5COneOnOneWireShapes(t *testing.T) {
	f := &oneOnOneFake{}
	dispatcher := OneOnOneDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: f}
	n := func(v string) json.Number { return json.Number(v) }
	call := func(mid uint16, p map[string]any) map[string]any {
		t.Helper()
		r := dispatcher.Dispatch(context.Background(), heroReq(t, mid, p))
		if r.HTTPStatus != 200 {
			t.Fatal(mid, r)
		}
		return r.Body
	}
	load := call(2480, map[string]any{})
	rank, base := load["rank_info"].(map[string]any), load["base_info"].(map[string]any)
	if rank["rank_level"] != int64(2) || rank["rank"] != int64(512) || rank["region_rank"] != int64(3) || rank["rank_point"] != int64(4700) || base["left_times"] != int64(7) ||
		base["last_fight_time"] != int64(1700000000) || base["mode"] != int64(1) || !reflect.DeepEqual(load["defense"], []string{"3|4@9", "5"}) {
		t.Fatal("LOAD_PEAK_ARENA", load)
	}
	call(2481, map[string]any{"formations": []any{"3|4@9", "5", "6"}})
	if !reflect.DeepEqual(f.teams, []d.Team{{Heroes: []int64{3, 4}, Pet: 9}, {Heroes: []int64{5}}, {Heroes: []int64{6}}}) {
		t.Fatal("PEAK_CHANGE_TEAMS", f.teams)
	}
	match := call(2482, map[string]any{})["match_infos"].([]map[string]any)[0]
	if match["player_info"].(map[string]any)["player_id"] != int64(200007) || match["rank_info"].(map[string]any)["rank"] != int64(512) {
		t.Fatal("MATCH_ENEMIES", match)
	}
	defense := call(2483, map[string]any{"enemy_id": n("200007")})["defense"].([]map[string]any)
	if len(defense) != 2 || len(defense[1]["formation_info"].([]map[string]any)) != 0 {
		t.Fatal("GET_ENEMY_TEAM hidden teams render empty", defense)
	}
	started := call(2484, map[string]any{"formations": []any{"3", "4"}, "enemy_id": n("200007")})
	if f.start.Enemy != 200007 || len(f.start.Formations) != 2 || started["is_win"] != int64(1) || !reflect.DeepEqual(started["wins"], []int64{1, 1}) || !reflect.DeepEqual(started["report_keys"], []string{"a", "", "c"}) {
		t.Fatal("PEAK_START_FIGHT", started)
	}
	f.closed = true
	if call(2484, map[string]any{"formations": []any{"3"}, "enemy_id": n("200007")})["error_code"] != int64(30002) {
		t.Fatal("closed hours answer in-band 30002")
	}
	if call(2485, map[string]any{"report_key": "a"})["report"] != `{"star":1}` {
		t.Fatal("PEAK_RECORDS report")
	}
	if r := dispatcher.Dispatch(context.Background(), heroReq(t, 2485, map[string]any{})); r.HTTPStatus != 200 || !reflect.DeepEqual(r.JSON, []map[string]any{{"report_key": "k1"}}) {
		t.Fatal("PEAK_RECORDS list is a bare array", r)
	}
	record := call(2487, map[string]any{})["battle_records"].([]map[string]any)[0]
	if record["record_id"] != int64(5) || record["is_win"] != int64(1) || record["mode"] != int64(2) || record["attack_player_info"].(map[string]any)["player_id"] != int64(100001) {
		t.Fatal("PEAK_RECORDS_LIST", record)
	}
	if call(2486, map[string]any{})["left_times"] != int64(10) || call(2488, map[string]any{})["left_times"] != int64(7) {
		t.Fatal("buy / reset")
	}
	if len(call(2489, map[string]any{"record_id": n("404"), "player_id": n("100001")})) != 0 || call(2489, map[string]any{"record_id": n("5")})["wins"] == nil {
		t.Fatal("PEAK_RECORDS_DETAIL")
	}
	before := f.calls
	for _, bad := range []struct {
		mid uint16
		p   map[string]any
	}{{2484, map[string]any{"formations": []any{"3|x"}, "enemy_id": n("7")}}, {2484, map[string]any{"formations": "3"}}, {2481, map[string]any{"formations": []any{3}}}, {2480, map[string]any{"rank": n("1")}}} {
		if r := dispatcher.Dispatch(context.Background(), heroReq(t, bad.mid, bad.p)); r.HTTPStatus != 400 {
			t.Fatal("invalid request accepted", bad, r)
		}
	}
	if f.calls != before {
		t.Fatal("invalid request reached the owner")
	}
}
