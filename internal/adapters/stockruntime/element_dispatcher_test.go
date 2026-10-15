package stockruntime

import (
	"context"
	"encoding/json"
	app "gxb.local/backend/v2/internal/application/elementequipment"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"testing"
)

type elementequipmentHTTPService struct {
	command app.Command
	calls   int
}

func (s *elementequipmentHTTPService) Command(_ context.Context, _ identity.ActorContext, c app.Command, _ operation.Context) (app.Result, error) {
	s.command = c
	s.calls++
	return app.Result{Command: c, Body: map[string]any{}}, nil
}
func (s *elementequipmentHTTPService) Response(context.Context, identity.ActorContext, app.Result, operation.Context) (map[string]any, error) {
	return map[string]any{"economy_": map[string]any{}}, nil
}
func TestI7C2GAllWireSchemasRejectUnsupportedIntentAndTypes(t *testing.T) {
	s := &elementequipmentHTTPService{}
	d := ElementDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: s}
	cases := []struct {
		mid    uint16
		p      map[string]any
		family string
	}{
		{2849, map[string]any{"partner_id": json.Number("1"), "equip_id": json.Number("7"), "equip_pos": json.Number("2")}, app.Equip},
		{2850, map[string]any{"partner_id": json.Number("1"), "equip_id": json.Number("7")}, app.Enhance},
		{2851, map[string]any{"partner_id": json.Number("1"), "equip_pos": json.Number("2")}, app.Unload},
		{2852, map[string]any{"partner_id": json.Number("1"), "equip_id": json.Number("7")}, app.DestroyBound},
		{2853, map[string]any{"equip_id": json.Number("7")}, app.DestroyBackpack}}

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
		r := d.Dispatch(context.Background(), heroReq(t, 2853, map[string]any{"equip_id": v}))
		if r.HTTPStatus != 400 {
			t.Fatal("invalid make_num", v, r)
		}
	}
}
