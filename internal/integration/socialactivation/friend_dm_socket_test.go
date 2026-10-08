//go:build postgres && socialintegration && channelintegration

package socialactivation_test

import (
	"context"
	"encoding/binary"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/presencestore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	dm "gxb.local/backend/v2/internal/application/frienddm"
	sr "gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/identity"
	dr "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
	"io"
	"net"
	"os"
	"sync"
	"sync/atomic"
	"testing"
	"time"
)

func dmDelivery(t *testing.T, f *fixture, h *channelHarness, s dm.Service) stockruntime.FriendDMDelivery {
	fence, e := (presencestore.Store{Queryer: f.p}).ActivateRealtimeOwnerFence(ctx)
	if e != nil {
		t.Fatal(e)
	}
	events, e := stockruntime.NewFriendSocialEventRegistry()
	if e != nil {
		t.Fatal(e)
	}
	return stockruntime.FriendDMDelivery{Service: s, Fence: fence, Operations: operation.Factory{Clock: clock.System{}}, Registry: h.reg, Publisher: stockruntime.RealtimePublisher{Registry: events, Limits: limits.Default()}, Authority: f.authority(), Time: postgres.AuthoritativeTime{Queryer: f.p}, MaxHandles: 2048, IsStaleActor: func(e error) bool { return errors.Is(e, i4store.ErrGameplayBearerNotLive) }}
}
func Test6A_G26_G27RoleIsolationReplacementAndFreshLiveness(t *testing.T) {
	f, s := dmPair(t)
	f.chatGuild(2000001, 200001)
	h := chatHarness(t, f, channelHarnessOptions{})
	guild, _, _ := h.login(200001, dr.Guild, 2000001)
	service, _, _ := h.login(200001, dr.Service, 99999)
	d := dmDelivery(t, f, h, s)
	f.dmSend(s, 100001, 200001, "world-only")
	if e := d.DeliverRecipient(ctx, 200001); e != nil {
		t.Fatal(e)
	}
	noChat(t, guild)
	noChat(t, service)
	if f.number(`SELECT count(*) FROM friend_dm_delivery WHERE status='PENDING'`) != 1 {
		t.Fatal("other roles consumed pending")
	}
	old, _, token := h.login(200001, dr.World, 2)
	current, a, _ := h.loginToken(200001, token, dr.World, 2)
	closedChat(t, old)
	if e := d.DeliverRecipient(ctx, 200001); e != nil {
		t.Fatal(e)
	}
	frame := frameRead(t, current, mids.MIDChatFromFriend)
	if rt.ValidateFriendDM(frame.Params) != nil {
		t.Fatal(frame)
	}
	noChat(t, guild)
	noChat(t, service)
	f.dmSend(s, 100001, 200001, "expired target")
	f.sql(`UPDATE account_sessions SET revoked_at=$2,revocation_reason='friend-native',liveness_version=liveness_version+1 WHERE session_id=$1::uuid`, a.Domain.Actor.SessionID.UUID().String(), f.now())
	if e := d.DeliverRecipient(ctx, 200001); e != nil {
		t.Fatal(e)
	}
	closedChat(t, current)
	if f.number(`SELECT count(*) FROM friend_dm_delivery WHERE status='PENDING'`) != 1 {
		t.Fatal("retired target claimed success")
	}
}
func Test6A_G24LateAdmittedFrameAfterPrivacySuppression(t *testing.T) {
	f, s := dmPair(t)
	gate := make(chan struct{})
	entered := make(chan struct{}, 1)
	h := chatHarness(t, f, channelHarnessOptions{decorate: func(c net.Conn) net.Conn {
		return &blockDMConn{Conn: c, gate: gate, entered: entered, closed: make(chan struct{})}
	}})
	target, _, _ := h.login(200001, dr.World, 2)
	d := dmDelivery(t, f, h, s)
	o := f.dmSend(s, 100001, 200001, "late admitted bytes")
	c, cancel := context.WithCancel(ctx)
	defer cancel()
	done := make(chan error, 1)
	go func() { done <- d.DeliverRecipient(c, 200001) }()
	select {
	case <-entered:
	case <-time.After(time.Second):
		t.Fatal("writer not admitted")
	}
	cancel()
	<-done
	f.ok(200001, sr.AddBlock, 100001)
	base, e := f.dmBase(s).LoadBase(ctx, actor(200001), f.op())
	if e != nil || len(base.PrivateMessages) != 0 || f.text(`SELECT status FROM friend_dm_delivery WHERE occurrence_id=$1::uuid`, o.ID) != "PRIVACY_SUPPRESSED" {
		t.Fatal(base, e)
	}
	close(gate)
	frame := frameRead(t, target, mids.MIDChatFromFriend)
	if rt.ValidateFriendDM(frame.Params) != nil {
		t.Fatal(frame)
	}
	if f.text(`SELECT status FROM friend_dm_delivery WHERE occurrence_id=$1::uuid`, o.ID) != "PRIVACY_SUPPRESSED" {
		t.Fatal("late byte reopened canonical state")
	}
	t.Log("ACTUAL_TCP_WRITE fault schedule: enqueue precedes privacy change; timeout + canonical suppression cannot retract already admitted bytes; late frame observed")
}
func Test6A_G29QueueSaturationPreservesPending(t *testing.T) {
	f, s := dmPair(t)
	gate := make(chan struct{})
	entered := make(chan struct{}, 1)
	cfg := limits.Default()
	cfg.WriterFrames = 1
	h := chatHarness(t, f, channelHarnessOptions{limits: &cfg, decorate: func(c net.Conn) net.Conn {
		return &blockDMConn{Conn: c, gate: gate, entered: entered, closed: make(chan struct{})}
	}})
	target, _, _ := h.login(200001, dr.World, 2)
	d := dmDelivery(t, f, h, s)
	o := f.dmSend(s, 100001, 200001, "pending after saturated writer")
	handle := h.reg.ByPlayerRole(200001, dr.World)[0]
	payload := &amf3.Object{Properties: []amf3.Property{{Name: "friend_id", Value: int64(100001)}, {Name: "message", Value: o.Message}, {Name: "time", Value: o.AcceptedAt.Unix()}}}
	for i := 0; i < 2; i++ {
		bounded, cancel := context.WithTimeout(ctx, 30*time.Millisecond)
		e := handle.Send(bounded, rt.Frame{MID: mids.MIDChatFromFriend, Params: payload}, cfg)
		cancel()
		if e == nil {
			t.Fatal("fault writer unexpectedly completed")
		}
		if i == 0 {
			select {
			case <-entered:
			case <-time.After(time.Second):
				t.Fatal("writer not blocked")
			}
		}
	}
	if e := d.DeliverRecipient(ctx, 200001); e != nil {
		t.Fatal(e)
	}
	if f.text(`SELECT status FROM friend_dm_delivery WHERE occurrence_id=$1::uuid`, o.ID) != "PENDING" {
		t.Fatal("queue-full treated as actual write")
	}
	close(gate)
	frameRead(t, target, mids.MIDChatFromFriend)
	frameRead(t, target, mids.MIDChatFromFriend)
}

