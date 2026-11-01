package stockruntime

import (
	"context"
	"errors"
	"fmt"
	"math"
	"net/http"
	"strconv"

	app "gxb.local/backend/v2/internal/application/illusion"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// IllusionMIDs are the src_64 Illusion model MIDs (mid.lua 508): the solo flow
// and the rank detail. The team room MIDs belong to the shared room dispatcher.
var IllusionMIDs = []uint16{1344, 1345, 1346, 1347, 1364}

const illusionFightExist = 30005

type IllusionPort interface {
	Info(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	Buy(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	Start(context.Context, identity.ActorContext, app.StartRequest, operation.Context) (map[string]any, error)
	Settle(context.Context, identity.ActorContext, app.ResultRequest, operation.Context) (app.Response, error)
	MemberTeam(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (map[string]any, error)
}

type IllusionDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   IllusionPort
}

func (o IllusionDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: o.Authority}).actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if o.Service == nil {
		return failIllusion(d.ErrUnavailable)
	}
	params, op := req.Envelope.Params, req.Envelope.Operation
	bad := badHero("illusion_invalid_parameter")
	switch req.Envelope.MID {
	case 1344:
		if !onlyStockGameplayParams(params) {
			return bad
		}
		body, err := o.Service.Info(ctx, a, op)
		if err != nil {
			return failIllusion(err)
		}
		return okI5(body)
	case 1345:
		if !onlyStockGameplayParams(params) {
			return bad
		}
		body, err := o.Service.Buy(ctx, a, op)
		if err != nil {
			return failIllusion(err)
		}
		return okI5(body)
	case 1346:
		request, ok := illusionStart(params)
		if !ok {
			return bad
		}
		body, err := o.Service.Start(ctx, a, request, op)
		if err != nil {
			return failIllusion(err)
		}
		return okI5(body)
	case 1347:
		request, ok := illusionResult(params)
		if !ok {
			return bad
		}
		response, err := o.Service.Settle(ctx, a, request, op)
		if err != nil {
			return failIllusion(err)
		}
		return illusionTerminal(response)
	case 1364:
		member, ok := topFloorInteger(params, "player_id", true)
		if !ok || member <= 0 || !onlyStockGameplayParams(params, "player_id") {
			return bad
		}
		body, err := o.Service.MemberTeam(ctx, a, identity.PlayerID(member), op)
		if err != nil {
			return failIllusion(err)
		}
		return okI5(body)
	}
	return bad
}

// illusionStart reads SelectTeamNewWindow's 1346 solo fight.
func illusionStart(params map[string]any) (app.StartRequest, bool) {
	formation, ok := topFloorFormation(params["formation"])
	pet, petOK := topFloorInteger(params, "pet_id", false)
	rentPlayer, rentPlayerOK := topFloorInteger(params, "rent_player_id", false)
	rentUnit, rentUnitOK := topFloorIdentifier(params["rent_formation"], false)
	rentPetPlayer, rentPetPlayerOK := topFloorInteger(params, "rent_pet_player_id", false)
	rentPetUnit, rentPetUnitOK := topFloorIdentifier(params["rent_pet_id"], false)
	allowed := onlyStockGameplayParams(params, "formation", "pet_id", "rent_player_id", "rent_formation", "rent_pet_player_id", "rent_pet_id", "tutor_rent_hero", "rent_hero_player", "rent_hero_id")
	if !allowed || !ok || !petOK || !rentPlayerOK || !rentUnitOK || !rentPetPlayerOK || !rentPetUnitOK ||
		(rentPlayer == 0) != (rentUnit == 0) || (rentPetPlayer == 0) != (rentPetUnit == 0) {
		return app.StartRequest{}, false
	}
	return app.StartRequest{Formation: formation, PetID: pet, RentPlayer: rentPlayer, RentUnit: rentUnit, RentPetPlayer: rentPetPlayer, RentPetUnit: rentPetUnit}, true
}

// illusionResult reads BattleCreate's 1347 client summary.
func illusionResult(params map[string]any) (app.ResultRequest, bool) {
	star, starOK := topFloorInteger(params, "star", true)
	damage, damageOK := illusionDamage(params["total_damage"])
	formation, formationOK := topFloorFormation(params["formation"])
	costTime, costOK := topFloorInteger(params, "cost_time", true)
	pet, petOK := topFloorInteger(params, "pet_id", false)
	allowed := onlyStockGameplayParams(params, "star", "total_damage", "formation", "cost_time", "pet_id", "rent_formation", "rent_player_id")
	if !allowed || !starOK || !damageOK || !formationOK || !costOK || !petOK || star > 1 {
		return app.ResultRequest{}, false
	}
	return app.ResultRequest{Star: star, Damage: damage, CostTime: costTime, PetID: pet, Formation: formation}, true
}

func illusionDamage(raw any) (int64, bool) {
	value, err := strconv.ParseFloat(fmt.Sprint(raw), 64)
	if err != nil || math.IsNaN(value) || math.IsInf(value, 0) || value < 0 {
		return 0, false
	}
	if value > float64(d.DamageCap) {
		value = float64(d.DamageCap)
	}
	return int64(value), true
}

func illusionTerminal(response app.Response) httpedge.Response {
	if response.Body == nil {
		response.Body = map[string]any{}
	}
	if response.Duplicate {
		response.Body["error_code"] = int64(illusionFightExist)
	}
	return okI5(response.Body)
}

func failIllusion(err error) httpedge.Response {
	var conflict *receipt.ConflictError
	if errors.Is(err, d.ErrInvalid) || errors.As(err, &conflict) {
		return badHero("illusion_invalid_parameter")
	}
	if errors.Is(err, d.ErrRefused) || errors.Is(err, cd.ErrLoanRefused) || errors.Is(err, economy.ErrInsufficientBalance) {
		return conflictRefusal(1)
	}
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: err, Body: map[string]any{"error": "illusion_unavailable"}}
}
