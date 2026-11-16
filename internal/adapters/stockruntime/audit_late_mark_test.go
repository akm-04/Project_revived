package stockruntime

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"sync"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/observability"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/undelivered"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/limits"
)

type auditLateMarkStore struct {
	mutex   sync.Mutex
	mark    undelivered.Mark
	found   bool
	started chan struct{}
	release chan struct{}
}

func (s *auditLateMarkStore) Mark(ctx context.Context, mark undelivered.Mark) error {
	close(s.started)
	select {
	case <-s.release:
	case <-ctx.Done():
		return ctx.Err()
	}
	s.mutex.Lock()
	defer s.mutex.Unlock()
	s.mark, s.found = mark, true
	return nil
}

func (s *auditLateMarkStore) TakeMark(context.Context, int64) (undelivered.Mark, bool, error) {
	s.mutex.Lock()
	defer s.mutex.Unlock()
	mark, found := s.mark, s.found
	s.found = false
	return mark, found, nil
}

type auditDisconnectedWriter struct{ *httptest.ResponseRecorder }

func (w auditDisconnectedWriter) Write(payload []byte) (int, error) {
	return 0, errors.New("disconnected")
}

func TestAuditA063LateMarkCannotUndoInterveningRequest(t *testing.T) {
	actor := actorForHTTP(t)
	store := &auditLateMarkStore{started: make(chan struct{}), release: make(chan struct{})}
	calls := 0
	dispatcher := httpedge.DispatcherFunc(func(ctx context.Context, request httpedge.DispatchRequest) httpedge.Response {
		calls++
		observability.NoteActor(ctx, observability.RequestActor{PlayerID: int64(actor.PlayerID), SessionID: actor.SessionID.UUID().String()})
		return httpedge.Response{HTTPStatus: 200, Body: map[string]any{"call": calls}}
	})
	router := httpedge.NewRouter()
	router.Wrap = func(next httpedge.Dispatcher) httpedge.Dispatcher {
		return UndeliveredReplay{Next: next, Authority: replayAuthority{actor}, Marks: store, Window: 10 * time.Minute}
	}
	if err := router.Register(5, dispatcher); err != nil {
		t.Fatal(err)
	}
	admission, err := httpedge.NewAdmission(4)
	if err != nil {
		t.Fatal(err)
	}
	handler := httpedge.Handler{Limits: limits.Default(), Admission: admission, Operations: operation.Factory{Clock: clock.System{}}, Router: router, Undelivered: store}
	request := func(message string) *http.Request {
		body := `{"mid":5,"token":"bearer","region":1,"msg":"` + message + `"}`
		request := httptest.NewRequest(http.MethodPost, "/", strings.NewReader("payload="+url.QueryEscape(body)))
		request.Header.Set("Content-Type", "application/x-www-form-urlencoded")
		return request
	}
	done := make(chan struct{})
	go func() {
		handler.ServeHTTP(auditDisconnectedWriter{httptest.NewRecorder()}, request("first"))
		close(done)
	}()
	<-store.started
	handler.ServeHTTP(httptest.NewRecorder(), request("intervening"))
	close(store.release)
	<-done
	if calls != 2 {
		t.Fatalf("setup dispatched %d operations, want2", calls)
	}
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request("first"))
	if calls != 3 {
		t.Fatalf("late mark resurrected the old reply after an intervening state request: dispatched%d want3, reply%s", calls, response.Body.String())
	}
}
