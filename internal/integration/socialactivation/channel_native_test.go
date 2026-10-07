//go:build postgres && socialintegration && channelintegration

package socialactivation_test

import (
	"bytes"
	"context"
	"encoding/binary"
	"encoding/json"
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/channelchatread"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/application/playerpresentation"
	ar "gxb.local/backend/v2/internal/application/realtimeauth"
	dr "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
	"math"
	"net"
	"os"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"
)

func TestChatA01ThreeRolesAuthReadWriteSelfEcho(t *testing.T) {
	for _, x := range []struct {
		role          dr.PhysicalRole
		channel, room int64
	}{{dr.World, 0, 1}, {dr.Guild, 2, 1000001}, {dr.Service, 4, 99999}} {
		t.Run(string(x.role), func(t *testing.T) {
			f := fresh(t)
			f.chatPlayers(100001, 100002)
			if x.role == dr.Guild {
				f.chatGuild(x.room, 100001, 100002)
			}
			h := chatHarness(t, f, channelHarnessOptions{})
			a, _, _ := h.login(100001, x.role, x.room)
			b, _, _ := h.login(100002, x.role, x.room)
			sendChat(t, a, "🙂 [face:1] hello", x.channel)
			for _, c := range []net.Conn{a, b} {
				m := readChat(t, c, "🙂 [face:1] hello")
				if m["player_id"] != float64(100001) {
					t.Fatal(m)
				}
			}
			r := h.report()
			if r.Outcomes[stockruntime.ChatTransportWriteRecorded] != 2 {
				t.Fatal(r)
			}
			noChat(t, a)
		})
	}
}
func TestChatA02RoleForgeryCrossProduct(t *testing.T) {
	for _, role := range []dr.PhysicalRole{dr.World, dr.Guild, dr.Service} {
		for _, channel := range []int64{0, 2, 4} {
			if (role == dr.World && channel == 0) || (role == dr.Guild && channel == 2) || (role == dr.Service && channel == 4) {
				continue
			}
			t.Run(fmt.Sprintf("%s-%d", role, channel), func(t *testing.T) {
				f := fresh(t)
				f.chatPlayers(100001)
				room := int64(1)
				if role == dr.Guild {
					room = 1000001
					f.chatGuild(room, 100001)
				}
				if role == dr.Service {
					room = 99999
				}
				h := chatHarness(t, f, channelHarnessOptions{})
				c, _, _ := h.login(100001, role, room)
				sendChat(t, c, "forged", channel)
				closedChat(t, c)
			})
		}
	}
}
func TestChatA03StrictAMFFieldsAndNumerics(t *testing.T) {
	f := fresh(t)
	f.chatPlayers(100001)
	h := chatHarness(t, f, channelHarnessOptions{})
	cases := [][]amf3.Property{{{Name: "player_id", Value: 200001.0}}, {{Name: "player_type", Value: 9.0}}, {{Name: "name", Value: "fake"}}, {{Name: "room_id", Value: 99999.0}}, {{Name: "np_info", Value: "{}"}}, {{Name: "type", Value: 0.5}}, {{Name: "type", Value: "0"}}, {{Name: "channel", Value: 0.0}}, {{Name: "message", Value: "duplicate"}}, {{Name: "region", Value: float64(1 << 53)}}, {{Name: "token", Value: 1.0}}}
	for i, x := range cases {
		t.Run(fmt.Sprint(i), func(t *testing.T) {
			c, _, _ := h.login(100001, dr.World, 1)
			sendChat(t, c, "x", 0, x...)
			closedChat(t, c)
		})
	}
	for _, obj := range []*amf3.Object{chatParams(amf3.Property{Name: "message", Value: "missingchannel"}), chatParams(amf3.Property{Name: "channel", Value: 0.0})} {
		c, _, _ := h.login(100001, dr.World, 1)
		writeChatFrame(t, c, rt.Frame{MID: mids.MIDSendChatMessage, Params: obj})
		closedChat(t, c)
	}
}
func TestChatA03bMalformedChannelsAndDiscriminators(t *testing.T) {
	f := fresh(t)
	f.chatPlayers(100001)
	h := chatHarness(t, f, channelHarnessOptions{})
	for _, channel := range []any{1.0, 3.0, 5.0, -1.0, 0.5, "0"} {
		c, _, _ := h.login(100001, dr.World, 1)
		writeChatFrame(t, c, rt.Frame{MID: mids.MIDSendChatMessage, Params: chatParams(amf3.Property{Name: "message", Value: "invalidchannel"}, amf3.Property{Name: "channel", Value: channel})})
		closedChat(t, c)
	}
	for _, kind := range []any{-1.0, 9.0, true} {
		c, _, _ := h.login(100001, dr.World, 1)
		sendChat(t, c, "invalidtype", 0, amf3.Property{Name: "type", Value: kind})
		closedChat(t, c)
	}
	for _, field := range []string{"channel", "type"} {
		for _, v := range []float64{math.NaN(), math.Inf(1), math.Inf(-1)} {
			c, _, _ := h.login(100001, dr.World, 1)
			props := []amf3.Property{{Name: "message", Value: "rawfloat"}, {Name: "channel", Value: 0.0}, {Name: "type", Value: 0.0}}
			for i := range props {
				if props[i].Name == field {
					props[i].Value = 123.456
				}
			}
			raw, e := rt.EncodeFrame(rt.Frame{MID: mids.MIDSendChatMessage, Params: chatParams(props...)})
			if e != nil {
				t.Fatal(e)
			}
			sentinel := make([]byte, 8)
			binary.BigEndian.PutUint64(sentinel, math.Float64bits(123.456))
			at := bytes.Index(raw, sentinel)
			if at < 0 {
				t.Fatal("double sentinel missing")
			}
			binary.BigEndian.PutUint64(raw[at:at+8], math.Float64bits(v))
			if _, e := c.Write(raw); e != nil {
				t.Fatal(e)
			}
			closedChat(t, c)
		}
	}
	c, _, _ := h.login(100001, dr.World, 1)
	writeChatFrame(t, c, rt.Frame{MID: mids.MIDSendChatMessage, Params: nil})
	closedChat(t, c)
}
func TestChatA04UnicodeBoundAndWhitespace(t *testing.T) {
	f := fresh(t)
	f.chatPlayers(100001)
	h := chatHarness(t, f, channelHarnessOptions{})
	c, _, _ := h.login(100001, dr.World, 1)
	for _, msg := range []string{" ", "  [face:1] 中文🙂  ", strings.Repeat("🙂", 140)} {
		sendChat(t, c, msg, 0)
		readChat(t, c, msg)
		h.report()
	}
	sendChat(t, c, strings.Repeat("🙂", 141), 0)
	closedChat(t, c)
	c, _, _ = h.login(100001, dr.World, 1)
	sendChat(t, c, "", 0)
	closedChat(t, c)
	// Corrupt valid encoded UTF8 bytes on actual wire; the native decoder rejects before dispatch.
	c, _, _ = h.login(100001, dr.World, 1)
	wire, e := rt.EncodeFrame(rt.Frame{MID: mids.MIDSendChatMessage, Params: chatParams(amf3.Property{Name: "message", Value: "UTF8_SENTINEL"}, amf3.Property{Name: "channel", Value: 0.0})})
	if e != nil {
		t.Fatal(e)
	}
	i := strings.Index(string(wire), "UTF8_SENTINEL")
	if i < 0 {
		t.Fatal("sentinel")
	}
	wire[i] = 0xff
	c.Write(wire)
	closedChat(t, c)
}
func TestChatA05RegionAndTokenCannotReplaceActor(t *testing.T) {
	f := fresh(t)
	f.chatPlayers(100001, 200001)
	h := chatHarness(t, f, channelHarnessOptions{})
	c, _, _ := h.login(100001, dr.World, 1)
	_, otherToken := f.live(200001)
	sendChat(t, c, "identity", 0, amf3.Property{Name: "token", Value: otherToken}, amf3.Property{Name: "region", Value: 1.0})
	m := readChat(t, c, "identity")
	if m["player_id"] != float64(100001) {
		t.Fatal(m)
	}
	h.report()
	sendChat(t, c, "badregion", 0, amf3.Property{Name: "region", Value: 2.0})
	closedChat(t, c)
}
func TestChatA06CanonicalPresentationAndInactiveCosmetics(t *testing.T) {
	f := fresh(t)
	f.chatPlayers(100001)
	f.sql(`UPDATE player_directory_profiles SET name='canonical',lev=42,avatar_id=17,avatar_frame_id=19,conquer_lev=21,conquer_loop_id=23 WHERE player_id=100001`)
	f.sql(`UPDATE player_profiles SET player_type=-77 WHERE player_id=100001`)
	h := chatHarness(t, f, channelHarnessOptions{})
	c, _, _ := h.login(100001, dr.World, 1)
	sendChat(t, c, "profile", 0)
	m := readChat(t, c, "profile")
	for k, v := range map[string]any{"player_name": "canonical", "lev": 42.0, "avatar_id": 17.0, "avatar_frame_id": 19.0, "player_type": -77.0} {
		if m[k] != v {
			t.Fatal(k, m[k])
		}
	}
	var np map[string]any
	if json.Unmarshal([]byte(m["np_info"].(string)), &np) != nil || np["title_info"] != "@@@@" || np["bubble_info"] != "10001@0" || np["conquer_lev"] != 21.0 || np["conquer_loop_id"] != 23.0 {
		t.Fatal(np)
	}
	h.report()
}
func TestChatA07MissingAndUnsafePresentationFailClosed(t *testing.T) {
	for _, q := range []string{`DELETE FROM player_directory_profiles WHERE player_id=100001`, `DELETE FROM player_profiles WHERE player_id=100001`, `UPDATE player_profiles SET player_type=9007199254740992 WHERE player_id=100001`} {
		f := fresh(t)
		f.chatPlayers(100001)
		h := chatHarness(t, f, channelHarnessOptions{})
		c, _, _ := h.login(100001, dr.World, 1)
		f.sql(q)
		sendChat(t, c, "missing", 0)
		closedChat(t, c)
		h.stop()
	}
}
func TestChatA08ExactOldHandleReplacementFence(t *testing.T) {
	f := fresh(t)
	f.chatPlayers(100001)
	h := chatHarness(t, f, channelHarnessOptions{})
	old, a, token := h.login(100001, dr.World, 1)
	snap := h.reg.ByPlayerRole(100001, dr.World)[0]
	newConn, _, _ := h.loginToken(100001, token, dr.World, 1)
	closedChat(t, old)
	_, err := h.dispatcher.HandleSessionClientFrame(context.Background(), snap, a, rt.Frame{MID: mids.MIDSendChatMessage, Params: chatParams(amf3.Property{Name: "message", Value: "old"}, amf3.Property{Name: "channel", Value: 0.0})})
	if !errors.Is(err, stockruntime.ErrInvalidRealtimeSession) {
		t.Fatal(err)
	}
	sendChat(t, newConn, "new", 0)
	readChat(t, newConn, "new")
	h.report()
}
func TestChatA09FreshRecipientExpiryBeforePeriodicTick(t *testing.T) {
	for _, expiry := range []bool{true, false} {
		f := fresh(t)
		f.chatPlayers(100001, 100002)
		h := chatHarness(t, f, channelHarnessOptions{})
		sender, _, _ := h.login(100001, dr.World, 1)
		recipient, a, _ := h.login(100002, dr.World, 1)
		if expiry {
			f.sql(`UPDATE account_sessions SET absolute_expires_at=issued_at+interval '30 milliseconds' WHERE session_id=$1::uuid`, a.Domain.Actor.SessionID.UUID().String())
			time.Sleep(40 * time.Millisecond)
		} else {
			f.sql(`UPDATE gameplay_contexts SET liveness_version=liveness_version+1 WHERE context_id=$1::uuid`, a.Domain.Actor.ContextID.UUID().String())
		}
		sendChat(t, sender, "liveonly", 0)
		readChat(t, sender, "liveonly")
		r := h.report()
		if r.Outcomes[stockruntime.ChatIneligible] != 1 {
			t.Fatal(r)
		}
		noChat(t, recipient)
		h.stop()
	}
}
func TestChatA10GuildLeaveRejoinIncarnationBothSides(t *testing.T) {
	f := fresh(t)
	f.chatPlayers(100001, 100002)
	f.chatGuild(1000001, 100001, 100002)
	h := chatHarness(t, f, channelHarnessOptions{})
	sender, _, _ := h.login(100001, dr.Guild, 1000001)
	oldRecipient, _, _ := h.login(100002, dr.Guild, 1000001)
	f.chatRejoin(100002, 1000001)
	sendChat(t, sender, "newjoin", 2)
	readChat(t, sender, "newjoin")
	r := h.report()
	if r.Outcomes[stockruntime.ChatIneligible] != 1 {
		t.Fatal(r)
	}
	noChat(t, oldRecipient)
	f.chatRejoin(100001, 1000001)
	sendChat(t, sender, "oldsender", 2)
	closedChat(t, sender)
	freshSender, _, _ := h.login(100001, dr.Guild, 1000001)
	freshRecipient, _, _ := h.login(100002, dr.Guild, 1000001)
	sendChat(t, freshSender, "freshboth", 2)
	readChat(t, freshSender, "freshboth")
	readChat(t, freshRecipient, "freshboth")
	h.report()
}
func TestChatA11WorldServiceDoNotReadGuildProvider(t *testing.T) {
	f := fresh(t)
	f.chatPlayers(100001)
	f.sql(`ALTER TABLE guild_memberships RENAME TO guild_memberships_unavailable`)
	defer f.sql(`ALTER TABLE guild_memberships_unavailable RENAME TO guild_memberships`)
	h := chatHarness(t, f, channelHarnessOptions{})
	for _, x := range []struct {
		role          dr.PhysicalRole
		room, channel int64
	}{{dr.World, 1, 0}, {dr.Service, 99999, 4}} {
		c, _, _ := h.login(100001, x.role, x.room)
		sendChat(t, c, "independent", x.channel)
		readChat(t, c, "independent")
		h.report()
	}
}
func TestChatA12RoomIsolationAndServiceScope(t *testing.T) {
	f := fresh(t)
	f.chatPlayers(100001, 100002, 100003, 200001)
	f.chatGuild(1000001, 100001, 100002)
	f.chatGuild(1000002, 100003)
	h := chatHarness(t, f, channelHarnessOptions{})
	w1, _, _ := h.login(100001, dr.World, 1)
	w2, _, _ := h.login(200001, dr.World, 2)
	sendChat(t, w1, "world1", 0)
	readChat(t, w1, "world1")
	h.report()
	noChat(t, w2)
	g1, _, _ := h.login(100001, dr.Guild, 1000001)
	g2, _, _ := h.login(100002, dr.Guild, 1000001)
	g3, _, _ := h.login(100003, dr.Guild, 1000002)
	sendChat(t, g1, "guild1", 2)
	readChat(t, g1, "guild1")
	readChat(t, g2, "guild1")
	h.report()
	noChat(t, g3)
	noChat(t, w1)
	s1, _, _ := h.login(100001, dr.Service, 99999)
	s2, _, _ := h.login(200001, dr.Service, 99999)
	sendChat(t, s1, "service", 4)
	readChat(t, s1, "service")
	readChat(t, s2, "service")
	h.report()
	noChat(t, g1)
	noChat(t, w1)
}
func TestChatA13MultiplePlayerContextsAreIndependent(t *testing.T) {
	f := fresh(t)
	f.chatPlayers(100001)
	h := chatHarness(t, f, channelHarnessOptions{})
	c1, _, _ := h.login(100001, dr.World, 1)
	c2, _, _ := h.login(100001, dr.World, 1)
	if len(h.reg.ByPlayerRole(100001, dr.World)) != 2 {
		t.Fatal("collapsed contexts")
	}
	sendChat(t, c1, "bothcontexts", 0)
	readChat(t, c1, "bothcontexts")
	readChat(t, c2, "bothcontexts")
	if h.report().Outcomes[stockruntime.ChatTransportWriteRecorded] != 2 {
		t.Fatal("contexts missing")
	}
}
func TestChatA14ReadOnlyRepeatableReadSingleCommitAndNoEffects(t *testing.T) {
	f := fresh(t)
	f.chatPlayers(100001, 100002)
	w := &readWitness{f: f}
	reader := channelReadFunc(func(c context.Context, t tx.Tx, a ar.Admission, b bool) (playerpresentation.Minimal, error) {
		var ro, iso string
		if e := t.QueryRow(c, `SELECT current_setting('transaction_read_only'),current_setting('transaction_isolation')`).Scan(&ro, &iso); e != nil || ro != "on" || iso != "repeatable read" {
			return playerpresentation.Minimal{}, fmt.Errorf("wrongtransaction %s %s %v", ro, iso, e)
		}
		return (channelchatread.Reader{}).ReadTx(c, t, a, b)
	})
	h := chatHarness(t, f, channelHarnessOptions{db: w, reader: reader})
	a, _, _ := h.login(100001, dr.World, 1)
	b, _, _ := h.login(100002, dr.World, 1)
	before := f.snapshot()
	sendChat(t, a, "readonly", 0)
	readChat(t, a, "readonly")
	readChat(t, b, "readonly")
	h.report()
	if w.begins.Load() != 3 || w.commits.Load() != 3 || w.active.Load() != 0 || f.snapshot() != before {
		t.Fatal("transaction/effect violation", w.begins.Load(), w.commits.Load(), w.active.Load())
	}
	if f.number(`SELECT count(*) FROM pg_locks WHERE mode LIKE '%ExclusiveLock' AND relation IN('players'::regclass,'guild_memberships'::regclass,'social_friendships'::regclass) AND granted`) != 0 {
		t.Fatal("gameplay lock stranded")
	}
}
func TestChatA15FreshDBTimeAndUnknownReadCompletion(t *testing.T) {
	f := fresh(t)
	f.chatPlayers(100001)
	var first time.Time
	reader := channelReadFunc(func(c context.Context, t tx.Tx, a ar.Admission, b bool) (playerpresentation.Minimal, error) {
		var at time.Time
		if e := t.QueryRow(c, `SELECT clock_timestamp()`).Scan(&at); e != nil {
			return playerpresentation.Minimal{}, e
		}
		if b {
			first = at
		} else if !at.After(first) {
			return playerpresentation.Minimal{}, errors.New("stale DB observation")
		}
		return (channelchatread.Reader{}).ReadTx(c, t, a, b)
	})
	h := chatHarness(t, f, channelHarnessOptions{reader: reader})
	c, _, _ := h.login(100001, dr.World, 1)
	sendChat(t, c, "freshclock", 0)
	readChat(t, c, "freshclock")
	h.report()
	h.stop()
	w := &readWitness{f: f, unknown: true}
	h = chatHarness(t, f, channelHarnessOptions{db: w})
	c, _, _ = h.login(100001, dr.World, 1)
	sendChat(t, c, "unknown", 0)
	closedChat(t, c)
	if w.commits.Load() != 1 || w.begins.Load() != 1 {
		t.Fatal("unknown read retried")
	}
}
func TestChatA16NoNetworkWithActiveTransactionOrRegistryMutex(t *testing.T) {
	f := fresh(t)
	f.chatPlayers(100001)
	w := &readWitness{f: f}
	var checks atomic.Int64
	var h *channelHarness
	decorate := func(c net.Conn) net.Conn {
		return &networkWitness{Conn: c, check: func() {
			if w.active.Load() != 0 {
				t.Error("network under active transaction")
			}
			checks.Add(1)
			if h != nil {
				h.reg.ByRoomRole(1, dr.World)
			}
		}}
	}
	h = chatHarness(t, f, channelHarnessOptions{db: w, decorate: decorate})
	c, _, _ := h.login(100001, dr.World, 1)
	sendChat(t, c, "unlocked", 0)
	readChat(t, c, "unlocked")
	h.report()
	if checks.Load() < 2 {
		t.Fatal("network not witnessed")
	}
}

