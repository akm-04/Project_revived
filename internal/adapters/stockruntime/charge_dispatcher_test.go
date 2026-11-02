package stockruntime

import (
	"context"
	"strings"
	"testing"
	"time"

	app "gxb.local/backend/v2/internal/application/commerceprivilege"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/privilege"
	"gxb.local/backend/v2/internal/foundation/operation"
)

type chargeProbe struct {
	taps    int
	claims  int
	queries int
	err     error
}

func (p *chargeProbe) Query(context.Context, identity.ActorContext, time.Time) (map[string]any, error) {
	p.queries++
	return map[string]any{"charges": []any{}, "giftbags": []any{}, "server_time": int64(1)}, p.err
}

func (p *chargeProbe) ClaimVIPAward(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error) {
	p.claims++
	return map[string]any{"awards": []any{}}, p.err
}

func (p *chargeProbe) Tap(context.Context, identity.ActorContext, app.TapRequest, operation.Context) (map[string]any, error) {
	p.taps++
	return map[string]any{"recharge_event": map[string]any{"mid": 36857, "params": map[string]any{}}}, p.err
}

func TestChargeDispatcherRefusesMalformedAndBusinessErrors(t *testing.T) {
	probe := &chargeProbe{}
	dispatcher := ChargeDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: probe}
	for _, tc := range []struct {
		name   string
		mid    uint16
		params map[string]any
		status int
	}{
		{"354", 354, map[string]any{}, 200},
		{"354 extra", 354, map[string]any{"charge_id": int64(1)}, 400},
		{"657", 657, map[string]any{"id": int64(1)}, 200},
		{"657 level zero", 657, map[string]any{"id": int64(0)}, 409},
		{"657 level high", 657, map[string]any{"id": int64(16)}, 409},
		{"657 missing", 657, map[string]any{}, 400},
		{"tap", 32000, map[string]any{"charge_id": int64(80001007), "intent_id": "vc-1"}, 200},
		{"tap zero charge", 32000, map[string]any{"charge_id": int64(0), "intent_id": "vc-1"}, 400},
		{"tap empty intent", 32000, map[string]any{"charge_id": int64(80001007), "intent_id": ""}, 400},
		{"tap long intent", 32000, map[string]any{"charge_id": int64(80001007), "intent_id": strings.Repeat("a", 65)}, 400},
		{"tap space intent", 32000, map[string]any{"charge_id": int64(80001007), "intent_id": "vc 1"}, 400},
		{"tap missing intent", 32000, map[string]any{"charge_id": int64(80001007)}, 400},
	} {
		t.Run(tc.name, func(t *testing.T) {
			got := dispatcher.Dispatch(context.Background(), heroReq(t, tc.mid, tc.params))
			if got.HTTPStatus != tc.status {
				t.Fatalf("status=%d body=%v", got.HTTPStatus, got.Body)
			}
		})
	}
	probe.err = d.ErrChargeRefused
	for _, mid := range []uint16{657, 32000} {
		params := map[string]any{"id": int64(1)}
		if mid == 32000 {
			params = map[string]any{"charge_id": int64(80001007), "intent_id": "vc-2"}
		}
		got := dispatcher.Dispatch(context.Background(), heroReq(t, mid, params))
		if got.HTTPStatus != 409 || got.Body["error_code"] != int64(1) {
			t.Fatalf("mid %d refusal=%d %v", mid, got.HTTPStatus, got.Body)
		}
	}
	if probe.queries != 1 || probe.claims != 2 || probe.taps != 2 {
		t.Fatalf("calls query=%d claim=%d tap=%d", probe.queries, probe.claims, probe.taps)
	}
	if got := failCharge(d.ErrConflict); got.HTTPStatus != 409 || got.Body["error_code"] != int64(1) {
		t.Fatalf("conflict mapped to %d %v", got.HTTPStatus, got.Body)
	}
	if got := failCharge(d.ErrUnavailable); got.HTTPStatus != 503 {
		t.Fatalf("unavailable mapped to %d", got.HTTPStatus)
	}
}
