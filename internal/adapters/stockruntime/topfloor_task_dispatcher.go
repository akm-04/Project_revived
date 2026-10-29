package stockruntime

import (
	"context"
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/application/realtimeauth"
	app "gxb.local/backend/v2/internal/application/topfloor"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/operation"
	projection "gxb.local/backend/v2/internal/projection/topfloor"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"net/http"
	"strconv"
	"strings"
)

var TopFloorTaskMIDs = []uint16{282, 283, 284, 285, 286, 287, 295, 296, 298, 299, 300}

type TopFloorTaskPort interface {
	LoadTask(context.Context, identity.ActorContext, operation.Context, bool) (app.TaskArenaView, error)
	SaveTaskDefense(context.Context, identity.ActorContext, domain.TaskModeDefense, operation.Context) error
	TaskPreFight(context.Context, identity.ActorContext, int64) error
	StartTask(context.Context, identity.ActorContext, app.TaskStartCommand, operation.Context) (app.FightView, error)
	PurchaseTask(context.Context, identity.ActorContext, operation.Context, bool) (domain.Player, error)
	TaskFormation(context.Context, identity.ActorContext, int64) (domain.Display, error)
	TaskReport(context.Context, identity.ActorContext, string) ([]byte, error)
	TaskRecordInfo(context.Context, identity.ActorContext, int64) (app.RecordInfo, error)
	TaskSchedule(context.Context) ([]domain.TaskModeRotation, error)
}
type TopFloorTaskDispatcher struct {
	Authority realtimeauth.GameplayAuthorityPort
	Service   TopFloorTaskPort
}

