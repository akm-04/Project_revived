package stockruntime

import (
	"context"
	"encoding/json"
	"errors"
	app "gxb.local/backend/v2/internal/application/elementequipment"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/economy"
	ins "gxb.local/backend/v2/internal/domain/elementequipment"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"net/http"
)

type ElementPort interface {
	Command(context.Context, identity.ActorContext, app.Command, operation.Context) (app.Result, error)
	Response(context.Context, identity.ActorContext, app.Result, operation.Context) (map[string]any, error)
}
type ElementDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   ElementPort
}

func (d ElementDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: d.Authority}).actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if d.Service == nil {
		return failElement(app.ErrUnavailable)
	}
	p := req.Envelope.Params
	c := app.Command{}
	var keys []string
	switch req.Envelope.MID {
	case 2849:
		c.Family = app.Equip
		keys = []string{"partner_id", "equip_id", "equip_pos"}
	case 2850:
		c.Family = app.Enhance
		keys = []string{"partner_id", "equip_id"}
	case 2851:
		c.Family = app.Unload
		keys = []string{"partner_id", "equip_pos"}
	case 2852:
		c.Family = app.DestroyBound
		keys = []string{"partner_id", "equip_id"}
	case 2853:
		c.Family = app.DestroyBackpack
		keys = []string{"equip_id"}
	default:
		return badHero("unsupported_element_mid")
	}
	if !onlyStockGameplayParams(p, keys...) {
		return badHero("invalid_elementequipment_parameter")
	}
	var e error
	for _, key := range keys {
		number, ok := p[key].(json.Number)
		if !ok {
			e = ins.ErrInvalid
			break
		}
		v, err := number.Int64()
		if err != nil {
			e = err
			break
		}
		switch key {
		case "partner_id":
			c.PartnerID = v
		case "equip_id":
			c.EquipID = v
		case "equip_pos":
			c.Position = v
		}
	}
	if e != nil || c.Validate() != nil {
		return badHero("invalid_elementequipment_request")
	}
	r, e := d.Service.Command(ctx, a, c, req.Envelope.Operation)
	if e != nil {
		return failElement(e)
	}
	body, e := d.Service.Response(ctx, a, r, req.Envelope.Operation)
	if e != nil {
		return failElement(e)
	}
	return okI5(body)
}
func failElement(e error) httpedge.Response {
	if errors.Is(e, app.ErrRejected) || errors.Is(e, ins.ErrInvalid) || errors.Is(e, economy.ErrInsufficientBalance) {
		return badHero("elementequipment_command_rejected")
	}
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: e, Body: map[string]any{"error": "elementequipment_unavailable_or_unresolved"}}
}
