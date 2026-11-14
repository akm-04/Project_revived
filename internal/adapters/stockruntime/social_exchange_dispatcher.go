package stockruntime

import (
	"context"

	authentication "gxb.local/backend/v2/internal/application/realtimeauth"
	exchange "gxb.local/backend/v2/internal/application/socialexchange"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/socialexchange"
	"gxb.local/backend/v2/internal/foundation/operation"
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
		return failureReply(refusal(unprovenRefusalCode))
	}
	if dispatcher.Service == nil {
		return failureReply(defect(nil))
	}
	body, err := dispatcher.Service.Exchange(ctx, actor, exchange.Request{ProductID: productID, Count: count}, request.Envelope.Operation)
	if err == nil {
		return okI5(body)
	}
	return failureFromRows(socialExchangeFailureRows, err)
}

var socialExchangeFailureRows = []failureRow{
	{match: exchange.ErrProductOff, class: failureRefusal, code: unprovenRefusalCode},
	{match: domain.ErrCount, class: failureRefusal, code: unprovenRefusalCode},
	{match: domain.ErrUnknownProduct, class: failureRefusal, code: unprovenRefusalCode},
	{match: economy.ErrInsufficientBalance, class: failureRefusal, balance: true},
	{match: economy.ErrStackCapacity, class: failureRefusal, code: unprovenRefusalCode},
}
