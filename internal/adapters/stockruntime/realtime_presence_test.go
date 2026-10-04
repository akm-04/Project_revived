package stockruntime

import (
	"bytes"
	"context"
	"errors"
	"net"
	"sync"
	"testing"
	"time"

	app "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/application/socialpresence"
	"gxb.local/backend/v2/internal/domain/identity"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
)

type presenceProjectionFake struct {
	mu        sync.Mutex
	admits    []socialpresence.LeaseRef
	renews    []socialpresence.LeaseRef
	retires   []socialpresence.LeaseRef
	admitErr  error
	renewErr  error
	retireErr error
}

func (f *presenceProjectionFake) Admit(_ context.Context, _ operation.Context, r socialpresence.LeaseRef, _ time.Duration) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.admits = append(f.admits, r)
	return f.admitErr
}
func (f *presenceProjectionFake) Renew(_ context.Context, _ operation.Context, r socialpresence.LeaseRef, _ time.Duration) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.renews = append(f.renews, r)
	return f.renewErr
}
func (f *presenceProjectionFake) Retire(_ context.Context, _ operation.Context, r socialpresence.LeaseRef) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.retires = append(f.retires, r)
	return f.retireErr
}

type fullRTAuthority struct{ actor identity.ActorContext }

func (r fullRTAuthority) ResolveGameplayBearer(context.Context, string, time.Time) (identity.ActorContext, error) {
	return r.actor, nil
}
func (r fullRTAuthority) ValidateActor(context.Context, identity.ActorContext, time.Time) error {
	return nil
}

func fullActorForPresence(t *testing.T) identity.ActorContext {
	t.Helper()
	parse := func(raw string) ids.UUID {
		u, err := ids.ParseUUID(raw)
		if err != nil {
			t.Fatal(err)
		}
		return u
	}
	aid, _ := identity.AccountIDFrom(parse("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"))
	sid, _ := identity.SessionIDFrom(parse("bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"))
	cid, _ := identity.ContextIDFrom(parse("cccccccc-cccc-4ccc-8ccc-cccccccccccc"))
	return identity.ActorContext{
		AccountID: aid, AccountUID: "presence-test", SessionID: sid, ContextID: cid,
		LogicalServerID: 1, PlayerID: 100001, ContextGeneration: 1,
		SessionLivenessVersion: 1, ContextLivenessVersion: 1,
	}
}

func presenceServer(t *testing.T, projection *presenceProjectionFake, onErr func(string, error)) RealtimeServer {
	t.Helper()
	instance, err := ids.ParseUUID("dddddddd-dddd-4ddd-8ddd-dddddddddddd")
	if err != nil {
		t.Fatal(err)
	}
	p := DefaultRealtimePolicy()
	p.LivenessInterval = time.Hour
	p.ClientIdleTimeout = time.Hour
	return RealtimeServer{
		Auth:   app.Service{Authority: fullRTAuthority{fullActorForPresence(t)}, Endpoints: rtEndpoint{}},
		Limits: limits.Default(), Policy: p, Registry: NewConnectionRegistry(), Presence: projection,
		PresenceOperations: operation.Factory{Clock: clock.Fixed{T: time.Unix(1000, 0).UTC()}, Random: bytes.NewReader(make([]byte, 4096))},
		RealtimeInstanceID: instance, OnPresenceError: onErr,
	}
}

func sendLoginAndReadAck(t *testing.T, client net.Conn) {
	t.Helper()
	login, _ := rt.EncodeFrame(rt.Frame{MID: mids.MIDTCPLogin, Params: &amf3.Object{Properties: []amf3.Property{{Name: "token", Value: "x"}, {Name: "region", Value: 1.0}, {Name: "room_id", Value: 1.0}}}})
	if _, err := client.Write(login); err != nil {
		t.Fatal(err)
	}
	buf := make([]byte, 1024)
	_ = client.SetReadDeadline(time.Now().Add(time.Second))
	n, err := client.Read(buf)
	if err != nil {
		t.Fatal(err)
	}
	dec, _ := rt.NewStreamDecoder(limits.Default())
	frames, err := dec.Feed(buf[:n])
	if err != nil || len(frames) != 1 || frames[0].MID != mids.MIDChatRoomEntered {
		t.Fatalf("frames=%v err=%v", frames, err)
	}
}

