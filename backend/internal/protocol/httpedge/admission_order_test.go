package httpedge

import (
	"bytes"
	"context"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/limits"
)

type stalledBody struct {
	started chan struct{}
	release chan struct{}
}

func (b *stalledBody) Read([]byte) (int, error) {
	close(b.started)
	<-b.release
	return 0, io.EOF
}

// A-047: a client that stalls its body must not hold a dispatch slot, so a stalled upload cannot starve other players.
func TestHandlerStalledBodyDoesNotHoldAdmission(t *testing.T) {
	admission, _ := NewAdmission(1)
	router := NewRouter()
	if err := router.Register(50, DispatcherFunc(func(context.Context, DispatchRequest) Response {
		return Response{HTTPStatus: http.StatusOK, Body: map[string]any{"ok": true}}
	})); err != nil {
		t.Fatal(err)
	}
	h := Handler{Limits: limits.Default(), Admission: admission, Router: router,
		Operations: operation.Factory{Clock: clock.Fixed{T: time.Unix(100, 0)}, Random: bytes.NewReader(make([]byte, 1024))}}

	stalled := &stalledBody{started: make(chan struct{}), release: make(chan struct{})}
	first := httptest.NewRequest(http.MethodPost, "http://gxb.invalid/", stalled)
	first.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	finished := make(chan struct{})
	go func() {
		h.ServeHTTP(httptest.NewRecorder(), first)
		close(finished)
	}()
	<-stalled.started

	w := httptest.NewRecorder()
	h.ServeHTTP(w, ordinaryRequest(t, `{"mid":50}`))
	close(stalled.release)
	<-finished
	if w.Code != http.StatusOK {
		t.Fatalf("second request while the first body stalls: status=%d body=%s", w.Code, w.Body.String())
	}
}

func TestHandlerDecodingLimitRefusesWithoutReadingBody(t *testing.T) {
	admission, _ := NewAdmission(1)
	decoding, _ := NewAdmission(1)
	h := Handler{Limits: limits.Default(), Admission: admission, Decoding: decoding, Router: NewRouter(),
		Operations: operation.Factory{Clock: clock.Fixed{T: time.Unix(100, 0)}, Random: bytes.NewReader(make([]byte, 1024))}}
	if !decoding.TryAcquire() {
		t.Fatal("acquire")
	}
	defer decoding.Release()
	w := httptest.NewRecorder()
	h.ServeHTTP(w, ordinaryRequest(t, `{"mid":50}`))
	if w.Code != http.StatusServiceUnavailable {
		t.Fatalf("decoding saturated: status=%d", w.Code)
	}
}
