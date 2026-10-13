package stockruntime

import (
	"context"
	"encoding/json"
	"errors"
	app "gxb.local/backend/v2/internal/application/dormhouse"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	dorm "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"net/http"
)

type DormPort interface {
	Command(context.Context, identity.ActorContext, app.Command, operation.Context) (app.Result, error)
	Read(context.Context, identity.ActorContext, operation.Context, uint16, int64, int64) (map[string]any, error)
}
type DormDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   DormPort
}

func (d DormDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: d.Authority}).actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if d.Service == nil {
		return failDorm(app.ErrUnavailable)
	}
	p := req.Envelope.Params
	mid := req.Envelope.MID
	c := app.Command{}
	var allowed []string
	switch mid {
	case 2512:
		allowed = []string{"host_id"}
	case 2514:
		allowed = []string{"host_id", "house_id"}
	case 2513:
		allowed = []string{"key_item", "floor", "pos"}
		c.Family = app.Open
	case 2515:
		allowed = []string{"house_id", "furniture_record"}
		c.Family = app.Save
	case 2516:
		allowed = []string{"house_id", "index"}
		c.Family = app.Equip
	case 2517:
		allowed = []string{"house_id", "partner_ids"}
		c.Family = app.Enter
	case 2693:
		allowed = []string{"item_id", "item_num"}
		c.Family = app.Exchange
	case 2694:
		allowed = []string{"house_id"}
		c.Family = app.Start
	case 2695:
		allowed = []string{"house_id"}
		c.Family = app.Finish
	default:
		return badHero("unsupported_dorm_mid")
	}
	if !onlyStockGameplayParams(p, allowed...) {
		return badHero("invalid_dorm_params")
	}
	var e error
	get := func(key string) int64 {
		v, err := requiredInt64(p, key)
		if err != nil {
			e = err
		}
		return v
	}
	if mid != 2512 && mid != 2513 && mid != 2693 {
		c.HouseID = get("house_id")
	}
	if mid == 2512 || mid == 2514 {
		host := int64(0)
		if _, ok := p["host_id"]; ok {
			host = get("host_id")
			if host <= 0 {
				return badHero("invalid_dorm_host")
			}
		}
		if e != nil {
			return badHero("invalid_dorm_read")
		}
		body, e := d.Service.Read(ctx, a, req.Envelope.Operation, mid, host, c.HouseID)
		if e != nil {
			return failDorm(e)
		}
		return httpedge.Response{HTTPStatus: 200, Body: body}
	}
	switch mid {
	case 2513:
		c.ItemID = get("key_item")
		c.Floor = get("floor")
		c.Position = get("pos")
	case 2516:
		c.Index = get("index")
	case 2693:
		c.ItemID = get("item_id")
		c.Amount = get("item_num")
	case 2515:
		raw, err := json.Marshal(p["furniture_record"])
		if err != nil {
			return badHero("invalid_dorm_layout")
		}
		if err = json.Unmarshal(raw, &c.Furniture); err != nil {
			return badHero("invalid_dorm_layout")
		}
	case 2517:
		raw, err := json.Marshal(p["partner_ids"])
		if err != nil {
			return badHero("invalid_dorm_residents")
		}
		if err = json.Unmarshal(raw, &c.Partners); err != nil || c.Partners == nil {
			return badHero("invalid_dorm_residents")
		}
	}
	if e != nil || c.Validate() != nil {
		return badHero("invalid_dorm_command")
	}
	out, e := d.Service.Command(ctx, a, c, req.Envelope.Operation)
	if e != nil {
		response := failDorm(e)
		if key, ok := out.Body["wrong_key"].(string); ok {
			response.Body["wrong_key"] = key
		}
		return response
	}
	return httpedge.Response{HTTPStatus: 200, Body: out.Body}
}
func failDorm(e error) httpedge.Response {
	status := http.StatusServiceUnavailable
	body := map[string]any{"error": "dorm_unavailable"}
	if errors.Is(e, app.ErrRejected) || errors.Is(e, dorm.ErrInvalidFacts) || errors.Is(e, dorm.ErrUnqualified) {
		status = http.StatusBadRequest
	}
	if errors.Is(e, dorm.ErrInvalidLayout) {
		status = http.StatusBadRequest
	}
	return httpedge.Response{HTTPStatus: status, Body: body}
}
