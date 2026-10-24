package stockruntime

import (
	"context"
	"encoding/json"
	"errors"
	app "gxb.local/backend/v2/internal/application/heroevolution"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/economy"
	ins "gxb.local/backend/v2/internal/domain/heroevolution"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"net/http"
)

type EvolutionPort interface {
	Command(context.Context, identity.ActorContext, app.Command, operation.Context) (app.Result, error)
	Response(context.Context, identity.ActorContext, app.Result, operation.Context) (map[string]any, error)
}
type EvolutionDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   EvolutionPort
}

func (d EvolutionDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: d.Authority}).actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if d.Service == nil {
		return failEvolution(app.ErrUnavailable)
	}
	p := req.Envelope.Params
	c := app.Command{}
	var keys []string
	switch req.Envelope.MID {
	case 2608:
		c.Family = app.Allocate
		keys = []string{"partner_id", "attr_id", "add_num", "cost_item"}
	case 2609:
		c.Family = app.Advance
		keys = []string{"partner_id"}
	default:
		return badHero("unsupported_evolution_mid")
	}
	if !onlyStockGameplayParams(p, keys...) {
		return badHero("invalid_heroevolution_parameter")
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
		case "attr_id":
			c.AttrID = v
		case "add_num":
			c.Amount = v
		case "cost_item":
			c.CostItem = v
		}

	}
	if e != nil || c.Validate() != nil {
		return badHero("invalid_heroevolution_request")
	}
	r, e := d.Service.Command(ctx, a, c, req.Envelope.Operation)
	if e != nil {
		return failEvolution(e)
	}
	body, e := d.Service.Response(ctx, a, r, req.Envelope.Operation)
	if e != nil {
		return failEvolution(e)
	}
	return okI5(body)
}
func failEvolution(e error) httpedge.Response {
	if errors.Is(e, app.ErrRejected) || errors.Is(e, ins.ErrInvalid) || errors.Is(e, economy.ErrInsufficientBalance) {
		return badHero("heroevolution_command_rejected")
	}
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: e, Body: map[string]any{"error": "heroevolution_unavailable_or_unresolved"}}
}
