package stockruntime

import (
	"context"
	"errors"
	"io"
	"net"
	"sync"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
	wireRT "gxb.local/backend/v2/internal/protocol/realtime"
)

func registryAdmission(t *testing.T, contextUUID string, player identity.PlayerID, role domainrt.PhysicalRole, room int64) domainrt.Admission {
	t.Helper()
	accountUUID, err := ids.ParseUUID("11111111-1111-4111-8111-111111111111")
	if err != nil {
		t.Fatal(err)
	}
	sessionUUID, err := ids.ParseUUID("22222222-2222-4222-8222-222222222222")
	if err != nil {
		t.Fatal(err)
	}
	ctxUUID, err := ids.ParseUUID(contextUUID)
	if err != nil {
		t.Fatal(err)
	}
	accountID, _ := identity.AccountIDFrom(accountUUID)
	sessionID, _ := identity.SessionIDFrom(sessionUUID)
	contextID, _ := identity.ContextIDFrom(ctxUUID)
	return domainrt.Admission{Role: role, RoomID: room, Actor: identity.ActorContext{
		AccountID: accountID, AccountUID: identity.AccountUID("20000007"), SessionID: sessionID,
		ContextID: contextID, LogicalServerID: 1, PlayerID: player, ContextGeneration: 3,
		SessionLivenessVersion: 4, ContextLivenessVersion: 5,
	}}
}

func newRegistryPipeWriter(t *testing.T) (*connWriter, net.Conn, net.Conn) {
	t.Helper()
	server, client := net.Pipe()
	w, err := newConnWriter(context.Background(), server, limits.Default(), time.Second)
	if err != nil {
		server.Close()
		client.Close()
		t.Fatal(err)
	}
	return w, server, client
}

func TestConnectionRegistryReplacementRetiresSnapshottedHandle(t *testing.T) {
	r := NewConnectionRegistry()
	admission := registryAdmission(t, "33333333-3333-4333-8333-333333333333", 100001, domainrt.World, 1)

	w1, _, client1 := newRegistryPipeWriter(t)
	defer client1.Close()
	h1, err := r.Replace(admission, w1)
	if err != nil {
		t.Fatal(err)
	}
	meta, ok := h1.Metadata()
	if !ok || meta.PlayerID != 100001 || meta.PhysicalRole != domainrt.World || meta.RoomID != 1 || meta.RegistryGeneration == 0 {
		t.Fatalf("bad metadata ok=%v meta=%+v", ok, meta)
	}

	w2, _, client2 := newRegistryPipeWriter(t)
	defer client2.Close()
	h2, err := r.Replace(admission, w2)
	if err != nil {
		t.Fatal(err)
	}
	if h2.RegistryGeneration() <= h1.RegistryGeneration() {
		t.Fatalf("replacement generation old=%d new=%d", h1.RegistryGeneration(), h2.RegistryGeneration())
	}
	if err := h1.Send(context.Background(), wireRT.Frame{MID: mids.MIDChatRoomEntered, Params: &amf3.Object{}}, limits.Default()); !errors.Is(err, ErrRealtimeSessionRetired) {
		t.Fatalf("stale handle send err=%v", err)
	}
	got := r.ByPlayerRole(100001, domainrt.World)
	if len(got) != 1 || got[0].RegistryGeneration() != h2.RegistryGeneration() {
		t.Fatalf("player index after replacement=%v", generations(got))
	}

	r.Remove(h1) // stale remover must not delete the replacement.
	got = r.ByRoomRole(1, domainrt.World)
	if len(got) != 1 || got[0].RegistryGeneration() != h2.RegistryGeneration() {
		t.Fatalf("stale remove deleted replacement: %v", generations(got))
	}
	r.Remove(h2)
	if got := r.ByPlayerRole(100001, domainrt.World); len(got) != 0 {
		t.Fatalf("removed handle still indexed: %v", generations(got))
	}
	if err := h2.Send(context.Background(), wireRT.Frame{MID: mids.MIDChatRoomEntered, Params: &amf3.Object{}}, limits.Default()); !errors.Is(err, ErrRealtimeSessionRetired) {
		t.Fatalf("removed handle send err=%v", err)
	}
}

func TestConnectionRegistryKeepsSamePlayerAcrossContexts(t *testing.T) {
	r := NewConnectionRegistry()
	admissions := []domainrt.Admission{
		registryAdmission(t, "33333333-3333-4333-8333-333333333331", 100001, domainrt.World, 1),
		registryAdmission(t, "33333333-3333-4333-8333-333333333332", 100001, domainrt.World, 1),
	}
	var handles []SessionHandle
	var clients []net.Conn
	for _, admission := range admissions {
		w, _, client := newRegistryPipeWriter(t)
		h, err := r.Replace(admission, w)
		if err != nil {
			t.Fatal(err)
		}
		handles = append(handles, h)
		clients = append(clients, client)
	}
	defer func() {
		for _, c := range clients {
			_ = c.Close()
		}
	}()
	got := r.ByPlayerRole(100001, domainrt.World)
	if len(got) != 2 {
		t.Fatalf("same player contexts collapsed: %v", generations(got))
	}
	room := r.ByRoomRole(1, domainrt.World)
	if len(room) != 2 {
		t.Fatalf("room index=%v", generations(room))
	}
	if got[0].RegistryGeneration() >= got[1].RegistryGeneration() {
		t.Fatalf("snapshot order is not stable: %v", generations(got))
	}
	r.Remove(handles[0])
	if got := r.ByPlayerRole(100001, domainrt.World); len(got) != 1 || got[0].RegistryGeneration() != handles[1].RegistryGeneration() {
		t.Fatalf("remaining player handles=%v", generations(got))
	}
	r.Remove(handles[1])
}