type visitDM struct {
	inner        stockruntime.FriendDMDelivery
	mu           sync.Mutex
	visits       map[identity.PlayerID]int
	active, peak atomic.Int64
}

func (v *visitDM) DeliverRecipient(c context.Context, id identity.PlayerID) error {
	n := v.active.Add(1)
	defer v.active.Add(-1)
	for {
		p := v.peak.Load()
		if n <= p || v.peak.CompareAndSwap(p, n) {
			break
		}
	}
	v.mu.Lock()
	v.visits[id]++
	v.mu.Unlock()
	return v.inner.DeliverRecipient(c, id)
}
func Test6A_G33FairKeysetAndBoundedWorkers(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	s := f.dm()
	for id := identity.PlayerID(100010); id <= 100080; id++ {
		f.player(id)
		f.friend(100001, id)
		f.dmSend(s, 100001, id, "sweep")
	}
	h := chatHarness(t, f, channelHarnessOptions{})
	target, _, _ := h.login(100080, dr.World, 1)
	d := dmDelivery(t, f, h, s)
	visits := &visitDM{inner: d, visits: map[identity.PlayerID]int{}}
	r := &dm.Reconciler{Store: s.Store, Queryer: f.p, Deliverer: visits}
	if e := r.InitialReconcile(ctx); e != nil {
		t.Fatal(e)
	}
	// This new root is below the already advanced cursor and must be seen on the
	// next sweep; incessant hot-recipient hints cannot monopolize periodic work.
	f.player(100002)
	f.friend(100001, 100002)
	low := f.dmSend(s, 100001, 100002, "below cursor")
	raw, _ := (dm.Reference{Recipient: 100002, OccurrenceID: low.ID, Version: 1}).Encode()
	c, cancel := context.WithCancel(ctx)
	done := make(chan error, 1)
	go func() { done <- r.Run(c) }()
	stopHints := make(chan struct{})
	hintDone := make(chan struct{})
	go func() {
		defer close(hintDone)
		tick := time.NewTicker(5 * time.Millisecond)
		defer tick.Stop()
		for {
			select {
			case <-stopHints:
				return
			case <-tick.C:
				r.ReloadAndDeliver(c, raw)
			}
		}
	}()
	frame := frameRead(t, target, mids.MIDChatFromFriend)
	if rt.ValidateFriendDM(frame.Params) != nil {
		t.Fatal(frame)
	}
	deadline := time.Now().Add(4 * time.Second)
	for {
		visits.mu.Lock()
		lowSeen := visits.visits[100002]
		initialAgain := visits.visits[100010]
		visits.mu.Unlock()
		if lowSeen > 0 && initialAgain > 1 {
			break
		}
		if time.Now().After(deadline) {
			t.Fatal("sweep cursor/hot hints starved pending root")
		}
		time.Sleep(20 * time.Millisecond)
	}
	close(stopHints)
	<-hintDone
	cancel()
	select {
	case <-done:
	case <-time.After(2 * time.Second):
		t.Fatal("reconcile workers not joined")
	}
	if visits.peak.Load() > 8 {
		t.Fatal("worker bound", visits.peak.Load())
	}
	t.Log("REAL_PG >64 pending recipients, offline/hot front roots, target beyond firstpage, new root belowcursor, coalesced hint lane and <=8 reconcile workers with join")
}

