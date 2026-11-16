package stockruntime

import (
	"context"
	"slices"
	"testing"

	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/mids"
)

func TestInactiveModeDispatcherAnswersStockRefusal(t *testing.T) {
	got := InactiveModeDispatcher{}.Dispatch(context.Background(), httpedge.DispatchRequest{})
	if got.HTTPStatus != 409 || !got.Inactive || len(got.Body) != 2 || got.Body["error_code"] != unprovenRefusalCode || got.Body["error_msg"] != "" {
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

// TestServedSummonAndArenaMIDsAreNotInactive guards I9_MODE_SURFACE_V1 F3/F5:
// 59 (hero summon), 768 (arena info) and 781 (pet summon) have production
// dispatchers, so the shared inactive dispatcher must not claim them.
func TestServedSummonAndArenaMIDsAreNotInactive(t *testing.T) {
	for _, mid := range []uint16{59, 768, 781} {
		if slices.Contains(InactiveModeMIDs, mid) {
			t.Fatalf("MID %d has a live owner and must not answer through the inactive dispatcher", mid)
		}
	}
}
