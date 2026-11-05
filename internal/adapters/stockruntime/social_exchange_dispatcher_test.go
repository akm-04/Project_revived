package stockruntime

import (
	"context"
	exchange "gxb.local/backend/v2/internal/application/socialexchange"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"testing"
)

type exchangeProbe struct {
	calls int
	err   error
}

func (probe *exchangeProbe) Exchange(context.Context, identity.ActorContext, exchange.Request, operation.Context) (map[string]any, error) {
	probe.calls++
	return map[string]any{"awards": []any{}}, probe.err
}
func TestSocialExchangeDispatcherStockParametersAndRefusals(t *testing.T) {
	probe := &exchangeProbe{}
	dispatcher := SocialExchangeDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: probe}
	for _, test := range []struct {
		parameters map[string]any
		status     int
	}{{map[string]any{"id": int64(1), "num": int64(1)}, 200}, {map[string]any{"id": int64(1), "num": int64(1), "price": int64(1)}, 400}, {map[string]any{"id": int64(1)}, 400}, {map[string]any{"id": int64(1), "num": int64(0)}, 409}} {
		result := dispatcher.Dispatch(context.Background(), heroReq(t, 191, test.parameters))
		if result.HTTPStatus != test.status {
			t.Fatal(result)
		}
	}
	if probe.calls != 1 {
		t.Fatal(probe.calls)
	}
	probe.err = economy.ErrInsufficientBalance
	if result := dispatcher.Dispatch(context.Background(), heroReq(t, 191, map[string]any{"id": int64(1), "num": int64(1)})); result.HTTPStatus != 409 {
		t.Fatal(result)
	}
	probe.err = exchange.ErrProof
	if result := dispatcher.Dispatch(context.Background(), heroReq(t, 191, map[string]any{"id": int64(1), "num": int64(1)})); result.HTTPStatus != 503 {
		t.Fatal(result)
	}
}
