package stockruntime

import (
	"context"
	"errors"

	mentor "gxb.local/backend/v2/internal/application/mentor"
	authentication "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	domainmentor "gxb.local/backend/v2/internal/domain/mentor"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// MentorService is the My Class application surface (MIDs 1856-1863).
type MentorService interface {
	Info(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	Apply(context.Context, identity.ActorContext, identity.PlayerID, int64, string, operation.Context) (map[string]any, error)
	Finding(context.Context, identity.ActorContext, int64, string, operation.Context) (map[string]any, error)
	Accept(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (map[string]any, error)
	Deny(context.Context, identity.ActorContext, identity.PlayerID, bool, operation.Context) (map[string]any, error)
	Terminate(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	Claim(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	Exam(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
}

type MentorDispatcher struct {
	Authority authentication.GameplayAuthorityPort
	Service   MentorService
}

func (dispatcher MentorDispatcher) Dispatch(ctx context.Context, request httpedge.DispatchRequest) httpedge.Response {
	actor, failure := (HeroDispatcher{Authority: dispatcher.Authority}).actor(ctx, request)
	if failure != nil {
		return *failure
	}
	if dispatcher.Service == nil {
		return failureReply(defect(nil))
	}
	parameters := request.Envelope.Params
	op := request.Envelope.Operation
	switch request.Envelope.MID {
	case 1856:
		if !onlyStockGameplayParams(parameters) {
			return badHero("invalid_mentor_request")
		}
		body, err := dispatcher.Service.Info(ctx, actor, op)
		if err != nil {
			return mentorFailure(err)
		}
		return okI5(body)
	case 1857:
		target, targetOK := topFloorInteger(parameters, "to_player_id", true)
		relationType, relationOK := topFloorInteger(parameters, "relation_type", true)
		message, messageOK := parameters["msg"].(string)
		if !targetOK || !relationOK || !messageOK || target <= 0 || relationType != 1 && relationType != 2 || !onlyStockGameplayParams(parameters, "to_player_id", "relation_type", "msg") {
			return badHero("invalid_mentor_request")
		}
		body, err := dispatcher.Service.Apply(ctx, actor, identity.PlayerID(target), relationType, message, op)
		if err != nil {
			return mentorFailure(err)
		}
		return okI5(body)
	case 1858:
		relationType, relationOK := topFloorInteger(parameters, "relation_type", true)
		filter := ""
		if raw, present := parameters["filter_str"]; present {
			value, stringOK := raw.(string)
			if !stringOK {
				return badHero("invalid_mentor_request")
			}
			filter = value
		}
		if !relationOK || relationType != 1 && relationType != 2 || !onlyStockGameplayParams(parameters, "relation_type", "filter_str") {
			return badHero("invalid_mentor_request")
		}
		body, err := dispatcher.Service.Finding(ctx, actor, relationType, filter, op)
		if err != nil {
			return mentorFailure(err)
		}
		return okI5(body)
	case 1859:
		from, valid := topFloorInteger(parameters, "from_player_id", true)
		if !valid || from <= 0 || !onlyStockGameplayParams(parameters, "from_player_id") {
			return badHero("invalid_mentor_request")
		}
		body, err := dispatcher.Service.Accept(ctx, actor, identity.PlayerID(from), op)
		if err != nil {
			return mentorFailure(err)
		}
		return okI5(body)
	case 1860:
		_, hasFrom := parameters["from_player_id"]
		_, hasDenyAll := parameters["is_deny_all"]
		if hasFrom == hasDenyAll || !onlyStockGameplayParams(parameters, "from_player_id", "is_deny_all") {
			return badHero("invalid_mentor_request")
		}
		from, denyAll := int64(0), false
		if hasFrom {
			value, valid := topFloorInteger(parameters, "from_player_id", true)
			if !valid || value <= 0 {
				return badHero("invalid_mentor_request")
			}
			from = value
		} else {
			value, valid := topFloorInteger(parameters, "is_deny_all", true)
			if !valid || value != 1 {
				return badHero("invalid_mentor_request")
			}
			denyAll = true
		}
		body, err := dispatcher.Service.Deny(ctx, actor, identity.PlayerID(from), denyAll, op)
		if err != nil {
			return mentorFailure(err)
		}
		return okI5(body)
	case 1861:
		relationType, valid := topFloorInteger(parameters, "relation_type", true)
		if !valid || relationType != 1 && relationType != 2 || !onlyStockGameplayParams(parameters, "relation_type") {
			return badHero("invalid_mentor_request")
		}
		body, err := dispatcher.Service.Terminate(ctx, actor, relationType, op)
		if err != nil {
			return mentorFailure(err)
		}
		return okI5(body)
	case 1862:
		mission, valid := topFloorInteger(parameters, "mission_id", true)
		if !valid || mission <= 0 || !onlyStockGameplayParams(parameters, "mission_id") {
			return badHero("invalid_mentor_request")
		}
		body, err := dispatcher.Service.Claim(ctx, actor, mission, op)
		if err != nil {
			return mentorFailure(err)
		}
		return okI5(body)
	case 1863:
		isWin, winOK := topFloorInteger(parameters, "is_win", true)
		formation, formationOK := parameters["formation"].(string)
		if !winOK || !formationOK || formation == "" || !onlyStockGameplayParams(parameters, "is_win", "formation", "pet_id") {
			return badHero("invalid_mentor_request")
		}
		if _, present := parameters["pet_id"]; present && !numericParameter(parameters, "pet_id") {
			return badHero("invalid_mentor_request")
		}
		body, err := dispatcher.Service.Exam(ctx, actor, isWin, op)
		if err != nil {
			return mentorFailure(err)
		}
		return okI5(body)
	default:
		return badHero("invalid_mentor_request")
	}
}

func numericParameter(parameters map[string]any, key string) bool {
	_, ok := topFloorInteger(parameters, key, false)
	return ok
}

// Every business refusal is HTTP 409 with the best stock message code, because
// the client treats any 200 as success and indexes nested reply fields.
var mentorFailureRows = []failureRow{
	{match: domainmentor.ErrRelationshipConflict, class: failureRefusal, code: staleConflictCode},
	{match: domainmentor.ErrRelationship, class: failureRefusal, code: unprovenRefusalCode},
	{match: domainmentor.ErrApplication, class: failureRefusal, code: unprovenRefusalCode},
	{match: domainmentor.ErrMission, class: failureRefusal, code: unprovenRefusalCode},
	{match: mentor.ErrInvalid, class: failureMalformed, detail: "invalid_mentor_request"},
}

func mentorFailure(err error) httpedge.Response {
	var refusal *mentor.Refusal
	if errors.As(err, &refusal) && refusal.Code > 0 {
		return failureReply(&classifiedFailure{class: failureRefusal, code: refusal.Code, cause: err})
	}
	return failureFromRows(mentorFailureRows, err)
}
