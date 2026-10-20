package stockruntime

import (
	"context"
	"errors"
	app "gxb.local/backend/v2/internal/application/achievement"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	d "gxb.local/backend/v2/internal/domain/achievement"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"log"
	"net/http"
)

var AchievementMIDs = []uint16{1302, 1303}

type AchievementPort interface {
	Load(context.Context, identity.ActorContext, operation.Context) (app.View, error)
	Claim(context.Context, identity.ActorContext, operation.Context) (app.ClaimResult, error)
}
type AchievementDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   AchievementPort
}

func (o AchievementDispatcher) Dispatch(c context.Context, req httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: o.Authority}).actor(c, req)
	if fail != nil {
		return *fail
	}
	if o.Service == nil {
		return failAchievement(d.ErrUnavailable)
	}
	if !onlyStockGameplayParams(req.Envelope.Params) {
		return badHero("invalid_achievement_parameter")
	}
	if req.Envelope.MID == 1303 {
		v, e := o.Service.Claim(c, a, req.Envelope.Operation)
		if e != nil {
			return failAchievement(e)
		}
		awards := []map[string]any{}
		for _, x := range v.Awards {
			awards = append(awards, map[string]any{"table_id": x.TableID, "item_num": x.ItemNum})
		}
		return okI5(map[string]any{"award_status": v.AwardStatus, "awards": awards})
	}
	v, e := o.Service.Load(c, a, req.Envelope.Operation)
	if e != nil {
		return failAchievement(e)
	}
	list := []map[string]any{}
	for _, x := range v.Entries {
		list = append(list, map[string]any{"achieve_id": x.AchievementID, "complete_time": x.CompleteTimes[:], "progress": x.Progress})
	}
	return okI5(map[string]any{"achieve_list": list, "base_info": map[string]any{"point_level": v.PointLevel, "total_points": v.TotalPoints, "rank": v.Rank, "award_status": v.AwardStatus}})
}
func failAchievement(e error) httpedge.Response {
	if errors.Is(e, app.ErrNothingToClaim) {
		return httpedge.Response{HTTPStatus: http.StatusBadRequest, Body: map[string]any{"error": "achievement_nothing_to_claim"}}
	}
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "achievement_unavailable"}}
}

type AchievementObserver interface {
	Observe(context.Context, identity.ActorContext, operation.Context, []int64) error
}

// AchievementObserving is C4F_OBSERVE_AFTER_COMMAND_V1: after a successful owner
// response it observes that owner's achievement family in its own transaction.
// The owner's response is returned unchanged whatever the observation outcome.
type AchievementObserving struct {
	Next      httpedge.Dispatcher
	Authority rt.GameplayAuthorityPort
	Observer  AchievementObserver
	Families  []int64
}

func (o AchievementObserving) Dispatch(c context.Context, req httpedge.DispatchRequest) httpedge.Response {
	r := o.Next.Dispatch(c, req)
	if r.HTTPStatus != http.StatusOK || o.Observer == nil {
		return r
	}
	a, fail := (HeroDispatcher{Authority: o.Authority}).actor(c, req)
	if fail != nil {
		return r
	}
	if e := o.Observer.Observe(c, a, req.Envelope.Operation, o.Families); e != nil {
		log.Printf("achievement observation degraded: mid=%d: %v", req.Envelope.MID, e)
	}
	return r
}
