package stockruntime

import (
	"context"
	"encoding/json"
	"gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"testing"
	"time"
)

type profileReadsFunc func(context.Context, identity.ActorContext, publicprofile.ReadRequest, operation.Context) (map[string]any, error)

func (f profileReadsFunc) Read(c context.Context, a identity.ActorContext, q publicprofile.ReadRequest, o operation.Context) (map[string]any, error) {
	return f(c, a, q, o)
}

type profileWireFunc func(context.Context, identity.ActorContext, publicprofile.Selection, operation.Context) (publicprofile.ShowcaseWireResult, error)

func (f profileWireFunc) Execute(c context.Context, a identity.ActorContext, q publicprofile.Selection, o operation.Context) (publicprofile.ShowcaseWireResult, error) {
	return f(c, a, q, o)
}
func Test6BProfileReadWireActorAndExactIDs(t *testing.T) {
	a := actorForHTTP(t)
	reads, commands := 0, 0
	d := PublicProfileReadDispatcher{Authority: httpAuthority{a}, Service: profileReadsFunc(func(c context.Context, actual identity.ActorContext, q publicprofile.ReadRequest, o operation.Context) (map[string]any, error) {
		reads++
		if actual.PlayerID != a.PlayerID {
			t.Fatal("lostactor/op")
		}
		if q.MID == 1840 && q.Target != a.PlayerID {
			t.Fatal("forgedself")
		}
		if q.MID == 1829 && q.Subtype == 0 {
			t.Fatal("defaultMAIN")
		}
		return map[string]any{"all_show_types": map[string]int64{"1011": 1700000000}}, nil
	}), Showcase: profileWireFunc(func(c context.Context, actual identity.ActorContext, q publicprofile.Selection, o operation.Context) (publicprofile.ShowcaseWireResult, error) {
		commands++
		var slots [6]map[string]any
		for i := range slots {
			slots[i] = map[string]any{}
		}
		return publicprofile.ShowcaseWireResult{Records: slots}, nil
	})}
	cases := []struct {
		mid    uint16
		p      map[string]any
		status int
	}{
		{1829, map[string]any{"to_player_id": int64(100002)}, 200},
		{1829, map[string]any{"to_player_id": int64(100002), "sub_type": 1.5}, 400},
		{1829, map[string]any{"to_player_id": 0}, 400},
		{1838, map[string]any{"to_player_id": 100002, "index": 6}, 200},
		{1838, map[string]any{"to_player_id": 100002, "index": 0}, 400},
		{1838, map[string]any{"to_player_id": json.Number("9007199254740992"), "index": 1}, 400},
		{1840, map[string]any{}, 200},
		{1840, map[string]any{"to_player_id": 100002}, 400},
		{1832, map[string]any{"hero_ids": []any{json.Number("1"), 0, json.Number("-1"), 0, 0, 2}}, 200},
		{1832, map[string]any{"hero_ids": []any{1, 0, -1, 0, 0}}, 400},
		{1832, map[string]any{"hero_ids": []any{1, 0, -1, 0, 0, 2}, "player_id": 100002}, 400},
		{1832, map[string]any{"hero_ids": []any{1.5, 0, -1, 0, 0, 2}}, 400},
	}
	for _, tc := range cases {
		got := d.Dispatch(context.Background(), activityReq(tc.mid, tc.p, time.Now()))
		if got.HTTPStatus != tc.status {
			t.Fatalf("%d %+v", tc.mid, got)
		}
		if tc.status != 200 && got.Body["error_code"] != int64(1) {
			t.Fatal(got)
		}
	}
	if reads != 3 || commands != 1 {
		t.Fatal("invalidrequestcrossedservice", reads, commands)
	}
	r := activityReq(1840, map[string]any{}, time.Now())
	r.Envelope.Claims.Region = 2
	if d.Dispatch(context.Background(), r).HTTPStatus != 403 {
		t.Fatal("forgedregion")
	}
}
