package stockruntime

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/application/memoir"
	"gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/memoir"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"sort"
	"strconv"
)

var MemoirMIDs = []uint16{2304, 2305, 2306, 2307, 2308, 2309, 2310, 2311, 2312, 2313, 2314, 2315}

type MemoirPort interface {
	Info(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	Start(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	SaveMap(context.Context, identity.ActorContext, int, []int, operation.Context) (map[string]any, error)
	OpenBox(context.Context, identity.ActorContext, int, operation.Context) (map[string]any, error)
	NextFloor(context.Context, identity.ActorContext, int, operation.Context) (map[string]any, error)
	EnemyInfo(context.Context, identity.ActorContext, int, operation.Context) (map[string]any, error)
	MonsterResult(context.Context, identity.ActorContext, memoir.MonsterResult, operation.Context) (map[string]any, error)
	PlayerFight(context.Context, identity.ActorContext, memoir.PlayerFight, operation.Context) (map[string]any, error)
	Abandon(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	FinalAward(context.Context, identity.ActorContext, int, int64, operation.Context) (map[string]any, error)
	StartFight(context.Context, identity.ActorContext, int, operation.Context) (map[string]any, error)
	Revive(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
}

var _ MemoirPort = memoir.Mode{}

type MemoirDispatcher struct {
	Authority realtimeauth.GameplayAuthorityPort
	Service   MemoirPort
}

func (dispatcher MemoirDispatcher) Dispatch(ctx context.Context, request httpedge.DispatchRequest) httpedge.Response {
	actor, failure := (HeroDispatcher{Authority: dispatcher.Authority}).actor(ctx, request)
	if failure != nil {
		return *failure
	}
	if dispatcher.Service == nil {
		return memoirFailure(domain.ErrUnavailable)
	}
	parameters, operationContext := request.Envelope.Params, request.Envelope.Operation
	invalid := badHero("memoir_invalid_parameter")
	var response map[string]any
	var err error
	switch request.Envelope.MID {
	case 2304, 2312:
		if !onlyStockGameplayParams(parameters) {
			return invalid
		}
		if request.Envelope.MID == 2304 {
			response, err = dispatcher.Service.Info(ctx, actor, operationContext)
		} else {
			response, err = dispatcher.Service.Abandon(ctx, actor, operationContext)
		}
	case 2305, 2315:
		name := "hero_id"
		if request.Envelope.MID == 2315 {
			name = "partner_id"
		}
		identifier, valid := topFloorInteger(parameters, name, true)
		if !valid || identifier <= 0 || identifier > 9007199254740991 || !onlyStockGameplayParams(parameters, name) {
			return invalid
		}
		if request.Envelope.MID == 2305 {
			response, err = dispatcher.Service.Start(ctx, actor, identifier, operationContext)
		} else {
			response, err = dispatcher.Service.Revive(ctx, actor, identifier, operationContext)
		}
	case 2306:
		if !onlyStockGameplayParams(parameters, "now_pos", "open_grids") {
			return invalid
		}
		position, valid := topFloorInteger(parameters, "now_pos", true)
		opened, openedValid := memoirOpened(parameters["open_grids"])
		if !valid || position < 1 || position > domain.BoardCells || !openedValid {
			return invalid
		}
		response, err = dispatcher.Service.SaveMap(ctx, actor, int(position), opened, operationContext)
	case 2307, 2308, 2309, 2314:
		position, valid := topFloorInteger(parameters, "grid_pos", true)
		if !valid || position < 1 || position > domain.BoardCells || !onlyStockGameplayParams(parameters, "grid_pos") {
			return invalid
		}
		switch request.Envelope.MID {
		case 2307:
			response, err = dispatcher.Service.OpenBox(ctx, actor, int(position), operationContext)
		case 2308:
			response, err = dispatcher.Service.NextFloor(ctx, actor, int(position), operationContext)
		case 2309:
			response, err = dispatcher.Service.EnemyInfo(ctx, actor, int(position), operationContext)
		case 2314:
			response, err = dispatcher.Service.StartFight(ctx, actor, int(position), operationContext)
		}
	case 2313:
		position, valid := topFloorInteger(parameters, "grid_pos", true)
		award, awardValid := topFloorInteger(parameters, "award_id", true)
		if !valid || position < 1 || position > domain.BoardCells || !awardValid || award <= 0 || !onlyStockGameplayParams(parameters, "grid_pos", "award_id") {
			return invalid
		}
		response, err = dispatcher.Service.FinalAward(ctx, actor, int(position), award, operationContext)
	case 2311:
		if !onlyStockGameplayParams(parameters, "grid_pos", "formation", "pet_id") {
			return invalid
		}
		position, valid := topFloorInteger(parameters, "grid_pos", true)
		formation, formationValid := memoirFormation(parameters["formation"])
		pet, petValid := topFloorInteger(parameters, "pet_id", false)
		if !valid || position < 1 || position > domain.BoardCells || !formationValid || !petValid || pet < 0 || pet > 9007199254740991 {
			return invalid
		}
		response, err = dispatcher.Service.PlayerFight(ctx, actor, memoir.PlayerFight{Grid: int(position), Formation: formation, Pet: pet}, operationContext)
	case 2310:
		result, valid := memoirResult(parameters, int64(actor.PlayerID))
		if !valid {
			return invalid
		}
		response, err = dispatcher.Service.MonsterResult(ctx, actor, result, operationContext)
	default:
		return httpedge.Response{HTTPStatus: 501, Body: map[string]any{"error_code": int64(1)}}
	}
	if err != nil {
		return memoirFailure(err)
	}
	return okI5(response)
}
func memoirFailure(err error) httpedge.Response {
	var conflict *receipt.ConflictError
	if errors.Is(err, domain.ErrInvalid) || errors.As(err, &conflict) {
		return badHero("memoir_invalid_parameter")
	}
	if errors.Is(err, domain.ErrRefused) || errors.Is(err, economy.ErrInsufficientBalance) || errors.Is(err, combat.ErrStartConflict) {
		return conflictRefusal(1)
	}
	return httpedge.Response{HTTPStatus: 503, Body: map[string]any{"error_code": int64(1), "error": "memoir_failed"}, Cause: err}
}
func memoirOpened(raw any) ([]int, bool) {
	if fields, valid := raw.(map[string]any); valid && len(fields) == 0 {
		return []int{}, true
	}
	rows, valid := raw.([]any)
	if !valid || len(rows) > domain.BoardCells {
		return nil, false
	}
	result := make([]int, 0, len(rows))
	seen := map[int64]bool{}
	for _, raw := range rows {
		value, err := feedbackInteger(raw, 1, domain.BoardCells)
		if err != nil || seen[value] {
			return nil, false
		}
		seen[value] = true
		result = append(result, int(value))
	}
	return result, true
}
func memoirFormation(raw any) ([]int64, bool) {
	if _, valid := raw.(string); !valid {
		return nil, false
	}
	formation, valid := topFloorFormation(raw)
	if !valid || !marchFormation(formation) {
		return nil, false
	}
	for _, identifier := range formation {
		if identifier <= 0 {
			return nil, false
		}
	}
	return formation, true
}
func memoirResult(parameters map[string]any, player int64) (memoir.MonsterResult, bool) {
	var result memoir.MonsterResult
	if !onlyStockGameplayParams(parameters, "grid_pos", "formation", "pet_id", "is_win", "heroes_status", "enemies_status", "round") {
		return result, false
	}
	position, positionValid := topFloorInteger(parameters, "grid_pos", true)
	pet, petValid := topFloorInteger(parameters, "pet_id", false)
	win, winValid := topFloorInteger(parameters, "is_win", true)
	round, roundValid := topFloorInteger(parameters, "round", true)
	formation, formationValid := memoirFormation(parameters["formation"])
	if !positionValid || position < 1 || position > domain.BoardCells || !petValid || pet < 0 || pet > 9007199254740991 || !winValid || win > 1 || win < 0 || !roundValid || round < 1 || round > 4 || !formationValid {
		return result, false
	}
	allies, alliesValid := memoirStatuses(parameters["heroes_status"], player, domain.TeamLimit)
	enemies, enemiesValid := memoirStatuses(parameters["enemies_status"], 0, 6)
	if !alliesValid || !enemiesValid {
		return result, false
	}
	result.Grid = int(position)
	result.Report = combat.Report{Win: win == 1, Formation: formation, Pet: pet, Round: int(round), Allies: allies, Enemies: enemies}
	return result, true
}
func memoirStatuses(raw any, player int64, limit int) ([]combat.ActorStatus, bool) {
	rows, valid := raw.(map[string]any)
	if !valid || len(rows) == 0 || len(rows) > limit {
		return nil, false
	}
	result := make([]combat.ActorStatus, 0, len(rows))
	for key, raw := range rows {
		identifier, err := strconv.ParseInt(key, 10, 64)
		if err != nil || identifier <= 0 || identifier > 9007199254740991 || strconv.FormatInt(identifier, 10) != key {
			return nil, false
		}
		row, valid := raw.(map[string]any)
		if !valid || len(row) != 4 {
			return nil, false
		}
		for name := range row {
			if name != "hero_id" && name != "hp" && name != "mp" && name != "is_reborn" {
				return nil, false
			}
		}
		hero, heroError := feedbackInteger(row["hero_id"], -1, 9007199254740991)
		heroValid := heroError == nil && (hero == identifier || player == 0 && hero == -1)
		reborn, rebornValid := topFloorInteger(row, "is_reborn", true)
		health, healthValid := marchNumber(row["hp"])
		mana, manaValid := marchNumber(row["mp"])
		if !heroValid || !rebornValid || reborn < 0 || reborn > 1 || !healthValid || !manaValid || mana > 1000 {
			return nil, false
		}
		result = append(result, combat.ActorStatus{Player: player, Identity: identifier, HP: health, MP: mana, Reborn: reborn})
	}
	sort.Slice(result, func(left, right int) bool { return result[left].Identity < result[right].Identity })
	return result, true
}
