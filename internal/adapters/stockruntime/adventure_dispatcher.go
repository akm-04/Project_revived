package stockruntime

import (
	"context"
	"fmt"

	app "gxb.local/backend/v2/internal/application/adventure"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	sr "gxb.local/backend/v2/internal/application/sharedroom"
	d "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	room "gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// AdventureMIDs are the src_64 Adventure model MIDs of I9-8D. Zhuge MIDs stay
// out (C10).
var AdventureMIDs = []uint16{2410, 2411, 2412, 2413, 2416, 2417, 2418, 2419, 2420, 2421, 2422, 2423, 2424, 2425, 2426, 2427, 2428, 2429, 2430, 2431}

const (
	adventureFightExist = 30005
	adventureExpired    = 35029
	// Adventure does not enable a borrow mode (I9_GUILD_RENTAL_V1 C4), so a
	// stock rent field is refused. 35028 "Not Available" is the stock message
	// row; the client has no rent-specific row.
	adventureRentRefused = 35028
)

type AdventurePort interface {
	List(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	Info(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	BuyShop(context.Context, identity.ActorContext, int64, operation.Context) (app.Response, error)
	BuyCard(context.Context, identity.ActorContext, int64, operation.Context) (app.Response, error)
	Fight(context.Context, identity.ActorContext, app.FightRequest, operation.Context) (app.Response, error)
	StartSingle(context.Context, identity.ActorContext, app.FightRequest, operation.Context) (map[string]any, error)
	SettleSingle(context.Context, identity.ActorContext, app.ResultRequest, operation.Context) (app.Response, error)
	PrepareDefense(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	StartDefense(context.Context, identity.ActorContext, app.FightRequest, int64, operation.Context) (map[string]any, error)
	DefenseResult(context.Context, identity.ActorContext, app.ResultRequest, int64, operation.Context) (app.Response, error)
	QuitDefense(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	EnterDefense(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	InviteDefense(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (map[string]any, error)
	KickDefense(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (map[string]any, error)
	ExitDefense(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	CreateCoop(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	EnterCoop(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	InviteCoop(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (map[string]any, error)
	RemoveCoop(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (map[string]any, error)
	ExitCoop(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	EnterTeamFight(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	SelectCoop(context.Context, identity.ActorContext, app.PickRequest, operation.Context) (map[string]any, error)
	PrepareCoop(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	StartCoop(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
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
		return failureReply(defect(nil))
	}
	params, op := req.Envelope.Params, req.Envelope.Operation
	if adventureRented(params) {
		return failureReply(refusal(adventureRentRefused))
	}
	switch req.Envelope.MID {
	case 2416:
		if !onlyStockGameplayParams(params) {
			return badAdventure()
		}
		body, err := o.Service.List(ctx, a, op)
		return adventureResponse(body, app.Response{}, err)
	case 2417, 2418, 2420, 2423, 2428, 2430:
		tableID, ok := topFloorInteger(params, "table_id", true)
		if !ok || tableID <= 0 || !onlyStockGameplayParams(params, "table_id") {
			return badAdventure()
		}
		return o.singleEvent(ctx, a, req.Envelope.MID, tableID, op)
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
	case 2410:
		request, position, ok := adventureDefenseResult(params)
		if !ok {
			return badAdventure()
		}
		response, err := o.Service.DefenseResult(ctx, a, request, position, op)
		return adventureResponse(nil, response, err)
	case 2411:
		tableID, tableOK := topFloorInteger(params, "table_id", true)
		if !tableOK || tableID != d.EventIllusion || !onlyStockGameplayParams(params, "table_id") {
			return badAdventure()
		}
		body, err := o.Service.StartCoop(ctx, a, op)
		return adventureResponse(body, app.Response{}, err)
	case 2412, 2413, 2431:
		position, ok := topFloorInteger(params, "monster_pos", true)
		tableID, tableOK := topFloorInteger(params, "table_id", true)
		if !ok || !tableOK || tableID != d.EventDefense || position < 1 || position > d.DefenseMonsterCount {
			return badAdventure()
		}
		if req.Envelope.MID == 2412 {
			if !onlyStockGameplayParams(params, "monster_pos", "table_id") {
				return badAdventure()
			}
			body, err := o.Service.PrepareDefense(ctx, a, position, op)
			return adventureResponse(body, app.Response{}, err)
		}
		if req.Envelope.MID == 2413 {
			if !onlyStockGameplayParams(params, "monster_pos", "table_id") {
				return badAdventure()
			}
			body, err := o.Service.QuitDefense(ctx, a, position, op)
			return adventureResponse(body, app.Response{}, err)
		}
		request, ok := adventureDefenseStart(params)
		if !ok {
			return badAdventure()
		}
		body, err := o.Service.StartDefense(ctx, a, request, position, op)
		return adventureResponse(body, app.Response{}, err)
	case 2424, 2427:
		target, ok := topFloorInteger(params, "player_id", true)
		tableID, tableOK := topFloorInteger(params, "table_id", true)
		if !ok || !tableOK || target <= 0 || !onlyStockGameplayParams(params, "player_id", "table_id") {
			return badAdventure()
		}
		var body map[string]any
		var err error
		coop := tableID == d.EventIllusion
		if req.Envelope.MID == 2424 {
			if coop {
				body, err = o.Service.RemoveCoop(ctx, a, identity.PlayerID(target), op)
			} else {
				body, err = o.Service.KickDefense(ctx, a, identity.PlayerID(target), op)
			}
		} else if coop {
			body, err = o.Service.InviteCoop(ctx, a, identity.PlayerID(target), op)
		} else {
			body, err = o.Service.InviteDefense(ctx, a, identity.PlayerID(target), op)
		}
		return adventureResponse(body, app.Response{}, err)
	case 2425:
		roomID, roomOK := topFloorInteger(params, "room_id", true)
		tableID, tableOK := topFloorInteger(params, "table_id", true)
		if !roomOK || !tableOK || roomID <= 0 || !onlyStockGameplayParams(params, "room_id", "table_id") {
			return badAdventure()
		}
		if tableID == d.EventIllusion {
			body, err := o.Service.EnterCoop(ctx, a, roomID, op)
			return adventureResponse(body, app.Response{}, err)
		}
		body, err := o.Service.EnterDefense(ctx, a, roomID, op)
		return adventureResponse(body, app.Response{}, err)
	case 2426:
		tableID, ok := topFloorInteger(params, "table_id", true)
		if !ok || !onlyStockGameplayParams(params, "table_id") {
			return badAdventure()
		}
		if tableID == d.EventIllusion {
			body, err := o.Service.ExitCoop(ctx, a, op)
			return adventureResponse(body, app.Response{}, err)
		}
		body, err := o.Service.ExitDefense(ctx, a, op)
		return adventureResponse(body, app.Response{}, err)
	case 2429:
		request, ok := adventurePick(params)
		if !ok {
			return badAdventure()
		}
		body, err := o.Service.SelectCoop(ctx, a, request, op)
		return adventureResponse(body, app.Response{}, err)
	default:
		return badAdventure()
	}
}

func (o AdventureDispatcher) singleEvent(ctx context.Context, a identity.ActorContext, mid uint16, tableID int64, op operation.Context) httpedge.Response {
	switch mid {
	case 2417:
		body, err := o.Service.Info(ctx, a, tableID, op)
		return adventureResponse(body, app.Response{}, err)
	case 2418:
		response, err := o.Service.BuyShop(ctx, a, tableID, op)
		return adventureResponse(nil, response, err)
	case 2420:
		response, err := o.Service.BuyCard(ctx, a, tableID, op)
		return adventureResponse(nil, response, err)
	case 2423:
		if tableID != d.EventIllusion {
			return badAdventure()
		}
		body, err := o.Service.CreateCoop(ctx, a, op)
		return adventureResponse(body, app.Response{}, err)
	case 2428:
		if tableID != d.EventIllusion {
			return badAdventure()
		}
		body, err := o.Service.EnterTeamFight(ctx, a, op)
		return adventureResponse(body, app.Response{}, err)
	}
	if tableID != d.EventIllusion {
		return badAdventure()
	}
	body, err := o.Service.PrepareCoop(ctx, a, op)
	return adventureResponse(body, app.Response{}, err)
}

func adventureRented(params map[string]any) bool {
	for _, key := range []string{"rent_player_id", "rent_formation", "rent_pet_player_id", "rent_pet_id"} {
		raw, present := params[key]
		if !present || raw == nil {
			continue
		}
		text := fmt.Sprint(raw)
		if text != "" && text != "0" {
			return true
		}
	}
	return false
}

// adventureFight reads 2419/2421: formation plus an optional pet; a nonzero
// rent field is refused in Dispatch before this parser runs.
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

// adventureDefenseResult reads 2410: the client's star, position and damage.
func adventureDefenseResult(params map[string]any) (app.ResultRequest, int64, bool) {
	star, starOK := topFloorInteger(params, "star", true)
	damage, damageOK := topFloorInteger(params, "total_damage", true)
	position, positionOK := topFloorInteger(params, "monster_pos", true)
	pet, petOK := topFloorInteger(params, "pet_id", false)
	formation, formationOK := topFloorFormation(params["formation"])
	allowed := onlyStockGameplayParams(params, "star", "total_damage", "monster_pos", "formation", "pet_id", "table_id", "rent_pet_id", "rent_pet_player_id", "rent_formation", "rent_player_id")
	request := app.ResultRequest{Star: star, Damage: damage, PetID: pet, Formation: formation}
	return request, position, allowed && starOK && damageOK && positionOK && petOK && formationOK
}

func adventureDefenseStart(params map[string]any) (app.FightRequest, bool) {
	formation, formationOK := topFloorFormation(params["formation"])
	pet, petOK := topFloorInteger(params, "pet_id", false)
	allowed := onlyStockGameplayParams(params, "formation", "pet_id", "monster_pos", "table_id", "rent_pet_id", "rent_pet_player_id", "rent_formation", "rent_player_id")
	return app.FightRequest{Formation: formation, PetID: pet}, allowed && formationOK && petOK
}

func adventurePick(params map[string]any) (app.PickRequest, bool) {
	partner, partnerOK := topFloorInteger(params, "partner_id", false)
	pet, petOK := topFloorInteger(params, "pet_id", false)
	position, positionOK := topFloorInteger(params, "pos", false)
	tableID, tableOK := topFloorInteger(params, "table_id", true)
	allowed := onlyStockGameplayParams(params, "partner_id", "pet_id", "pos", "table_id")
	return app.PickRequest{PartnerID: partner, Position: position, PetID: pet}, allowed && partnerOK && petOK && positionOK && tableOK && tableID == d.EventIllusion
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

// Adventure keeps refusals on 409 so the stock callbacks never receive an OK
// body; 35029 and the room codes come from the R4 mapper table.
var adventureFailureRows = []failureRow{
	{match: d.ErrInvalid, class: failureMalformed, detail: "adventure_invalid_parameter"},
	{match: d.ErrExpired, class: failureRefusal, code: adventureExpired},
	{match: d.ErrRefused, class: failureRefusal, code: unprovenRefusalCode},
	{match: economy.ErrInsufficientBalance, class: failureRefusal, balance: true},
	{match: sr.ErrNotInRoom, class: failureRefusal, code: unprovenRefusalCode},
	{match: sr.ErrAlreadyInRoom, class: failureRefusal, code: adventureExpired}, // I9_ADVENTURE_POLICY_V1 rooms.second_room_for_slot
	{match: sr.ErrNotFound, class: failureRefusal, code: unprovenRefusalCode},
	{match: room.ErrFull, class: failureRefusal, code: unprovenRefusalCode},
	{match: room.ErrKicked, class: failureRefusal, code: unprovenRefusalCode},
	{match: room.ErrExpired, class: failureRefusal, code: unprovenRefusalCode},
	{match: room.ErrClosed, class: failureRefusal, code: unprovenRefusalCode},
	{match: room.ErrNotOwner, class: failureRefusal, code: unprovenRefusalCode},
	{match: room.ErrNotSeated, class: failureRefusal, code: unprovenRefusalCode},
	{match: economy.ErrUnknownResource, class: failureDefect},
}

func failAdventure(err error) httpedge.Response {
	return failureFromRows(adventureFailureRows, err)
}

func badAdventure() httpedge.Response {
	return badHero("adventure_invalid_parameter")
}
