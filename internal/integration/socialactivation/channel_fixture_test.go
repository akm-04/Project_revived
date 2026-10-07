//go:build postgres && socialintegration && channelintegration

package socialactivation_test

import (
	"context"
	"encoding/binary"
	"errors"
	"gxb.local/backend/v2/internal/adapters/channelchatread"
	"gxb.local/backend/v2/internal/adapters/postgres/guildprojection"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/application/channelchat"
	"gxb.local/backend/v2/internal/application/playerpresentation"
	ar "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	dr "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
	"io"
	"net"
	"sync"
	"sync/atomic"
	"testing"
	"time"
)

type channelHarness struct {
	f          *fixture
	reg        *stockruntime.ConnectionRegistry
	dispatcher *stockruntime.ChannelChatDispatcher
	reports    chan stockruntime.ChannelChatReport
	addr       string
	stop       func()
	service    channelchat.Service
	ends       chan error
}
type channelHarnessOptions struct {
	policy   *stockruntime.ChannelChatPolicy
	reader   channelchat.Reader
	db       tx.Beginner
	decorate func(net.Conn) net.Conn
}

func chatHarness(t *testing.T, f *fixture, o channelHarnessOptions) *channelHarness {
	t.Helper()
	reg := stockruntime.NewConnectionRegistry()
	events, e := rt.NewChannelChatEventRegistry()
	if e != nil {
		t.Fatal(e)
	}
	svc := channelchat.Service{Runner: tx.Runner{DB: f.p}, Operations: operation.Factory{Clock: clock.System{}}, Reader: channelchatread.Reader{}}
	if o.reader != nil {
		svc.Reader = o.reader
	}
	if o.db != nil {
		svc.Runner.DB = o.db
	}
	p := stockruntime.DefaultChannelChatPolicy(2048)
	if o.policy != nil {
		p = *o.policy
	}
	d, e := stockruntime.NewChannelChatDispatcher(reg, svc, stockruntime.RealtimePublisher{Registry: events, Limits: limits.Default()}, p)
	if e != nil {
		t.Fatal(e)
	}
	reports := make(chan stockruntime.ChannelChatReport, 256)
	d.OnReport = func(r stockruntime.ChannelChatReport) { reports <- r }
	auth := ar.Service{Authority: f.authority(), Guilds: guildprojection.RealtimeMembership{Queryer: f.p}}
	policy := stockruntime.DefaultRealtimePolicy()
	policy.LivenessInterval = time.Minute
	limiter, e := stockruntime.NewAdmissionLimiter(policy)
	if e != nil {
		t.Fatal(e)
	}
	server := stockruntime.RealtimeServer{Auth: auth, Registry: reg, Policy: policy, Admission: limiter, SessionDispatcher: d}
	l, e := net.Listen("tcp", "127.0.0.1:0")
	if e != nil {
		t.Fatal(e)
	}
	c, cancel := context.WithCancel(context.Background())
	var joins sync.WaitGroup
	done := make(chan struct{})
	ends := make(chan error, 256)
	go func() {
		defer close(done)
		for {
			conn, e := l.Accept()
			if e != nil {
				return
			}
			if o.decorate != nil {
				conn = o.decorate(conn)
			}
			joins.Add(1)
			go func(conn net.Conn) {
				defer joins.Done()
				defer conn.Close()
				stop := context.AfterFunc(c, func() { conn.Close() })
				defer stop()
				ends <- server.ServeConn(c, conn)
			}(conn)
		}
	}()
	var once sync.Once
	stop := func() { once.Do(func() { cancel(); l.Close(); reg.CloseAll(); <-done; joins.Wait() }) }
	t.Cleanup(stop)
	return &channelHarness{f: f, reg: reg, dispatcher: d, reports: reports, addr: l.Addr().String(), stop: stop, service: svc, ends: ends}
}
func (h *channelHarness) login(pid identity.PlayerID, role dr.PhysicalRole, room int64) (net.Conn, ar.Admission, string) {
	h.f.t.Helper()
	_, token := h.f.live(pid)
	return h.loginToken(pid, token, role, room)
}
func (h *channelHarness) loginToken(pid identity.PlayerID, token string, role dr.PhysicalRole, room int64) (net.Conn, ar.Admission, string) {
	t := h.f.t
	c, e := net.Dial("tcp", h.addr)
	if e != nil {
		t.Fatal(e)
	}
	t.Cleanup(func() { c.Close() })
	server := int64(pid) / 100000
	writeChatFrame(t, c, rt.Frame{MID: mids.MIDTCPLogin, Params: chatParams(amf3.Property{Name: "token", Value: token}, amf3.Property{Name: "region", Value: float64(server)}, amf3.Property{Name: "room_id", Value: float64(room)})})
	frameRead(t, c, mids.MIDChatRoomEntered)
	handles := h.reg.ByPlayerRole(pid, role)
	var a ar.Admission
	for _, v := range handles {
		vA, ok := v.Admission()
		if ok {
			a = vA
		}
	}
	if a.Domain.Actor.PlayerID != pid {
		t.Fatal("admitted handle missing")
	}
	return c, a, token
}
func chatParams(p ...amf3.Property) *amf3.Object { return &amf3.Object{Properties: p} }
func writeChatFrame(t *testing.T, c net.Conn, f rt.Frame) {
	t.Helper()
	b, e := rt.EncodeFrame(f)
	if e != nil {
		t.Fatal(e)
	}
	c.SetWriteDeadline(time.Now().Add(time.Second))
	if _, e = c.Write(b); e != nil {
		t.Fatal(e)
	}
}
func sendChat(t *testing.T, c net.Conn, message string, channel int64, extras ...amf3.Property) {
	p := []amf3.Property{{Name: "message", Value: message}, {Name: "channel", Value: float64(channel)}}
	p = append(p, extras...)
	writeChatFrame(t, c, rt.Frame{MID: mids.MIDSendChatMessage, Sequence: 91, Params: chatParams(p...)})
}
func noChat(t *testing.T, c net.Conn) {
	t.Helper()
	c.SetReadDeadline(time.Now().Add(80 * time.Millisecond))
	buf := make([]byte, 1)
	n, e := c.Read(buf)
	if n != 0 || e == nil {
		t.Fatalf("unexpected bytes n=%d e=%v", n, e)
	}
	if ne, ok := e.(net.Error); !ok || !ne.Timeout() {
		t.Fatalf("expected healthy quiet socket: %v", e)
	}
}
func closedChat(t *testing.T, c net.Conn) {
	t.Helper()
	c.SetReadDeadline(time.Now().Add(time.Second))
	buf := make([]byte, 1)
	n, e := c.Read(buf)
	if n != 0 || e == nil {
		t.Fatalf("expected closed socket n=%d e=%v", n, e)
	}
	if ne, ok := e.(net.Error); ok && ne.Timeout() {
		t.Fatal("invalid/auth command keptsocket")
	}
}
func (h *channelHarness) report() stockruntime.ChannelChatReport {
	h.f.t.Helper()
	select {
	case r := <-h.reports:
		return r
	case <-time.After(6 * time.Second):
		h.f.t.Fatal("publication report missing")
	}
	return stockruntime.ChannelChatReport{}
}
func (f *fixture) chatPlayers(pids ...identity.PlayerID) {
	for _, pid := range pids {
		f.player(pid)
	}
}
func (f *fixture) chatGuild(gid int64, pids ...identity.PlayerID) {
	f.sql(`INSERT INTO guilds(guild_id,logical_server_id,name,icon,apply_type,min_allow_level,vitality,policy_revision,created_at,updated_at)VALUES($1,$2,$3,1,0,1,0,'fixture',$4,$4)`, gid, int32(gid/1000000), "g"+string(rune('a'+gid%26)), f.now())
	for _, pid := range pids {
		f.sql(`INSERT INTO guild_memberships(player_id,guild_id,role,joined_at,updated_at)VALUES($1,$2,0,$3,$3)`, int64(pid), gid, f.now())
		f.sql(`INSERT INTO guild_membership_events(player_id,guild_id,event_kind,actor_player_id,occurred_at,policy_revision)VALUES($1,$2,'JOIN',$1,$3,'fixture')`, int64(pid), gid, f.now())
	}
}
func (f *fixture) chatRejoin(pid identity.PlayerID, gid int64) {
	f.sql(`DELETE FROM guild_memberships WHERE player_id=$1`, int64(pid))
	f.sql(`INSERT INTO guild_membership_events(player_id,guild_id,event_kind,actor_player_id,occurred_at,policy_revision)VALUES($1,$2,'LEAVE',$1,$3,'fixture')`, int64(pid), gid, f.now())
	f.sql(`INSERT INTO guild_memberships(player_id,guild_id,role,joined_at,updated_at)VALUES($1,$2,0,$3,$3)`, int64(pid), gid, f.now())
	f.sql(`INSERT INTO guild_membership_events(player_id,guild_id,event_kind,actor_player_id,occurred_at,policy_revision)VALUES($1,$2,'JOIN',$1,$3,'fixture')`, int64(pid), gid, f.now())
}

