package stockruntime

import (
	"context"
	"errors"
	"net"
	"os"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	app "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/projection/lobby"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
	wireRT "gxb.local/backend/v2/internal/protocol/realtime"
)

type runtimeAuthority struct {
	actor     identity.ActorContext
	resolve   func(context.Context) error
	validate  func(context.Context) error
	liveCalls atomic.Int32
}

func (r *runtimeAuthority) ResolveGameplayBearer(ctx context.Context, _ string, _ time.Time) (identity.ActorContext, error) {
	if r.resolve != nil {
		if err := r.resolve(ctx); err != nil {
			return identity.ActorContext{}, err
		}
	}
	return r.actor, nil
}
func (r *runtimeAuthority) ValidateActor(ctx context.Context, _ identity.ActorContext, _ time.Time) error {
	r.liveCalls.Add(1)
	if r.validate != nil {
		return r.validate(ctx)
	}
	return nil
}

func r3bActor(t *testing.T) identity.ActorContext {
	u, _ := ids.ParseUUID("55555555-5555-4555-8555-555555555555")
	c, _ := identity.ContextIDFrom(u)
	return identity.ActorContext{ContextID: c, LogicalServerID: 1, PlayerID: 100001}
}
func testPolicy() RealtimePolicy {
	p := DefaultRealtimePolicy()
	p.MaxConnections = 8
	p.MaxPreauth = 4
	p.MaxEstablished = 8
	p.HandshakeTimeout = 80 * time.Millisecond
	p.AuthQueryTimeout = 30 * time.Millisecond
	p.LivenessQueryTimeout = 30 * time.Millisecond
	p.LivenessInterval = 20 * time.Millisecond
	p.ClientIdleTimeout = 80 * time.Millisecond
	p.WriteTimeout = 100 * time.Millisecond
	p.heartbeatInterval = 10 * time.Millisecond
	return p
}
func loginFrame(t *testing.T) []byte {
	t.Helper()
	b, err := wireRT.EncodeFrame(wireRT.Frame{MID: mids.MIDTCPLogin, Params: &amf3.Object{Properties: []amf3.Property{{Name: "token", Value: "x"}, {Name: "region", Value: 1.0}, {Name: "room_id", Value: 1.0}}}})
	if err != nil {
		t.Fatal(err)
	}
	return b
}
func startAuthenticated(t *testing.T, srv RealtimeServer) (net.Conn, <-chan error) {
	t.Helper()
	server, client := net.Pipe()
	done := make(chan error, 1)
	go func() { done <- srv.ServeConn(context.Background(), server); _ = server.Close() }()
	if _, err := client.Write(loginFrame(t)); err != nil {
		t.Fatal(err)
	}
	buf := make([]byte, 1024)
	_ = client.SetReadDeadline(time.Now().Add(time.Second))
	n, err := client.Read(buf)
	if err != nil {
		t.Fatal(err)
	}
	dec, _ := wireRT.NewStreamDecoder(limits.Default())
	fs, err := dec.Feed(buf[:n])
	if err != nil || len(fs) != 1 || fs[0].MID != mids.MIDChatRoomEntered {
		t.Fatalf("ack frames=%v err=%v", fs, err)
	}
	_ = client.SetReadDeadline(time.Time{})
	return client, done
}

func TestR3BAbsoluteHandshakeDeadlineSlowloris(t *testing.T) {
	p := testPolicy()
	p.HandshakeTimeout = 70 * time.Millisecond
	a := &runtimeAuthority{actor: r3bActor(t)}
	srv := RealtimeServer{Auth: app.Service{Authority: a, Endpoints: rtEndpoint{}}, Limits: limits.Default(), Policy: p}
	server, client := net.Pipe()
	defer client.Close()
	done := make(chan error, 1)
	start := time.Now()
	go func() { defer server.Close(); done <- srv.ServeConn(context.Background(), server) }()
	frame := loginFrame(t)
	for i := 0; i < 4; i++ {
		_, _ = client.Write(frame[i : i+1])
		time.Sleep(20 * time.Millisecond)
	}
	select {
	case err := <-done:
		if err == nil {
			t.Fatal("expected handshake timeout")
		}
		if time.Since(start) > 180*time.Millisecond {
			t.Fatalf("deadline was extended: %v", time.Since(start))
		}
	case <-time.After(250 * time.Millisecond):
		t.Fatal("slowloris did not hit absolute handshake deadline")
	}
}

