package stockruntime

import (
	"context"
	"errors"
	"net/http"

	app "gxb.local/backend/v2/internal/application/adventure"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	d "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// AdventureMIDs are the single-player Adventure MIDs of I9-8D part 2: the
// list/info reads, shop and card buys, the PVP fight and the Fantasy single.
// Room MIDs 2410-2413 and 2423-2431 arrive with SharedRoom in part 3; Zhuge
// MIDs stay out (C10).
var AdventureMIDs = []uint16{2416, 2417, 2418, 2419, 2420, 2421, 2422}

const (
	adventureFightExist = 30005
	adventureExpired    = 35029
)

type AdventurePort interface {
	List(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	Info(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	BuyShop(context.Context, identity.ActorContext, int64, operation.Context) (app.Response, error)
	BuyCard(context.Context, identity.ActorContext, int64, operation.Context) (app.Response, error)
	Fight(context.Context, identity.ActorContext, app.FightRequest, operation.Context) (app.Response, error)
	StartSingle(context.Context, identity.ActorContext, app.FightRequest, operation.Context) (map[string]any, error)
	SettleSingle(context.Context, identity.ActorContext, app.ResultRequest, operation.Context) (app.Response, error)
}

type AdventureDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   AdventurePort
}

func (o AdventureDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: o.Authority}).actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if o.Service == nil {
		return failAdventure(d.ErrUnavailable)
	}
	params, op := req.Envelope.Params, req.Envelope.Operation
	switch req.Envelope.MID {
	case 2416:
		if !onlyStockGameplayParams(params) {
			return badAdventure()
		}
		body, err := o.Service.List(ctx, a, op)
		return adventureResponse(body, app.Response{}, err)
	case 2417, 2418, 2420:
		tableID, ok := topFloorInteger(params, "table_id", true)
		if !ok || tableID <= 0 || !onlyStockGameplayParams(params, "table_id") {
			return badAdventure()
		}
		if req.Envelope.MID == 2417 {
			body, err := o.Service.Info(ctx, a, tableID, op)
			return adventureResponse(body, app.Response{}, err)
		}
		if req.Envelope.MID == 2418 {
			response, err := o.Service.BuyShop(ctx, a, tableID, op)
			return adventureResponse(nil, response, err)
		}
		response, err := o.Service.BuyCard(ctx, a, tableID, op)
		return adventureResponse(nil, response, err)
	case 2419, 2421:
		request, ok := adventureFight(params)
		if !ok {
			return badAdventure()
		}
		if req.Envelope.MID == 2419 {
			response, err := o.Service.Fight(ctx, a, request, op)
			return adventureResponse(nil, response, err)
		}
		body, err := o.Service.StartSingle(ctx, a, request, op)
		return adventureResponse(body, app.Response{}, err)
	case 2422:
		request, ok := adventureResult(params)
		if !ok {
			return badAdventure()
		}
		response, err := o.Service.SettleSingle(ctx, a, request, op)
		return adventureResponse(nil, response, err)
	default:
		return badAdventure()
	}
}

// adventureFight reads 2419/2421: formation plus an optional pet; the client's
// rent_ fields are accepted and ignored.
func adventureFight(params map[string]any) (app.FightRequest, bool) {
	formation, formationOK := topFloorFormation(params["formation"])
	pet, petOK := topFloorInteger(params, "pet_id", false)
	allowed := onlyStockGameplayParams(params, "formation", "pet_id", "rent_pet_id", "rent_pet_player_id", "rent_formation", "rent_player_id")
	return app.FightRequest{Formation: formation, PetID: pet}, allowed && formationOK && petOK
}

// adventureResult reads 2422's attested summary.
func adventureResult(params map[string]any) (app.ResultRequest, bool) {
	star, starOK := topFloorInteger(params, "star", true)
	damage, damageOK := topFloorInteger(params, "total_damage", true)
	pet, petOK := topFloorInteger(params, "pet_id", false)
	formation, formationOK := topFloorFormation(params["formation"])
	allowed := onlyStockGameplayParams(params, "star", "total_damage", "formation", "pet_id", "rent_pet_id", "rent_pet_player_id", "rent_formation", "rent_player_id")
	return app.ResultRequest{Star: star, Damage: damage, PetID: pet, Formation: formation}, allowed && starOK && damageOK && petOK && formationOK
}

func adventureResponse(body map[string]any, response app.Response, err error) httpedge.Response {
	if err != nil {
		return failAdventure(err)
	}
	if response.Body != nil {
		body = response.Body
	}
	if body == nil {
		body = map[string]any{}
	}
	if response.Duplicate {
		body["error_code"] = int64(adventureFightExist)
	}
	return okI5(body)
}

func failAdventure(err error) httpedge.Response {
	if errors.Is(err, d.ErrInvalid) {
		return badAdventure()
	}
	if errors.Is(err, d.ErrExpired) {
		return okI5(map[string]any{"error_code": int64(adventureExpired)})
	}
	if errors.Is(err, d.ErrRefused) || errors.Is(err, d.ErrUnavailable) || errors.Is(err, economy.ErrInsufficientBalance) || errors.Is(err, economy.ErrUnknownResource) {
		return okI5(map[string]any{"error_code": int64(1)})
	}
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: err, Body: map[string]any{"error": "adventure_unavailable"}}
}

func badAdventure() httpedge.Response {
	return badHero("adventure_invalid_parameter")
}
