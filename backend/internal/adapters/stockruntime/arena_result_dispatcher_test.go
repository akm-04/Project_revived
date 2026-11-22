package stockruntime

import (
	"context"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/protocol/replyconformance"
)

func TestArenaResultDuplicateTerminal(t *testing.T) {
	dispatcher := NewArenaResultDispatcher(httpAuthority{actorForHTTP(t)})
	response := dispatcher.Dispatch(context.Background(), env(279, nil, time.Unix(600, 0).UTC()))
	if response.HTTPStatus != 200 {
		t.Fatalf("279 status = %d", response.HTTPStatus)
	}
	if response.Body["error_code"] != int64(30005) {
		t.Fatalf("error_code = %#v", response.Body["error_code"])
	}
	favor, ok := response.Body["partner_favor"].(map[string]any)
	if !ok || len(favor) != 0 {
		t.Fatalf("partner_favor = %#v", response.Body["partner_favor"])
	}
	items, ok := response.Body["items"].([]any)
	if !ok || items == nil || len(items) != 0 {
		t.Fatalf("items = %#v", response.Body["items"])
	}
	if len(response.Body) != 3 {
		t.Fatalf("279 body = %#v, want the three terminal keys", response.Body)
	}
	replyconformance.Check(t, 279, response.Body)
}

func TestArenaResultRequiresABearer(t *testing.T) {
	dispatcher := NewArenaResultDispatcher(httpAuthority{actorForHTTP(t)})
	request := env(279, nil, time.Unix(600, 0).UTC())
	request.Envelope.Claims.Token = ""
	if response := dispatcher.Dispatch(context.Background(), request); response.HTTPStatus != 401 {
		t.Fatalf("279 without bearer = %+v", response)
	}
}
