//go:build postgres && socialintegration && channelintegration

package socialactivation_test

import (
	"context"
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/channelchatread"
	cc "gxb.local/backend/v2/internal/application/channelchat"
	ar "gxb.local/backend/v2/internal/application/realtimeauth"
	dr "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"os"
	"strings"
	"testing"
	"time"
)

type nativeStructuredFixture struct {
	kind    float64
	message string
}

func structuredNativeFixtures() []nativeStructuredFixture {
	return []nativeStructuredFixture{
		{1, `{"player_id":100001,"player_name":"forged","enemy_name":"enemy","time":0,"is_attack":0,"id":1}`},
		{2, `{"player_id":100001,"player_name":"forged","share_gua":1,"rand_card_group":[],"card_group":[],"scratch_status":[]}`},
		{3, `{"room_id":1,"type":3,"boss_name":"boss","room_lev":1}`},
		{4, `{"room_id":1,"type":4,"chapter_id":1,"force":0}`},
		{5, `{"room_id":1,"type":5,"boss_name":"boss","room_lev":1}`},
		{6, `{"room_id":1,"type":6,"room_lev":1}`},
		{7, `{"type":7,"message":"x","msgType":0,"selectType":5,"roomID":0,"camp":0}`},
		{8, `{"room_id":1,"type":8,"boss_name":"boss","room_lev":1}`},
		{1, `{"player_id":100001,"player_name":"forged","enemy_name":"enemy","time":0,"isAttack":false,"isWin":false,"record_id":1,"attackInfo":{"player_id":100001,"player_name":"x","lev":1,"avatar_id":1,"avatar_frame_id":1,"conquer_lev":0,"conquer_loop_id":1},"defendInfo":{"player_id":100001,"player_name":"x","lev":1,"avatar_id":1,"avatar_frame_id":1,"conquer_lev":0,"conquer_loop_id":1}}`},
	}
}

type nativeArenaOwner struct {
	w      *readWitness
	seen   int
	write  bool
	source cc.SourceObservation
}

