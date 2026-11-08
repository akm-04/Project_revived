package stockruntime

import (
	"context"
	"errors"
	"log"
	"net/http"

	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	d "gxb.local/backend/v2/internal/domain/herorecommend"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// HeroRecommendPort is the recommendation owner's read surface.
type HeroRecommendPort interface {
	Overview(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	Detail(context.Context, identity.ActorContext, operation.Context, int64) (map[string]any, error)
	ForceRank(context.Context, identity.ActorContext, operation.Context, int64) (map[string]any, error)
}

type HeroRecommendDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   HeroRecommendPort
}

func (h HeroRecommendDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	actor, fail := (HeroDispatcher{Authority: h.Authority}).actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if h.Service == nil {
		return failHeroRecommend(d.ErrUnavailable)
	}
	params, o, mid := req.Envelope.Params, req.Envelope.Operation, req.Envelope.MID
	switch mid {
	case 2496:
		// PRIVATE_POLICY: no client caller or success shape is recovered for GET_HERO_SCORE.
		return conflictRefusal(1)
	case 2497:
		if !onlyStockGameplayParams(params) {
			return badHero("invalid_hero_recommend_params")
		}
		body, err := h.Service.Overview(ctx, actor, o)
		if err != nil {
			return failHeroRecommend(err)
		}
		return httpedge.Response{HTTPStatus: 200, Body: body}
	case 2498, 2499:
		if !onlyStockGameplayParams(params, "table_id") {
			return badHero("invalid_hero_recommend_params")
		}
		tableID, err := requiredInt64(params, "table_id")
		if err != nil || tableID <= 0 {
			return badHero("invalid_hero_recommend_table")
		}
		var body map[string]any
		if mid == 2498 {
			body, err = h.Service.Detail(ctx, actor, o, tableID)
		} else {
			body, err = h.Service.ForceRank(ctx, actor, o, tableID)
		}
		if err != nil {
			return failHeroRecommend(err)
		}
		return httpedge.Response{HTTPStatus: 200, Body: body}
	}
	return badHero("unsupported_hero_recommend_mid")
}

// failHeroRecommend refuses a business conflict on 409 so the stock callbacks
// see ERROR instead of an OK body they would index.
func failHeroRecommend(e error) httpedge.Response {
	if errors.Is(e, d.ErrRefused) {
		return conflictRefusal(1)
	}
	log.Printf("hero recommend unavailable: %v", e)
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "hero_recommend_unavailable"}}
}
