package stockruntime

import (
	"context"
	"errors"
	"net/http"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/foundation/undelivered"
)

type auditFailedClaimStore struct {
	mark undelivered.Mark
	fail bool
}

func (s *auditFailedClaimStore) TakeMark(context.Context, int64) (undelivered.Take, error) {
	if s.fail {
		return undelivered.Take{}, errors.New("claim statement aborted before changing the row")
	}
	take := undelivered.Take{Claim: 2, Mark: s.mark, HasMark: len(s.mark.Reply) > 0}
	s.mark = undelivered.Mark{}
	return take, nil
}

func TestAuditA067FailedClaimCannotLeaveAReplyAcrossAnInterveningWrite(t *testing.T) {
	now := time.Date(2026, 11, 16, 12, 0, 0, 0, time.UTC)
	actor := actorForHTTP(t)
	params := map[string]any{"token": "bearer", "region": int64(1), "msg": "first"}
	store := &auditFailedClaimStore{mark: replayMark(t, actor, 5, params, now), fail: true}
	next := &nextDispatcher{}
	guard := UndeliveredReplay{Next: next, Authority: replayAuthority{actor}, Marks: store, Window: 10 * time.Minute}
	intervening := guard.Dispatch(context.Background(), replayRequest(t, 5, map[string]any{"token": "bearer", "region": int64(1), "msg": "intervening"}, "bearer", now))
	if next.calls == 0 && intervening.HTTPStatus != http.StatusOK {
		return
	}
	if next.calls != 1 || intervening.HTTPStatus != http.StatusOK {
		t.Fatalf("unexpected intervening response: calls=%d response=%+v", next.calls, intervening)
	}
	store.fail = false
	response := guard.Dispatch(context.Background(), replayRequest(t, 5, params, "bearer", now.Add(time.Second)))
	if next.calls != 2 || len(response.Raw) != 0 {
		t.Fatalf("old reply survived a successful intervening write after claim failure: calls=%d want2 reply=%s", next.calls, response.Raw)
	}
}
