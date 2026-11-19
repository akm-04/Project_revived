package stockruntime

import (
	"context"
	"encoding/json"
	"reflect"
	"testing"
	"time"

	app "gxb.local/backend/v2/internal/application/arena"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/replyconformance"
)

type arenaFake struct {
	fight          app.FightCommand
	unresolved     bool
	fightErr       error
	partnerErr     error
	partnerSubject identity.PlayerID
	calls          int
}

var arenaPlayer = d.Player{PlayerID: 100001, Season: 33, Star: 12, Point: 0, TotalFight: 4, WinTimes: 3, KeepWin: 2, DailyFights: 4, Defense: d.Lineup{Heroes: []int64{1, 2, 3, 4, 5}, Pet: 9},
	Missions: []d.MissionSlot{{MissionID: 1004, Current: 2, Complete: true}}, MissionTime: time.Unix(1700000000, 0), ExchangeTimes: [3]int64{1, 0, 2}, Awards: []d.Award{{TableID: 11001, AddStar: 1, Summon: true}}}

func (f *arenaFake) Info(context.Context, identity.ActorContext, operation.Context) (d.InfoView, error) {
	f.calls++
	return d.InfoView{Player: arenaPlayer, Season: d.Season{Number: 33, OpensAt: time.Unix(1700000000, 0)}, Rank: 7, Total: 20, KingCoin: 640, At: time.Unix(1700000000+2*86400, 0)}, nil
}
func (f *arenaFake) Partners(_ context.Context, _ identity.ActorContext, subject identity.PlayerID, _ operation.Context) (d.PartnersView, error) {
	f.partnerSubject = subject
	if f.partnerErr != nil {
		return d.PartnersView{}, f.partnerErr
	}
	star := int64(4)
	return d.PartnersView{Player: arenaPlayer, Usage: []d.Usage{{TableID: 11001, Fights: 2, Wins: 1, Kills: 3, Harms: "1200.500000", Star: &star}}}, nil
}
func (f *arenaFake) ModifyDefence(_ context.Context, _ identity.ActorContext, heroes []int64, pet int64, _ operation.Context) (d.Player, error) {
	f.calls++
	return d.Player{Defense: d.Lineup{Heroes: heroes, Pet: pet}}, nil
}
func (f *arenaFake) Match(context.Context, identity.ActorContext, bool, operation.Context) (d.EnemyView, error) {
	return d.EnemyView{Face: d.Face{Player: 200007, Name: "rival", Server: 2, ServerName: "S2"}, Standing: d.Standing{WinTimes: 3, TotalFight: 5}, Heroes: []map[string]any{{"table_id": int64(11001)}}, SelfServerName: "S1"}, nil
}
func (f *arenaFake) Start(context.Context, identity.ActorContext, operation.Context) error {
	f.calls++
	return nil
}
func (f *arenaFake) Fight(_ context.Context, _ identity.ActorContext, r app.FightCommand, _ operation.Context) (d.FightView, error) {
	f.calls++
	f.fight = r
	if f.fightErr != nil {
		return d.FightView{}, f.fightErr
	}
	if f.unresolved {
		return d.FightView{}, app.ErrUnresolved
	}
	return d.FightView{Win: true, Report: json.RawMessage(`{"star":1}`), Player: arenaPlayer, Coins: 50, RegionCoin: 150}, nil
}
func (f *arenaFake) Stop(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (d.Player, error) {
	return d.Player{Star: 11}, nil
}
func (f *arenaFake) Records(context.Context, identity.ActorContext, operation.Context) ([]d.RecordView, error) {
	return []d.RecordView{{Record: d.Record{Win: true, At: time.Unix(1700000000, 0)}, Opponent: d.Face{Player: 200007, Name: "rival"}, ReportKey: "k1"}}, nil
}
func (f *arenaFake) Report(_ context.Context, key string, _ operation.Context) ([]byte, bool, error) {
	return []byte(`{"star":1}`), key == "k1", nil
}
func (f *arenaFake) GiveUpMission(context.Context, identity.ActorContext, int64, operation.Context) (d.MissionsView, error) {
	return d.MissionsView{Player: arenaPlayer, KingCoin: 640}, nil
}
func (f *arenaFake) ClaimMission(context.Context, identity.ActorContext, int64, operation.Context) (d.MissionsView, error) {
	return d.MissionsView{Player: arenaPlayer, KingCoin: 760, Coins: 120}, nil
}
func (f *arenaFake) Exchange(context.Context, identity.ActorContext, int64, int64, operation.Context) (d.MissionsView, error) {
	return d.MissionsView{Player: arenaPlayer, KingCoin: 370, Award: &d.Award{TableID: 11001, AddStar: 2}}, nil
}

func TestI7C5DArenaWireShapes(t *testing.T) {
	f := &arenaFake{}
	dispatcher := ArenaDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: f}
	n := func(v string) json.Number { return json.Number(v) }
	call := func(mid uint16, p map[string]any) map[string]any {
		t.Helper()
		r := Decorated{Next: dispatcher}.Dispatch(context.Background(), heroReq(t, mid, p))
		if r.HTTPStatus != 200 {
			t.Fatal(mid, r)
		}
		return r.Body
	}
	direct := dispatcher.Dispatch(context.Background(), heroReq(t, 849, map[string]any{"mission_id": n("1004")}))
	if _, written := direct.Body["economy_"]; written {
		t.Fatalf("dispatcher assembled economy_: %#v", direct.Body)
	}
	info := call(768, map[string]any{})
	if info["star"] != int64(12) || info["my_rank"] != int64(7) || info["count"] != int64(33) || info["day_count"] != int64(3) || info["king_coin"] != int64(640) || info["is_close"] != int64(0) ||
		info["exchange_times_3"] != int64(2) || !reflect.DeepEqual(info["defence_formation"], []int64{1, 2, 3, 4, 5}) || info["pet_id"] != int64(9) || info["mission_time"] != int64(1700000000) {
		t.Fatal("GET_REARENA_INFO", info)
	}
	if partners := call(769, map[string]any{}); partners["partner_info"].([]map[string]any)[0]["total_damage"] != int64(1200) ||
		partners["partner_info"].([]map[string]any)[0]["star"] != int64(4) {
		t.Fatal("GET_REARENA_PARTNERS", partners)
	} else {
		replyconformance.Check(t, 769, partners)
	}
	if saved := call(770, map[string]any{"heros": []any{n("1"), n("2"), n("3"), n("4"), n("5")}, "pet_id": n("9")}); saved["pet_id"] != int64(9) {
		t.Fatal("REARENA_MODIFY_DEFENCE", saved)
	}
	if enemy := call(771, map[string]any{"is_practice": n("1")}); enemy["player_id"] != int64(200007) || enemy["region_name"] != "S2" || enemy["self_region_name"] != "S1" || enemy["total_fight"] != int64(5) {
		t.Fatal("REARENA_MATCH_ENEMY", enemy)
	} else {
		replyconformance.Check(t, 771, enemy)
	}
	if call(772, map[string]any{})["is_back_battle"] != int64(1) {
		t.Fatal("REARENA_START_FIGHT answers a server battle")
	}
	fight := call(773, map[string]any{"enemy_id": n("200007"), "is_test": n("0"), "formation": []any{n("11001"), n("11002")}, "pet_id": n("0")})
	if f.fight.Enemy != 200007 || len(f.fight.Formation) != 2 || fight["is_win"] != int64(1) || fight["battle_report"].([]map[string]any)[0]["content"] != `{"star":1}` ||
		fight["arena_info"].(map[string]any)["star"] != int64(12) || fight["economy_"].(map[string]any)["region_coin"] != int64(150) {
		t.Fatal("REARENA_FIGHT", fight)
	}
	f.unresolved = true
	if retry := call(773, map[string]any{"enemy_id": n("200007"), "formation": []any{n("11001")}}); len(retry["battle_report"].([]any)) != 0 {
		t.Fatal("unresolved FIGHT answers an empty battle_report", retry)
	}
	if records := call(776, map[string]any{})["records"].([]map[string]any); records[0]["win"] != int64(1) || records[0]["report_key"] != "k1" {
		t.Fatal("REARENA_FIGHT_RECORDS", records)
	}
	if report := call(777, map[string]any{"report_key": "k1"}); report["report"].([]map[string]any)[0]["content"] != `{"star":1}` {
		t.Fatal("REARENA_FIGHT_REPORT", report)
	}
	if len(call(777, map[string]any{"report_key": "gone"})) != 0 {
		t.Fatal("expired report answers empty")
	}
	if call(779, map[string]any{"enemy_id": n("200007")})["star"] != int64(11) {
		t.Fatal("REARENA_STOP_FIGHT")
	}
	claim := call(849, map[string]any{"mission_id": n("1004")})
	if claim["awards"].([]map[string]any)[0]["king_coin"] != int64(120) || claim["economy_"].(map[string]any)["king_coin"] != int64(760) || claim["mission_time"] != int64(1700000000) {
		t.Fatal("GET_MISSION_AWARD", claim)
	}
	if exchange := call(848, map[string]any{"exchange_type": n("1"), "table_id": n("11001")}); exchange["award"].(map[string]any)["add_star"] != int64(2) {
		t.Fatal("GET_EXCHANGE_AWARD", exchange)
	}
	before := f.calls
	for _, bad := range []struct {
		mid uint16
		p   map[string]any
	}{{773, map[string]any{"formation": []any{n("1")}}}, {771, map[string]any{"is_practice": n("2")}}, {770, map[string]any{"heros": "1|2"}}, {768, map[string]any{"x": n("1")}}, {774, map[string]any{}}} {
		if r := dispatcher.Dispatch(context.Background(), heroReq(t, bad.mid, bad.p)); r.HTTPStatus != 400 {
			t.Fatal("invalid request accepted", bad, r)
		}
	}
	if f.calls != before {
		t.Fatal("invalid request reached the owner")
	}
}

