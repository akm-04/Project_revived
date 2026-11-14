package stockruntime

import (
	"context"
	"net/http"

	apprealtime "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// OperationLogDispatcher acknowledges stock MID121 SEND_OPERATION_LOG, the client's fire-and-forget funnel stat
// ({operation_id}, xyd.StatID; D70). Resolving the bearer attributes the request journal row to the player, so the
// journal (ROUTINE retention) is the record of it.
// shortcut: operation_id is validated but not stored; add a column or table when an operator funnel report needs it.
type OperationLogDispatcher struct {
	Authority apprealtime.GameplayAuthorityPort
}

func (d OperationLogDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	if d.Authority == nil {
		return failureReply(defect(nil))
	}
	if req.Envelope.Claims.Token == "" {
		return failureReply(sessionFailure())
	}
	if _, err := d.Authority.ResolveGameplayBearer(ctx, req.Envelope.Claims.Token, req.Envelope.ReceivedAt); err != nil {
		return authFailure(err)
	}
	if _, err := requiredInt64(req.Envelope.Params, "operation_id"); err != nil {
		return failureReply(&classifiedFailure{class: failureMalformed, detail: "invalid_operation_id", cause: err})
	}
	return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{}}
}
