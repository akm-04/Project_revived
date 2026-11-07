package stockruntime

import (
	"context"
	"errors"
	"net/http"

	authentication "gxb.local/backend/v2/internal/application/realtimeauth"
	recall "gxb.local/backend/v2/internal/application/socialrecall"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

type SocialRecallStartPort interface {
	Start(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (map[string]any, error)
}
type SocialRecallStartDispatcher struct {
	Authority authentication.GameplayAuthorityPort
	Service   SocialRecallStartPort
}

type SocialRecallAwardPort interface {
	Claim(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
}

type SocialRecallAwardDispatcher struct {
	Authority authentication.GameplayAuthorityPort
	Service   SocialRecallAwardPort
}

func (dispatcher SocialRecallAwardDispatcher) Dispatch(ctx context.Context, request httpedge.DispatchRequest) httpedge.Response {
	actor, failure := (HeroDispatcher{Authority: dispatcher.Authority}).actor(ctx, request)
	if failure != nil {
		return *failure
	}
	parameters := request.Envelope.Params
	award, valid := topFloorInteger(parameters, "award_id", true)
	if request.Envelope.MID != 194 || !valid || !onlyStockGameplayParams(parameters, "award_id") {
		return badHero("invalid_social_recall_award_parameter")
	}
	if award <= 0 {
		return badHero("invalid_social_recall_award_parameter")
	}
	if dispatcher.Service == nil {
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "social_recall_unavailable"}}
	}
	body, err := dispatcher.Service.Claim(ctx, actor, award, request.Envelope.Operation)
	if err == nil {
		return okI5(body)
	}
	var conflict *receipt.ConflictError
	if errors.Is(err, recall.ErrAwardRefused) || errors.As(err, &conflict) {
		return conflictRefusal(1)
	}
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: err, Body: map[string]any{"error": "social_recall_unavailable"}}
}

func (dispatcher SocialRecallStartDispatcher) Dispatch(ctx context.Context, request httpedge.DispatchRequest) httpedge.Response {
	actor, failure := (HeroDispatcher{Authority: dispatcher.Authority}).actor(ctx, request)
	if failure != nil {
		return *failure
	}
	parameters := request.Envelope.Params
	target, valid := topFloorInteger(parameters, "friend_id", true)
	if request.Envelope.MID != 193 || !valid || !onlyStockGameplayParams(parameters, "friend_id") {
		return badHero("invalid_social_recall_parameter")
	}
	if target <= 0 {
		return conflictRefusal(1)
	}
	if dispatcher.Service == nil {
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "social_recall_unavailable"}}
	}
	body, err := dispatcher.Service.Start(ctx, actor, identity.PlayerID(target), request.Envelope.Operation)
	if err == nil {
		return okI5(body)
	}
	var conflict *receipt.ConflictError
	if errors.Is(err, recall.ErrStartRefused) || errors.Is(err, recall.ErrStartFacts) || errors.As(err, &conflict) {
		return conflictRefusal(1)
	}
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: err, Body: map[string]any{"error": "social_recall_unavailable"}}
}
