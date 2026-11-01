package stockruntime

import (
	"context"
	"errors"
	pet "gxb.local/backend/v2/internal/application/characterpet"
	app "gxb.local/backend/v2/internal/application/godstrial"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/economy"
	d "gxb.local/backend/v2/internal/domain/godstrial"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

var GodsTrialMIDs = []uint16{3092, 3093, 3097, 3099, 3100, 3101}

type GodsTrialPort interface {
	Info(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	Detail(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	Start(context.Context, identity.ActorContext, app.Fight, operation.Context) (map[string]any, error)
	Result(context.Context, identity.ActorContext, app.Result, operation.Context) (map[string]any, error)
	BeginAuto(context.Context, identity.ActorContext, int64, int64, operation.Context) (map[string]any, error)
	CollectAuto(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
}
type GodsTrialDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   GodsTrialPort
}

func (m GodsTrialDispatcher) Dispatch(c context.Context, r httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: m.Authority}).actor(c, r)
	if fail != nil {
		return *fail
	}
	bad := badHero("gods_trial_invalid_parameter")
	if m.Service == nil {
		return httpedge.Response{HTTPStatus: 503, Body: map[string]any{"error_code": int64(1)}}
	}
	p, op := r.Envelope.Params, r.Envelope.Operation
	var out map[string]any
	var e error
	switch r.Envelope.MID {
	case 3097, 3100, 3101:
		if !onlyStockGameplayParams(p) {
			return bad
		}
		switch r.Envelope.MID {
		case 3097:
			out, e = m.Service.Info(c, a, op)
		case 3101:
			out, e = m.Service.Detail(c, a, op)
		case 3100:
			out, e = m.Service.CollectAuto(c, a, op)
		}
	case 3099:
		if !onlyStockGameplayParams(p, "campaign_id", "times") {
			return bad
		}
		id, ok := topFloorInteger(p, "campaign_id", true)
		n, nok := topFloorInteger(p, "times", true)
		if !ok || !nok || id <= 0 || n < 1 || n > 10 {
			return bad
		}
		out, e = m.Service.BeginAuto(c, a, id, n, op)
	case 3092, 3093:
		id, ok := topFloorInteger(p, "campaign_id", true)
		kind, kok := topFloorInteger(p, "campaign_type", true)
		pet, pok := topFloorInteger(p, "pet_id", false)
		if !ok || !kok || !pok || id <= 0 || kind != 79 || pet < 0 {
			return bad
		}
		if r.Envelope.MID == 3092 {
			if !onlyStockGameplayParams(p, "campaign_id", "campaign_type", "formation", "pet_id", "rent_player_id", "rent_formation", "rent_pet_player_id", "rent_pet_id") {
				return bad
			}
			ids, valid := topFloorFormation(p["formation"])
			if !valid || len(ids) < 1 || len(ids) > 5 {
				return bad
			}
			rentPlayer, rentPlayerOK := topFloorInteger(p, "rent_player_id", false)
			rentUnit, rentUnitOK := topFloorIdentifier(p["rent_formation"], false)
			rentPetPlayer, rentPetPlayerOK := topFloorInteger(p, "rent_pet_player_id", false)
			rentPetUnit, rentPetUnitOK := topFloorIdentifier(p["rent_pet_id"], false)
			if !rentPlayerOK || !rentUnitOK || !rentPetPlayerOK || !rentPetUnitOK ||
				(rentPlayer == 0) != (rentUnit == 0) || (rentPetPlayer == 0) != (rentPetUnit == 0) {
				return bad
			}
			out, e = m.Service.Start(c, a, app.Fight{Campaign: id, Pet: pet, Formation: ids, RentPlayer: rentPlayer, RentUnit: rentUnit, RentPetPlayer: rentPetPlayer, RentPetUnit: rentPetUnit}, op)
		} else {
			if !onlyStockGameplayParams(p, "campaign_id", "campaign_type", "star", "partner_ids", "pet_id") {
				return bad
			}
			star, sok := topFloorInteger(p, "star", true)
			ids, ie := decodeHeroFumoMaterials(p["partner_ids"])
			if !sok || star < 0 || star > 3 || ie != nil || len(ids) < 1 || len(ids) > 5 {
				return bad
			}
			out, e = m.Service.Result(c, a, app.Result{Campaign: id, Star: star, Pet: pet, Formation: ids}, op)
		}
	default:
		return httpedge.Response{HTTPStatus: 501, Body: map[string]any{"error_code": int64(1)}}
	}
	if e != nil {
		var conflict *receipt.ConflictError
		if errors.Is(e, d.ErrInvalid) || errors.As(e, &conflict) {
			return bad
		}
		if errors.Is(e, d.ErrRefused) || errors.Is(e, economy.ErrInsufficientBalance) || errors.Is(e, pet.ErrPetNotFound) {
			return okI5(map[string]any{"error_code": int64(1)})
		}
		return httpedge.Response{HTTPStatus: 503, Body: map[string]any{"error_code": int64(1), "error": "gods_trial_failed"}}
	}
	return okI5(out)
}