func TestR3BAdmissionSaturationAndRelease(t *testing.T) {
	p := testPolicy()
	p.MaxConnections = 1
	p.MaxPreauth = 1
	p.MaxEstablished = 1
	p.HandshakeTimeout = time.Second
	lim, _ := NewAdmissionLimiter(p)
	a := &runtimeAuthority{actor: r3bActor(t)}
	srv := RealtimeServer{Auth: app.Service{Authority: a, Endpoints: rtEndpoint{}}, Limits: limits.Default(), Policy: p, Admission: lim}
	s1, c1 := net.Pipe()
	done := make(chan error, 1)
	go func() { done <- srv.ServeConn(context.Background(), s1) }()
	time.Sleep(10 * time.Millisecond)
	s2, c2 := net.Pipe()
	defer c2.Close()
	if err := srv.ServeConn(context.Background(), s2); !errors.Is(err, ErrRealtimeAdmissionFull) {
		t.Fatalf("err=%v", err)
	}
	_ = c1.Close()
	<-done
	s3, c3 := net.Pipe()
	ctx, cancel := context.WithCancel(context.Background())
	d3 := make(chan error, 1)
	go func() { d3 <- srv.ServeConn(ctx, s3) }()
	time.Sleep(10 * time.Millisecond)
	cancel()
	_ = c3.Close()
	<-d3
}

func TestR3BAuthAndLivenessQueryTimeouts(t *testing.T) {
	p := testPolicy()
	p.AuthQueryTimeout = 20 * time.Millisecond
	a := &runtimeAuthority{actor: r3bActor(t), resolve: func(ctx context.Context) error { <-ctx.Done(); return ctx.Err() }}
	srv := RealtimeServer{Auth: app.Service{Authority: a, Endpoints: rtEndpoint{}}, Limits: limits.Default(), Policy: p}
	s, c := net.Pipe()
	done := make(chan error, 1)
	go func() { done <- srv.ServeConn(context.Background(), s) }()
	_, _ = c.Write(loginFrame(t))
	if err := <-done; !errors.Is(err, context.DeadlineExceeded) {
		t.Fatalf("auth err=%v", err)
	}
	_ = c.Close()

	p = testPolicy()
	p.LivenessInterval = 15 * time.Millisecond
	p.LivenessQueryTimeout = 20 * time.Millisecond
	p.ClientIdleTimeout = 120 * time.Millisecond
	a = &runtimeAuthority{actor: r3bActor(t), validate: func(ctx context.Context) error { <-ctx.Done(); return ctx.Err() }}
	srv = RealtimeServer{Auth: app.Service{Authority: a, Endpoints: rtEndpoint{}}, Limits: limits.Default(), Policy: p}
	c2, done2 := startAuthenticated(t, srv)
	defer c2.Close()
	select {
	case err := <-done2:
		if !errors.Is(err, context.DeadlineExceeded) {
			t.Fatalf("live err=%v", err)
		}
	case <-time.After(200 * time.Millisecond):
		t.Fatal("liveness query timeout not enforced")
	}
}

func TestR3BHeartbeatKeepsAliveAndSilentConnectionExpires(t *testing.T) {
	p := testPolicy()
	p.ClientIdleTimeout = 70 * time.Millisecond
	p.LivenessInterval = 15 * time.Millisecond
	a := &runtimeAuthority{actor: r3bActor(t)}
	srv := RealtimeServer{Auth: app.Service{Authority: a, Endpoints: rtEndpoint{}}, Limits: limits.Default(), Policy: p}
	c, done := startAuthenticated(t, srv)
	hb, _ := wireRT.EncodeFrame(wireRT.Frame{MID: mids.MIDSocketHeartbeat, Params: &amf3.Object{}})
	for i := 0; i < 4; i++ {
		time.Sleep(30 * time.Millisecond)
		if _, err := c.Write(hb); err != nil {
			t.Fatal(err)
		}
		select {
		case err := <-done:
			t.Fatalf("closed while heartbeats active: %v", err)
		default:
		}
	}
	_ = c.Close()
	<-done

	a = &runtimeAuthority{actor: r3bActor(t)}
	srv = RealtimeServer{Auth: app.Service{Authority: a, Endpoints: rtEndpoint{}}, Limits: limits.Default(), Policy: p}
	c2, done2 := startAuthenticated(t, srv)
	defer c2.Close()
	select {
	case err := <-done2:
		if !errors.Is(err, ErrRealtimeClientIdle) {
			t.Fatalf("idle err=%v", err)
		}
	case <-time.After(250 * time.Millisecond):
		t.Fatal("silent connection did not expire")
	}
}

