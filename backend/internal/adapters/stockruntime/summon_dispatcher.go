package stockruntime

import (
	"context"
	"errors"
	"net/http"

	apphero "gxb.local/backend/v2/internal/application/characterhero"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	app "gxb.local/backend/v2/internal/application/summon"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/summon"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// SummonMIDs are Vending: pull and load (I9-3E), Magic buy and switch, Vows scroll exchange (I9-3F).
var SummonMIDs = []uint16{50, 56, 70, 71, 306}

type SummonPort interface {
	Load(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	Summon(context.Context, identity.ActorContext, app.Pull, operation.Context) (map[string]any, error)
	Magic(context.Context, identity.ActorContext, app.MagicPull, operation.Context) (map[string]any, error)
	SwitchMagic(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	ExchangeVows(context.Context, identity.ActorContext, app.VowsExchange, operation.Context) (map[string]any, error)
}

type SummonDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   SummonPort
}

func (o SummonDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: o.Authority}).actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if o.Service == nil {
		return failSummon(d.ErrUnavailable)
	}
	p, op := req.Envelope.Params, req.Envelope.Operation
	bad := badHero("summon_invalid_parameter")
	var body map[string]any
	var err error
	switch req.Envelope.MID {
	case 56:
		if !onlyStockGameplayParams(p) {
			return bad
		}
		body, err = o.Service.Load(ctx, a, op)
	case 70:
		times, timesOK := topFloorInteger(p, "summon_time", true)
		target, targetOK := topFloorInteger(p, "partner_id", true)
		if !timesOK || !targetOK || !onlyStockGameplayParams(p, "summon_time", "partner_id") {
			return bad
		}
		body, err = o.Service.Magic(ctx, a, app.MagicPull{Times: times, Target: target}, op)
	case 71:
		target, targetOK := topFloorInteger(p, "partner_id", true)
		if !targetOK || !onlyStockGameplayParams(p, "partner_id") {
			return bad
		}
		body, err = o.Service.SwitchMagic(ctx, a, target, op)
	case 306:
		tableID, tableOK := topFloorInteger(p, "table_id", true)
		times, timesOK := topFloorInteger(p, "times", true)
		if !tableOK || !timesOK || !onlyStockGameplayParams(p, "table_id", "times") {
			return bad
		}
		body, err = o.Service.ExchangeVows(ctx, a, app.VowsExchange{TableID: tableID, Times: times}, op)
	case 50:
		return o.summon(ctx, a, req)
	default:
		return bad
	}
	if err != nil {
		return failSummon(err)
	}
	return okI5(body)
}

func (o SummonDispatcher) summon(ctx context.Context, a identity.ActorContext, req httpedge.DispatchRequest) httpedge.Response {
	p, op := req.Envelope.Params, req.Envelope.Operation
	bad := badHero("summon_invalid_parameter")
	kind, kindOK := topFloorInteger(p, "summon_type", true)
	index, indexOK := topFloorInteger(p, "summon_index", false)
	// SummonWindow omits summon_index for the coupon buttons (CouponTypeOne/Ten are undefined in enums.lua).
	if index == 0 {
		index = 1
	}
	if !kindOK || !indexOK || !onlyStockGameplayParams(p, "summon_type", "summon_index") {
		return bad
	}
	body, err := o.Service.Summon(ctx, a, app.Pull{Type: kind, Index: index}, op)
	if err != nil {
		return failSummon(err)
	}
	return okI5(body)
}

// failSummon keeps result = [] on a refusal: SelfPlayer.summonHero iterates it (V1 Pass41.3).
func failSummon(err error) httpedge.Response {
	var conflict *receipt.ConflictError
	if errors.Is(err, d.ErrInvalid) || errors.As(err, &conflict) {
		return badHero("summon_invalid_parameter")
	}
	if errors.Is(err, d.ErrRefused) || errors.Is(err, apphero.ErrHeroCapacityExceeded) {
		return conflictRefusal(1)
	}
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: err, Body: map[string]any{"error": "summon_unavailable"}}
}