func TestConnectionRegistryReplacementInterruptsBlockedOldWriteWithoutHoldingRegistryMutex(t *testing.T) {
	r := NewConnectionRegistry()
	admission := registryAdmission(t, "33333333-3333-4333-8333-333333333333", 100001, domainrt.World, 1)
	blocking := newBlockingWriteConn()
	w1, err := newConnWriter(context.Background(), blocking, limits.Default(), time.Second)
	if err != nil {
		t.Fatal(err)
	}
	h1, err := r.Replace(admission, w1)
	if err != nil {
		t.Fatal(err)
	}

	sendDone := make(chan error, 1)
	go func() {
		sendDone <- h1.Send(context.Background(), wireRT.Frame{MID: mids.MIDChatRoomEntered, Params: &amf3.Object{}}, limits.Default())
	}()
	select {
	case <-blocking.writeStarted:
	case <-time.After(time.Second):
		t.Fatal("old writer did not enter blocked write")
	}

	w2, _, client2 := newRegistryPipeWriter(t)
	defer client2.Close()
	replaceDone := make(chan struct{})
	var h2 SessionHandle
	var replaceErr error
	go func() {
		h2, replaceErr = r.Replace(admission, w2)
		close(replaceDone)
	}()

	// The new generation must become observable without waiting for the blocked
	// old conn.Write, proving the registry mutex is not held during retirement.
	deadline := time.Now().Add(250 * time.Millisecond)
	visible := false
	for time.Now().Before(deadline) {
		got := r.ByPlayerRole(100001, domainrt.World)
		if len(got) == 1 && got[0].RegistryGeneration() > h1.RegistryGeneration() {
			visible = true
			break
		}
		time.Sleep(time.Millisecond)
	}
	if !visible {
		t.Fatal("new generation never became visible while old write was blocked")
	}

	// Retirement owns the private socket close, so replacement must interrupt
	// that old blocked write and complete without an external release signal.
	select {
	case <-replaceDone:
		if replaceErr != nil {
			t.Fatal(replaceErr)
		}
	case <-time.After(time.Second):
		t.Fatal("replacement did not interrupt blocked old write")
	}
	select {
	case err := <-sendDone:
		if err == nil {
			t.Fatal("retired blocked send unexpectedly succeeded")
		}
	case <-time.After(time.Second):
		t.Fatal("blocked old send did not terminate after retirement")
	}
	if err := h1.Send(context.Background(), wireRT.Frame{MID: mids.MIDChatRoomEntered, Params: &amf3.Object{}}, limits.Default()); !errors.Is(err, ErrRealtimeSessionRetired) {
		t.Fatalf("stale handle post-retirement send err=%v", err)
	}
	r.Remove(h2)
}

func generations(in []SessionHandle) []uint64 {
	out := make([]uint64, 0, len(in))
	for _, h := range in {
		out = append(out, h.RegistryGeneration())
	}
	return out
}

type blockingWriteConn struct {
	writeStarted chan struct{}
	releaseWrite chan struct{}
	closed       chan struct{}
	startOnce    sync.Once
	closeOnce    sync.Once
}

func newBlockingWriteConn() *blockingWriteConn {
	return &blockingWriteConn{writeStarted: make(chan struct{}), releaseWrite: make(chan struct{}), closed: make(chan struct{})}
}
func (c *blockingWriteConn) Read([]byte) (int, error) { return 0, io.EOF }
func (c *blockingWriteConn) Write(p []byte) (int, error) {
	c.startOnce.Do(func() { close(c.writeStarted) })
	select {
	case <-c.releaseWrite:
		return len(p), nil
	case <-c.closed:
		return 0, net.ErrClosed
	}
}
func (c *blockingWriteConn) Close() error                     { c.closeOnce.Do(func() { close(c.closed) }); return nil }
func (c *blockingWriteConn) LocalAddr() net.Addr              { return registryDummyAddr("local") }
func (c *blockingWriteConn) RemoteAddr() net.Addr             { return registryDummyAddr("remote") }
func (c *blockingWriteConn) SetDeadline(time.Time) error      { return nil }
func (c *blockingWriteConn) SetReadDeadline(time.Time) error  { return nil }
func (c *blockingWriteConn) SetWriteDeadline(time.Time) error { return nil }

type registryDummyAddr string

func (d registryDummyAddr) Network() string { return string(d) }
func (d registryDummyAddr) String() string  { return string(d) }
