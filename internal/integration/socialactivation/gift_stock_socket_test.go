//go:build postgres && socialintegration && channelintegration

package socialactivation_test

import (
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	dr "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
	"testing"
)

func Test7B_GiftReloadActualWriterWorldOnly(t *testing.T) {
	f, s, a, b := giftFixture(t)
	r, e := s.Send(ctx, a, b.PlayerID, f.op())
	if e != nil {
		t.Fatal(e)
	}
	refs, e := s.ReloadReferences(ctx, a, b.PlayerID, r, f.op())
	if e != nil {
		t.Fatal(e)
	}
	_, _, _, reload := f.giftStock(s, f.scalar())
	h := chatHarness(t, f, channelHarnessOptions{})
	sender, _, _ := h.login(a.PlayerID, dr.World, 1)
	recipient, _, token := h.login(b.PlayerID, dr.World, 2)
	current, _, _ := h.loginToken(b.PlayerID, token, dr.World, 2)
	closedChat(t, recipient)
	service, _, _ := h.login(b.PlayerID, dr.Service, 99999)
	events, e := stockruntime.NewSocialEventRegistry()
	if e != nil {
		t.Fatal(e)
	}
	handler := stockruntime.SocialReloadHandler{Service: reload, Operations: operation.Factory{Clock: clock.System{}}, Registry: h.reg, Publisher: stockruntime.RealtimePublisher{Registry: events, Limits: limits.Default()}, Authority: f.authority(), Time: postgres.AuthoritativeTime{Queryer: f.p}, MaxHandles: 64}
	for _, r := range refs {
		raw, e := r.Encode()
		if e != nil {
			t.Fatal(e)
		}
		if e = handler.ReloadAndDeliver(ctx, raw); e != nil {
			t.Fatal(e)
		}
	}
	frame := frameRead(t, sender, mids.MIDForceReload)
	if stockruntime.ValidateSocialReload(frame.Params) != nil {
		t.Fatal(frame)
	}
	m, _ := frame.Params.(*amf3.Object).StrictMap()
	if m["friend_list"] == nil || m["friend_notice"] != nil {
		t.Fatal(m)
	}
	frame = frameRead(t, current, mids.MIDForceReload)
	m, _ = frame.Params.(*amf3.Object).StrictMap()
	if m["friend_notice"] == nil || m["friend_list"] != nil {
		t.Fatal(m)
	}
	noChat(t, service)
	noChat(t, sender)
	noChat(t, current)
	before := f.giftState()
	if e = handler.ReloadAndDeliver(ctx, "g1|200001|100001|1|5|00000000-0000-0000-0000-000000000000"); e == nil {
		t.Fatal("forged source accepted")
	}
	if f.giftState() != before {
		t.Fatal("hint changed gameplay")
	}
}
