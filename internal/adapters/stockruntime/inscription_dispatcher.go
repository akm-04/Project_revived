package stockruntime

import (
	"context"
	"encoding/json"
	"errors"
	app "gxb.local/backend/v2/internal/application/inscription"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	ins "gxb.local/backend/v2/internal/domain/inscription"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"net/http"
)

type InscriptionPort interface {
	Command(context.Context, identity.ActorContext, app.Command, operation.Context) (app.Result, error)
	Response(context.Context, identity.ActorContext, app.Result, operation.Context) (map[string]any, error)
}
type InscriptionDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   InscriptionPort
}

func (d InscriptionDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: d.Authority}).actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if d.Service == nil {
		return failInscription(app.ErrUnavailable)
	}
	p := req.Envelope.Params
	c := app.Command{}
	var keys []string
	switch req.Envelope.MID {
	case 1400:
		c.Family = app.Make
		keys = []string{"inscript_id", "make_num"}
	case 1401:
		c.Family = app.Rebuild
		keys = []string{"item_id", "rebuild_num", "cost_type"}
	case 1402:
		c.Family = app.Insert
		keys = []string{"partner_id", "item_id", "replace_item_id"}
	case 1403:
		c.Family = app.Remove
		keys = []string{"partner_id", "item_id"}
	case 1404:
		c.Family = app.Resolve
		keys = []string{"item_id", "resolve_num"}
	case 1405:
		c.Family = app.Save
		keys = []string{"item_id"}
	case 1406:
		c.Family = app.Abandon
	case 1407:
		c.Family = app.Exchange
	default:
		return badHero("unsupported_inscription_mid")
	}
	if !onlyStockGameplayParams(p, keys...) {
		return badHero("invalid_inscription_parameter")
	}
	var e error
	for _, key := range keys {
		if key == "replace_item_id" {
			if _, ok := p[key]; !ok {
				continue
			}
		}
		var v int64
		number, ok := p[key].(json.Number)
		if !ok {
			e = ins.ErrInvalid
			break
		}
		v, e = number.Int64()
		if e != nil {
			break
		}
		switch key {
		case "partner_id":
			c.PartnerID = v
		case "item_id":
			c.ItemID = v
		case "replace_item_id":
			c.ReplaceID = v
		case "inscript_id":
			c.FamilyID = v
		case "make_num", "rebuild_num", "resolve_num":
			c.Amount = v
		case "cost_type":
			c.CostType = v
		}
	}
	if e != nil || c.Validate() != nil {
		return badHero("invalid_inscription_request")
	}
	r, e := d.Service.Command(ctx, a, c, req.Envelope.Operation)
	if e != nil {
		return failInscription(e)
	}
	body, e := d.Service.Response(ctx, a, r, req.Envelope.Operation)
	if e != nil {
		return failInscription(e)
	}
	return okI5(body)
}
func failInscription(e error) httpedge.Response {
	if errors.Is(e, app.ErrRejected) || errors.Is(e, ins.ErrInvalid) || errors.Is(e, economy.ErrInsufficientBalance) {
		return badHero("inscription_command_rejected")
	}
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: e, Body: map[string]any{"error": "inscription_unavailable_or_unresolved"}}
}
