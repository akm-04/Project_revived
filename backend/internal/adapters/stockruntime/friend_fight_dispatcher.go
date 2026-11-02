package stockruntime

import (
	"context"
	app "gxb.local/backend/v2/internal/application/arena"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	projection "gxb.local/backend/v2/internal/projection/arena"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

var FriendFightMIDs = []uint16{1312, 1313, 1314, 1315}

type FriendFightPort interface {
	InviteFriendFight(context.Context, identity.ActorContext, app.FriendFightCommand, operation.Context) (d.FriendInvitation, error)
	AcceptFriendFight(context.Context, identity.ActorContext, app.FriendFightCommand, operation.Context) (d.TournamentRoom, error)
	RejectFriendFight(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) error
	TournamentReport(context.Context, identity.ActorContext, ids.UUID, int, int, operation.Context) (d.TournamentRoomView, error)
}
type FriendFightDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   FriendFightPort
}

func (dispatcher FriendFightDispatcher) Dispatch(requestContext context.Context, request httpedge.DispatchRequest) httpedge.Response {
	actor, failure := (HeroDispatcher{Authority: dispatcher.Authority}).actor(requestContext, request)
	if failure != nil {
		return *failure
	}
	if dispatcher.Service == nil {
		return failArena(d.ErrUnavailable)
	}
	params, operationContext := request.Envelope.Params, request.Envelope.Operation
	bad := badHero("invalid_friend_fight_parameter")
	if request.Envelope.MID == 1314 {
		raw, valid := params["record_id"].(string)
		identifier, parseError := ids.ParseUUID(raw)
		round, roundValid := topFloorInteger(params, "index", true)
		if !valid || parseError != nil || !roundValid || round > d.SelectionTeamCount || !onlyStockGameplayParams(params, "record_id", "index") {
			return bad
		}
		view, err := dispatcher.Service.TournamentReport(requestContext, actor, identifier, int(round), 0, operationContext)
		if err != nil {
			return failArena(err)
		}
		if !view.Room.IsFriendFight() {
			return failArena(d.ErrRefused)
		}
		return okI5(projection.TournamentReport(view))
	}
	player, valid := topFloorInteger(params, "player_id", true)
	if !valid {
		return bad
	}
	if request.Envelope.MID == 1315 {
		if !onlyStockGameplayParams(params, "player_id") {
			return bad
		}
		if err := dispatcher.Service.RejectFriendFight(requestContext, actor, identity.PlayerID(player), operationContext); err != nil {
			return failArena(err)
		}
		return okI5(map[string]any{})
	}
	mode, modeValid := topFloorInteger(params, "model", true)
	gameType, typeValid := topFloorInteger(params, "game_type", true)
	if !modeValid || !typeValid || mode > 2 || gameType > 2 || !onlyStockGameplayParams(params, "player_id", "model", "game_type") {
		return bad
	}
	command := app.FriendFightCommand{Player: identity.PlayerID(player), Mode: int(mode), GameType: int(gameType)}
	switch request.Envelope.MID {
	case 1312:
		if _, err := dispatcher.Service.InviteFriendFight(requestContext, actor, command, operationContext); err != nil {
			return failArena(err)
		}
	case 1313:
		if _, err := dispatcher.Service.AcceptFriendFight(requestContext, actor, command, operationContext); err != nil {
			return failArena(err)
		}
	default:
		return bad
	}
	return okI5(map[string]any{})
}
