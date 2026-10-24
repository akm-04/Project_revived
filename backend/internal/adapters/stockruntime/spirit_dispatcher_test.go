package stockruntime

import (
	"context"
	"encoding/json"
	app "gxb.local/backend/v2/internal/application/spirit"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"testing"
)

type spiritHTTPService struct {
	command app.Command
	calls   int
}

func (s *spiritHTTPService) Command(_ context.Context, _ identity.ActorContext, c app.Command, _ operation.Context) (app.Result, error) {
	s.command = c
	s.calls++
	return app.Result{Command: c, Body: map[string]any{}}, nil
}
func (s *spiritHTTPService) Response(context.Context, identity.ActorContext, app.Result, operation.Context) (map[string]any, error) {
	return map[string]any{}, nil
}
func (s *spiritHTTPService) Programs(context.Context, identity.ActorContext, operation.Context) ([]map[string]any, error) {
	s.calls++
	return []map[string]any{}, nil
}
func TestI7C2HStrictNineWireShapesAndOpaqueIdentifiers(t *testing.T) {
	s := &spiritHTTPService{}
	d := SpiritDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: s}
	n := func(x string) json.Number { return json.Number(x) }
	for _, c := range []struct {
		mid    uint16
		p      map[string]any
		family string
	}{{3089, map[string]any{"spirit_id": n("1"), "spirit_ids": []any{n("2"), n("3")}}, app.Enhance}, {3090, map[string]any{"spirit_id": n("1")}, app.Lock}, {3091, map[string]any{"spirit_id": n("1")}, app.Unlock}, {3094, map[string]any{"partner_id": n("1"), "spirit_id": n("0"), "pos": n("6")}, app.Equip}, {3095, map[string]any{"partner_id": n("1")}, app.AllOff}, {3113, map[string]any{"name": "保存", "collocation": "1|0|0|0|0|0"}, app.Save}, {3114, map[string]any{"id": n("1")}, app.Delete}, {3115, map[string]any{"id": n("1"), "partner_id": n("2")}, app.Apply}} {
		r := d.Dispatch(context.Background(), heroReq(t, c.mid, c.p))
		if r.HTTPStatus != 200 || s.command.Family != c.family {
			t.Fatal(c, r)
		}
		c.p["proposal_nonce"] = n("1")
		before := s.calls
		if r = d.Dispatch(context.Background(), heroReq(t, c.mid, c.p)); r.HTTPStatus != 400 || s.calls != before {
			t.Fatal("invented param", r)
		}
	}
	r := d.Dispatch(context.Background(), heroReq(t, 3112, map[string]any{}))
	if r.HTTPStatus != 200 || r.JSON == nil {
		t.Fatal("raw list missing", r)
	}
	for _, v := range []any{true, "1", n("1.0"), n("1e0"), n("-1"), n("9007199254740992")} {
		if r = d.Dispatch(context.Background(), heroReq(t, 3090, map[string]any{"spirit_id": v})); r.HTTPStatus != 400 {
			t.Fatal("invalid ID", v, r)
		}
	}
	for _, ids := range []any{[]any{n("2"), n("2")}, []any{n("1")}, []any{true}, "2|3", []any{}} {
		if r = d.Dispatch(context.Background(), heroReq(t, 3089, map[string]any{"spirit_id": n("1"), "spirit_ids": ids})); r.HTTPStatus != 400 {
			t.Fatal("invalid actual instance array", ids, r)
		}
	}
}
