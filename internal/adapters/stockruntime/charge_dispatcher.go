package stockruntime

import (
	"context"
	"errors"
	"net/http"
	"time"

	app "gxb.local/backend/v2/internal/application/commerceprivilege"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/privilege"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/mids"
)

// ChargeMIDs are recharge history (354), VIP awards (657) and the private tap (32000).
var ChargeMIDs = []uint16{354, 657, mids.MIDRechargeTap}

type ChargePort interface {
	Query(context.Context, identity.ActorContext, time.Time) (map[string]any, error)
	ClaimVIPAward(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	Tap(context.Context, identity.ActorContext, app.TapRequest, operation.Context) (map[string]any, error)
}

type ChargeDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   ChargePort
}

func (o ChargeDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: o.Authority}).actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if o.Service == nil {
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "charge_unavailable"}}
	}
	p, op := req.Envelope.Params, req.Envelope.Operation
	bad := badHero("charge_invalid_parameter")
	var body map[string]any
	var err error
	switch req.Envelope.MID {
	case 354:
		if !onlyStockGameplayParams(p) {
			return bad
		}
		body, err = o.Service.Query(ctx, a, req.Envelope.ReceivedAt)
	case 657:
		level, ok := topFloorInteger(p, "id", true)
		if !ok || !onlyStockGameplayParams(p, "id") {
			return bad
		}
		if level < 1 || level > 15 {
			return conflictRefusal(1)
		}
		body, err = o.Service.ClaimVIPAward(ctx, a, level, op)
	case mids.MIDRechargeTap:
		chargeID, chargeOK := topFloorInteger(p, "charge_id", true)
		intent, intentOK := p["intent_id"].(string)
		if !chargeOK || chargeID <= 0 || !intentOK || !validTapIntent(intent) || !onlyStockGameplayParams(p, "charge_id", "intent_id") {
			return bad
		}
		body, err = o.Service.Tap(ctx, a, app.TapRequest{ChargeID: chargeID, IntentID: intent}, op)
	default:
		return bad
	}
	if err != nil {
		return failCharge(err)
	}
	return okI5(body)
}

func validTapIntent(intent string) bool {
	if intent == "" || len(intent) > 64 {
		return false
	}
	for _, r := range intent {
		if r < '!' || r > '~' {
			return false
		}
	}
	return true
}

// failCharge refuses business conflicts on 409 so stock callbacks see ERROR.
func failCharge(err error) httpedge.Response {
	var conflict *receipt.ConflictError
	if errors.Is(err, d.ErrChargeRefused) || errors.Is(err, d.ErrConflict) || errors.As(err, &conflict) {
		return conflictRefusal(1)
	}
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: err, Body: map[string]any{"error": "charge_unavailable"}}
}
