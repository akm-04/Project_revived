package postgres

import (
	"context"
	"errors"
	"sync"
	"testing"
	"time"

	appwakeup "gxb.local/backend/v2/internal/application/realtimewakeup"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type fakeWakeupFactory struct {
	mu       sync.Mutex
	sessions []wakeupSession
	acquires int
}

func (f *fakeWakeupFactory) Acquire(context.Context) (wakeupSession, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.acquires++
	if len(f.sessions) == 0 {
		return nil, errors.New("no fake session")
	}
	s := f.sessions[0]
	f.sessions = f.sessions[1:]
	return s, nil
}

type fakeWakeupSession struct {
	listenErr error
	payloads  []string
	waitErr   error
	closed    bool
}

func (s *fakeWakeupSession) Listen(context.Context) error { return s.listenErr }
func (s *fakeWakeupSession) Wait(context.Context) (string, error) {
	if len(s.payloads) > 0 {
		p := s.payloads[0]
		s.payloads = s.payloads[1:]
		return p, nil
	}
	if s.waitErr != nil {
		return "", s.waitErr
	}
	return "", context.Canceled
}
func (s *fakeWakeupSession) Close() { s.closed = true }

func encodedWakeup(t *testing.T, route, ref string) string {
	t.Helper()
	b, err := (appwakeup.Envelope{Version: 1, Route: route, Ref: ref}).Encode()
	if err != nil {
		t.Fatal(err)
	}
	return string(b)
}

func TestRealtimeWakeupListenerReconnectsConnectionLossThenDispatchesCanonicalReloadRoute(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	lost := errors.New("connection lost")
	s1 := &fakeWakeupSession{waitErr: lost}
	s2 := &fakeWakeupSession{payloads: []string{encodedWakeup(t, "social.friend", "p:7")}, waitErr: context.Canceled}
	factory := &fakeWakeupFactory{sessions: []wakeupSession{s1, s2}}
	var got string
	registry, err := appwakeup.NewRegistry(appwakeup.Registration{Route: "social.friend", Handler: appwakeup.RouteHandlerFunc(func(_ context.Context, ref string) error {
		got = ref
		cancel()
		return nil
	})})
	if err != nil {
		t.Fatal(err)
	}
	err = runRealtimeWakeupListener(ctx, factory, registry, 0)
	if !errors.Is(err, context.Canceled) {
		t.Fatalf("run err=%v", err)
	}
	if got != "p:7" || factory.acquires != 2 || !s1.closed || !s2.closed {
		t.Fatalf("got=%q acquires=%d closed1=%v closed2=%v", got, factory.acquires, s1.closed, s2.closed)
	}
}

func TestRealtimeWakeupListenerFailsClosedOnUnknownRouteWithoutReconnectLoop(t *testing.T) {
	empty, _ := appwakeup.NewRegistry()
	s := &fakeWakeupSession{payloads: []string{encodedWakeup(t, "unknown.route", "x")}}
	factory := &fakeWakeupFactory{sessions: []wakeupSession{s}}
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	err := runRealtimeWakeupListener(ctx, factory, empty, 0)
	if !errors.Is(err, appwakeup.ErrUnknownRoute) {
		t.Fatalf("err=%v", err)
	}
	if factory.acquires != 1 || !s.closed {
		t.Fatalf("acquires=%d closed=%v", factory.acquires, s.closed)
	}
}

type wakeupCommandTag struct{}

func (wakeupCommandTag) RowsAffected() int64 { return 1 }

type wakeupExecer struct {
	query string
	args  []any
	calls int
	err   error
}

func (e *wakeupExecer) Exec(_ context.Context, query string, args ...any) (tx.CommandTag, error) {
	e.calls++
	e.query = query
	e.args = append([]any(nil), args...)
	return wakeupCommandTag{}, e.err
}

func TestEmitRealtimeWakeupUsesCallerExecerAndReferenceEnvelopeOnly(t *testing.T) {
	exec := &wakeupExecer{}
	envelope := appwakeup.Envelope{Version: appwakeup.EnvelopeVersion, Route: "social.friend", Ref: "p:7"}
	if err := EmitRealtimeWakeup(context.Background(), exec, envelope); err != nil {
		t.Fatal(err)
	}
	if exec.calls != 1 || exec.query != `SELECT pg_notify($1,$2)` || len(exec.args) != 2 || exec.args[0] != RealtimeWakeupChannel {
		t.Fatalf("unexpected pg_notify call calls=%d query=%q args=%#v", exec.calls, exec.query, exec.args)
	}
	payload, ok := exec.args[1].(string)
	if !ok {
		t.Fatalf("payload type=%T", exec.args[1])
	}
	got, err := appwakeup.Decode([]byte(payload))
	if err != nil || got != envelope {
		t.Fatalf("decoded=%+v err=%v", got, err)
	}
	if err := EmitRealtimeWakeup(context.Background(), exec, appwakeup.Envelope{Version: 99, Route: "social.friend", Ref: "p:7"}); !errors.Is(err, appwakeup.ErrInvalidEnvelope) {
		t.Fatalf("invalid envelope err=%v", err)
	}
	if exec.calls != 1 {
		t.Fatalf("invalid envelope reached execer calls=%d", exec.calls)
	}
}
