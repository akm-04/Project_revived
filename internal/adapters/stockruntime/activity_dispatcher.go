package stockruntime

import (
	"context"
	"net/http"

	appactivity "gxb.local/backend/v2/internal/application/activitydirectory"
	apprealtime "gxb.local/backend/v2/internal/application/realtimeauth"
	activityproj "gxb.local/backend/v2/internal/projection/activity"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// ActivityDispatcher exposes only the read-only I6B ActivityDirectory surface.
// Gameplay child owners remain responsible for their own mutations and details.
type ActivityDispatcher struct {
	Authority apprealtime.GameplayAuthorityPort
	Service   appactivity.Runtime
}

func (d ActivityDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	if d.Authority == nil || req.Envelope.Claims.Token == "" {
		return httpedge.Response{HTTPStatus: http.StatusUnauthorized, Body: map[string]any{"error": "gameplay_auth_required"}}
	}
	actor, err := d.Authority.ResolveGameplayBearer(ctx, req.Envelope.Claims.Token, req.Envelope.ReceivedAt)
	if err != nil {
		return authFailure(err)
	}
	if req.Envelope.Claims.Region != int64(actor.LogicalServerID) {
		return httpedge.Response{HTTPStatus: http.StatusForbidden, Body: map[string]any{"error": "region_mismatch"}}
	}

	switch req.Envelope.MID {
	case 229:
		rows, err := d.Service.List(ctx, actor)
		if err != nil {
			return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "activity_projection_unavailable"}}
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: activityproj.List(rows)}
	case 234:
		id, err := requiredInt64(req.Envelope.Params, "activity_id")
		if err != nil || id <= 0 {
			return httpedge.Response{HTTPStatus: http.StatusBadRequest, Body: map[string]any{"error": "invalid_activity_id"}}
		}
		row, ok, err := d.Service.Lookup(ctx, actor, id)
		if err != nil {
			return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "activity_projection_unavailable"}}
		}
		if !ok {
			return httpedge.Response{HTTPStatus: http.StatusNotFound, Body: map[string]any{"error": "activity_unavailable"}}
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: activityproj.Row(row)}
	default:
		return httpedge.Response{HTTPStatus: http.StatusNotImplemented, Body: map[string]any{"error": "not_activity_directory", "mid": int64(req.Envelope.MID)}}
	}
}
