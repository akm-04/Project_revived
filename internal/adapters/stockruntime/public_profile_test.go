package stockruntime

import (
	"context"
	"encoding/json"
	app "gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/limits"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"time"
)

type profileCommandsFunc func(context.Context, identity.ActorContext, app.Command, operation.Context) (app.CommandResult, error)

func (f profileCommandsFunc) Execute(c context.Context, a identity.ActorContext, q app.Command, o operation.Context) (app.CommandResult, error) {
	return f(c, a, q, o)
}
func TestProfilePreferenceWireAndFailureCallbacks(t *testing.T) {
	a := actorForHTTP(t)
	calls := 0
	d := PublicProfileDispatcher{Authority: httpAuthority{a}, Service: profileCommandsFunc(func(c context.Context, a identity.ActorContext, q app.Command, o operation.Context) (app.CommandResult, error) {
		calls++
		r := app.CommandResult{Kind: q.Kind, PlayerID: int64(a.PlayerID), Server: int32(a.LogicalServerID), Intro: q.Intro, Hide: q.Hide, Show: map[string]int64{"1011": 1730000000}}
		if q.Intro == "unavailable" {
			return app.CommandResult{}, app.ErrContent
		}
		return r, nil
	})}
	for _, tc := range []struct {
		mid    uint16
		params map[string]any
		status int
		field  string
	}{{1834, map[string]any{"content": ""}, 200, "intro"}, {1834, map[string]any{"content": "unavailable"}, 409, ""}, {1834, map[string]any{"content": nil}, 400, ""}, {1834, map[string]any{"content": "mine", "to_player_id": int64(200001)}, 400, ""}, {1833, map[string]any{"sub_types": map[string]any{}}, 200, "hide_types"}, {1833, map[string]any{"sub_types": []any{json.Number("4"), json.Number("2")}}, 200, "hide_types"}, {1833, map[string]any{"sub_types": []any{2, 2}}, 400, ""}, {1833, map[string]any{"sub_types": []any{3}}, 400, ""}, {1831, map[string]any{"show_types": []any{json.Number("1011")}}, 200, "show_types"}, {1831, map[string]any{"show_types": []any{"1011"}}, 400, ""}, {1831, map[string]any{"show_types": []any{1011.5}}, 400, ""}, {1831, map[string]any{"show_types": map[string]any{"1011": true}}, 400, ""}} {
		r := activityReq(tc.mid, tc.params, time.Now())
		got := d.Dispatch(context.Background(), r)
		if got.HTTPStatus != tc.status {
			t.Fatalf("mid%d %#v =>%+v", tc.mid, tc.params, got)
		}
		if tc.status == 200 {
			if _, yes := got.Body[tc.field]; !yes {
				t.Fatalf("missing consumer field %s", tc.field)
			}
		} else if _, yes := got.Body["intro"]; yes {
			t.Fatal("failure may mutate client intro")
		}
	}
	r := activityReq(1834, map[string]any{"content": "x"}, time.Now())
	r.Envelope.Claims.Region = 2
	if got := d.Dispatch(context.Background(), r); got.HTTPStatus != 403 {
		t.Fatal(got)
	}
	if calls != 5 {
		t.Fatalf("unexpected service calls%d", calls)
	}
}
func TestProfileRawDuplicateAndUnicodeRejection(t *testing.T) {
	for _, raw := range []string{`{"mid":1834,"content":"a","content":"b"}`, `{"mid":1834,"mid":50,"content":"a"}`, `{"mid":1831,"show_types":[1011],"show_types":[]}`, `{"mid":1833,"sub_types":[],"sub_types":[2]}`, `{"mid":1834,"content":"\ud800"}`} {
		r := httptest.NewRequest(http.MethodPost, "/", strings.NewReader(url.Values{"payload": {raw}}.Encode()))
		r.Header.Set("Content-Type", "application/x-www-form-urlencoded")
		_, e := httpedge.Decode(r /* existing finite default bounds */, limits.Default())
		if e == nil {
			t.Fatal("ambiguous raw accepted", raw)
		}
	}
}
