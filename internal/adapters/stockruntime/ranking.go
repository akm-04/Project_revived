package stockruntime

import (
	"context"
	"net/http"

	"gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/ranking"
	"gxb.local/backend/v2/internal/foundation/operation"
	projection "gxb.local/backend/v2/internal/projection/ranking"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

type GirlsRankingReads interface {
	ReadGirls(context.Context, identity.ActorContext, operation.Context) (d.GirlsSnapshot, error)
}
type RankingDispatcher struct {
	Authority realtimeauth.GameplayAuthorityPort
	Service   GirlsRankingReads
}

func (d RankingDispatcher) Dispatch(c context.Context, r httpedge.DispatchRequest) httpedge.Response {
	fail := func(status int) httpedge.Response {
		return httpedge.Response{HTTPStatus: status, Body: map[string]any{"error_code": int64(1), "error": "ranking_request_failed"}}
	}
	if d.Authority == nil || d.Service == nil || r.Envelope.Claims.Token == "" {
		return fail(http.StatusUnauthorized)
	}
	a, e := d.Authority.ResolveGameplayBearer(c, r.Envelope.Claims.Token, r.Envelope.ReceivedAt)
	if e != nil || r.Envelope.Claims.Region != int64(a.LogicalServerID) {
		return fail(http.StatusForbidden)
	}
	if r.Envelope.MID != 301 {
		return fail(http.StatusNotImplemented)
	}
	for k := range r.Envelope.Params {
		if k != "mid" && k != "token" && k != "region" && k != "rank_types" {
			return fail(http.StatusBadRequest)
		}
	}
	types, ok := r.Envelope.Params["rank_types"].([]any)
	if !ok || len(types) != 1 {
		return fail(http.StatusBadRequest)
	}
	subtype, e := feedbackInteger(types[0], 1, 9007199254740991)
	if e != nil {
		return fail(http.StatusBadRequest)
	}
	if subtype != 37 {
		return fail(http.StatusNotImplemented)
	}
	snapshot, e := d.Service.ReadGirls(c, a, r.Envelope.Operation)
	if e != nil {
		return fail(http.StatusServiceUnavailable)
	}
	body, e := projection.GirlsList(snapshot, a.PlayerID)
	if e != nil {
		return fail(http.StatusServiceUnavailable)
	}
	body["error_code"] = int64(0)
	return httpedge.Response{HTTPStatus: http.StatusOK, Body: body}
}
