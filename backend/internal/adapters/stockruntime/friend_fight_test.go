package stockruntime

import (
	"context"
	app "gxb.local/backend/v2/internal/application/arena"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
	"testing"
	"time"
)

type friendFightFixture struct {
	command app.FriendFightCommand
	refused bool
	room    d.TournamentRoom
}

func (fixture *friendFightFixture) InviteFriendFight(_ context.Context, _ identity.ActorContext, command app.FriendFightCommand, _ operation.Context) (d.FriendInvitation, error) {
	fixture.command = command
	if fixture.refused {
		return d.FriendInvitation{}, d.ErrRefused
	}
	return d.FriendInvitation{}, nil
}
func (fixture *friendFightFixture) AcceptFriendFight(_ context.Context, _ identity.ActorContext, command app.FriendFightCommand, _ operation.Context) (d.TournamentRoom, error) {
	fixture.command = command
	return fixture.room, nil
}
func (fixture *friendFightFixture) RejectFriendFight(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) error {
	return nil
}
func (fixture *friendFightFixture) TournamentReport(context.Context, identity.ActorContext, ids.UUID, int, int, operation.Context) (d.TournamentRoomView, error) {
	return d.TournamentRoomView{Room: fixture.room}, nil
}
func TestFriendFightDispatcherPreservesStockParametersAndRefusals(t *testing.T) {
	fixture := &friendFightFixture{}
	dispatcher := FriendFightDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: fixture}
	request := env(1312, nil, time.Now())
	request.Envelope.Params["player_id"] = int64(100002)
	request.Envelope.Params["model"] = int64(1)
	request.Envelope.Params["game_type"] = int64(2)
	if response := dispatcher.Dispatch(context.Background(), request); response.HTTPStatus != 200 || fixture.command.Mode != 1 || fixture.command.GameType != 2 {
		t.Fatal("source shape", response)
	}
	fixture.refused = true
	if response := dispatcher.Dispatch(context.Background(), request); response.HTTPStatus != 400 {
		t.Fatal("unsafe callback ran", response)
	}
	fixture.refused = false
	request.Envelope.Params["mode"] = int64(1)
	if response := dispatcher.Dispatch(context.Background(), request); response.HTTPStatus != 400 {
		t.Fatal("unrecognized field admitted", response)
	}
	delete(request.Envelope.Params, "mode")
	request.Envelope.Params["model"] = int64(3)
	if response := dispatcher.Dispatch(context.Background(), request); response.HTTPStatus != 400 {
		t.Fatal("invalid mode", response)
	}
}
func TestFriendFightNoticeSchemasAreFiniteAndWorldOnly(t *testing.T) {
	registry, err := NewFriendFightNoticeRegistry()
	if err != nil {
		t.Fatal(err)
	}
	params, _ := tournamentAMF(map[string]any{"player_info": map[string]any{"player_id": int64(100001), "player_name": "Annie"}, "model": int64(1), "game_type": int64(2)})
	frame := &amf3.Object{Properties: []amf3.Property{{Name: "notice_type", Value: int64(14)}, {Name: "params", Value: params}}}
	if err := registry.ValidateNotice(mids.MIDPlayerNotice, rt.NoticeNamespaceGeneric, rt.World, frame); err != nil {
		t.Fatal(err)
	}
	if err := registry.ValidateNotice(mids.MIDPlayerNotice, rt.NoticeNamespaceGeneric, rt.Guild, frame); err == nil {
		t.Fatal("Guild notice allowed")
	}
	frame.Properties[0].Value = int64(15)
	if ValidateFriendFightNotice(frame) == nil {
		t.Fatal("reject schema accepted invitation body")
	}
	frame.Properties[1].Value = &amf3.Object{}
	if err := registry.ValidateNotice(mids.MIDPlayerNotice, rt.NoticeNamespaceGeneric, rt.World, frame); err != nil {
		t.Fatal(err)
	}
	frame.Properties[0].Value = int64(16)
	if ValidateFriendFightNotice(frame) == nil {
		t.Fatal("future notice type admitted")
	}
}

var _ httpedge.Dispatcher = FriendFightDispatcher{}

type friendNoticeFixture struct{ view app.FriendFightNotice }

func (fixture friendNoticeFixture) ReadFriendNotice(context.Context, string) (app.FriendFightNotice, bool, error) {
	return fixture.view, true, nil
}
func TestFriendFightNoticePublishesThroughLiveWorldSocket(t *testing.T) {
	registry := NewConnectionRegistry()
	defer registry.CloseAll()
	writer, _, client := newRegistryPipeWriter(t)
	defer client.Close()
	if _, err := registry.Replace(registryAdmission(t, "33333333-3333-4333-8333-333333333333", 100002, domainrt.World, 1), writer); err != nil {
		t.Fatal(err)
	}
	events, err := NewFriendFightNoticeRegistry()
	if err != nil {
		t.Fatal(err)
	}
	handler := FriendFightNoticeHandler{Service: friendNoticeFixture{app.FriendFightNotice{Recipient: 100002, Type: 14, Inviter: d.Face{Player: 100001, Name: "Annie"}, Mode: 1, GameType: 1}}, Delivery: TournamentNoticeHandler{Registry: registry, Publisher: RealtimePublisher{Registry: events, Limits: limits.Default()}, Authority: deliveryAuthority{}, Time: deliveryClock{}, MaxHandles: 10}}
	frames := make(chan rt.Frame, 1)
	failures := make(chan error, 1)
	go func() {
		frame, err := structuredFixtureRead(client)
		if err != nil {
			failures <- err
			return
		}
		frames <- frame
	}()
	if err := handler.ReloadAndDeliver(context.Background(), "invitation"); err != nil {
		t.Fatal(err)
	}
	select {
	case frame := <-frames:
		if frame.MID != mids.MIDPlayerNotice {
			t.Fatal(frame.MID)
		}
	case err := <-failures:
		t.Fatal(err)
	case <-time.After(2 * time.Second):
		t.Fatal("invite not delivered")
	}
	handler.Delivery.Authority = deliveryAuthority{bad: true}
	if err := handler.ReloadAndDeliver(context.Background(), "invitation"); err != nil {
		t.Fatal(err)
	}
	client.SetReadDeadline(time.Now().Add(50 * time.Millisecond))
	if count, err := client.Read(make([]byte, 4096)); err == nil || count != 0 {
		t.Fatal("revoked recipient received invitation")
	}
}
