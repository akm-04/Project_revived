package stockruntime

import (
	"context"
	"testing"

	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/mids"
)

func TestInactiveModeDispatcherAnswersStockRefusal(t *testing.T) {
	got := InactiveModeDispatcher{}.Dispatch(context.Background(), httpedge.DispatchRequest{})
	if got.HTTPStatus != 200 || !got.Inactive || len(got.Body) != 1 || got.Body["error_code"] != 1 {
		t.Fatalf("%+v", got)
	}
}

func TestInactiveModeMIDsAreKnownHTTPMIDs(t *testing.T) {
	seen := map[uint16]bool{}
	for _, mid := range InactiveModeMIDs {
		descriptor, known := mids.Lookup(mid)
		if !known || descriptor.Transport != mids.HTTP || seen[mid] {
			t.Fatalf("MID %d known=%v transport=%v duplicate=%v", mid, known, descriptor.Transport, seen[mid])
		}
		seen[mid] = true
	}
}
