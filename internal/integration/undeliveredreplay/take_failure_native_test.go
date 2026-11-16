//go:build postgres

package undeliveredreplay_test

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"sync"
	"testing"

	"gxb.local/backend/v2/internal/adapters/postgres/undeliveredstore"
	"gxb.local/backend/v2/internal/foundation/undelivered"
)

// The stock edge maps an unavailable replay claim to the transient 503 body
// (stockruntime/failure.go serverBusyCode).
const serverBusyCode int64 = 35033

type failOnceTaker struct {
	store    undeliveredstore.Store
	mutex    sync.Mutex
	failNext bool
}

func (t *failOnceTaker) failOneTake() {
	t.mutex.Lock()
	defer t.mutex.Unlock()
	t.failNext = true
}

func (t *failOnceTaker) TakeMark(ctx context.Context, playerID int64) (undelivered.Take, error) {
	t.mutex.Lock()
	fail := t.failNext
	t.failNext = false
	t.mutex.Unlock()
	if fail {
		return undelivered.Take{}, errors.New("claim statement unavailable")
	}
	return t.store.TakeMark(ctx, playerID)
}

func refusedCode(body []byte) int64 {
	var payload struct {
		ErrorCode int64 `json:"error_code"`
	}
	_ = json.Unmarshal(body, &payload)
	return payload.ErrorCode
}

// A state request that cannot take its claim must not dispatch: the older mark
// stays stored, so a resend of the earlier request still replays its reply, and
// no intervening state write committed (A-067).
func TestUndeliveredReplayRefusesAStateRequestWhoseClaimFails(t *testing.T) {
	var taker *failOnceTaker
	h := newHarnessWithTaker(t, func(store undeliveredstore.Store) undelivered.Taker {
		taker = &failOnceTaker{store: store}
		return taker
	})
	before := h.questionCount()
	first := &disconnectWriter{}
	h.request(5, "first", first)
	if !h.markReplyExists() {
		t.Fatal("no mark after an undelivered success")
	}
	taker.failOneTake()
	refused := httptest.NewRecorder()
	h.request(5, "intervening", refused)
	if refused.Code != http.StatusServiceUnavailable || refusedCode(refused.Body.Bytes()) != serverBusyCode {
		t.Fatalf("status=%d body=%q", refused.Code, refused.Body.String())
	}
	if got := h.questionCount(); got != before+1 {
		t.Fatalf("questions=%d want=%d (a failed claim must not dispatch)", got, before+1)
	}
	if !h.markReplyExists() {
		t.Fatal("a failed take cleared the older mark")
	}
	if h.metrics.value(undelivered.TakeFailuresTotal) != 1 {
		t.Fatalf("take failures=%d", h.metrics.value(undelivered.TakeFailuresTotal))
	}
	resend := httptest.NewRecorder()
	h.request(5, "first", resend)
	if resend.Code != http.StatusOK || resend.Body.String() != string(first.written) {
		t.Fatalf("resend status=%d body=%q want=%q", resend.Code, resend.Body.String(), first.written)
	}
	if got := h.questionCount(); got != before+1 {
		t.Fatalf("questions=%d want=%d (the resend replayed)", got, before+1)
	}
	if h.metrics.value(undelivered.ReplaysTotal) != 1 {
		t.Fatalf("replays=%d", h.metrics.value(undelivered.ReplaysTotal))
	}
}

// After a state request runs, an earlier request's mark is gone, so its resend
// dispatches fresh instead of replaying the invalidated reply.
func TestUndeliveredReplayDispatchesFreshAfterAnInterveningStateRequest(t *testing.T) {
	h := newHarness(t)
	before := h.questionCount()
	first := &disconnectWriter{}
	h.request(5, "first", first)
	h.request(5, "intervening", nil)
	if h.markReplyExists() {
		t.Fatal("the intervening state request did not take the mark")
	}
	resend := httptest.NewRecorder()
	h.request(5, "first", resend)
	if resend.Code != http.StatusOK {
		t.Fatalf("resend status=%d body=%q", resend.Code, resend.Body.String())
	}
	if got := h.questionCount(); got != before+3 {
		t.Fatalf("questions=%d want=%d (A, B, and the fresh resend)", got, before+3)
	}
	if h.metrics.value(undelivered.ReplaysTotal) != 0 {
		t.Fatalf("replays=%d after an intervening state request", h.metrics.value(undelivered.ReplaysTotal))
	}
}