type echoDispatcher struct{}

func (echoDispatcher) HandleClientFrame(_ context.Context, _ app.Admission, f wireRT.Frame) ([]wireRT.Frame, error) {
	return []wireRT.Frame{{MID: mids.MIDChatRoomEntered, Sequence: f.Sequence, Params: &amf3.Object{Properties: []amf3.Property{{Name: "room_id", Value: 1.0}}}}}, nil
}
func TestR3BMinimalDispatcherUsesExistingWriter(t *testing.T) {
	p := testPolicy()
	a := &runtimeAuthority{actor: r3bActor(t)}
	srv := RealtimeServer{Auth: app.Service{Authority: a, Endpoints: rtEndpoint{}}, Limits: limits.Default(), Policy: p, Dispatcher: echoDispatcher{}}
	c, done := startAuthenticated(t, srv)
	defer c.Close()
	req, _ := wireRT.EncodeFrame(wireRT.Frame{MID: 32782, Sequence: 7, Params: &amf3.Object{}})
	_, _ = c.Write(req)
	buf := make([]byte, 1024)
	_ = c.SetReadDeadline(time.Now().Add(time.Second))
	n, err := c.Read(buf)
	if err != nil {
		t.Fatal(err)
	}
	dec, _ := wireRT.NewStreamDecoder(limits.Default())
	fs, err := dec.Feed(buf[:n])
	if err != nil || len(fs) != 1 || fs[0].Sequence != 7 {
		t.Fatalf("frames=%v err=%v", fs, err)
	}
	_ = c.Close()
	<-done
}

type blockingConn struct {
	release chan struct{}
	entered chan struct{}
	active  atomic.Int32
	max     atomic.Int32
}

func newBlockingConn() *blockingConn {
	return &blockingConn{release: make(chan struct{}, 8), entered: make(chan struct{}, 8)}
}
func (c *blockingConn) Read([]byte) (int, error) { return 0, net.ErrClosed }
func (c *blockingConn) Write(b []byte) (int, error) {
	n := c.active.Add(1)
	for {
		m := c.max.Load()
		if n <= m || c.max.CompareAndSwap(m, n) {
			break
		}
	}
	c.entered <- struct{}{}
	<-c.release
	c.active.Add(-1)
	return len(b), nil
}
func (c *blockingConn) Close() error                     { return nil }
func (c *blockingConn) LocalAddr() net.Addr              { return dummyAddr("l") }
func (c *blockingConn) RemoteAddr() net.Addr             { return dummyAddr("r") }
func (c *blockingConn) SetDeadline(time.Time) error      { return nil }
func (c *blockingConn) SetReadDeadline(time.Time) error  { return nil }
func (c *blockingConn) SetWriteDeadline(time.Time) error { return nil }

type dummyAddr string

func (d dummyAddr) Network() string { return "pipe" }
func (d dummyAddr) String() string  { return string(d) }
func TestR3BBoundedSingleWriterBackpressure(t *testing.T) {
	cfg := limits.Default()
	cfg.WriterFrames = 1
	cfg.WriterBytes = 1 << 20
	c := newBlockingConn()
	w, err := newConnWriter(context.Background(), c, cfg, time.Second)
	if err != nil {
		t.Fatal(err)
	}
	defer w.Close()
	frame := wireRT.Frame{MID: mids.MIDChatRoomEntered, Params: &amf3.Object{Properties: []amf3.Property{{Name: "room_id", Value: 1.0}}}}
	d1 := make(chan error, 1)
	go func() { d1 <- w.Send(context.Background(), frame, cfg) }()
	<-c.entered
	d2 := make(chan error, 1)
	go func() { d2 <- w.Send(context.Background(), frame, cfg) }()
	time.Sleep(10 * time.Millisecond)
	if err := w.Send(context.Background(), frame, cfg); !errors.Is(err, wireRT.ErrQueueFull) {
		t.Fatalf("backpressure err=%v", err)
	}
	c.release <- struct{}{}
	<-d1
	<-c.entered
	c.release <- struct{}{}
	<-d2
	if c.max.Load() != 1 {
		t.Fatalf("concurrent writes=%d", c.max.Load())
	}
}

