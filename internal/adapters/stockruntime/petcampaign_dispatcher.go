package stockruntime

import (
	"context"
	"errors"
	app "gxb.local/backend/v2/internal/application/petcampaign"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/petcampaign"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"net/http"
)

var PetCampaignMIDs = []uint16{816, 817, 818, 819, 820, 821, 822, 823, 824, 825, 826, 827}

type PetCampaignPort interface {
	Load(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	Detail(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	Start(context.Context, identity.ActorContext, app.Fight, operation.Context) (map[string]any, error)
	Result(context.Context, identity.ActorContext, app.Result, operation.Context) (map[string]any, error)
	BeginSweep(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	FinishSweep(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	Reset(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	AwakeSweep(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	EliteSweep(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	BuyElite(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	SaveElite(context.Context, identity.ActorContext, int64, int64, operation.Context) (map[string]any, error)
}
type PetCampaignDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   PetCampaignPort
}

func (m PetCampaignDispatcher) Dispatch(c context.Context, r httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: m.Authority}).actor(c, r)
	if fail != nil {
		return *fail
	}
	bad := badHero("pet_campaign_invalid_parameter")
	if m.Service == nil {
		return httpedge.Response{HTTPStatus: 503, Body: map[string]any{"error_code": int64(1)}}
	}
	p, op := r.Envelope.Params, r.Envelope.Operation
	var out map[string]any
	var e error
	switch r.Envelope.MID {
	case 816, 818, 821, 822:
		if !onlyStockGameplayParams(p) {
			return bad
		}
		switch r.Envelope.MID {
		case 816:
			out, e = m.Service.Load(c, a, op)
		case 818:
			out, e = m.Service.BeginSweep(c, a, op)
		case 821:
			out, e = m.Service.Reset(c, a, op)
		case 822:
			out, e = m.Service.Detail(c, a, op)
		}
	case 817:
		if !onlyStockGameplayParams(p, "finish_time") {
			return bad
		}
		n, ok := topFloorInteger(p, "finish_time", true)
		if !ok || n < 0 {
			return bad
		}
		out, e = m.Service.FinishSweep(c, a, n, op)
	case 819, 827:
		if !onlyStockGameplayParams(p, "campaign_id", "formation", "pet_id", "rent_player_id", "rent_formation", "rent_pet_player_id", "rent_pet_id") {
			return bad
		}
		id, ok := topFloorInteger(p, "campaign_id", true)
		ids, good := topFloorFormation(p["formation"])
		pet, pok := topFloorInteger(p, "pet_id", false)
		if !ok || !good || !pok || len(ids) < 1 || len(ids) > 5 || pet < 0 {
			return bad
		}
		for _, k := range []string{"rent_player_id", "rent_pet_player_id", "rent_pet_id", "rent_formation"} {
			if v, ok := p[k]; ok && v != nil && v != "" && v != "0" && v != int64(0) && v != float64(0) {
				return bad
			}
		}
		out, e = m.Service.Start(c, a, app.Fight{Campaign: id, Formation: ids, Pet: pet, Practice: r.Envelope.MID == 827}, op)
	case 820:
		if !onlyStockGameplayParams(p, "is_win", "floor", "floor_type", "pet_id") {
			return bad
		}
		win, ok := p["is_win"].(bool)
		floor, fok := topFloorInteger(p, "floor", true)
		kind, kok := topFloorInteger(p, "floor_type", true)
		pet, pok := topFloorInteger(p, "pet_id", false)
		_, has := p["pet_id"]
		if !ok || !fok || !kok || !pok || pet < 0 {
			return bad
		}
		out, e = m.Service.Result(c, a, app.Result{Win: win, Floor: floor, Kind: kind, Pet: pet, HasPet: has && p["pet_id"] != nil}, op)
	case 823, 825:
		if !onlyStockGameplayParams(p, "floor") {
			return bad
		}
		n, ok := topFloorInteger(p, "floor", true)
		if !ok {
			return bad
		}
		if r.Envelope.MID == 823 {
			out, e = m.Service.AwakeSweep(c, a, n, op)
		} else {
			out, e = m.Service.BuyElite(c, a, n, op)
		}
	case 824:
		if !onlyStockGameplayParams(p, "campaign_id") {
			return bad
		}
		n, ok := topFloorInteger(p, "campaign_id", true)
		if !ok {
			return bad
		}
		out, e = m.Service.EliteSweep(c, a, n, op)
	case 826:
		if !onlyStockGameplayParams(p, "floor", "state") {
			return bad
		}
		n, ok := topFloorInteger(p, "floor", true)
		state, sok := topFloorInteger(p, "state", true)
		if !ok || !sok {
			return bad
		}
		out, e = m.Service.SaveElite(c, a, n, state, op)
	default:
		return httpedge.Response{HTTPStatus: http.StatusNotImplemented, Body: map[string]any{"error_code": int64(1)}}
	}
	if e != nil {
		var conflict *receipt.ConflictError
		status := http.StatusServiceUnavailable
		if errors.Is(e, d.ErrInvalid) || errors.As(e, &conflict) {
			status = 400
		} else if errors.Is(e, d.ErrRefused) || errors.Is(e, economy.ErrInsufficientBalance) {
			return conflictRefusal(1)
		}
		return httpedge.Response{HTTPStatus: status, Body: map[string]any{"error_code": int64(1), "error": "pet_campaign_failed"}}
	}
	return okI5(out)
}
