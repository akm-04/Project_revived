package stockruntime

import (
	"context"
	"net/http"

	apprealtime "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// FunctionClickDispatcher acknowledges stock MID30 FUNCTION_CLICK, the
// Event Centre's fire-and-forget button telemetry ({click_id},
// SelfPlayer.lua:4691). The callback reads no field, so an empty object is the
// whole contract. The stock client sends it before login (the journal shows no
// session), therefore a bearer is resolved only when present and never
// required.
// shortcut: click_id is validated but not stored; store it when an operator
// funnel report needs the value.
type FunctionClickDispatcher struct {
	Authority apprealtime.GameplayAuthorityPort
}

func (d FunctionClickDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	if d.Authority != nil && req.Envelope.Claims.Token != "" {
		_, _ = d.Authority.ResolveGameplayBearer(ctx, req.Envelope.Claims.Token, req.Envelope.ReceivedAt)
	}
	if _, err := requiredInt64(req.Envelope.Params, "click_id"); err != nil {
		return httpedge.Response{HTTPStatus: http.StatusBadRequest, Cause: err, Body: map[string]any{"error": "invalid_click_id"}}
	}
	return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{}}
}
