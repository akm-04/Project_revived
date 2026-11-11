package stockruntime

import (
	"context"
	"net/http"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

func part3bEnvelope(mid uint16, params map[string]any, now time.Time) wire.RequestEnvelope {
	return wire.RequestEnvelope{MID: mid, Params: params, ReceivedAt: now}
}

func TestPart3BPracticeAutoFailureReplies(t *testing.T) {
	now := time.Unix(10, 0).UTC()
	actor := actorForHTTP(t)
	dispatcher := PracticeDispatcher{}
	valid := map[string]any{
		"partner_id":    int64(1),
		"locks":         []any{int64(1), int64(1), int64(1)},
		"practice_type": int64(1),
		"practice_num":  int64(2),
		"save_types":    []any{int64(1), int64(1), int64(1), int64(1)},
	}
	assertPart2FailureCases(t, []part2FailureCase{
		{"invalid request", dispatcher.dispatchPracticeAuto(context.Background(), httpedge.DispatchRequest{Envelope: part3bEnvelope(127, map[string]any{"partner_id": int64(0)}, now)}, actor), http.StatusBadRequest, 0, "invalid_practice_request"},
		{"unavailable", dispatcher.dispatchPracticeAuto(context.Background(), httpedge.DispatchRequest{Envelope: part3bEnvelope(127, valid, now)}, actor), http.StatusServiceUnavailable, serverBusyCode, ""},
	})
}
