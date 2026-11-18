package stockruntime

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"

	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	app "gxb.local/backend/v2/internal/application/shop"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/shop"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// ShopMIDs are the I9-11C core-shop routes. MID 35 is INACTIVE and answers
// through the inactive dispatcher; MID 1396 stays I10.
var ShopMIDs = []uint16{32, 33, 34, 37, 38, 2982}

type ShopPort interface {
	LoadShop(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	List(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	CloseShop(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	Buy(context.Context, identity.ActorContext, app.BuyRequest, operation.Context) (map[string]any, error)
	MultiBuy(context.Context, identity.ActorContext, app.MultiBuyRequest, operation.Context) (map[string]any, error)
	Refresh(context.Context, identity.ActorContext, app.RefreshRequest, operation.Context) (map[string]any, error)
}

// ShopDispatcher answers I9_11C C1-C16.
type ShopDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   ShopPort
}

func (o ShopDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: o.Authority}).actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if o.Service == nil {
		return failureReply(defect(nil))
	}
	p, op := req.Envelope.Params, req.Envelope.Operation
	switch req.Envelope.MID {
	case 32:
		shopType, err := shopTypeParam(p)
		if err != nil || !onlyStockGameplayParams(p, "shop_type") {
			return shopMalformed()
		}
		body, err := o.Service.LoadShop(ctx, a, shopType, op)
		return shopReply(body, err)
	case 33:
		shopType, err := shopTypeParam(p)
		if err != nil || !onlyStockGameplayParams(p, "shop_type", "index", "client_price", "num") {
			return shopMalformed()
		}
		index, err := requiredInt64(p, "index")
		if err != nil || index <= 0 {
			return shopMalformed()
		}
		var clientPrice *int64
		if raw, present := p["client_price"]; present && raw != nil {
			value, err := requiredInt64(p, "client_price")
			if err != nil || value < 0 {
				return shopMalformed()
			}
			clientPrice = &value
		}
		body, err := o.Service.Buy(ctx, a, app.BuyRequest{ShopType: shopType, Index: index, ClientPrice: clientPrice}, op)
		return shopReply(body, err)
	case 34:
		shopType, err := shopTypeParam(p)
		if err != nil || !onlyStockGameplayParams(p, "shop_type") {
			return shopMalformed()
		}
		body, err := o.Service.Refresh(ctx, a, app.RefreshRequest{ShopType: shopType}, op)
		return shopReply(body, err)
	case 37:
		if !onlyStockGameplayParams(p) {
			return shopMalformed()
		}
		body, err := o.Service.List(ctx, a, op)
		return shopReply(body, err)
	case 38:
		shopType, err := shopTypeParam(p)
		if err != nil || !onlyStockGameplayParams(p, "shop_type") {
			return shopMalformed()
		}
		body, err := o.Service.CloseShop(ctx, a, shopType, op)
		return shopReply(body, err)
	case 2982:
		shopType, err := shopTypeParam(p)
		if err != nil || !onlyStockGameplayParams(p, "shop_type", "list", "client_prices", "nums") {
			return shopMalformed()
		}
		list, err := shopIntList(p, "list")
		if err != nil || len(list) == 0 {
			return shopMalformed()
		}
		clientPrices, err := shopOptionalIntList(p, "client_prices")
		if err != nil {
			return shopMalformed()
		}
		body, err := o.Service.MultiBuy(ctx, a, app.MultiBuyRequest{ShopType: shopType, List: list, ClientPrices: clientPrices}, op)
		return shopReply(body, err)
	}
	return failureReply(refusal(unprovenRefusalCode))
}

func shopTypeParam(params map[string]any) (int64, error) {
	shopType, err := requiredInt64(params, "shop_type")
	if err != nil || shopType <= 0 {
		return 0, errors.New("invalid shop_type")
	}
	return shopType, nil
}

func shopIntList(params map[string]any, key string) ([]int64, error) {
	raw, present := params[key]
	if !present || raw == nil {
		return nil, errors.New("missing list")
	}
	entries, ok := raw.([]any)
	if !ok {
		return nil, errors.New("list is not an array")
	}
	out := make([]int64, 0, len(entries))
	for _, entry := range entries {
		value, err := shopIntValue(entry)
		if err != nil || value <= 0 {
			return nil, fmt.Errorf("invalid list entry: %v", err)
		}
		out = append(out, value)
	}
	return out, nil
}

func shopOptionalIntList(params map[string]any, key string) ([]int64, error) {
	raw, present := params[key]
	if !present || raw == nil {
		return nil, nil
	}
	switch entries := raw.(type) {
	case []any:
		out := make([]int64, 0, len(entries))
		for _, entry := range entries {
			value, err := shopIntValue(entry)
			if err != nil || value < 0 {
				return nil, fmt.Errorf("invalid entry: %v", err)
			}
			out = append(out, value)
		}
		return out, nil
	case map[string]any:
		// cjson sends an empty Lua table as {}; only the empty object is accepted.
		if len(entries) == 0 {
			return nil, nil
		}
		return nil, errors.New("not an array")
	default:
		return nil, errors.New("not an array")
	}
}

func shopIntValue(entry any) (int64, error) {
	switch value := entry.(type) {
	case int64:
		return value, nil
	case int:
		return int64(value), nil
	case json.Number:
		return value.Int64()
	case float64:
		if value != float64(int64(value)) {
			return 0, errors.New("non-integral")
		}
		return int64(value), nil
	default:
		return 0, errors.New("not a number")
	}
}

func shopMalformed() httpedge.Response {
	return failureReply(malformed("shop_invalid_parameter"))
}

var shopFailureRows = []failureRow{
	{match: d.ErrInvalid, class: failureMalformed, detail: "shop_invalid_parameter"},
	{match: d.ErrRefused, class: failureRefusal, code: unprovenRefusalCode},
	{match: d.ErrStaleState, class: failureRefusal, code: staleConflictCode},
	{match: d.ErrPriceExpired, class: failureRefusal, code: 34020},
	{match: d.ErrPriceDiscount, class: failureRefusal, code: 34021},
	{match: economy.ErrInsufficientBalance, class: failureRefusal, balance: true},
	{match: d.ErrUnavailable, class: failureUnavailable},
}

func shopReply(body map[string]any, err error) httpedge.Response {
	if err == nil {
		return okI5(body)
	}
	response := failureFromRows(shopFailureRows, err)
	if response.HTTPStatus == http.StatusConflict && response.Body != nil {
		response.Body["error_msg"] = ""
	}
	return response
}
