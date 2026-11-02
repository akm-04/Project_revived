package stockruntime

import (
	"context"
	"net/http"

	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// InactiveModeDispatcher answers a mode the private server has not opened (I9_MODE_FRAMEWORK_V1 F5, D83): the stock
// refusal shape, no state read or written. The bearer is resolved only so the journal row names the player; a missing or
// stale session still gets the same answer.
type InactiveModeDispatcher struct {
	Authority rt.GameplayAuthorityPort
}

func (d InactiveModeDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	if d.Authority != nil && req.Envelope.Claims.Token != "" {
		_, _ = d.Authority.ResolveGameplayBearer(ctx, req.Envelope.Claims.Token, req.Envelope.ReceivedAt)
	}
	return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{"error_code": 1}, Inactive: true}
}
