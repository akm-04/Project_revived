package stockruntime

import (
	"context"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/protocol/httpedge"
)

func TestFunctionClickAcknowledgesStockTelemetry(t *testing.T) {
	now := time.Unix(400, 0).UTC()
	d := FunctionClickDispatcher{Authority: httpAuthority{actorForHTTP(t)}}
	click := func(value any, token bool) httpedge.DispatchRequest {
		request := env(30, nil, now)
		if !token {
			request.Envelope.Claims.Token = ""
			request.Envelope.Params["token"] = ""
		}
		if value != nil {
			request.Envelope.Params["click_id"] = value
		}
		return request
	}
	for _, value := range []any{float64(33), int64(36), int32(34)} {
		if r := d.Dispatch(context.Background(), click(value, true)); r.HTTPStatus != 200 || len(r.Body) != 0 {
			t.Fatalf("click_id %v: %+v", value, r)
		}
	}
	if r := d.Dispatch(context.Background(), click(float64(33), false)); r.HTTPStatus != 200 {
		t.Fatalf("sessionless telemetry: %+v", r)
	}
	if r := d.Dispatch(context.Background(), click(nil, true)); r.HTTPStatus != 400 {
		t.Fatalf("missing click_id: %+v", r)
	}
}
