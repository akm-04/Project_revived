//go:build postgres

package undeliveredreplay_test

import (
	"context"
	"net/http"
	"net/http/httptest"
	"sync"
	"testing"

	"gxb.local/backend/v2/internal/adapters/postgres/undeliveredstore"
	"gxb.local/backend/v2/internal/foundation/undelivered"
)

// heldMarker delays A's mark write until the test releases it, then delegates to
// the production store. B runs while A's write is held.
type heldMarker struct {
	store   undeliveredstore.Store
	started chan struct{}
	release chan struct{}
	once    sync.Once
	err     error
}

func (m *heldMarker) Mark(ctx context.Context, mark undelivered.Mark) error {
	m.once.Do(func() { close(m.started) })
	select {
	case <-m.release:
	case <-ctx.Done():
		return ctx.Err()
	}
	m.err = m.store.Mark(ctx, mark)
	return m.err
}

// A per-player claim fences a late mark (R6 Amendment 1 item B, A-063). A's
// reply write fails and its mark write is held; B, a later state request, runs
// and takes the claim; A's mark then lands too late to be restored; a resend of
// A must dispatch instead of replaying A's stale reply.
func TestUndeliveredReplayLateMarkCannotUndoInterveningRequest(t *testing.T) {
	h := newHarness(t)
	before := h.questionCount()
	held := &heldMarker{store: h.store, started: make(chan struct{}), release: make(chan struct{})}
	heldHandler := h.buildHandler(held, h.metrics)

	done := make(chan struct{})
	go func() {
		defer close(done)
		h.requestWith(heldHandler, 5, "first", h.bearer, &disconnectWriter{})
	}()
	<-held.started
	h.request(5, "intervening", nil)
	close(held.release)
	<-done

	resend := httptest.NewRecorder()
	h.request(5, "first", resend)
	if resend.Code != http.StatusOK {
		t.Fatalf("resend status=%d body=%q", resend.Code, resend.Body.String())
	}
	if got := h.questionCount(); got != before+3 {
		t.Fatalf("questions=%d want=%d (A, B, and the resend must each dispatch; the late mark must not replay)", got, before+3)
	}
}
