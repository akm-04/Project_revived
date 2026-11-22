package stockruntime

import (
	"context"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/protocol/mids"
)

func TestAuditA062RentalCommandsAreStateChanging(t *testing.T) {
	for _, mid := range []uint16{594, 595, 619, 620} {
		if !mids.StateChanging(mid) {
			t.Errorf("rental command MID %d is classified read", mid)
		}
	}
}

func TestAuditA062RentalCommandInvalidatesEarlierReply(t *testing.T) {
	now := time.Date(2026, 11, 16, 12, 0, 0, 0, time.UTC)
	actor := actorForHTTP(t)
	params := map[string]any{"token": "bearer", "region": int64(1), "msg": "old question"}
	taker := &replayTaker{mark: replayMark(t, actor, 5, params, now), found: true}
	rental := GuildRentalDispatcher{Authority: replayAuthority{actor}, Service: &rentalProbe{}}
	guard := UndeliveredReplay{Next: rental, Authority: replayAuthority{actor}, Marks: taker, Window: 10 * time.Minute}
	response := guard.Dispatch(context.Background(), replayRequest(t, 594, map[string]any{"token": "bearer", "region": int64(1), "partner_id": int64(31)}, "bearer", now))
	if response.HTTPStatus != 200 {
		t.Fatalf("rental placement failed: %+v", response)
	}
	if taker.calls == 0 {
		t.Fatal("successful real rental dispatcher bypassed mark invalidation; an older matching MID 5 still replays after this state command")
	}
}
