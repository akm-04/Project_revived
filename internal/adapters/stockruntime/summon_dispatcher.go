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

// SummonMIDs are the I9-3E Vending pull and load.
var SummonMIDs = []uint16{50, 56}

type SummonPort interface {
	Load(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	Summon(context.Context, identity.ActorContext, app.Pull, operation.Context) (map[string]any, error)
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
	if req.Envelope.MID == 56 {
		if !onlyStockGameplayParams(p) {
			return bad
		}
		body, err := o.Service.Load(ctx, a, op)
		if err != nil {
			return failSummon(err)
		}
		return okI5(body)
	}
	kind, kindOK := topFloorInteger(p, "summon_type", true)
	index, indexOK := topFloorInteger(p, "summon_index", false)
	// SummonWindow omits summon_index for the coupon buttons (CouponTypeOne/Ten are undefined in enums.lua).
	if index == 0 {
		index = 1
	}
	if req.Envelope.MID != 50 || !kindOK || !indexOK || !onlyStockGameplayParams(p, "summon_type", "summon_index") {
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
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{"error_code": int64(1), "result": []any{}}}
	}
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: err, Body: map[string]any{"error": "summon_unavailable"}}
}
