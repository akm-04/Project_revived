package stockruntime

import (
	"context"
	"net/http"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/protocol/httpedge"
)

func TestPart3BPublicationFailureReplies(t *testing.T) {
	now := time.Unix(10, 0).UTC()
	dispatcher := PublicationDispatcher{}
	assertPart2FailureCases(t, []part2FailureCase{
		{"invalid params", dispatcher.Dispatch(context.Background(), httpedge.DispatchRequest{Envelope: part3bEnvelope(1537, map[string]any{"extra": int64(1)}, now)}), http.StatusBadRequest, 0, "invalid_publication_params"},
		{"auth required", dispatcher.Dispatch(context.Background(), httpedge.DispatchRequest{Envelope: part3bEnvelope(1537, map[string]any{}, now)}), http.StatusUnauthorized, 0, "gameplay_auth_required"},
	})
}
