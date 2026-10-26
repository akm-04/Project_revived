package stockruntime

import (
	"context"
	"errors"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"net/http"
)

type AwakeningBloodService interface {
	Start(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	Result(context.Context, identity.ActorContext, int64, int64, operation.Context) (map[string]any, error)
}
type AwakeningBloodDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   AwakeningBloodService
}

func (d AwakeningBloodDispatcher) Dispatch(ctx context.Context, r httpedge.DispatchRequest) httpedge.Response {
	actor, fail := (HeroDispatcher{Authority: d.Authority}).actor(ctx, r)
	if fail != nil {
		return *fail
	}
	p := r.Envelope.Params
	if _, blood := p["twice_awake_mission"]; !blood {
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "incubus_provider_deferred"}}
	}
	id, a := topFloorInteger(p, "twice_awake_mission", true)
	incubus, b := topFloorInteger(p, "incubus_id", true)
	if !a || !b || id <= 0 || id != incubus {
		return badI5("invalid_blood_mission")
	}
	if d.Service == nil {
		return failI5(errors.New("Blood combat unavailable"))
	}
	var body map[string]any
	var e error
	switch r.Envelope.MID {
	case 866:
		if !onlyStockGameplayParams(p, "twice_awake_mission", "incubus_id") {
			return badI5("invalid_blood_start")
		}
		body, e = d.Service.Start(ctx, actor, id, r.Envelope.Operation)
	case 867:
		n, ok := topFloorInteger(p, "num", true)
		empty := false
		switch ids := p["npc_ids"].(type) {
		case map[string]any:
			empty = len(ids) == 0
		case []any:
			empty = len(ids) == 0
		}
		if !ok || n != 20 || !empty || !onlyStockGameplayParams(p, "twice_awake_mission", "incubus_id", "num", "npc_ids") {
			return badI5("invalid_blood_result")
		}
		body, e = d.Service.Result(ctx, actor, id, n, r.Envelope.Operation)
	default:
		return badI5("invalid_blood_mid")
	}
	if e != nil {
		return failI5(e)
	}
	return okI5(body)
}
