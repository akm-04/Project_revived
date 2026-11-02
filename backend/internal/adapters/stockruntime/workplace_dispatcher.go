package stockruntime

import (
	"context"
	"errors"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	app "gxb.local/backend/v2/internal/application/workplace"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/workplace"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"net/http"
)

var WorkplaceMIDs = []uint16{528, 530, 531, 532, 533}

type WorkplacePort interface {
	Load(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	SP(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	Log(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	Dispatch(context.Context, identity.ActorContext, app.Dispatch, operation.Context) (map[string]any, error)
	Claim(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
}
type WorkplaceDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   WorkplacePort
}

func (m WorkplaceDispatcher) Dispatch(c context.Context, r httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: m.Authority}).actor(c, r)
	if fail != nil {
		return *fail
	}
	if m.Service == nil {
		return workplaceFailure(d.ErrUnavailable)
	}
	p, op := r.Envelope.Params, r.Envelope.Operation
	bad := badHero("workplace_invalid_parameter")
	var body map[string]any
	var err error
	switch r.Envelope.MID {
	case 528, 530, 533:
		if !onlyStockGameplayParams(p) {
			return bad
		}
		switch r.Envelope.MID {
		case 528:
			body, err = m.Service.SP(c, a, op)
		case 530:
			body, err = m.Service.Load(c, a, op)
		case 533:
			body, err = m.Service.Log(c, a, op)
		}
	case 531:
		if !onlyStockGameplayParams(p, "partners", "treasure_type", "team_id", "sp_num") {
			return bad
		}
		partners, e := workplacePartners(p["partners"])
		if e != nil || len(partners) == 0 {
			return bad
		}
		team, ok := topFloorInteger(p, "team_id", true)
		if !ok {
			return bad
		}
		job, ok := topFloorInteger(p, "treasure_type", true)
		if !ok {
			return bad
		}
		sp, ok := topFloorInteger(p, "sp_num", true)
		if !ok {
			return bad
		}
		body, err = m.Service.Dispatch(c, a, app.Dispatch{Team: team, Job: job, Partners: partners, SP: sp}, op)
	case 532:
		if !onlyStockGameplayParams(p, "team_id") {
			return bad
		}
		team, ok := topFloorInteger(p, "team_id", true)
		if !ok {
			return bad
		}
		body, err = m.Service.Claim(c, a, team, op)
	default:
		return bad
	}
	if err != nil {
		return workplaceFailure(err)
	}
	if r.Envelope.MID == 533 {
		return httpedge.Response{HTTPStatus: http.StatusOK, JSON: body["records"]}
	}
	return okI5(body)
}
func workplaceFailure(err error) httpedge.Response {
	var conflict *receipt.ConflictError
	if errors.Is(err, d.ErrInvalid) || errors.As(err, &conflict) {
		return badHero("workplace_invalid_parameter")
	}
	if errors.Is(err, d.ErrRefused) || errors.Is(err, economy.ErrInsufficientBalance) {
		return conflictRefusal(1)
	}
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "workplace_unavailable"}}
}

func workplacePartners(value any) ([]int64, error) {
	values, ok := value.([]any)
	if !ok || len(values) == 0 || len(values) > 23 {
		return nil, d.ErrInvalid
	}
	ids := make([]int64, len(values))
	seen := map[int64]bool{}
	for i, raw := range values {
		id, err := feedbackInteger(raw, 1, 9007199254740991)
		if err != nil || seen[id] {
			return nil, d.ErrInvalid
		}
		ids[i], seen[id] = id, true
	}
	return ids, nil
}
