package stockruntime

import (
	"context"
	"errors"
	"testing"
	"time"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	app "gxb.local/backend/v2/internal/application/shop"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/shop"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

type shopFake struct {
	calls map[string]int
	err   error
	body  map[string]any
}

func newShopFake() *shopFake { return &shopFake{calls: map[string]int{}, body: map[string]any{}} }

func (f *shopFake) done(name string) (map[string]any, error) {
	f.calls[name]++
	return f.body, f.err
}

func (f *shopFake) LoadShop(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error) {
	return f.done("load")
}
func (f *shopFake) List(context.Context, identity.ActorContext, operation.Context) (map[string]any, error) {
	return f.done("list")
}
func (f *shopFake) CloseShop(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error) {
	return f.done("close")
}
func (f *shopFake) Buy(context.Context, identity.ActorContext, app.BuyRequest, operation.Context) (map[string]any, error) {
	return f.done("buy")
}
func (f *shopFake) MultiBuy(context.Context, identity.ActorContext, app.MultiBuyRequest, operation.Context) (map[string]any, error) {
	return f.done("multi")
}
func (f *shopFake) Refresh(context.Context, identity.ActorContext, app.RefreshRequest, operation.Context) (map[string]any, error) {
	return f.done("refresh")
}

func shopRequest(mid uint16, params map[string]any, now time.Time) httpedge.DispatchRequest {
	request := itemsEnergyRequest(mid, params, now)
	return request
}

func TestShopDispatcherRoutesEveryMID(t *testing.T) {
	now := time.Now().UTC()
	fake := newShopFake()
	dispatcher := ShopDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)}, Service: fake}
	cases := []struct {
		mid    uint16
		params map[string]any
		call   string
	}{
		{32, map[string]any{"shop_type": 1}, "load"},
		{33, map[string]any{"shop_type": 13, "index": 3, "client_price": 50}, "buy"},
		{34, map[string]any{"shop_type": 1}, "refresh"},
		{37, map[string]any{}, "list"},
		{38, map[string]any{"shop_type": 8}, "close"},
		{2982, map[string]any{"shop_type": 1, "list": []any{int64(1), int64(2)}, "client_prices": map[string]any{}, "nums": map[string]any{}}, "multi"},
	}
	for _, cell := range cases {
		response := dispatcher.Dispatch(context.Background(), shopRequest(cell.mid, cell.params, now))
		if response.HTTPStatus != 200 || fake.calls[cell.call] != 1 {
			t.Fatalf("MID %d routed to %v: %+v", cell.mid, fake.calls, response)
		}
	}
}

func TestShopDispatcherMalformedParams(t *testing.T) {
	now := time.Now().UTC()
	dispatcher := ShopDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)}, Service: newShopFake()}
	for _, cell := range []struct {
		mid    uint16
		params map[string]any
	}{
		{32, map[string]any{}},
		{32, map[string]any{"shop_type": 0}},
		{32, map[string]any{"shop_type": "x"}},
		{32, map[string]any{"shop_type": 1, "index": 1}},
		{33, map[string]any{"shop_type": 1}},
		{33, map[string]any{"shop_type": 1, "index": 0}},
		{33, map[string]any{"shop_type": 1, "index": 1, "client_price": -1}},
		{33, map[string]any{"shop_type": 1, "index": 1, "unknown": 1}},
		{34, map[string]any{"shop_type": 1, "index": 1}},
		{37, map[string]any{"shop_type": 1}},
		{38, map[string]any{}},
		{2982, map[string]any{"shop_type": 1, "list": []any{}}},
		{2982, map[string]any{"shop_type": 1, "list": []any{int64(0)}}},
		{2982, map[string]any{"shop_type": 1, "list": []any{int64(1)}, "client_prices": []any{"x"}}},
	} {
		response := dispatcher.Dispatch(context.Background(), shopRequest(cell.mid, cell.params, now))
		if response.HTTPStatus != 400 {
			t.Fatalf("MID %d malformed %v answered %d %#v", cell.mid, cell.params, response.HTTPStatus, response.Body)
		}
	}
}

func TestShopDispatcherRefusalCodes(t *testing.T) {
	now := time.Now().UTC()
	fake := newShopFake()
	dispatcher := ShopDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)}, Service: fake}
	for _, cell := range []struct {
		err    error
		status int
		code   int64
	}{
		{d.ErrRefused, 409, unprovenRefusalCode},
		{d.ErrStaleState, 409, staleConflictCode},
		{d.ErrPriceExpired, 409, 34020},
		{d.ErrPriceDiscount, 409, 34021},
		{economy.InsufficientBalance("crystal"), 409, 20005},
		{economy.InsufficientBalance("mana"), 409, 20006},
		{economy.ErrStackCapacity, 409, unprovenRefusalCode},
		{appi5.ErrMailStackFull, 409, unprovenRefusalCode},
		{d.ErrUnavailable, 503, serverBusyCode},
		{errors.New("unexpected"), 500, unprovenRefusalCode},
	} {
		fake.err = cell.err
		response := dispatcher.Dispatch(context.Background(), shopRequest(33, map[string]any{"shop_type": 1, "index": 1}, now))
		if response.HTTPStatus != cell.status || response.Body["error_code"] != cell.code {
			t.Fatalf("failure %v mapped to %+v", cell.err, response)
		}
	}
}