type blockDMConn struct {
	net.Conn
	gate     <-chan struct{}
	entered  chan<- struct{}
	closed   chan struct{}
	once     sync.Once
	deadline time.Time
	mu       sync.Mutex
	fail     bool
}

func (c *blockDMConn) Write(b []byte) (int, error) {
	if len(b) >= rt.HeaderBytes && binary.BigEndian.Uint16(b[4:6]) == mids.MIDChatFromFriend {
		if c.fail {
			return 0, io.ErrClosedPipe
		}
		select {
		case c.entered <- struct{}{}:
		default:
		}
		c.mu.Lock()
		deadline := c.deadline
		c.mu.Unlock()
		wait := time.Until(deadline)
		if wait <= 0 {
			wait = 5 * time.Second
		}
		timer := time.NewTimer(wait)
		defer timer.Stop()
		select {
		case <-c.gate:
		case <-c.closed:
			return 0, net.ErrClosed
		case <-timer.C:
			return 0, context.DeadlineExceeded
		}
	}
	return c.Conn.Write(b)
}
func (c *blockDMConn) SetWriteDeadline(t time.Time) error {
	c.mu.Lock()
	c.deadline = t
	c.mu.Unlock()
	return c.Conn.SetWriteDeadline(t)
}
func (c *blockDMConn) Close() error { c.once.Do(func() { close(c.closed) }); return c.Conn.Close() }

func Test6A_G32CanonicalScanFailureClosesAndJoins(t *testing.T) {
	f, _ := dmPair(t)
	_, token := f.live(200001)
	binary := os.Getenv("GXB_I7A4D_REALTIME_BINARY")
	if binary == "" {
		t.Fatal("exact realtime binary required")
	}
	api, world := freeAddr(t), freeAddr(t)
	process := startProcess(t, binary, api, world)
	socket := worldLogin(t, world, token, 2)
	// A reversible database-schema fault exercises fatal canonical supervision.
	f.sql(`ALTER TABLE friend_dm_delivery RENAME TO friend_dm_delivery_fault`)
	t.Cleanup(func() { f.sql(`ALTER TABLE friend_dm_delivery_fault RENAME TO friend_dm_delivery`) })
	done := make(chan error, 1)
	go func() { done <- process.Wait() }()
	select {
	case e := <-done:
		if e == nil {
			t.Fatal("canonical failure reported successful exit")
		}
	case <-time.After(4 * time.Second):
		t.Fatal("fatal canonical scan did not stop process")
	}
	closedChat(t, socket)
	t.Log("ACTUAL_PROCESS canonical scan failure: nonzero exit, socket closure, listener/reconcile shutdown joins executed")
}