func TestArenaPartnersReadsTheRequestedSubject(t *testing.T) {
	f := &arenaFake{}
	dispatcher := ArenaDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: f}
	number := func(v string) json.Number { return json.Number(v) }
	call := func(params map[string]any) httpedge.Response {
		return dispatcher.Dispatch(context.Background(), heroReq(t, 769, params))
	}
	if r := call(map[string]any{}); r.HTTPStatus != 200 || f.partnerSubject != 100001 {
		t.Fatal("own History without player_id", r, f.partnerSubject)
	}
	if r := call(map[string]any{"player_id": number("100001")}); r.HTTPStatus != 200 || f.partnerSubject != 100001 {
		t.Fatal("own History with player_id", r, f.partnerSubject)
	}
	if r := call(map[string]any{"player_id": number("200007")}); r.HTTPStatus != 200 || f.partnerSubject != 200007 {
		t.Fatal("another player's History", r, f.partnerSubject)
	}
	f.partnerErr = d.ErrRefused
	if r := call(map[string]any{"player_id": number("200008")}); r.HTTPStatus != 409 || r.Body["error_code"] != unprovenRefusalCode {
		t.Fatal("unknown subject is not the arena refusal", r)
	}
	f.partnerErr = nil
	before := f.calls
	if r := call(map[string]any{"player_id": number("200007"), "other": number("1")}); r.HTTPStatus != 400 || f.calls != before {
		t.Fatal("a foreign request key reached the owner", r)
	}
}

