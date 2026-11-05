package stockruntime

import (
	"context"
	exchange "gxb.local/backend/v2/internal/application/socialexchange"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	socialdomain "gxb.local/backend/v2/internal/domain/socialexchange"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
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
	}{
		{map[string]any{"id": int64(1), "num": int64(1)}, 200},
		{map[string]any{"id": int64(1), "num": int64(1), "price": int64(1)}, 400},
		{map[string]any{"id": int64(1)}, 400},
		{map[string]any{"id": int64(1), "num": int64(0)}, 409},
		{map[string]any{"id": int64(0), "num": int64(1)}, 409},
		{map[string]any{"id": "-1", "num": int64(1)}, 400},
		{map[string]any{"id": int64(1), "num": 1.5}, 400},
		{map[string]any{}, 400},
	} {
		result := dispatcher.Dispatch(context.Background(), heroReq(t, 191, test.parameters))
		if result.HTTPStatus != test.status {
			t.Fatal(test.parameters, result)
		}
		if test.status != 200 && result.Body["awards"] != nil {
			t.Fatal("refusal carried a success callback body", test.parameters, result.Body)
		}
	}
	if probe.calls != 1 {
		t.Fatal(probe.calls)
	}
	for _, refusal := range []error{economy.ErrInsufficientBalance, economy.ErrStackCapacity, socialdomain.ErrCount, socialdomain.ErrUnknownProduct, exchange.ErrProductOff, &receipt.ConflictError{}} {
		probe.err = refusal
		if result := dispatcher.Dispatch(context.Background(), heroReq(t, 191, map[string]any{"id": int64(1), "num": int64(1)})); result.HTTPStatus != 409 || result.Body["awards"] != nil {
			t.Fatal(refusal, result)
		}
	}
	probe.err = exchange.ErrProof
	if result := dispatcher.Dispatch(context.Background(), heroReq(t, 191, map[string]any{"id": int64(1), "num": int64(1)})); result.HTTPStatus != 503 || result.Body["awards"] != nil {
		t.Fatal(result)
	}
	if result := (SocialExchangeDispatcher{Authority: httpAuthority{actorForHTTP(t)}}).Dispatch(context.Background(), heroReq(t, 191, map[string]any{"id": int64(1), "num": int64(1)})); result.HTTPStatus != 503 {
		t.Fatal("unavailable service", result)
	}
}