type channelReadFunc func(context.Context, tx.Tx, ar.Admission, bool) (playerpresentation.Minimal, error)

func (f channelReadFunc) ReadTx(c context.Context, t tx.Tx, a ar.Admission, b bool) (playerpresentation.Minimal, error) {
	return f(c, t, a, b)
}

// blockChatConn delays an actual TCP write under an explicit fault schedule.
// Login/other frames use the unmodified native TCP path. It never exists in production wiring.
type blockChatConn struct {
	net.Conn
	gate     <-chan struct{}
	entered  chan<- struct{}
	closed   chan struct{}
	once     sync.Once
	deadline time.Time
	mu       sync.Mutex
	fail     bool
}

func (c *blockChatConn) Write(b []byte) (int, error) {
	if len(b) >= rt.HeaderBytes && binary.BigEndian.Uint16(b[4:6]) == mids.MIDChatMessage {
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
func (c *blockChatConn) SetWriteDeadline(t time.Time) error {
	c.mu.Lock()
	c.deadline = t
	c.mu.Unlock()
	return c.Conn.SetWriteDeadline(t)
}
func (c *blockChatConn) Close() error { c.once.Do(func() { close(c.closed) }); return c.Conn.Close() }

type readWitness struct {
	f                       *fixture
	active, commits, begins atomic.Int64
	unknown                 bool
	observations            sync.Map
}

func (w *readWitness) Begin(c context.Context, o tx.Options) (tx.Tx, error) {
	if o != (tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}) {
		return nil, errors.New("wrong readoptions")
	}
	v, e := w.f.p.Begin(c, o)
	if e != nil {
		return nil, e
	}
	w.begins.Add(1)
	w.active.Add(1)
	return &witnessTx{Tx: v, w: w}, nil
}

type witnessTx struct {
	tx.Tx
	w    *readWitness
	done atomic.Bool
}

func (t *witnessTx) Commit(c context.Context) error {
	e := t.Tx.Commit(c)
	if t.done.CompareAndSwap(false, true) {
		t.w.active.Add(-1)
	}
	t.w.commits.Add(1)
	if e == nil && t.w.unknown {
		return errors.New("injected lost real read-commitreply")
	}
	return e
}
func (t *witnessTx) Rollback(c context.Context) error {
	e := t.Tx.Rollback(c)
	if t.done.CompareAndSwap(false, true) {
		t.w.active.Add(-1)
	}
	return e
}
func readChat(t *testing.T, c net.Conn, message string) map[string]any {
	t.Helper()
	frame := frameRead(t, c, mids.MIDChatMessage)
	if frame.Sequence != 0 || rt.ValidateOrdinaryChannelChat(frame.Params) != nil {
		t.Fatal("bad typed push", frame)
	}
	m, e := frame.Params.(*amf3.Object).StrictMap()
	if e != nil || m["message"] != message || m["type"] != float64(0) {
		t.Fatal(m, e)
	}
	return m
}
