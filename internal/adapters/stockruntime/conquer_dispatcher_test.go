package stockruntime

import (
	"context"
	"encoding/json"
	"reflect"
	"testing"

	d "gxb.local/backend/v2/internal/domain/conquerschool"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
)

type conquerFake struct {
	result d.Result
	report json.RawMessage
	calls  int
}

var conquerInfo = d.InfoView{Run: d.Run{Loop: 2, CurrentID: 10002, PassedID: 10001}, Teams: 3,
	Mode: d.Mode{LeftTimes: 7, Buff: 2, AwardTimes: 1, BuyTimes: 3, BeatenTeams: []int64{2}, UsedHeroes: []int64{11, 12}, UsedPets: []int64{5}}}

func (f *conquerFake) Info(context.Context, identity.ActorContext, operation.Context) (d.InfoView, error) {
	f.calls++
	return conquerInfo, nil
}
func (f *conquerFake) Start(_ context.Context, _ identity.ActorContext, formation []int64, pet int64, _ operation.Context) (d.InfoView, error) {
	f.calls++
	f.result = d.Result{Formation: formation, Pet: pet}
	return conquerInfo, nil
}
func (f *conquerFake) Result(_ context.Context, _ identity.ActorContext, r d.Result, report json.RawMessage, _ operation.Context) (d.ResultView, error) {
	f.calls++
	f.result, f.report = r, report
	return d.ResultView{Info: conquerInfo, Promoted: true, Rewards: [][2]int64{{50001346, 1}}, Progress: d.Progress{Level: 2, Loop: 2}, Region: 5}, nil
}
func (f *conquerFake) Reports(context.Context, int64, int64, int64, operation.Context) ([]d.Report, error) {
	return []d.Report{{Key: "k1", Profile: d.ReportProfile{Name: "ada", Server: 3, ConquerLevel: 2}, Heroes: json.RawMessage(`[{"table_id":11001}]`), Pet: json.RawMessage(`{}`)}}, nil
}
func (f *conquerFake) Report(context.Context, identity.ActorContext, string, operation.Context) (d.Report, error) {
	return d.Report{Body: json.RawMessage(`{"fighter":{}}`)}, nil
}
func (f *conquerFake) Reset(context.Context, identity.ActorContext, operation.Context) (d.InfoView, error) {
	f.calls++
	return conquerInfo, nil
}
func (f *conquerFake) Buy(context.Context, identity.ActorContext, operation.Context) (d.InfoView, error) {
	f.calls++
	return conquerInfo, nil
}

func TestI7C5EConquerWireShapes(t *testing.T) {
	f := &conquerFake{}
	dispatcher := ConquerDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: f}
	n := func(v string) json.Number { return json.Number(v) }
	call := func(mid uint16, p map[string]any) map[string]any {
		t.Helper()
		r := dispatcher.Dispatch(context.Background(), heroReq(t, mid, p))
		if r.HTTPStatus != 200 {
			t.Fatal(mid, r)
		}
		return r.Body
	}
	for _, mid := range []uint16{1568, 1573, 2790} {
		info := call(mid, map[string]any{})["info"].(map[string]any)
		if info["conquer_loop_id"] != int64(2) || info["current_id"] != int64(10002) || info["left_times"] != int64(7) || info["is_buff_on"] != int64(2) ||
			info["buy_conquer_times"] != int64(3) || !reflect.DeepEqual(info["team_status"], []int64{0, 1, 0}) || !reflect.DeepEqual(info["used_heroes"], []int64{11, 12}) {
			t.Fatal(mid, info)
		}
	}
	call(1569, map[string]any{"formation": "11|12", "pet_id": n("5")})
	if !reflect.DeepEqual(f.result.Formation, []int64{11, 12}) || f.result.Pet != 5 {
		t.Fatal("START", f.result)
	}
	result := call(1570, map[string]any{"campaign_id": n("10002"), "team_id": n("1"), "is_win": true, "formation": "11|12", "report": `{"fighter":{}}`,
		"report_invalid": n("0"), "total_damage": n("1234.75"), "alive_num": n("2")})
	if f.result.Damage != 1234 || !f.result.Win || f.result.Alive != 2 || string(f.report) != `{"fighter":{}}` {
		t.Fatal("RESULT request", f.result)
	}
	if result["is_promote"] != true || result["conquer_lev"] != int64(2) || result["conquer_region"] != int64(5) || result["awards"].([]map[string]any)[0]["table_id"] != int64(50001346) {
		t.Fatal("RESULT", result)
	}
	reports := call(1571, map[string]any{"conquer_loop_id": n("2"), "campaign_id": n("10002"), "team_id": n("1")})["reports"].([]map[string]any)
	if reports[0]["report_key"] != "k1" || reports[0]["region"] != int64(3) || reports[0]["player_name"] != "ada" {
		t.Fatal("REPORT_LIST", reports)
	}
	if replay := call(1572, map[string]any{"report_key": "k1"})["report"].(map[string]any); replay["report"] != `{"fighter":{}}` {
		t.Fatal("REPORT", replay)
	}
	before := f.calls
	for _, bad := range []struct {
		mid uint16
		p   map[string]any
	}{{1568, map[string]any{"x": n("1")}}, {1569, map[string]any{"formation": "a|b"}}, {1570, map[string]any{"campaign_id": n("10002"), "team_id": n("1"), "is_win": true, "formation": "1", "report": "{", "alive_num": n("1"), "total_damage": n("1")}},
		{1570, map[string]any{"campaign_id": n("10002"), "team_id": n("1"), "is_win": true, "formation": "1", "report": "{}", "alive_num": n("1"), "total_damage": n("-1")}},
		{1571, map[string]any{"campaign_id": n("10002")}}, {1572, map[string]any{}}, {1574, map[string]any{}}} {
		if r := dispatcher.Dispatch(context.Background(), heroReq(t, bad.mid, bad.p)); r.HTTPStatus != 400 {
			t.Fatal("invalid request accepted", bad, r)
		}
	}
	if f.calls != before {
		t.Fatal("invalid request reached the owner")
	}
}
