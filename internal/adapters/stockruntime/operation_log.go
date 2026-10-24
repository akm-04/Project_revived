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
	if d.Authority == nil || req.Envelope.Claims.Token == "" {
		return httpedge.Response{HTTPStatus: http.StatusUnauthorized, Body: map[string]any{"error": "gameplay_auth_required"}}
	}
	if _, err := d.Authority.ResolveGameplayBearer(ctx, req.Envelope.Claims.Token, req.Envelope.ReceivedAt); err != nil {
		return authFailure(err)
	}
	if _, err := requiredInt64(req.Envelope.Params, "operation_id"); err != nil {
		return httpedge.Response{HTTPStatus: http.StatusBadRequest, Cause: err, Body: map[string]any{"error": "invalid_operation_id"}}
	}
	return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{}}
}
