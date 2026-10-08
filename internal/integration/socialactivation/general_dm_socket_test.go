//go:build postgres && socialintegration && channelintegration

package socialactivation_test

import (
	"context"
	"encoding/binary"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/presencestore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	dm "gxb.local/backend/v2/internal/application/generaldm"
	dr "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
	"net"
	"os"
	"sync"
	"sync/atomic"
	"testing"
	"time"
)

func generalSocketDelivery(t *testing.T, f *fixture, h *channelHarness) stockruntime.GeneralDMDelivery {
	fence, e := (presencestore.Store{Queryer: f.p}).ActivateRealtimeOwnerFence(ctx)
	if e != nil {
		t.Fatal(e)
	}
	u, _ := ids.NewUUID()
	for _, handle := range h.reg.ByPlayerRole(200001, dr.World) {
		m, ok := handle.Metadata()
		if !ok {
			t.Fatal("metadata")
		}
		f.sql(`INSERT INTO player_social_presence(player_id,state_version,created_at,updated_at)VALUES(200001,1,$1,$1) ON CONFLICT DO NOTHING`, f.now())
		f.sql(`INSERT INTO realtime_presence_leases(gameplay_context_id,player_id,physical_role,realtime_instance_id,connection_generation,realtime_owner_fence,connected_at,lease_expires_at,last_renewed_at)VALUES($1::uuid,200001,'WORLD',$2::uuid,$3,$4,$5,$6,$5)`, m.ContextID.UUID().String(), u.String(), int64(m.RegistryGeneration), fence, f.now(), f.now().Add(time.Minute))
	}
	events, e := stockruntime.NewGeneralSocialEventRegistry()
	if e != nil {
		t.Fatal(e)
	}
	return stockruntime.GeneralDMDelivery{Service: f.general(), Fence: fence, InstanceID: u, Operations: operation.Factory{Clock: clock.System{}}, Registry: h.reg, Publisher: stockruntime.RealtimePublisher{Registry: events, Limits: limits.Default()}, Authority: f.authority(), Time: postgres.AuthoritativeTime{Queryer: f.p}}
}

type generalBlockConn struct {
	net.Conn
	gate    <-chan struct{}
	entered chan<- struct{}
	closed  chan struct{}
	once    sync.Once
}

func (c *generalBlockConn) Write(b []byte) (int, error) {
	if len(b) >= rt.HeaderBytes && binary.BigEndian.Uint16(b[4:6]) == mids.MIDChatFromPlayer {
		select {
		case c.entered <- struct{}{}:
		default:
		}
		select {
		case <-c.gate:
		case <-c.closed:
			return 0, net.ErrClosed
		}
	}
	return c.Conn.Write(b)
}
func (c *generalBlockConn) Close() error {
	c.once.Do(func() { close(c.closed) })
	return c.Conn.Close()
}
func Test6B_G32LateAdmittedFrameCannotBecomePositive(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.player(200001)
	gate := make(chan struct{})
	entered := make(chan struct{}, 1)
	var release sync.Once
	t.Cleanup(func() { release.Do(func() { close(gate) }) })
	h := chatHarness(t, f, channelHarnessOptions{decorate: func(c net.Conn) net.Conn {
		return &generalBlockConn{Conn: c, gate: gate, entered: entered, closed: make(chan struct{})}
	}})
	target, _, _ := h.login(200001, dr.World, 2)
	d := generalSocketDelivery(t, f, h)
	i := generalAccept(t, f, d.Service)
	c, cancel := context.WithCancel(ctx)
	done := make(chan error, 1)
	go func() { done <- d.DeliverIntent(c, i.ID) }()
	select {
	case <-entered:
	case <-time.After(time.Second):
		t.Fatal("writer not queued")
	}
	cancel()
	select {
	case <-done:
	case <-time.After(3 * time.Second):
		t.Fatal("workers not joined")
	}
	if done, e := d.Service.Recover(ctx, i.ID, f.op()); e != nil || !done {
		t.Fatal(e)
	}
	if _, e := d.Service.Wait(ctx, i); e == nil {
		t.Fatal("queue/timeout created HTTP success")
	}
	release.Do(func() { close(gate) })
	frame := frameRead(t, target, mids.MIDChatFromPlayer)
	if rt.ValidateGeneralDM(frame.Params) != nil {
		t.Fatal(frame)
	}
	if f.text(`SELECT status FROM personal_dm_delivery WHERE operation_id=$1::uuid`, i.ID) != "UNKNOWN" || f.number(`SELECT count(*) FROM personal_dm_payloads`) != 0 {
		t.Fatal("late frame changed receipt")
	}
	t.Log("ACTUAL_TCP_WRITE fault: admitted frame after cancelled Send/non200 remains possible; durable ATTEMPTING recovery UNKNOWN/purge, no repeated fanout or positive receipt")
}

type generalJumpTime struct {
	f     *fixture
	shift time.Duration
	n     int
}