func (o *nativeArenaOwner) ReadArenaTx(c context.Context, t tx.Tx, a ar.Admission, at time.Time, s cc.RecordSelection) (cc.Owned[cc.Arena], error) {
	o.seen++
	if o.w.active.Load() != 1 || o.w.commits.Load() != 0 || at.IsZero() {
		return cc.Owned[cc.Arena]{}, errors.New("outside active read")
	}
	var now time.Time
	var ro, iso string
	if e := t.QueryRow(c, `SELECT clock_timestamp(),current_setting('transaction_read_only'),current_setting('transaction_isolation')`).Scan(&now, &ro, &iso); e != nil {
		return cc.Owned[cc.Arena]{}, e
	}
	if ro != "on" || iso != "repeatable read" || now.Before(at) || now.Sub(at) > time.Second {
		return cc.Owned[cc.Arena]{}, errors.New("wrong DB-time/options")
	}
	if o.write {
		_, e := t.Exec(c, `UPDATE players SET name=name WHERE player_id=100001`)
		return cc.Owned[cc.Arena]{}, e
	}
	return cc.Owned[cc.Arena]{Source: o.source, Value: cc.Arena{PlayerID: 1, PlayerName: "forged", EnemyName: "canonicalenemy", RecordID: s.RecordID}}, nil
}
func TestChatB17AllNineFiniteSchemasRemainInactiveWithoutReads(t *testing.T) {
	f := fresh(t)
	f.chatPlayers(100001)
	w := &readWitness{f: f}
	h := chatHarness(t, f, channelHarnessOptions{db: w})
	c, _, _ := h.login(100001, dr.Service, 99999)
	before := f.snapshot()
	for _, v := range structuredNativeFixtures() {
		sendChat(t, c, v.message, 4, amf3.Property{Name: "type", Value: v.kind})
		if !h.report().ProviderGated {
			t.Fatal(v)
		}
		noChat(t, c)
	}
	if w.begins.Load() != 0 || f.snapshot() != before {
		t.Fatal("inactive gate read/mutated")
	}
	sendChat(t, c, "afterallnine", 4)
	readChat(t, c, "afterallnine")
	h.report()
}
func TestChatB18InjectedOwnerCannotActivateProductionConstructor(t *testing.T) {
	f := fresh(t)
	f.chatPlayers(100001)
	w := &readWitness{f: f}
	o := &nativeArenaOwner{w: w}
	h := chatHarness(t, f, channelHarnessOptions{db: w, owners: cc.Owners{Arena: o}})
	c, _, _ := h.login(100001, dr.World, 1)
	sendChat(t, c, structuredNativeFixtures()[0].message, 0, amf3.Property{Name: "type", Value: 1.0})
	if !h.report().ProviderGated || o.seen != 0 || w.begins.Load() != 0 {
		t.Fatal("fake owner activated")
	}
	noChat(t, c)
}
func TestChatB05FiniteMalformedTCPClosesWithoutOwnerRead(t *testing.T) {
	bad := []string{`{}`, `{"type":1,"type":1}`, structuredNativeFixtures()[0].message + `{}`, strings.Replace(structuredNativeFixtures()[0].message, `"id":1`, `"id":9007199254740992`, 1), strings.Replace(structuredNativeFixtures()[0].message, `"enemy_name":"enemy"`, `"enemy_name":"\uD800"`, 1), structuredNativeFixtures()[0].message + strings.Repeat(" ", 8193)}
	for i, msg := range bad {
		t.Run(fmt.Sprint(i), func(t *testing.T) {
			f := fresh(t)
			f.chatPlayers(100001)
			w := &readWitness{f: f}
			h := chatHarness(t, f, channelHarnessOptions{db: w})
			c, _, _ := h.login(100001, dr.World, 1)
			sendChat(t, c, msg, 0, amf3.Property{Name: "type", Value: 1.0})
			closedChat(t, c)
			if w.begins.Load() != 0 {
				t.Fatal("malformed read")
			}
		})
	}
}
func TestChatB07Structured8192NativeQualification(t *testing.T) {
	f := fresh(t)
	f.chatPlayers(100001)
	h := chatHarness(t, f, channelHarnessOptions{})
	c, _, _ := h.login(100001, dr.Service, 99999)
	v := structuredNativeFixtures()[8]
	msg := v.message + strings.Repeat(" ", 8192-len(v.message))
	sendChat(t, c, msg, 4, amf3.Property{Name: "type", Value: v.kind})
	if !h.report().ProviderGated {
		t.Fatal("valid largefiniteJSON rejected")
	}
	noChat(t, c)
	sendChat(t, c, "ordinaryafter8192", 4)
	readChat(t, c, "ordinaryafter8192")
	h.report()
}
func TestChatB19RealReadOwnerSameTxDBTimeAndPrivateUnknown(t *testing.T) {
	for _, mode := range []string{"definite", "unknown", "write", "missingrevision"} {
		t.Run(mode, func(t *testing.T) {
			f := fresh(t)
			f.chatPlayers(100001)
			w := &readWitness{f: f, unknown: mode == "unknown"}
			o := &nativeArenaOwner{w: w, write: mode == "write", source: cc.SourceObservation{Identity: "fixture:1", ContentRevisionID: 1}}
			if mode == "missingrevision" {
				o.source.ContentRevisionID = 0
			}
			h := chatHarness(t, f, channelHarnessOptions{db: w, owners: cc.Owners{Arena: o}})
			_, a, _ := h.login(100001, dr.World, 1)
			before := f.snapshot()
			p, e := h.service.PrepareStructured(context.Background(), a, cc.Selector{Kind: cc.ArenaReference, Arena: &cc.RecordSelection{PlayerID: 100001, RecordID: 1}})
			if mode == "definite" {
				if e != nil || p.Message.Arena.PlayerName == "forged" || p.Message.Arena.PlayerID != 100001 {
					t.Fatal(p, e)
				}
			} else if e == nil || p.Message.Arena != nil {
				t.Fatal("private projection escaped", p, e)
			}
			if w.begins.Load() != 1 || o.seen != 1 || w.active.Load() != 0 || f.snapshot() != before {
				t.Fatal("retry/effect")
			}
		})
	}
}
func TestChatB30ActualProductionProcessStructuredGate(t *testing.T) {
	f := fresh(t)
	f.chatPlayers(100001)
	_, token := f.live(100001)
	api, world := freeAddr(t), freeAddr(t)
	startProcess(t, os.Getenv("GXB_I7A4D_REALTIME_BINARY"), api, world)
	c := worldLogin(t, world, token, 1)
	sendChat(t, c, structuredNativeFixtures()[0].message, 0, amf3.Property{Name: "type", Value: 1.0})
	noChat(t, c)
	sendChat(t, c, "actualafterstructured", 0)
	readChat(t, c, "actualafterstructured")
}

var _ = channelchatread.Reader{}