func failTopFloorTask(err error) httpedge.Response {
	if errors.Is(err, domain.ErrInvalid) {
		return badHero("invalid_top_floor_task_parameter")
	}
	return failTopFloor(err)
}
func (dispatcher TopFloorTaskDispatcher) Dispatch(requestContext context.Context, request httpedge.DispatchRequest) httpedge.Response {
	actor, failure := (HeroDispatcher{Authority: dispatcher.Authority}).actor(requestContext, request)
	if failure != nil {
		return *failure
	}
	if dispatcher.Service == nil {
		return failTopFloor(domain.ErrUnavailable)
	}
	parameters, op := request.Envelope.Params, request.Envelope.Operation
	bad := badHero("invalid_top_floor_task_parameter")
	switch request.Envelope.MID {
	case 282, 283:
		if !onlyStockGameplayParams(parameters) {
			return bad
		}
		view, err := dispatcher.Service.LoadTask(requestContext, actor, op, request.Envelope.MID == 283)
		if err != nil {
			return failTopFloorTask(err)
		}
		if request.Envelope.MID == 283 {
			return okI5(projection.Enemies(view.Enemies))
		}
		body := projection.Arena(view.Player, view.Rank, view.Enemies, view.ServerTime)
		body["mode"], body["submode"], body["leader"] = view.Rotation.Mode, view.Rotation.Submode, view.Leader
		heroes := []string{}
		for _, hero := range view.Player.Defense {
			heroes = append(heroes, strconv.FormatInt(hero, 10))
		}
		body[fmt.Sprintf("defense_%d", view.Rotation.Mode)] = strings.Join(heroes, "|")
		return okI5(body)
	case 284:
		if !onlyStockGameplayParams(parameters, "heroIDs", "pet_id", "leader_id") {
			return bad
		}
		raw, valid := parameters["heroIDs"].([]any)
		pet, petOK := topFloorInteger(parameters, "pet_id", false)
		leader, leaderOK := topFloorInteger(parameters, "leader_id", false)
		if !valid || !petOK || !leaderOK {
			return bad
		}
		heroes := []int64{}
		for _, value := range raw {
			hero, err := feedbackInteger(value, 1, 9007199254740991)
			if err != nil {
				return bad
			}
			heroes = append(heroes, hero)
		}
		if err := dispatcher.Service.SaveTaskDefense(requestContext, actor, domain.TaskModeDefense{Heroes: heroes, Pet: pet, Leader: leader}, op); err != nil {
			return failTopFloorTask(err)
		}
		return okI5(map[string]any{})
	case 285:
		enemy, valid := topFloorInteger(parameters, "enemy_id", false)
		if !valid || !onlyStockGameplayParams(parameters, "enemy_id") {
			return bad
		}
		if err := dispatcher.Service.TaskPreFight(requestContext, actor, enemy); err != nil {
			return failTopFloorTask(err)
		}
		return okI5(map[string]any{})
	case 286:
		formation, formationOK := topFloorFormation(parameters["formation"])
		pet, petOK := topFloorInteger(parameters, "pet_id", false)
		leader, leaderOK := topFloorInteger(parameters, "leader_id", false)
		enemy, enemyOK := topFloorInteger(parameters, "enemy_id", true)
		avenge, avengeOK := topFloorInteger(parameters, "is_avenge", false)
		campaign, campaignOK := topFloorInteger(parameters, "campaign_type", false)
		_, battleOK := topFloorInteger(parameters, "campaign_id", false)
		if !formationOK || !petOK || !leaderOK || !enemyOK || !avengeOK || avenge > 1 || !campaignOK || campaign != 0 && campaign != domain.TaskModeCampaignType || !battleOK || !onlyStockGameplayParams(parameters, "formation", "pet_id", "leader_id", "enemy_id", "is_avenge", "campaign_id", "campaign_type") {
			return bad
		}
		view, err := dispatcher.Service.StartTask(requestContext, actor, app.TaskStartCommand{StartCommand: app.StartCommand{Formation: formation, PetID: pet, Enemy: enemy, Avenge: avenge == 1}, Leader: leader}, op)
		if err != nil {
			return failTopFloorTask(err)
		}
		return okI5(projection.Fight(view.Formation, view.Report, view.Win, 0, view.Enemy))
	case 287, 296:
		if !onlyStockGameplayParams(parameters) {
			return bad
		}
		player, err := dispatcher.Service.PurchaseTask(requestContext, actor, op, request.Envelope.MID == 296)
		if err != nil {
			return failTopFloorTask(err)
		}
		return okI5(projection.Ticket(player))
	case 295:
		player, valid := topFloorInteger(parameters, "other_player_id", true)
		if !valid || !onlyStockGameplayParams(parameters, "other_player_id") {
			return bad
		}
		display, err := dispatcher.Service.TaskFormation(requestContext, actor, player)
		if err != nil {
			return failTopFloorTask(err)
		}
		return okI5(projection.Formation(display))
	case 298:
		key, valid := parameters["report_key"].(string)
		player, playerOK := topFloorInteger(parameters, "player_id", false)
		if !valid || !playerOK || player != 0 && player != int64(actor.PlayerID) || !onlyStockGameplayParams(parameters, "player_id", "report_key") {
			return bad
		}
		report, err := dispatcher.Service.TaskReport(requestContext, actor, key)
		if err != nil {
			return failTopFloorTask(err)
		}
		return okI5(projection.Report(report))
	case 299:
		id, valid := topFloorInteger(parameters, "id", true)
		if !valid || !onlyStockGameplayParams(parameters, "id") {
			return bad
		}
		info, err := dispatcher.Service.TaskRecordInfo(requestContext, actor, id)
		if err != nil {
			return failTopFloorTask(err)
		}
		return okI5(projection.RecordInfo(info.Opponent, info.CanAvenge, info.AvengeType))
	case 300:
		if !onlyStockGameplayParams(parameters) {
			return bad
		}
		schedule, err := dispatcher.Service.TaskSchedule(requestContext)
		if err != nil {
			return failTopFloorTask(err)
		}
		rows := []map[string]any{}
		for _, slot := range schedule {
			rows = append(rows, map[string]any{"mode": slot.Mode, "submode": slot.Submode, "start_time": slot.StartsAt.Unix(), "end_time": slot.EndsAt.Unix()})
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, JSON: rows}
	}
	return bad
}
