package stockruntime

import (
	"context"
	"errors"
	"net/http"

	authentication "gxb.local/backend/v2/internal/application/realtimeauth"
	exchange "gxb.local/backend/v2/internal/application/socialexchange"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/socialexchange"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

type SocialExchangePort interface {
	Exchange(context.Context, identity.ActorContext, exchange.Request, operation.Context) (map[string]any, error)
}
type SocialExchangeDispatcher struct {
	Authority authentication.GameplayAuthorityPort
	Service   SocialExchangePort
}

func (dispatcher SocialExchangeDispatcher) Dispatch(ctx context.Context, request httpedge.DispatchRequest) httpedge.Response {
	actor, failure := (HeroDispatcher{Authority: dispatcher.Authority}).actor(ctx, request)
	if failure != nil {
		return *failure
	}
	parameters := request.Envelope.Params
	productID, productValid := topFloorInteger(parameters, "id", true)
	count, countValid := topFloorInteger(parameters, "num", true)
	if request.Envelope.MID != 191 || !productValid || !countValid || !onlyStockGameplayParams(parameters, "id", "num") {
		return badHero("invalid_social_exchange_parameter")
	}
	if productID <= 0 || count <= 0 {
		return conflictRefusal(1)
	}
	if dispatcher.Service == nil {
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "social_exchange_unavailable"}}
	}
	body, err := dispatcher.Service.Exchange(ctx, actor, exchange.Request{ProductID: productID, Count: count}, request.Envelope.Operation)
	if err == nil {
		return okI5(body)
	}
	var conflict *receipt.ConflictError
	if errors.Is(err, exchange.ErrProductOff) || errors.Is(err, domain.ErrCount) || errors.Is(err, domain.ErrUnknownProduct) || errors.Is(err, economy.ErrInsufficientBalance) || errors.Is(err, economy.ErrStackCapacity) || errors.As(err, &conflict) {
		return conflictRefusal(1)
	}
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: err, Body: map[string]any{"error": "social_exchange_unavailable"}}
}