func (v *generalJumpTime) Now(c context.Context) (time.Time, error) {
	v.n++
	now := (postgres.AuthoritativeTime{Queryer: v.f.p})
	at, e := now.Now(c)
	if v.n > 1 {
		at = at.Add(v.shift)
	}
	return at, e
}
func Test6B_G33NativeWriterBridgeClockFaults(t *testing.T) {
	for _, shift := range []time.Duration{-time.Hour, time.Hour, 10 * time.Second} {
		t.Run(shift.String(), func(t *testing.T) {
			f := fresh(t)
			f.player(100001)
			f.player(200001)
			h := chatHarness(t, f, channelHarnessOptions{})
			target, _, _ := h.login(200001, dr.World, 2)
			d := generalSocketDelivery(t, f, h)
			i := generalAccept(t, f, d.Service)
			d.Time = &generalJumpTime{f: f, shift: shift}
			if e := d.DeliverIntent(ctx, i.ID); e != nil {
				t.Fatal(e)
			}
			frameRead(t, target, mids.MIDChatFromPlayer)
			j, ok, e := d.Service.Store.Find(ctx, f.p, i.ID)
			if e != nil || !ok || j.Status != dm.TimeInvalid {
				t.Fatal("clock fault accepted", j, e)
			}
			if _, e = d.Service.Wait(ctx, i); e == nil {
				t.Fatal("clock fault success")
			}
		})
	}
}
func Test6B_G46CanonicalGeneralFailureClosesProductionOwner(t *testing.T) {
	f := fresh(t)
	f.player(200001)
	_, token := f.live(200001)
	binary := os.Getenv("GXB_I7A4D_REALTIME_BINARY")
	if binary == "" {
		t.Fatal("exact binary required")
	}
	api, world := freeAddr(t), freeAddr(t)
	p := startProcess(t, binary, api, world)
	socket := worldLogin(t, world, token, 2)
	f.sql(`ALTER TABLE personal_dm_delivery RENAME TO personal_dm_delivery_fault`)
	defer f.sql(`ALTER TABLE personal_dm_delivery_fault RENAME TO personal_dm_delivery`)
	done := make(chan error, 1)
	go func() { done <- p.Wait() }()
	select {
	case e := <-done:
		if e == nil {
			t.Fatal("fatal scan succeeded")
		}
	case <-time.After(4 * time.Second):
		t.Fatal("owner did not shut down")
	}
	closedChat(t, socket)
	t.Log("ACTUAL_PROCESS General scan failure closes socket and joins General, Friend, Presence, listener and registry workers")
}

type generalConcurrentTime struct {
	f            *fixture
	active, peak atomic.Int64
}

func (v *generalConcurrentTime) Now(c context.Context) (time.Time, error) {
	n := v.active.Add(1)
	defer v.active.Add(-1)
	for {
		old := v.peak.Load()
		if old >= n || v.peak.CompareAndSwap(old, n) {
			break
		}
	}
	select {
	case <-c.Done():
		return time.Time{}, c.Err()
	case <-time.After(10 * time.Millisecond):
	}
	return (postgres.AuthoritativeTime{Queryer: v.f.p}).Now(c)
}
func Test6B_G27_G29_G30SixtyFourOriginalWorldHandlesEightWriters(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.player(200001)
	h := chatHarness(t, f, channelHarnessOptions{})
	targets := []net.Conn{}
	for n := 0; n < 64; n++ {
		c, _, _ := h.login(200001, dr.World, 2)
		targets = append(targets, c)
	}
	d := generalSocketDelivery(t, f, h)
	i := generalAccept(t, f, d.Service)
	if len(i.Bindings) != 64 {
		t.Fatal("capture count", len(i.Bindings))
	}
	observation := &generalConcurrentTime{f: f}
	d.Time = observation
	if e := d.DeliverIntent(ctx, i.ID); e != nil {
		t.Fatal(e)
	}
	for _, c := range targets {
		if frame := frameRead(t, c, mids.MIDChatFromPlayer); rt.ValidateGeneralDM(frame.Params) != nil {
			t.Fatal(frame)
		}
	}
	if observation.peak.Load() > 8 || observation.peak.Load() < 2 || observation.active.Load() != 0 {
		t.Fatal("unbounded/unjoined fanout", observation.peak.Load(), observation.active.Load())
	}
	if j, e := d.Service.Wait(ctx, i); e != nil || j.Status != dm.WrittenBeforeDeadline {
		t.Fatal(j, e)
	}
	// A 65th candidate is an explicit bounded capture rejection, never truncation.
	extra, _, _ := h.login(200001, dr.World, 2)
	defer extra.Close()
	handle := h.reg.ByPlayerRole(200001, dr.World)
	for _, v := range handle {
		m, _ := v.Metadata()
		if f.number(`SELECT count(*) FROM realtime_presence_leases WHERE gameplay_context_id=$1::uuid`, m.ContextID.UUID().String()) == 0 {
			f.sql(`INSERT INTO realtime_presence_leases(gameplay_context_id,player_id,physical_role,realtime_instance_id,connection_generation,realtime_owner_fence,connected_at,lease_expires_at,last_renewed_at)VALUES($1::uuid,200001,'WORLD',$2::uuid,$3,$4,$5,$6,$5)`, m.ContextID.UUID().String(), d.InstanceID.String(), int64(m.RegistryGeneration), d.Fence, f.now(), f.now().Add(time.Minute))
		}
	}
	if _, e := d.Service.Accept(ctx, 100001, 200001, "too many bindings", f.op()); e == nil {
		t.Fatal("65 silently truncated")
	}
	t.Logf("ACTUAL_TCP 64 original WORLD connections all observed514; concurrent writer time-port peak%d <=8 and joined; 65 capture denied", observation.peak.Load())
}