func TestRealtimePresenceAdmitHeartbeatRetireLifecycle(t *testing.T) {
	serverConn, client := net.Pipe()
	defer client.Close()
	proj := &presenceProjectionFake{}
	s := presenceServer(t, proj, nil)
	done := make(chan error, 1)
	go func() { done <- s.ServeConn(context.Background(), serverConn) }()
	sendLoginAndReadAck(t, client)
	hb, _ := rt.EncodeFrame(rt.Frame{MID: mids.MIDSocketHeartbeat, Params: &amf3.Object{}})
	if _, err := client.Write(hb); err != nil {
		t.Fatal(err)
	}
	time.Sleep(10 * time.Millisecond)
	_ = client.Close()
	select {
	case err := <-done:
		if err != nil {
			t.Fatal(err)
		}
	case <-time.After(time.Second):
		t.Fatal("server did not exit")
	}
	proj.mu.Lock()
	defer proj.mu.Unlock()
	if len(proj.admits) != 1 || len(proj.renews) != 1 || len(proj.retires) != 1 {
		t.Fatalf("admit=%d renew=%d retire=%d", len(proj.admits), len(proj.renews), len(proj.retires))
	}
	a, r, x := proj.admits[0], proj.renews[0], proj.retires[0]
	if a != r || a != x || a.ConnectionGeneration == 0 || a.Role != domainrt.World {
		t.Fatalf("refs admit=%+v renew=%+v retire=%+v", a, r, x)
	}
}

func TestRealtimePresenceProjectionFailureDoesNotRejectCanonicalAdmission(t *testing.T) {
	serverConn, client := net.Pipe()
	defer client.Close()
	proj := &presenceProjectionFake{admitErr: errors.New("db unavailable")}
	var mu sync.Mutex
	var stages []string
	s := presenceServer(t, proj, func(stage string, err error) {
		if err == nil {
			t.Fatal("nil projection error")
		}
		mu.Lock()
		stages = append(stages, stage)
		mu.Unlock()
	})
	done := make(chan error, 1)
	go func() { done <- s.ServeConn(context.Background(), serverConn) }()
	sendLoginAndReadAck(t, client) // canonical admission still succeeds and ACK is sent.
	_ = client.Close()
	<-done
	mu.Lock()
	defer mu.Unlock()
	if len(stages) == 0 || stages[0] != "admit" {
		t.Fatalf("stages=%v", stages)
	}
}

func TestMalformedHeartbeatNeverRenewsPresence(t *testing.T) {
	serverConn, client := net.Pipe()
	defer client.Close()
	proj := &presenceProjectionFake{}
	s := presenceServer(t, proj, nil)
	done := make(chan error, 1)
	go func() { done <- s.ServeConn(context.Background(), serverConn) }()
	sendLoginAndReadAck(t, client)
	hb, _ := rt.EncodeFrame(rt.Frame{MID: mids.MIDSocketHeartbeat, Params: &amf3.Object{Properties: []amf3.Property{{Name: "bad", Value: 1.0}}}})
	if _, err := client.Write(hb); err != nil {
		t.Fatal(err)
	}
	select {
	case err := <-done:
		if !errors.Is(err, ErrMalformedHeartbeat) {
			t.Fatalf("err=%v", err)
		}
	case <-time.After(time.Second):
		t.Fatal("server did not reject malformed heartbeat")
	}
	proj.mu.Lock()
	defer proj.mu.Unlock()
	if len(proj.renews) != 0 {
		t.Fatalf("malformed heartbeat renewed %d leases", len(proj.renews))
	}
}
