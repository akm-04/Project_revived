package stockruntime

import (
	"context"
	"encoding/json"
	"errors"

	app "gxb.local/backend/v2/internal/application/arena"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	projection "gxb.local/backend/v2/internal/projection/arena"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

var TournamentMIDs = []uint16{276, 1281, 1282, 1283, 1284, 1285, 1286, 1287, 1288, 1289, 1290, 1291, 1292, 1294, 1872, 1873, 1874, 1875, 1876, 1877}

type TournamentPort interface {
	PlayoffsView(context.Context, identity.ActorContext, operation.Context) (d.TournamentView, error)
	CasualView(context.Context, identity.ActorContext, operation.Context) (d.CasualView, error)
	EnrollTournament(context.Context, identity.ActorContext, operation.Context) (d.TournamentPeriod, error)
	SupportTournament(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (d.TournamentPeriod, error)
	DeclareTournament(context.Context, identity.ActorContext, string, operation.Context) (string, error)
	QueueCasual(context.Context, identity.ActorContext, operation.Context) (d.CasualEntry, error)
	CancelCasual(context.Context, identity.ActorContext, operation.Context) error
	ReadyTournament(context.Context, identity.ActorContext, ids.UUID, operation.Context) (d.TournamentRoom, error)
	SelectTournament(context.Context, identity.ActorContext, app.TournamentSelectionCommand, operation.Context) (d.TournamentRoom, error)
	TournamentRoom(context.Context, identity.ActorContext, ids.UUID, operation.Context) (d.TournamentRoom, error)
	TournamentSelectionView(context.Context, identity.ActorContext, ids.UUID, operation.Context) (d.TournamentRoomView, error)
	TournamentReport(context.Context, identity.ActorContext, ids.UUID, int, int, operation.Context) (d.TournamentRoomView, error)
	AcknowledgeTournament(context.Context, identity.ActorContext, ids.UUID, int64, operation.Context) error
}

type TournamentDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   TournamentPort
}

func (dispatcher TournamentDispatcher) Dispatch(requestContext context.Context, request httpedge.DispatchRequest) httpedge.Response {
	actor, failure := (HeroDispatcher{Authority: dispatcher.Authority}).actor(requestContext, request)
	if failure != nil {
		return *failure
	}
	if dispatcher.Service == nil {
		return failArena(d.ErrUnavailable)
	}
	params, operationContext := request.Envelope.Params, request.Envelope.Operation
	bad := badHero("invalid_tournament_parameter")
	switch request.Envelope.MID {
	case 1283, 1285, 1289:
		if !onlyStockGameplayParams(params) {
			return bad
		}
		view, err := dispatcher.Service.PlayoffsView(requestContext, actor, operationContext)
		if err != nil {
			return failArena(err)
		}
		if request.Envelope.MID == 1285 {
			return okI5(projection.PlayoffsSignList(view))
		}
		if request.Envelope.MID == 1289 {
			return okI5(projection.PlayoffsMatches(view))
		}
		return okI5(projection.PlayoffsInfo(view))
	case 1284:
		if !onlyStockGameplayParams(params) {
			return bad
		}
		period, err := dispatcher.Service.EnrollTournament(requestContext, actor, operationContext)
		if err != nil {
			return failArena(err)
		}
		_, enrolled := period.Entrant(actor.PlayerID)
		if !enrolled {
			return failArena(d.ErrConflict)
		}
		return okI5(map[string]any{"is_signed": int64(1)})
	case 1286:
		group, valid := topFloorInteger(params, "index", true)
		if !valid || group > d.TournamentGroupCount || !onlyStockGameplayParams(params, "index") {
			return bad
		}
		view, err := dispatcher.Service.PlayoffsView(requestContext, actor, operationContext)
		if err != nil {
			return failArena(err)
		}
		return okI5(projection.PlayoffsGroup(view, int(group)))
	case 1287:
		declaration, valid := params["dec"].(string)
		if !valid || !onlyStockGameplayParams(params, "dec") {
			return bad
		}
		stored, err := dispatcher.Service.DeclareTournament(requestContext, actor, declaration, operationContext)
		if err != nil {
			return failArena(err)
		}
		return okI5(map[string]any{"dec": stored})
	case 1288:
		target, valid := topFloorInteger(params, "support_player", true)
		if !valid || !onlyStockGameplayParams(params, "support_player") {
			return bad
		}
		_, err := dispatcher.Service.SupportTournament(requestContext, actor, identity.PlayerID(target), operationContext)
		if err != nil {
			return failArena(err)
		}
		view, err := dispatcher.Service.PlayoffsView(requestContext, actor, operationContext)
		if err != nil {
			return failArena(err)
		}
		return okI5(projection.TournamentSupport(view))
	case 1291:
		player, valid := topFloorInteger(params, "player_id", true)
		stage, stageValid := topFloorInteger(params, "stage", true)
		if !valid || !stageValid || stage < 3 || stage > 7 || !onlyStockGameplayParams(params, "player_id", "stage") {
			return bad
		}
		view, err := dispatcher.Service.PlayoffsView(requestContext, actor, operationContext)
		if err != nil {
			return failArena(err)
		}
		return httpedge.Response{HTTPStatus: 200, JSON: projection.TournamentRecords(view.Rooms, identity.PlayerID(player), int(stage))}
	case 1281, 1282, 1292, 1294:
		rawKey, valid := params["room_key"].(string)
		identifier, team, keyError := d.ParseSelectionKey(rawKey)
		if !valid || keyError != nil {
			return bad
		}
		if request.Envelope.MID == 1281 {
			if !onlyStockGameplayParams(params, "room_key") {
				return bad
			}
			before, readError := dispatcher.Service.TournamentRoom(requestContext, actor, identifier, operationContext)
			if readError != nil {
				return failArena(readError)
			}
			if before.Selection.Team != team {
				return failArena(d.ErrRefused)
			}
			room, err := dispatcher.Service.ReadyTournament(requestContext, actor, identifier, operationContext)
			if err != nil {
				return failArena(err)
			}
			if room.Selection.Team != team {
				return failArena(d.ErrRefused)
			}
			return okI5(map[string]any{"room_key": room.SelectionKey()})
		}
		turn, turnError := tournamentTurn(params["stage"])
		if turnError != nil {
			return bad
		}
		if request.Envelope.MID == 1282 {
			formation, formationError := arenaTableIDs(params["formation"])
			pet, petValid := topFloorInteger(params, "pet_id", false)
			if formationError != nil || !petValid || !onlyStockGameplayParams(params, "room_key", "stage", "formation", "pet_id") {
				return bad
			}
			room, err := dispatcher.Service.SelectTournament(requestContext, actor, app.TournamentSelectionCommand{Room: identifier, Team: team, Turn: turn, Formation: d.SelectedFormation{Heroes: formation, Pet: pet}}, operationContext)
			if err != nil {
				return failArena(err)
			}
			return okI5(map[string]any{"room_key": room.SelectionKey(), "stage": room.Selection.Turn})
		}
		if !onlyStockGameplayParams(params, "room_key", "stage") {
			return bad
		}
		room, err := dispatcher.Service.TournamentRoom(requestContext, actor, identifier, operationContext)
		if err != nil {
			return failArena(err)
		}
		if team > room.Selection.Team || team == room.Selection.Team && turn > room.Selection.Turn {
			return failArena(d.ErrRefused)
		}
		if request.Envelope.MID == 1294 {
			if team == room.Selection.Team && turn == room.Selection.Turn {
				if err := dispatcher.Service.AcknowledgeTournament(requestContext, actor, identifier, room.NoticeVersion, operationContext); err != nil {
					return failArena(err)
				}
			}
			return okI5(map[string]any{"room_key": rawKey, "stage": turn})
		}
		view, err := dispatcher.Service.TournamentSelectionView(requestContext, actor, identifier, operationContext)
		if err != nil {
			return failArena(err)
		}
		return okI5(projection.TournamentRoom(view))
	case 1290, 1877:
		raw, valid := params["record_id"].(string)
		identifier, identifierError := ids.ParseUUID(raw)
		stage, stageValid := topFloorInteger(params, "stage", false)
		round, roundValid := topFloorInteger(params, "index", true)
		if !valid || identifierError != nil || !stageValid || !roundValid || round > d.SelectionTeamCount || !onlyStockGameplayParams(params, "record_id", "stage", "index") {
			return bad
		}
		view, err := dispatcher.Service.TournamentReport(requestContext, actor, identifier, int(round), int(stage), operationContext)
		if err != nil {
			return failArena(err)
		}
		if view.Room.Casual != (request.Envelope.MID == 1877) {
			return failArena(d.ErrRefused)
		}
		return okI5(projection.TournamentReport(view))
	case 1874:
		raw, valid := params["record_id"].(string)
		identifier, identifierError := ids.ParseUUID(raw)
		if !valid || identifierError != nil || !onlyStockGameplayParams(params, "record_id") {
			return bad
		}
		reports := []map[string]any{}
		for round := 1; round <= d.SelectionTeamCount; round++ {
			view, err := dispatcher.Service.TournamentReport(requestContext, actor, identifier, round, 0, operationContext)
			if errors.Is(err, d.ErrRefused) {
				if round == 1 {
					return failArena(err)
				}
				break
			}
			if err != nil {
				return failArena(err)
			}
			if !view.Room.Casual {
				return failArena(d.ErrRefused)
			}
			reports = append(reports, projection.TournamentReport(view))
		}
		return okI5(map[string]any{"report_list": reports})
	case 1875:
		if !onlyStockGameplayParams(params) {
			return bad
		}
		entry, err := dispatcher.Service.QueueCasual(requestContext, actor, operationContext)
		if err != nil {
			return failArena(err)
		}
		return okI5(map[string]any{"need_match_time": int64(d.CasualQueueLifetime.Seconds()), "match_time": entry.AdmittedAt.Unix()})
	case 1876:
		if !onlyStockGameplayParams(params) {
			return bad
		}
		if err := dispatcher.Service.CancelCasual(requestContext, actor, operationContext); err != nil {
			return failArena(err)
		}
		return okI5(map[string]any{})
	case 276, 1872, 1873:
		if !onlyStockGameplayParams(params) {
			return bad
		}
		view, err := dispatcher.Service.CasualView(requestContext, actor, operationContext)
		if err != nil {
			return failArena(err)
		}
		if request.Envelope.MID == 276 {
			return okI5(map[string]any{"leisure_arena_rank": projection.CasualRanks(view)})
		}
		if request.Envelope.MID == 1873 {
			return okI5(map[string]any{"records": projection.TournamentRecords(view.Rooms, actor.PlayerID, 0)})
		}
		return okI5(projection.CasualInfo(view))
	}
	return bad
}

func tournamentTurn(raw any) (int, error) {
	if number, ok := raw.(json.Number); ok && number.String() == "0.5" {
		return 1, nil
	}
	if number, ok := raw.(float64); ok && number == 0.5 {
		return 1, nil
	}
	value, err := feedbackInteger(raw, 0, d.SelectionDoneTurn)
	if err != nil {
		return 0, err
	}
	return int(value), nil
}