func TestR3BPolicyEnvAndStockHeartbeatCompatibility(t *testing.T) {
	vals := map[string]string{"GXB_REALTIME_MAX_CONNECTIONS": "10", "GXB_REALTIME_MAX_PREAUTH": "2", "GXB_REALTIME_MAX_ESTABLISHED": "9", "GXB_REALTIME_CLIENT_IDLE_TIMEOUT": "21m"}
	p, err := RealtimePolicyFromEnv(func(k string) string { return vals[k] })
	if err != nil {
		t.Fatal(err)
	}
	if p.MaxConnections != 10 || p.ClientIdleTimeout != 21*time.Minute {
		t.Fatalf("policy=%+v", p)
	}
	vals["GXB_REALTIME_CLIENT_IDLE_TIMEOUT"] = "5m"
	if _, err := RealtimePolicyFromEnv(func(k string) string { return vals[k] }); err == nil {
		t.Fatal("idle shorter than stock heartbeat accepted")
	}
}

func r3cActor(t *testing.T) identity.ActorContext {
	t.Helper()
	au, _ := ids.ParseUUID("44444444-4444-4444-8444-444444444444")
	su, _ := ids.ParseUUID("66666666-6666-4666-8666-666666666666")
	cu, _ := ids.ParseUUID("55555555-5555-4555-8555-555555555555")
	a, err := identity.AccountIDFrom(au)
	if err != nil {
		t.Fatal(err)
	}
	s, err := identity.SessionIDFrom(su)
	if err != nil {
		t.Fatal(err)
	}
	c, err := identity.ContextIDFrom(cu)
	if err != nil {
		t.Fatal(err)
	}
	return identity.ActorContext{AccountID: a, AccountUID: "700001", SessionID: s, ContextID: c, LogicalServerID: 1, PlayerID: 100001, ContextGeneration: 3}
}

func TestR3CRealtimeEvidenceUsesOpaqueCorrelatedLifecycle(t *testing.T) {
	actor := r3cActor(t)
	dir := t.TempDir()
	path := dir + "/r3c-realtime.jsonl"
	tracker, err := lobby.NewCapturedBootTracker(lobby.EvidenceConfig{
		RunID: "r3c-test", ProcessRole: lobby.ProcessRealtime, ProcessID: "proc-rt",
		SinkPath: path, MaxEvents: 64, RingEvents: 64, StartedAt: time.Now().UTC().Add(-time.Second),
	})
	if err != nil {
		t.Fatal(err)
	}
	p := testPolicy()
	p.ClientIdleTimeout = time.Second
	srv := RealtimeServer{Auth: app.Service{Authority: &runtimeAuthority{actor: actor}, Endpoints: rtEndpoint{}}, Limits: limits.Default(), Policy: p, Tracker: tracker}
	c, done := startAuthenticated(t, srv)
	if err := c.Close(); err != nil {
		t.Fatal(err)
	}
	if err := <-done; err != nil {
		t.Fatalf("serve err=%v", err)
	}
	if err := tracker.Close(); err != nil {
		t.Fatal(err)
	}

	events := tracker.Events()
	var protocol []lobby.BootEvent
	for _, e := range events {
		switch e.Kind {
		case lobby.BootTCPLogin, lobby.BootClientConnected, lobby.BootRoomEntered, lobby.BootClientClosed:
			protocol = append(protocol, e)
		}
	}
	if len(protocol) != 4 {
		t.Fatalf("lifecycle events=%d all=%+v", len(protocol), events)
	}
	wantSession, wantContext, wantConn := protocol[0].SessionTag, protocol[0].ContextTag, protocol[0].ConnectionTag
	if wantSession == "" || wantContext == "" || wantConn == "" {
		t.Fatalf("missing correlation tags: %+v", protocol[0])
	}
	for _, e := range protocol {
		if e.RunID != "r3c-test" || e.ProcessRole != lobby.ProcessRealtime || e.ProcessID != "proc-rt" {
			t.Fatalf("process correlation mismatch: %+v", e)
		}
		if e.SessionTag != wantSession || e.ContextTag != wantContext || e.ConnectionTag != wantConn {
			t.Fatalf("lifecycle correlation mismatch: %+v", e)
		}
	}
	if wantSession == actor.SessionID.UUID().String() || wantContext == actor.ContextID.UUID().String() {
		t.Fatalf("raw canonical id leaked into correlation tags")
	}
	b, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	raw := string(b)
	if strings.Contains(raw, actor.SessionID.UUID().String()) || strings.Contains(raw, actor.ContextID.UUID().String()) {
		t.Fatalf("raw canonical session/context id leaked to JSONL: %s", raw)
	}
}