// D507/D426: FIGHT refusals answer stock 409 codes; malformed stays 400.
func TestD507ArenaFightRefusals(t *testing.T) {
	f := &arenaFake{}
	dispatcher := ArenaDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: f}
	n := func(v string) json.Number { return json.Number(v) }
	call := func(p map[string]any) httpedge.Response {
		return dispatcher.Dispatch(context.Background(), heroReq(t, 773, p))
	}
	params := func(formation []any) map[string]any {
		return map[string]any{"enemy_id": n("200007"), "is_test": n("0"), "pet_id": n("0"), "campaign_id": n("0"), "formation": formation}
	}
	for _, tc := range []struct {
		err    error
		status int
		code   int64
	}{
		{app.ErrNoTeam, 409, 35006},
		{d.ErrRefused, 409, 30023},
		{d.ErrClosed, 409, 31004},
		{d.ErrInvalid, 400, 0},
	} {
		f.fightErr = tc.err
		response := call(params([]any{n("11001")}))
		if response.HTTPStatus != tc.status {
			t.Fatal(tc.err, response)
		}
		if tc.code != 0 && response.Body["error_code"] != tc.code {
			t.Fatal(tc.err, response)
		}
	}
	f.fightErr = app.ErrNoTeam
	empty := call(params([]any{}))
	if empty.HTTPStatus != 409 || empty.Body["error_code"] != int64(35006) {
		t.Fatal("an empty formation is a stock no-team refusal", empty)
	}
	before := f.calls
	if malformed := call(map[string]any{"formation": []any{}}); malformed.HTTPStatus != 400 || f.calls != before {
		t.Fatal("a malformed FIGHT stays 400 without reaching the owner", malformed)
	}
}
