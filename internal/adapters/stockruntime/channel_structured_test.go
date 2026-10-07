package stockruntime

import (
	"context"
	"errors"
	"fmt"
	cc "gxb.local/backend/v2/internal/application/channelchat"
	"gxb.local/backend/v2/internal/application/playerpresentation"
	ar "gxb.local/backend/v2/internal/application/realtimeauth"
	dr "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
	"net"
	"sync/atomic"
	"testing"
	"time"
)

type structuredFixtureDB struct {
	active  atomic.Int64
	unknown bool
}
type structuredFixtureTx struct {
	db   *structuredFixtureDB
	done bool
}

func (d *structuredFixtureDB) Begin(_ context.Context, o tx.Options) (tx.Tx, error) {
	if o != (tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}) {
		return nil, errors.New("wrong profile")
	}
	d.active.Add(1)
	return &structuredFixtureTx{db: d}, nil
}
func (t *structuredFixtureTx) QueryRow(context.Context, string, ...any) tx.Row { return nil }
func (t *structuredFixtureTx) Exec(_ context.Context, query string, _ ...any) (tx.CommandTag, error) {
	if query != "SELECT set_config($1, $2, true)" {
		return nil, errors.New("no fixture gameplay writes")
	}
	return nil, nil
}
func (t *structuredFixtureTx) Commit(context.Context) error {
	if !t.done {
		t.db.active.Add(-1)
		t.done = true
	}
	if t.db.unknown {
		return errors.New("lost commit")
	}
	return nil
}
func (t *structuredFixtureTx) Rollback(context.Context) error {
	if !t.done {
		t.db.active.Add(-1)
		t.done = true
	}
	return nil
}

type structuredFixtureReader struct{}

func (structuredFixtureReader) ReadTx(_ context.Context, _ tx.Tx, a ar.Admission, _ bool) (playerpresentation.Minimal, error) {
	return playerpresentation.Minimal{PlayerID: a.Domain.Actor.PlayerID, Name: "canonical", Level: 1, AvatarID: 1, AvatarFrameID: 1}, nil
}
func (f structuredFixtureReader) ObserveTx(c context.Context, t tx.Tx, a ar.Admission, b bool) (cc.Observation, error) {
	v, e := f.ReadTx(c, t, a, b)
	return cc.Observation{At: time.Unix(1, 0), Sender: v}, e
}

type structuredFixtureCamp struct{}

func (structuredFixtureCamp) ReadCampTx(_ context.Context, t tx.Tx, _ ar.Admission, at time.Time, s cc.CampSelection) (cc.Owned[cc.Camp], cc.CampAudience, error) {
	if at.IsZero() {
		return cc.Owned[cc.Camp]{}, cc.CampAudience{}, errors.New("no time")
	}
	return cc.Owned[cc.Camp]{Value: cc.Camp{Text: s.Text, CampID: 1}, Source: cc.SourceObservation{Identity: "fixture:event", ContentRevisionID: 1}}, cc.CampAudience{EventID: 11, CampID: 1}, nil
}
func (structuredFixtureCamp) AuthorizeCampRecipientTx(_ context.Context, _ tx.Tx, a ar.Admission, _ time.Time, audience cc.CampAudience) error {
	if audience.EventID != 11 || a.Domain.Actor.PlayerID != 100001 {
		return errors.New("wrong canonical audience")
	}
	return nil
}
func structuredFixtureRead(c net.Conn) (rt.Frame, error) {
	c.SetReadDeadline(time.Now().Add(time.Second))
	d, _ := rt.NewStreamDecoder(limits.Default())
	buf := make([]byte, 16384)
	for {
		n, e := c.Read(buf)
		if e != nil {
			return rt.Frame{}, e
		}
		frames, e := d.Feed(buf[:n])
		if e != nil {
			return rt.Frame{}, e
		}
		if len(frames) > 0 {
			return frames[0], nil
		}
	}
}
func TestStructuredFixturePublicationUsesCanonicalCampBeforeSend(t *testing.T) {
	for _, mode := range []string{"fixtureenabled", "productiondisabled", "unknownread", "forgedcamp", "retiredsender"} {
		t.Run(mode, func(t *testing.T) {
			reg := NewConnectionRegistry()
			defer reg.CloseAll()
			db := &structuredFixtureDB{unknown: mode == "unknownread"}
			svc := cc.Service{Runner: tx.Runner{DB: db}, Operations: operation.Factory{Clock: clock.System{}}, Reader: structuredFixtureReader{}, Owners: cc.Owners{Camp: structuredFixtureCamp{}}}
			events, _ := rt.NewChannelChatEventRegistry()
			d, e := NewChannelChatDispatcher(reg, svc, RealtimePublisher{Registry: events, Limits: limits.Default()}, DefaultChannelChatPolicy(16))
			if e != nil {
				t.Fatal(e)
			}
			// This private switch is reachable only in this same-package test, never product assembly.
			if mode != "productiondisabled" {
				d.structuredEnabled = true
			}
			a := ar.Admission{Domain: registryAdmission(t, "33333333-3333-4333-8333-333333333333", 100001, dr.Service, 99999)}
			w, _, self := newRegistryPipeWriter(t)
			defer self.Close()
			h, e := reg.ReplaceAdmission(a, w)
			if e != nil {
				t.Fatal(e)
			}
			b := ar.Admission{Domain: registryAdmission(t, "44444444-4444-4444-8444-444444444444", 100002, dr.Service, 99999)}
			w2, _, wrong := newRegistryPipeWriter(t)
			defer wrong.Close()
			if _, e = reg.ReplaceAdmission(b, w2); e != nil {
				t.Fatal(e)
			}
			if mode == "retiredsender" {
				w3, _, c3 := newRegistryPipeWriter(t)
				defer c3.Close()
				reg.ReplaceAdmission(a, w3)
			}
			camp := 1
			if mode == "forgedcamp" {
				camp = 2
			}
			msg := fmt.Sprintf(`{"type":7,"message":"x","msgType":0,"selectType":5,"roomID":0,"camp":%d}`, camp)
			result := make(chan rt.Frame, 1)
			readErr := make(chan error, 1)
			if mode == "fixtureenabled" {
				go func() { frame, e := structuredFixtureRead(self); result <- frame; readErr <- e }()
			}
			var report ChannelChatReport
			d.OnReport = func(r ChannelChatReport) { report = r }
			replies, e := d.HandleSessionClientFrame(context.Background(), h, a, rt.Frame{MID: mids.MIDSendChatMessage, Params: &amf3.Object{Properties: []amf3.Property{{Name: "message", Value: msg}, {Name: "channel", Value: 4.0}, {Name: "type", Value: 7.0}}}})
			if len(replies) != 0 || db.active.Load() != 0 {
				t.Fatal("ACK or activeTx")
			}
			if mode == "fixtureenabled" {
				frame := <-result
				if e != nil || <-readErr != nil || rt.ValidateChannelChat(frame.Params) != nil || report.Outcomes[ChatTransportWriteRecorded] != 1 || report.Outcomes[ChatIneligible] != 1 {
					t.Fatal(frame, e, report)
				}
			} else if mode == "productiondisabled" {
				if e != nil || !report.ProviderGated {
					t.Fatal(e, report)
				}
			} else if e == nil {
				t.Fatal("bad input/completion emitted")
			}
			wrong.SetReadDeadline(time.Now().Add(20 * time.Millisecond))
			buf := make([]byte, 1)
			if n, _ := wrong.Read(buf); n != 0 {
				t.Fatal("client filter substituted for authority")
			}
		})
	}
}
