package stockruntime

import (
	"context"

	questions "gxb.local/backend/v2/internal/application/gmquestion"
	authentication "gxb.local/backend/v2/internal/application/realtimeauth"
	domain "gxb.local/backend/v2/internal/domain/gmquestion"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

type GMQuestionPort interface {
	Ask(context.Context, identity.ActorContext, string, operation.Context) (questions.Acknowledgement, error)
	List(context.Context, identity.ActorContext, operation.Context) ([]questions.Entry, error)
}
type GMQuestionDispatcher struct {
	Authority authentication.GameplayAuthorityPort
	Service   GMQuestionPort
}

func (dispatcher GMQuestionDispatcher) Dispatch(ctx context.Context, request httpedge.DispatchRequest) httpedge.Response {
	actor, failure := (HeroDispatcher{Authority: dispatcher.Authority}).actor(ctx, request)
	if failure != nil {
		return *failure
	}
	parameters := request.Envelope.Params
	message := ""
	switch request.Envelope.MID {
	case 4:
		if !onlyStockGameplayParams(parameters) {
			return badHero("invalid_gm_question_parameter")
		}
	case 5:
		value, ok := parameters["msg"].(string)
		if !ok || !onlyStockGameplayParams(parameters, "msg") {
			return badHero("invalid_gm_question_parameter")
		}
		message = value
	default:
		return badHero("invalid_gm_question_mid")
	}
	if dispatcher.Service == nil {
		return questionUnavailable(nil)
	}
	if request.Envelope.MID == 5 {
		_, err := dispatcher.Service.Ask(ctx, actor, message, request.Envelope.Operation)
		if err == nil {
			return okI5(map[string]any{})
		}
		return failureFromRows(gmQuestionFailureRows, err)
	}
	entries, err := dispatcher.Service.List(ctx, actor, request.Envelope.Operation)
	if err != nil {
		return questionUnavailable(err)
	}
	rows := make([]any, 0, len(entries))
	for _, entry := range entries {
		rows = append(rows, map[string]any{"talker_id": int64(entry.Question.Player), "player_id": int64(entry.Question.Player), "talker_name": entry.Profile.Name, "player_type": int64(0), "msg": entry.Question.Message, "created_time": entry.Question.AskedAt.Unix()})
	}
	return okI5(map[string]any{"list": rows})
}

var gmQuestionFailureRows = []failureRow{
	{match: domain.ErrQuestion, class: failureRefusal, code: unprovenRefusalCode},
}

func questionUnavailable(cause error) httpedge.Response {
	return failureReply(unavailable(cause))
}
