package stockruntime

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/application/dodgeball"
	"gxb.local/backend/v2/internal/application/realtimeauth"
	domain "gxb.local/backend/v2/internal/domain/dodgeball"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

var DodgeballMIDs = []uint16{2960, 2961, 2962, 2963, 2964}

type DodgeballPort interface {
	Info(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	FriendInfo(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	Enter(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (map[string]any, error)
	Start(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	Result(context.Context, identity.ActorContext, []domain.HitRecord, operation.Context) (map[string]any, error)
}

var _ DodgeballPort = dodgeball.Mode{}

type DodgeballDispatcher struct {
	Authority realtimeauth.GameplayAuthorityPort
	Service   DodgeballPort
}

func (dispatcher DodgeballDispatcher) Dispatch(ctx context.Context, request httpedge.DispatchRequest) httpedge.Response {
	actor, failure := (HeroDispatcher{Authority: dispatcher.Authority}).actor(ctx, request)
	if failure != nil {
		return *failure
	}
	if dispatcher.Service == nil {
		return httpedge.Response{HTTPStatus: 503, Body: map[string]any{"error_code": int64(1)}}
	}
	parameters, operationContext := request.Envelope.Params, request.Envelope.Operation
	invalid := badHero("dodgeball_invalid_parameter")
	var response map[string]any
	var err error
	switch request.Envelope.MID {
	case 2960, 2964:
		if !onlyStockGameplayParams(parameters) {
			return invalid
		}
		if request.Envelope.MID == 2960 {
			response, err = dispatcher.Service.Info(ctx, actor, operationContext)
		} else {
			response, err = dispatcher.Service.FriendInfo(ctx, actor, operationContext)
		}
	case 2961:
		if !onlyStockGameplayParams(parameters, "friend_id") {
			return invalid
		}
		friend, valid := topFloorInteger(parameters, "friend_id", false)
		if !valid || friend < 0 || friend > domain.MaximumSequence {
			return invalid
		}
		response, err = dispatcher.Service.Enter(ctx, actor, identity.PlayerID(friend), operationContext)
	case 2962:
		if !onlyStockGameplayParams(parameters, "select_id") {
			return invalid
		}
		marked, valid := topFloorInteger(parameters, "select_id", true)
		if !valid || marked < 1 || marked > 90 {
			return invalid
		}
		response, err = dispatcher.Service.Start(ctx, actor, marked, operationContext)
	case 2963:
		if !onlyStockGameplayParams(parameters, "records") {
			return invalid
		}
		records, valid := dodgeballRecords(parameters["records"])
		if !valid {
			return invalid
		}
		response, err = dispatcher.Service.Result(ctx, actor, records, operationContext)
	default:
		return httpedge.Response{HTTPStatus: 501, Body: map[string]any{"error_code": int64(1)}}
	}
	if err != nil {
		var conflict *receipt.ConflictError
		if errors.Is(err, domain.ErrInvalid) || errors.As(err, &conflict) {
			return invalid
		}
		if errors.Is(err, domain.ErrRefused) || errors.Is(err, economy.ErrInsufficientBalance) {
			return okI5(map[string]any{"error_code": int64(1)})
		}
		return httpedge.Response{HTTPStatus: 503, Body: map[string]any{"error_code": int64(1), "error": "dodgeball_failed"}, Cause: err}
	}
	if request.Envelope.MID == 2964 {
		return httpedge.Response{HTTPStatus: 200, JSON: response["friend_infos"]}
	}
	return okI5(response)
}

func dodgeballRecords(raw any) ([]domain.HitRecord, bool) {
	if fields, valid := raw.(map[string]any); valid && len(fields) == 0 {
		return []domain.HitRecord{}, true
	}
	rows, valid := raw.([]any)
	if !valid || len(rows) > 25 {
		return nil, false
	}
	records := make([]domain.HitRecord, 0, len(rows))
	for _, row := range rows {
		fields, valid := row.(map[string]any)
		if !valid || len(fields) != 5 {
			return nil, false
		}
		for name := range fields {
			if name != "rate_id" && name != "id" && name != "is_buff1" && name != "is_buff2" && name != "ball_num" {
				return nil, false
			}
		}
		throw, throwValid := topFloorInteger(fields, "rate_id", true)
		occurrence, occurrenceValid := topFloorInteger(fields, "id", true)
		hits, hitsValid := topFloorInteger(fields, "ball_num", true)
		probability, probabilityValid := fields["is_buff1"].(bool)
		friendProbability, friendProbabilityValid := fields["is_buff2"].(bool)
		if !throwValid || !occurrenceValid || !hitsValid || !probabilityValid || !friendProbabilityValid || throw < 1 || throw > 650 || occurrence < 1 || occurrence > 25 || hits < 1 || hits > 15 {
			return nil, false
		}
		records = append(records, domain.HitRecord{Throw: throw, Occurrence: occurrence, Hits: hits, ProbabilityBuff: probability, FriendProbabilityBuff: friendProbability})
	}
	return records, true
}
