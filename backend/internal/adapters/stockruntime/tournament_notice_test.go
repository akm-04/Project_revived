package stockruntime

import (
	"context"
	"encoding/json"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
	"testing"
	"time"
)

func TestTournamentNoticeUsesRegisteredWorldSchema(t *testing.T) {
	identifier, _ := ids.NewUUID()
	view := d.TournamentRoomView{Room: d.TournamentRoom{Identifier: identifier, Selection: d.SelectionRoom{Players: [2]identity.PlayerID{100001, 100002}, Team: 1}, Status: d.RoomSelecting}, Heroes: [2]map[string]map[string]any{{}, {}}, Pets: [2]map[string]map[string]any{{}, {}}}
	frame, err := tournamentNoticeFrame(view)
	if err != nil {
		t.Fatal(err)
	}
	registry, err := NewTournamentNoticeRegistry()
	if err != nil {
		t.Fatal(err)
	}
	if err := registry.ValidateNotice(mids.MIDPlayerNotice, rt.NoticeNamespaceGeneric, rt.World, frame); err != nil {
		t.Fatal(err)
	}
	if err := registry.ValidateNotice(mids.MIDPlayerNotice, rt.NoticeNamespaceGeneric, rt.Guild, frame); err == nil {
		t.Fatal("non-World accepted")
	}
}

func TestTournamentFractionalStageAliasAndRefusals(t *testing.T) {
	for _, input := range []any{json.Number("0.5"), float64(0.5), json.Number("1")} {
		turn, err := tournamentTurn(input)
		if err != nil || turn != 1 {
			t.Fatal(input, turn, err)
		}
	}
	for _, input := range []any{json.Number("0.7"), json.Number("9"), "0.5", nil} {
		if _, err := tournamentTurn(input); err == nil {
			t.Fatal("invalid turn accepted", input)
		}
	}
}

type tournamentNoticeFixture struct{ view d.TournamentRoomView }

func (fixture tournamentNoticeFixture) ReadNotice(context.Context, string) (d.TournamentRoomView, bool, error) {
	return fixture.view, true, nil
}

func TestTournamentNoticeDeliveryChecksAcknowledgementAndLiveActor(t *testing.T) {
	identifier, _ := ids.NewUUID()
	view := d.TournamentRoomView{Room: d.TournamentRoom{Identifier: identifier, Selection: d.SelectionRoom{Players: [2]identity.PlayerID{100001, 100002}, Team: 1}, NoticeVersion: 3, Status: d.RoomSelecting}, Heroes: [2]map[string]map[string]any{{}, {}}, Pets: [2]map[string]map[string]any{{}, {}}}
	registry := NewConnectionRegistry()
	defer registry.CloseAll()
	writer, _, client := newRegistryPipeWriter(t)
	defer client.Close()
	if _, err := registry.Replace(registryAdmission(t, "33333333-3333-4333-8333-333333333333", 100001, domainrt.World, 1), writer); err != nil {
		t.Fatal(err)
	}
	events, err := NewTournamentNoticeRegistry()
	if err != nil {
		t.Fatal(err)
	}
	handler := TournamentNoticeHandler{Service: tournamentNoticeFixture{view}, Registry: registry, Publisher: RealtimePublisher{Registry: events, Limits: limits.Default()}, Authority: deliveryAuthority{}, Time: deliveryClock{}, MaxHandles: 10}
	frames := make(chan rt.Frame, 1)
	readError := make(chan error, 1)
	go func() {
		decoder, _ := rt.NewStreamDecoder(limits.Default())
		client.SetReadDeadline(time.Now().Add(2 * time.Second))
		buffer := make([]byte, 4096)
		for {
			count, err := client.Read(buffer)
			if err != nil {
				readError <- err
				return
			}
			values, err := decoder.Feed(buffer[:count])
			if err != nil {
				readError <- err
				return
			}
			if len(values) > 0 {
				frames <- values[0]
				return
			}
		}
	}()
	if err := handler.ReloadAndDeliver(context.Background(), identifier.String()); err != nil {
		t.Fatal(err)
	}
	select {
	case frame := <-frames:
		if frame.MID != mids.MIDPlayerNotice {
			t.Fatal(frame.MID)
		}
	case err := <-readError:
		t.Fatal(err)
	case <-time.After(3 * time.Second):
		t.Fatal("notice not delivered")
	}
	view.Room.Acknowledged[0] = 3
	handler.Service = tournamentNoticeFixture{view}
	if err := handler.ReloadAndDeliver(context.Background(), identifier.String()); err != nil {
		t.Fatal(err)
	}
	view.Room.Acknowledged[0] = 0
	handler.Service = tournamentNoticeFixture{view}
	handler.Authority = deliveryAuthority{bad: true}
	if err := handler.ReloadAndDeliver(context.Background(), identifier.String()); err != nil {
		t.Fatal(err)
	}
	client.SetReadDeadline(time.Now().Add(50 * time.Millisecond))
	if count, err := client.Read(make([]byte, 4096)); err == nil || count != 0 {
		t.Fatal("acknowledged or revoked notice delivered", count, err)
	}
}
