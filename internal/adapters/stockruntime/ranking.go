package stockruntime

import (
	"context"
	"net/http"

	"gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/application/topfloor"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/oneonone"
	d "gxb.local/backend/v2/internal/domain/ranking"
	"gxb.local/backend/v2/internal/foundation/operation"
	oneononeprojection "gxb.local/backend/v2/internal/projection/oneonone"
	projection "gxb.local/backend/v2/internal/projection/ranking"
	topfloorprojection "gxb.local/backend/v2/internal/projection/topfloor"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

type GirlsRankingReads interface {
	ReadGirls(context.Context, identity.ActorContext, operation.Context) (d.GirlsSnapshot, error)
}
type TopFloorRanks interface {
	RankList(context.Context, identity.ActorContext) (topfloor.RankList, error)
}
type OneOnOneRanks interface {
	RankList(context.Context, identity.ActorContext, bool) (oneonone.RankList, error)
}
type RankingDispatcher struct {
	Authority realtimeauth.GameplayAuthorityPort
	Service   GirlsRankingReads
	TopFloor  TopFloorRanks
	OneOnOne  OneOnOneRanks
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
	if subtype == 1 && d.TopFloor != nil {
		list, e := d.TopFloor.RankList(c, a)
		if e != nil {
			return fail(http.StatusServiceUnavailable)
		}
		body := topfloorprojection.RankList(list.Rows, list.MyRank, a.LogicalServerID)
		body["error_code"] = int64(0)
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: body}
	}
	if (subtype == 3 || subtype == 4) && d.OneOnOne != nil {
		list, e := d.OneOnOne.RankList(c, a, subtype == 3)
		if e != nil {
			return fail(http.StatusServiceUnavailable)
		}
		body := oneononeprojection.RankList(list, subtype)
		body["error_code"] = int64(0)
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: body}
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
