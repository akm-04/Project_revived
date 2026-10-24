package stockruntime

import (
	"context"
	"encoding/json"
	app "gxb.local/backend/v2/internal/application/inscription"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"testing"
)

type inscriptionHTTPService struct {
	command app.Command
	calls   int
}

func (s *inscriptionHTTPService) Command(_ context.Context, _ identity.ActorContext, c app.Command, _ operation.Context) (app.Result, error) {
	s.command = c
	s.calls++
	return app.Result{Command: c, Body: map[string]any{}}, nil
}
func (s *inscriptionHTTPService) Response(context.Context, identity.ActorContext, app.Result, operation.Context) (map[string]any, error) {
	return map[string]any{"economy_": map[string]any{}}, nil
}
func TestI7C2FAllWireSchemasRejectUnsupportedIntentAndTypes(t *testing.T) {
	s := &inscriptionHTTPService{}
	d := InscriptionDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: s}
	cases := []struct {
		mid    uint16
		p      map[string]any
		family string
	}{
		{1400, map[string]any{"inscript_id": json.Number("10001"), "make_num": json.Number("1")}, app.Make},
		{1401, map[string]any{"item_id": json.Number("160100101"), "rebuild_num": json.Number("10"), "cost_type": json.Number("2")}, app.Rebuild},
		{1402, map[string]any{"partner_id": json.Number("1"), "item_id": json.Number("160100101")}, app.Insert},
		{1403, map[string]any{"partner_id": json.Number("1"), "item_id": json.Number("160100101")}, app.Remove},
		{1404, map[string]any{"item_id": json.Number("160100101"), "resolve_num": json.Number("999")}, app.Resolve},
		{1405, map[string]any{"item_id": json.Number("160100102")}, app.Save}, {1406, map[string]any{}, app.Abandon}, {1407, map[string]any{}, app.Exchange}}
	for _, c := range cases {
		r := d.Dispatch(context.Background(), heroReq(t, c.mid, c.p))
		if r.HTTPStatus != 200 || s.command.Family != c.family {
			t.Fatal(c.mid, r, s.command)
		}
		bad := map[string]any{}
		for k, v := range c.p {
			bad[k] = v
		}
		bad["proposal_nonce"] = json.Number("1")
		before := s.calls
		if r = d.Dispatch(context.Background(), heroReq(t, c.mid, bad)); r.HTTPStatus != 400 || s.calls != before {
			t.Fatal("invented nonce accepted", r)
		}
	}
	for _, v := range []any{true, "1", json.Number("1.0"), json.Number("1e0"), json.Number("-1"), json.Number("9007199254740992")} {
		r := d.Dispatch(context.Background(), heroReq(t, 1400, map[string]any{"inscript_id": json.Number("10001"), "make_num": v}))
		if r.HTTPStatus != 400 {
			t.Fatal("invalid make_num", v, r)
		}
	}
}
