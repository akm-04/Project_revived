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
	if d.Authority == nil {
		return failureReply(defect(nil))
	}
	if req.Envelope.Claims.Token == "" {
		return failureReply(sessionFailure())
	}
	actor, err := d.Authority.ResolveGameplayBearer(ctx, req.Envelope.Claims.Token, req.Envelope.ReceivedAt)
	if err != nil {
		return authFailure(err)
	}
	if req.Envelope.Claims.Region != int64(actor.LogicalServerID) {
		return failureReply(refusal(unprovenRefusalCode))
	}

	switch req.Envelope.MID {
	case 229:
		rows, err := d.Service.List(ctx, actor)
		if err != nil {
			return failureFromRows(nil, err)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: activityproj.List(rows)}
	case 234:
		id, err := requiredInt64(req.Envelope.Params, "activity_id")
		if err != nil || id <= 0 {
			return failureReply(malformed("invalid_activity_id"))
		}
		row, ok, err := d.Service.Lookup(ctx, actor, id)
		if err != nil {
			return failureFromRows(nil, err)
		}
		if !ok {
			return failureReply(refusal(unprovenRefusalCode))
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: activityproj.Row(row)}
	default:
		return failureReply(refusal(unprovenRefusalCode))
	}
}