type networkWitness struct {
	net.Conn
	check func()
}

func (c *networkWitness) Write(b []byte) (int, error) { c.check(); return c.Conn.Write(b) }
func TestChatA17SlowAndFailedPeerIsolation(t *testing.T) {
	for _, fail := range []bool{false, true} {
		t.Run(fmt.Sprint(fail), func(t *testing.T) {
			f := fresh(t)
			f.chatPlayers(100001, 100002)
			gate := make(chan struct{})
			entered := make(chan struct{}, 1)
			var ordinal atomic.Int64
			h := chatHarness(t, f, channelHarnessOptions{decorate: func(c net.Conn) net.Conn {
				if ordinal.Add(1) == 2 {
					return &blockChatConn{Conn: c, gate: gate, entered: entered, closed: make(chan struct{}), fail: fail}
				}
				return c
			}})
			sender, _, _ := h.login(100001, dr.World, 1)
			slow, _, _ := h.login(100002, dr.World, 1)
			sendChat(t, sender, "partial", 0)
			readChat(t, sender, "partial")
			r := h.report()
			if r.Outcomes[stockruntime.ChatTransportWriteRecorded] != 1 || r.Outcomes[stockruntime.ChatSendUnknown] != 1 {
				t.Fatal(r)
			}
			if !fail {
				close(gate)
				readChat(t, slow, "partial")
			}
			sendChat(t, sender, "next", 0)
			readChat(t, sender, "next")
			h.report()
		})
	}
}
func TestChatA18GlobalMessageWorkerOverflowAndShutdown(t *testing.T) {
	f := fresh(t)
	f.chatPlayers(100001)
	p, e := postgres.Open(context.Background(), os.Getenv("GXB_I7A4D_TEST_DSN"), postgres.PoolSettings{MaxConns: 40, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		t.Fatal(e)
	}
	defer p.Close()
	prepGate, recipientGate := make(chan struct{}), make(chan struct{})
	prepared := make(chan struct{}, 16)
	entered := make(chan struct{}, 8)
	var active, peak atomic.Int64
	reader := channelReadFunc(func(c context.Context, tr tx.Tx, a ar.Admission, b bool) (playerpresentation.Minimal, error) {
		if b {
			prepared <- struct{}{}
			select {
			case <-prepGate:
			case <-c.Done():
				return playerpresentation.Minimal{}, c.Err()
			}
		} else {
			n := active.Add(1)
			defer active.Add(-1)
			for old := peak.Load(); n > old; old = peak.Load() {
				if peak.CompareAndSwap(old, n) {
					break
				}
			}
			select {
			case entered <- struct{}{}:
			default:
			}
			select {
			case <-recipientGate:
			case <-c.Done():
				return playerpresentation.Minimal{}, c.Err()
			}
		}
		return (channelchatread.Reader{}).ReadTx(c, tr, a, b)
	})
	h := chatHarness(t, f, channelHarnessOptions{db: p, reader: reader})
	conns := make([]net.Conn, 17)
	for i := range conns {
		conns[i], _, _ = h.login(100001, dr.World, 1)
	}
	for i := 0; i < 16; i++ {
		sendChat(t, conns[i], fmt.Sprintf("capacity%d", i), 0)
	}
	for i := 0; i < 16; i++ {
		select {
		case <-prepared:
		case <-time.After(time.Second):
			t.Fatal("16 sender slots not occupied")
		}
	}
	sendChat(t, conns[16], "saturated", 0)
	r := h.report()
	if !r.Saturated {
		t.Fatal(r)
	}
	noChat(t, conns[16])
	var drain sync.WaitGroup
	drain.Add(17)
	for _, conn := range conns {
		go func(c net.Conn) {
			defer drain.Done()
			for i := 0; i < 16; i++ {
				frameRead(t, c, mids.MIDChatMessage)
			}
		}(conn)
	}
	close(prepGate)
	for i := 0; i < 8; i++ {
		select {
		case <-entered:
		case <-time.After(time.Second):
			t.Fatal("8 recipient slots not occupied")
		}
	}
	if peak.Load() != 8 {
		t.Fatal("global worker bound", peak.Load())
	}
	close(recipientGate)
	for i := 0; i < 16; i++ {
		r := h.report()
		if r.Outcomes[stockruntime.ChatTransportWriteRecorded] != 17 {
			t.Fatal(r)
		}
	}
	drain.Wait()
	// Bound snapshot before enqueuing: both actual admitted sockets exceed a smaller test limit.
	h.stop()
	pol := stockruntime.DefaultChannelChatPolicy(1)
	overflow := chatHarness(t, f, channelHarnessOptions{policy: &pol})
	a, _, _ := overflow.login(100001, dr.World, 1)
	b, _, _ := overflow.login(100001, dr.World, 1)
	sendChat(t, a, "overflow", 0)
	if !overflow.report().SnapshotOverflow {
		t.Fatal("no overflow rejection")
	}
	noChat(t, a)
	noChat(t, b)
	overflow.stop()
	blocked := make(chan struct{}, 1)
	cancelReader := channelReadFunc(func(c context.Context, tr tx.Tx, a ar.Admission, b bool) (playerpresentation.Minimal, error) {
		if !b {
			blocked <- struct{}{}
			<-c.Done()
			return playerpresentation.Minimal{}, c.Err()
		}
		return (channelchatread.Reader{}).ReadTx(c, tr, a, b)
	})
	shutdown := chatHarness(t, f, channelHarnessOptions{reader: cancelReader})
	c, _, _ := shutdown.login(100001, dr.World, 1)
	sendChat(t, c, "shutdown", 0)
	select {
	case <-blocked:
	case <-time.After(time.Second):
		t.Fatal("recipient did not start")
	}
	at := time.Now()
	shutdown.stop()
	if time.Since(at) > 3*time.Second {
		t.Fatal("shutdown unbounded")
	}
}
func TestChatA19PartialNoRetryACKOrConsumptionClaim(t *testing.T) {
	f := fresh(t)
	f.chatPlayers(100001, 100002)
	var ordinal atomic.Int64
	h := chatHarness(t, f, channelHarnessOptions{decorate: func(c net.Conn) net.Conn {
		if ordinal.Add(1) == 2 {
			return &blockChatConn{Conn: c, closed: make(chan struct{}), fail: true}
		}
		return c
	}})
	a, _, _ := h.login(100001, dr.World, 1)
	_, _, _ = h.login(100002, dr.World, 1)
	before := f.snapshot()
	sendChat(t, a, "partialonce", 0)
	readChat(t, a, "partialonce")
	r := h.report()
	if r.Outcomes[stockruntime.ChatTransportWriteRecorded] != 1 || r.Outcomes[stockruntime.ChatSendUnknown] != 1 || f.snapshot() != before {
		t.Fatal(r)
	}
	noChat(t, a)
}
func TestChatA20TimeoutAdmittedFrameMayWriteLaterNativeTCP(t *testing.T) {
	f := fresh(t)
	f.chatPlayers(100001)
	gate := make(chan struct{})
	entered := make(chan struct{}, 1)
	h := chatHarness(t, f, channelHarnessOptions{decorate: func(c net.Conn) net.Conn {
		return &blockChatConn{Conn: c, gate: gate, entered: entered, closed: make(chan struct{})}
	}})
	c, _, _ := h.login(100001, dr.World, 1)
	sendChat(t, c, "lateframe", 0)
	select {
	case <-entered:
	case <-time.After(time.Second):
		t.Fatal("no queue admission")
	}
	r := h.report()
	if r.Outcomes[stockruntime.ChatSendUnknown] != 1 || r.Outcomes[stockruntime.ChatTransportWriteRecorded] != 0 {
		t.Fatal(r)
	}
	close(gate)
	readChat(t, c, "lateframe")
	noChat(t, c)
	t.Log("Native TCP: complete frame after caller timeout; unknown outcome retained without retry")
}
func TestChatA21ConcurrentFramesRespectSingleWriter(t *testing.T) {
	f := fresh(t)
	f.chatPlayers(100001, 100002)
	var writing, peak atomic.Int64
	h := chatHarness(t, f, channelHarnessOptions{decorate: func(c net.Conn) net.Conn { return &writeSerialWitness{Conn: c, writing: &writing, peak: &peak} }})
	a, _, _ := h.login(100001, dr.World, 1)
	b, _, _ := h.login(100002, dr.World, 1)
	var writes sync.WaitGroup
	writes.Add(2)
	go func() { defer writes.Done(); sendChat(t, a, "A", 0) }()
	go func() { defer writes.Done(); sendChat(t, b, "B", 0) }()
	writes.Wait()
	for _, c := range []net.Conn{a, b} {
		seen := map[string]bool{}
		for i := 0; i < 2; i++ {
			f := frameRead(t, c, mids.MIDChatMessage)
			m, _ := f.Params.(*amf3.Object).StrictMap()
			seen[m["message"].(string)] = true
		}
		if !seen["A"] || !seen["B"] {
			t.Fatal(seen)
		}
	}
	h.report()
	h.report()
	noChat(t, a)
	noChat(t, b)
	if peak.Load() != 1 {
		t.Fatal("concurrent writer on sameconn", peak.Load())
	}
}

type writeSerialWitness struct {
	net.Conn
	writing, peak *atomic.Int64
	own           atomic.Int64
}

func (c *writeSerialWitness) Write(b []byte) (int, error) {
	n := c.own.Add(1)
	defer c.own.Add(-1)
	for old := c.peak.Load(); n > old; old = c.peak.Load() {
		if c.peak.CompareAndSwap(old, n) {
			break
		}
	}
	return c.Conn.Write(b)
}
func TestChatA22StructuredTypesGatedMalformedUnknownClose(t *testing.T) {
	f := fresh(t)
	f.chatPlayers(100001)
	h := chatHarness(t, f, channelHarnessOptions{})
	c, _, _ := h.login(100001, dr.Service, 99999)
	for n := 1; n <= 8; n++ {
		sendChat(t, c, structuredNativeFixtures()[n-1].message, 4, amf3.Property{Name: "type", Value: float64(n)})
		if !h.report().ProviderGated {
			t.Fatal(n)
		}
		noChat(t, c)
	}
	sendChat(t, c, "ordinaryaftergate", 4)
	readChat(t, c, "ordinaryaftergate")
	h.report()
	sendChat(t, c, "unknown", 4, amf3.Property{Name: "type", Value: 9.0})
	closedChat(t, c)
}
func TestChatA23RestartNoReplayOrChatSchema(t *testing.T) {
	f := fresh(t)
	f.chatPlayers(100001)
	h := chatHarness(t, f, channelHarnessOptions{})
	c, _, token := h.login(100001, dr.World, 1)
	sendChat(t, c, "ephemeral", 0)
	readChat(t, c, "ephemeral")
	h.report()
	h.stop()
	h = chatHarness(t, f, channelHarnessOptions{})
	c, _, _ = h.loginToken(100001, token, dr.World, 1)
	noChat(t, c)
	if f.number(`SELECT count(*) FROM information_schema.tables WHERE table_schema='public' AND (table_name LIKE '%channel_chat%' OR table_name LIKE '%chat_history%')`) != 0 {
		t.Fatal("durable chat introduced")
	}
	sendChat(t, c, "afterrestart", 0)
	readChat(t, c, "afterrestart")
	h.report()
}
func TestChatA24ActualProductionDispatcherAndHTTPRejection(t *testing.T) {
	f := fresh(t)
	f.chatPlayers(100001)
	_, token := f.live(100001)
	apiBin, rtBin := os.Getenv("GXB_I7A4D_API_BINARY"), os.Getenv("GXB_I7A4D_REALTIME_BINARY")
	if apiBin == "" || rtBin == "" {
		t.Fatal("exact frozen candidate production binaries required")
	}
	api, world := freeAddr(t), freeAddr(t)
	startProcess(t, apiBin, api, world)
	proc := startProcess(t, rtBin, api, world)
	c := worldLogin(t, world, token, 1)
	leaseBefore := f.text(`SELECT lease_expires_at::text FROM realtime_presence_leases WHERE player_id=100001 LIMIT 1`)
	sendChat(t, c, "production", 0)
	readChat(t, c, "production")
	if f.text(`SELECT lease_expires_at::text FROM realtime_presence_leases WHERE player_id=100001 LIMIT 1`) != leaseBefore {
		t.Fatal("chat renewed Presence")
	}
	writeChatFrame(t, c, rt.Frame{MID: mids.MIDSocketHeartbeat, Params: chatParams()})
	deadline := time.Now().Add(time.Second)
	for f.text(`SELECT lease_expires_at::text FROM realtime_presence_leases WHERE player_id=100001 LIMIT 1`) == leaseBefore {
		if time.Now().After(deadline) {
			t.Fatal("heartbeat did not renew Presence")
		}
		time.Sleep(5 * time.Millisecond)
	}
	noChat(t, c)
	code, _ := postProcess(t, api, token, 1, 32782, map[string]any{"message": "httpmustreject", "channel": 0})
	if code == 200 {
		t.Fatal("HTTP chat route activated")
	}
	noChat(t, c)
	// Abrupt process death then a new process on the same database never replays text.
	if e := proc.Process.Kill(); e != nil {
		t.Fatal(e)
	}
	proc.Wait()
	closedChat(t, c)
	startProcess(t, rtBin, api, world)
	c = worldLogin(t, world, token, 1)
	noChat(t, c)
	sendChat(t, c, "newprocess", 0)
	readChat(t, c, "newprocess")
}
func TestChatA25HeartbeatPresenceAndSocialProductionRegression(t *testing.T) {
	// The owning existing production test exercises real LISTEN, multiple world contexts,
	// Social reload, listener reconnect, owner fence and process restart on this exact candidate.
	TestD07ProductionProcessesWorldListenerFanoutAndRestart(t)
}
func TestChatA26NativeMigrationSchemaAndIdempotentComposition(t *testing.T) {
	f := fresh(t)
	f.chatPlayers(100001)
	if f.number(`SELECT max(version_id) FROM goose_db_version WHERE is_applied`) != 33 {
		t.Fatal("migration highwater changed")
	}
	h := chatHarness(t, f, channelHarnessOptions{})
	c, _, _ := h.login(100001, dr.World, 1)
	sendChat(t, c, "migration33", 0)
	readChat(t, c, "migration33")
	h.report()
	if f.number(`SELECT count(*) FROM information_schema.tables WHERE table_schema='public' AND table_name LIKE '%chat%'`) != 0 {
		t.Fatal("chat durable schema")
	}
}
func TestChatA28ExactNativeReadAndRaceComposition(t *testing.T) {
	f := fresh(t)
	f.chatPlayers(100001)
	h := chatHarness(t, f, channelHarnessOptions{})
	c, a, _ := h.login(100001, dr.World, 1)
	before := f.now()
	value, e := h.service.Prepare(context.Background(), a, "prepared")
	if e != nil || value.PlayerID != 100001 || !f.now().After(before) {
		t.Fatal(value, e)
	}
	sendChat(t, c, "nativecandidate", 0)
	readChat(t, c, "nativecandidate")
	h.report()
}
func TestChatA29CrashReconnectAndRetirementNativeLifecycle(t *testing.T) {
	f := fresh(t)
	f.chatPlayers(100001, 100002)
	gate := make(chan struct{})
	started := make(chan struct{}, 1)
	var ordinal atomic.Int64
	h := chatHarness(t, f, channelHarnessOptions{decorate: func(c net.Conn) net.Conn {
		if ordinal.Add(1) == 2 {
			return &blockChatConn{Conn: c, gate: gate, entered: started, closed: make(chan struct{})}
		}
		return c
	}})
	sender, _, _ := h.login(100001, dr.World, 1)
	old, a, token := h.login(100002, dr.World, 1)
	sendChat(t, sender, "retirequeued", 0)
	readChat(t, sender, "retirequeued")
	select {
	case <-started:
	case <-time.After(time.Second):
		t.Fatal("write not queued")
	}
	replacement, _, _ := h.loginToken(100002, token, dr.World, 1)
	closedChat(t, old)
	h.report()
	noChat(t, replacement)
	f.sql(`UPDATE gameplay_contexts SET liveness_version=liveness_version+1 WHERE context_id=$1::uuid`, a.Domain.Actor.ContextID.UUID().String())
	sendChat(t, replacement, "staleactor", 0)
	closedChat(t, replacement)
	sendChat(t, sender, "stilllive", 0)
	readChat(t, sender, "stilllive")
	h.report()
}

func TestChatA17bFullNativeWriterQueueIsolated(t *testing.T) {
	f := fresh(t)
	f.chatPlayers(100001, 100002)
	gate := make(chan struct{})
	entered := make(chan struct{}, 1)
	var ordinal atomic.Int64
	cfg := limits.Default()
	cfg.WriterFrames = 1
	h := chatHarness(t, f, channelHarnessOptions{limits: &cfg, decorate: func(c net.Conn) net.Conn {
		if ordinal.Add(1) == 4 {
			return &blockChatConn{Conn: c, gate: gate, entered: entered, closed: make(chan struct{})}
		}
		return c
	}})
	senders := make([]net.Conn, 3)
	for i := range senders {
		senders[i], _, _ = h.login(100001, dr.World, 1)
	}
	peer, _, _ := h.login(100002, dr.World, 1)
	var drains sync.WaitGroup
	for _, c := range senders {
		drains.Add(1)
		go func(c net.Conn) {
			defer drains.Done()
			for i := 0; i < 3; i++ {
				frameRead(t, c, mids.MIDChatMessage)
			}
		}(c)
	}
	for i, c := range senders {
		sendChat(t, c, fmt.Sprintf("queue%d", i), 0)
	}
	for i := 0; i < 3; i++ {
		r := h.report()
		if r.Outcomes[stockruntime.ChatSendUnknown] != 1 || r.Outcomes[stockruntime.ChatTransportWriteRecorded] != 3 {
			t.Fatal(r)
		}
	}
	drains.Wait()
	close(gate)
	seen := map[string]bool{}
	for i := 0; i < 2; i++ {
		f := frameRead(t, peer, mids.MIDChatMessage)
		m, _ := f.Params.(*amf3.Object).StrictMap()
		seen[m["message"].(string)] = true
	}
	if len(seen) != 2 {
		t.Fatal(seen)
	}
	noChat(t, peer)
	t.Log("Real TCP, nativePG, explicit WriterFrames1 fault-capacity variant: third enqueue rejected while two admitted frames complete later; healthy recipients isolated")
}
