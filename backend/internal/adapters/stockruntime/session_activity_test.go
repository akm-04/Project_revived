package stockruntime

import (
	"context"
	"sync"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/observability"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

type recordingSessionActivity struct {
	mutex    sync.Mutex
	sessions []identity.SessionID
	touched  chan identity.SessionID
}

func (r *recordingSessionActivity) TouchActivity(_ context.Context, sessionID identity.SessionID) error {
	r.mutex.Lock()
	r.sessions = append(r.sessions, sessionID)
	r.mutex.Unlock()
	r.touched <- sessionID
	return nil
}

func testSessionID(t *testing.T) identity.SessionID {
	t.Helper()
	raw, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	sessionID, err := identity.SessionIDFrom(raw)
	if err != nil {
		t.Fatal(err)
	}
	return sessionID
}

func notingDispatcher(sessionID identity.SessionID) httpedge.Dispatcher {
	return httpedge.DispatcherFunc(func(ctx context.Context, _ httpedge.DispatchRequest) httpedge.Response {
		observability.NoteActor(ctx, observability.RequestActor{SessionID: sessionID.UUID().String()})
		return httpedge.Response{HTTPStatus: 200, Body: map[string]any{"ok": true}}
	})
}

func dispatchWithNote(ctx context.Context, dispatcher httpedge.Dispatcher) httpedge.Response {
	return dispatcher.Dispatch(ctx, httpedge.DispatchRequest{})
}

func TestSessionActivityTouchesOncePerInterval(t *testing.T) {
	sessionID := testSessionID(t)
	toucher := &recordingSessionActivity{touched: make(chan identity.SessionID, 4)}
	current := time.Unix(1_700_000_000, 0).UTC()
	activity := &SessionActivity{Touch: toucher, Interval: time.Minute, now: func() time.Time { return current }}
	wrapped := activity.Wrap(notingDispatcher(sessionID))
	ctx, _ := observability.WithRequestNote(context.Background())

	response := dispatchWithNote(ctx, wrapped)
	if response.HTTPStatus != 200 || response.Body["ok"] != true {
		t.Fatalf("wrapped reply = %+v, the decorator must not change it", response)
	}
	select {
	case got := <-toucher.touched:
		if got != sessionID {
			t.Fatalf("touched session = %s, want %s", got.UUID(), sessionID.UUID())
		}
	case <-time.After(2 * time.Second):
		t.Fatal("authenticated request did not touch its identity session")
	}

	dispatchWithNote(ctx, wrapped)
	select {
	case got := <-toucher.touched:
		t.Fatalf("second request in the same interval touched %s again", got.UUID())
	case <-time.After(100 * time.Millisecond):
	}

	current = current.Add(time.Minute + time.Second)
	dispatchWithNote(ctx, wrapped)
	select {
	case <-toucher.touched:
	case <-time.After(2 * time.Second):
		t.Fatal("request after the interval did not touch its identity session")
	}
}

func TestSessionActivitySkipsRequestsWithoutAnAuthenticatedActor(t *testing.T) {
	toucher := &recordingSessionActivity{touched: make(chan identity.SessionID, 1)}
	activity := &SessionActivity{Touch: toucher, Interval: time.Minute}
	dispatcher := httpedge.DispatcherFunc(func(context.Context, httpedge.DispatchRequest) httpedge.Response {
		return httpedge.Response{HTTPStatus: 200}
	})
	ctx, _ := observability.WithRequestNote(context.Background())
	dispatchWithNote(ctx, activity.Wrap(dispatcher))

	select {
	case got := <-toucher.touched:
		t.Fatalf("unauthenticated request touched %s", got.UUID())
	case <-time.After(100 * time.Millisecond):
	}
}
