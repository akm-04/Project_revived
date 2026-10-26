package stockruntime

import (
	"context"
	"encoding/json"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/operation"
	"testing"
	"time"
)

type awakeWireFake struct {
	action   string
	id, kind int64
	calls    int
}

func (f *awakeWireFake) ReadAwakening(context.Context, identity.ActorContext, operation.Context) (map[string]any, error) {
	f.calls++
	return map[string]any{"mission_list": []any{}}, nil
}
func (f *awakeWireFake) ChangeAwakening(_ context.Context, _ identity.ActorContext, action string, id, kind int64, _ operation.Context) (map[string]any, error) {
	f.action, f.id, f.kind = action, id, kind
	f.calls++
	return map[string]any{}, nil
}
func (f *awakeWireFake) ClaimAwakening(_ context.Context, _ identity.ActorContext, id int64, _ operation.Context) (map[string]any, bool, error) {
	f.calls++
	return map[string]any{"awakening_claim": id}, id == 1001001, nil
}
func TestAwakeningWireRoutesAndTrustBoundary(t *testing.T) {
	f := &awakeWireFake{}
	d := I5Dispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: &i5WireFake{}, Awakening: f}
	now := time.Unix(703, 0).UTC()
	for _, c := range []struct {
		mid    uint16
		action string
		kind   int64
	}{{163, "open", 1}, {164, "cancel", 1}, {165, "open", 3}, {166, "cancel", 3}, {167, "open", 2}, {168, "cancel", 2}} {
		got := d.Dispatch(context.Background(), i5Req(c.mid, map[string]any{"table_id": json.Number("1001001")}, now))
		if got.HTTPStatus != 200 || f.action != c.action || f.kind != c.kind || f.id != 1001001 {
			t.Fatalf("legacy %d: %+v fake=%+v", c.mid, got, f)
		}
	}
	for _, mid := range []uint16{2737, 2738} {
		got := d.Dispatch(context.Background(), i5Req(mid, map[string]any{"mission_id": json.Number("2001001"), "awake_type": json.Number("2")}, now))
		if got.HTTPStatus != 200 || f.kind != 2 || f.id != 2001001 {
			t.Fatalf("modern %d: %+v", mid, got)
		}
	}
	for _, c := range []struct {
		mid uint16
		p   map[string]any
	}{{171, map[string]any{"item_num": json.Number("2")}}, {2738, map[string]any{"mission_id": json.Number("1001001"), "awake_type": json.Number("4")}}, {2737, map[string]any{"mission_id": json.Number("1001001"), "awake_type": json.Number("1"), "complete": true}}, {165, map[string]any{"table_id": json.Number("1.5")}}, {2561, map[string]any{"generation": json.Number("1")}}} {
		before := f.calls
		got := d.Dispatch(context.Background(), i5Req(c.mid, c.p, now))
		if got.HTTPStatus == 200 || f.calls != before {
			t.Fatalf("malformed request reached owner: %d %+v", c.mid, got)
		}
	}
	got := d.Dispatch(context.Background(), i5Req(171, map[string]any{"item_num": json.Number("1")}, now))
	if got.HTTPStatus != 200 || f.action != "wish" {
		t.Fatalf("Wish: %+v", got)
	}
	got = d.Dispatch(context.Background(), i5Req(2736, map[string]any{"mission_type": json.Number("5")}, now))
	if got.HTTPStatus != 200 || got.Body["mission_list"] == nil {
		t.Fatalf("family5: %+v", got)
	}
	got = d.Dispatch(context.Background(), i5Req(161, map[string]any{"table_id": json.Number("1001001")}, now))
	if got.HTTPStatus != 200 || got.Body["awakening_claim"] != int64(1001001) {
		t.Fatalf("claim161: %+v", got)
	}
}

type bloodWireFake struct{ calls int }

func (f *bloodWireFake) Start(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error) {
	f.calls++
	return map[string]any{}, nil
}
func (f *bloodWireFake) Result(context.Context, identity.ActorContext, int64, int64, operation.Context) (map[string]any, error) {
	f.calls++
	return map[string]any{}, nil
}
func TestBloodWireOnlySourceBranchAndEmptyNPCShapes(t *testing.T) {
	f := &bloodWireFake{}
	d := AwakeningBloodDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: f}
	at := time.Unix(703, 0)
	for _, empty := range []any{map[string]any{}, []any{}} {
		r := d.Dispatch(context.Background(), i5Req(867, map[string]any{"twice_awake_mission": json.Number("2001002"), "incubus_id": json.Number("2001002"), "num": json.Number("20"), "npc_ids": empty}, at))
		if r.HTTPStatus != 200 {
			t.Fatal(r)
		}
	}
	for _, bad := range []any{nil, []any{json.Number("1")}, map[string]any{"1": json.Number("1")}, "[]"} {
		n := f.calls
		r := d.Dispatch(context.Background(), i5Req(867, map[string]any{"twice_awake_mission": json.Number("2001002"), "incubus_id": json.Number("2001002"), "num": json.Number("20"), "npc_ids": bad}, at))
		if r.HTTPStatus == 200 || f.calls != n {
			t.Fatal("bad NPC shape reached owner", r)
		}
	}
	n := f.calls
	r := d.Dispatch(context.Background(), i5Req(866, map[string]any{"incubus_id": json.Number("1")}, at))
	if r.HTTPStatus == 200 || f.calls != n {
		t.Fatal("generic Infinity claimed", r)
	}
	r = d.Dispatch(context.Background(), i5Req(866, map[string]any{"twice_awake_mission": json.Number("2001002"), "incubus_id": json.Number("2001002"), "formation": "1|2"}, at))
	if r.HTTPStatus == 200 || f.calls != n {
		t.Fatal("invented selected formation accepted", r)
	}
}

type timedMissionWire struct {
	MissionServicePort
	family objective.StockFamily
	calls  int
}

func (m *timedMissionWire) ReadMissions(_ context.Context, _ identity.ActorContext, f objective.StockFamily, _ operation.Context) (map[string]any, error) {
	m.family = f
	m.calls++
	return map[string]any{"mission_list": []any{}, "daily_mission_": []any{}}, nil
}
func TestTimedMissionRefreshRecognizesOnlyStockEvent(t *testing.T) {
	m := &timedMissionWire{}
	d := I5Dispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: &i5WireFake{}, Missions: m}
	for _, raw := range []any{nil, map[string]any{"name": "__update_mission_ontime__"}} {
		r := d.Dispatch(context.Background(), i5Req(2736, map[string]any{"mission_type": raw}, time.Unix(703, 0)))
		if r.HTTPStatus != 200 || m.family != objective.Daily || r.Body["daily_mission_"] == nil {
			t.Fatal(r, m)
		}
	}
	for _, raw := range []any{map[string]any{}, map[string]any{"name": "other"}, map[string]any{"name": "__update_mission_ontime__", "complete": true}, "__update_mission_ontime__", json.Number("0")} {
		n := m.calls
		r := d.Dispatch(context.Background(), i5Req(2736, map[string]any{"mission_type": raw}, time.Unix(703, 0)))
		if r.HTTPStatus == 200 || m.calls != n {
			t.Fatal("malformed event reached owner", r)
		}
	}
}
