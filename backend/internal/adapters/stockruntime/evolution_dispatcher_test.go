package stockruntime

import (
	"context"
	"encoding/json"
	"errors"
	"reflect"
	"testing"

	app "gxb.local/backend/v2/internal/application/heroevolution"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
)

type evolutionHTTPService struct {
	command app.Command
	calls   int
	err     error
}

func (s *evolutionHTTPService) Command(_ context.Context, _ identity.ActorContext, c app.Command, _ operation.Context) (app.Result, error) {
	s.command = c
	s.calls++
	return app.Result{Command: c}, s.err
}
func (s *evolutionHTTPService) Response(context.Context, identity.ActorContext, app.Result, operation.Context) (map[string]any, error) {
	return map[string]any{"evo_info": map[string]any{"evo_stage": int64(2), "evo_attr_points": map[string]int64{}}}, nil
}
func TestI7C2IExactWireFieldsAndFailureEnvelope(t *testing.T) {
	s := &evolutionHTTPService{}
	d := EvolutionDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: s}
	n := func(v string) json.Number { return json.Number(v) }
	p := map[string]any{"partner_id": n("9"), "attr_id": n("4"), "add_num": n("2"), "cost_item": n("40001001")}
	r := d.Dispatch(context.Background(), heroReq(t, 2608, p))
	want := app.Command{Family: app.Allocate, PartnerID: 9, AttrID: 4, Amount: 2, CostItem: 40001001}
	if r.HTTPStatus != 200 || !reflect.DeepEqual(s.command, want) || r.Body["evo_info"] == nil || len(r.Body) != 1 {
		t.Fatal(r, s.command)
	}
	r = d.Dispatch(context.Background(), heroReq(t, 2609, map[string]any{"partner_id": n("9")}))
	if r.HTTPStatus != 200 || s.command.Family != app.Advance || s.command.Amount != 0 {
		t.Fatal(r, s.command)
	}
	for _, bad := range []any{"9", true, n("9.0"), n("9e0"), n("0"), n("-1"), n("9007199254740992")} {
		before := s.calls
		r = d.Dispatch(context.Background(), heroReq(t, 2609, map[string]any{"partner_id": bad}))
		if r.HTTPStatus != 400 || s.calls != before {
			t.Fatal("invalid ID reached owner", bad, r)
		}
	}
	for _, key := range []string{"proposal_nonce", "evo_stage", "twice_awake_stage", "attr_id"} {
		before := s.calls
		r = d.Dispatch(context.Background(), heroReq(t, 2609, map[string]any{"partner_id": n("9"), key: n("3")}))
		if r.HTTPStatus != 400 || s.calls != before {
			t.Fatal("invented field reached owner", key, r)
		}
	}
	for _, key := range []string{"partner_id", "attr_id", "add_num", "cost_item"} {
		copy := map[string]any{}
		for k, v := range p {
			copy[k] = v
		}
		delete(copy, key)
		before := s.calls
		r = d.Dispatch(context.Background(), heroReq(t, 2608, copy))
		if r.HTTPStatus != 400 || s.calls != before {
			t.Fatal("missing key reached owner", key, r)
		}
	}
	s.err = economy.ErrInsufficientBalance
	r = d.Dispatch(context.Background(), heroReq(t, 2608, p))
	if r.HTTPStatus != 400 || r.Body["evo_info"] != nil {
		t.Fatal("failed debit produced success callback", r)
	}
	s.err = errors.New("database unavailable")
	r = d.Dispatch(context.Background(), heroReq(t, 2608, p))
	if r.HTTPStatus != 503 || r.Body["evo_info"] != nil {
		t.Fatal("infrastructure failure disguised", r)
	}
}
