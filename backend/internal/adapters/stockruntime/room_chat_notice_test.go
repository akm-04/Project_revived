package stockruntime

import (
	"context"
	"net"
	"testing"
	"time"

	appadventure "gxb.local/backend/v2/internal/application/adventure"
	appoccult "gxb.local/backend/v2/internal/application/occult"
	"gxb.local/backend/v2/internal/domain/identity"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
)

type occultChatNoticeSource struct{ view appoccult.RoomNotice }

func (s occultChatNoticeSource) ReadRoomNotice(context.Context, string) (appoccult.RoomNotice, bool, error) {
	return s.view, true, nil
}

type adventureChatNoticeSource struct{ view appadventure.RoomNotice }

func (s adventureChatNoticeSource) ReadRoomNotice(context.Context, string) (appadventure.RoomNotice, bool, error) {
	return s.view, true, nil
}

func readRoomFrames(client net.Conn) <-chan rt.Frame {
	frames := make(chan rt.Frame, 16)
	go func() {
		defer close(frames)
		decoder, _ := rt.NewStreamDecoder(limits.Default())
		buf := make([]byte, 4096)
		_ = client.SetReadDeadline(time.Now().Add(3 * time.Second))
		for {
			n, err := client.Read(buf)
			if err != nil {
				return
			}
			out, err := decoder.Feed(buf[:n])
			if err != nil {
				return
			}
			for _, frame := range out {
				frames <- frame
			}
		}
	}()
	return frames
}

// TestOccultRoomChatDeliversSelectTypeOnce names A-182: an Occult room wakeup
// publishes the addressed line as a direct 516 whose canonical body keeps the
// selectType, exactly once.
func TestOccultRoomChatDeliversSelectTypeOnce(t *testing.T) {
	registry := NewConnectionRegistry()
	defer registry.CloseAll()
	events, err := NewOccultRoomNoticeRegistry()
	if err != nil {
		t.Fatal(err)
	}
	const recipient = identity.PlayerID(100001)
	writer, _, client := newRegistryPipeWriter(t)
	defer client.Close()
	if _, err = registry.Replace(registryAdmission(t, "33333333-3333-4333-8333-333333333301", recipient, domainrt.World, 1), writer); err != nil {
		t.Fatal(err)
	}
	frames := readRoomFrames(client)
	message := `{"msgType":0,"message":"team","selectType":2,"roomID":0}`
	view := appoccult.RoomNotice{RoomID: 9, Seated: []appoccult.PlayerBody{{Player: recipient}},
		Chats: []sharedroom.ChatMessage{{Serial: 1, Sender: 300001, Recipients: []int64{int64(recipient)}, Message: message, At: 1700000000}}}
	handler := OccultRoomNoticeHandler{Service: occultChatNoticeSource{view: view},
		Delivery: RoomDelivery{Registry: registry, Publisher: RealtimePublisher{Registry: events, Limits: limits.Default()},
			Authority: deliveryAuthority{}, Time: deliveryClock{}, MaxHandles: 10,
			OnDeliveryError: func(err error) { t.Errorf("delivery: %v", err) }},
		Delivered: NewRoomNoticeLedger(), Online: func(identity.PlayerID) bool { return false }}
	if err = handler.ReloadAndDeliver(context.Background(), "9"); err != nil {
		t.Fatal(err)
	}
	if err = handler.ReloadAndDeliver(context.Background(), "9"); err != nil {
		t.Fatal(err)
	}
	_ = client.Close()
	var chats []rt.Frame
	for frame := range frames {
		if frame.MID == mids.MIDChatFromFriend {
			chats = append(chats, frame)
		}
	}
	if len(chats) != 1 {
		t.Fatalf("chat deliveries %d", len(chats))
	}
	fields, err := chats[0].Params.(*amf3.Object).StrictMap()
	if err != nil {
		t.Fatal(err)
	}
	if fields["friend_id"] != float64(300001) || fields["message"] != message || fields["time"] != float64(1700000000) {
		t.Fatalf("chat frame %#v", fields)
	}
}

// TestAdventureRoomChatDeliversSelectType names A-182 for the Adventure room
// notice route: the addressed line is one direct 516 with its selectType.
func TestAdventureRoomChatDeliversSelectType(t *testing.T) {
	registry := NewConnectionRegistry()
	defer registry.CloseAll()
	events, err := NewAdventureRoomNoticeRegistry()
	if err != nil {
		t.Fatal(err)
	}
	const recipient = identity.PlayerID(100002)
	writer, _, client := newRegistryPipeWriter(t)
	defer client.Close()
	if _, err = registry.Replace(registryAdmission(t, "33333333-3333-4333-8333-333333333302", recipient, domainrt.World, 1), writer); err != nil {
		t.Fatal(err)
	}
	frames := readRoomFrames(client)
	message := `{"msgType":0,"message":"team","selectType":4,"roomID":9}`
	view := appadventure.RoomNotice{RoomID: 9, RoomType: 2, Seated: []appadventure.PlayerBody{{Player: recipient}},
		Chats: []sharedroom.ChatMessage{{Serial: 1, Sender: 300002, Recipients: []int64{int64(recipient)}, Message: message, At: 1700000001}}}
	handler := AdventureRoomNoticeHandler{Service: adventureChatNoticeSource{view: view},
		Delivery: RoomDelivery{Registry: registry, Publisher: RealtimePublisher{Registry: events, Limits: limits.Default()},
			Authority: deliveryAuthority{}, Time: deliveryClock{}, MaxHandles: 10,
			OnDeliveryError: func(err error) { t.Errorf("delivery: %v", err) }},
		Delivered: NewRoomNoticeLedger(), Pushes: NewAdventurePushLedger()}
	if err = handler.ReloadAndDeliver(context.Background(), "9"); err != nil {
		t.Fatal(err)
	}
	if err = handler.ReloadAndDeliver(context.Background(), "9"); err != nil {
		t.Fatal(err)
	}
	_ = client.Close()
	var chats []rt.Frame
	for frame := range frames {
		if frame.MID == mids.MIDChatFromFriend {
			chats = append(chats, frame)
		}
	}
	if len(chats) != 1 {
		t.Fatalf("chat deliveries %d", len(chats))
	}
	fields, err := chats[0].Params.(*amf3.Object).StrictMap()
	if err != nil {
		t.Fatal(err)
	}
	if fields["friend_id"] != float64(300002) || fields["message"] != message {
		t.Fatalf("chat frame %#v", fields)
	}
}

// TestAdventureRoomChatRetriesAnUndeliveredLine names BUGS #127: a line is not
// consumed when the addressee is between world sockets. The host talks while the
// teammate's chat socket is absent; when the teammate reconnects and the room
// wakes again the same line must arrive instead of being marked delivered.
func TestAdventureRoomChatRetriesAnUndeliveredLine(t *testing.T) {
	registry := NewConnectionRegistry()
	defer registry.CloseAll()
	events, err := NewAdventureRoomNoticeRegistry()
	if err != nil {
		t.Fatal(err)
	}
	const host, teammate = identity.PlayerID(100001), identity.PlayerID(100002)
	message := `{"msgType":0,"message":"host line","selectType":4,"roomID":9}`
	view := appadventure.RoomNotice{RoomID: 9, RoomType: 2,
		Seated: []appadventure.PlayerBody{{Player: host}, {Player: teammate}},
		Chats:  []sharedroom.ChatMessage{{Serial: 1, Sender: int64(host), Recipients: []int64{int64(teammate)}, Message: message, At: 1700000000}}}
	handler := AdventureRoomNoticeHandler{Service: adventureChatNoticeSource{view: view},
		Delivery: RoomDelivery{Registry: registry, Publisher: RealtimePublisher{Registry: events, Limits: limits.Default()},
			Authority: deliveryAuthority{}, Time: deliveryClock{}, MaxHandles: 10,
			OnDeliveryError: func(err error) { t.Errorf("delivery: %v", err) }},
		Delivered: NewRoomNoticeLedger(), Pushes: NewAdventurePushLedger()}
	if err = handler.ReloadAndDeliver(context.Background(), "9"); err != nil {
		t.Fatal(err)
	}

	teammateWriter, _, teammateClient := newRegistryPipeWriter(t)
	defer teammateClient.Close()
	if _, err = registry.Replace(registryAdmission(t, "33333333-3333-4333-8333-333333333312", teammate, domainrt.World, 1), teammateWriter); err != nil {
		t.Fatal(err)
	}
	frames := readRoomFrames(teammateClient)
	if err = handler.ReloadAndDeliver(context.Background(), "9"); err != nil {
		t.Fatal(err)
	}

	deadline := time.After(3 * time.Second)
	for {
		select {
		case frame, open := <-frames:
			if !open {
				t.Fatal("teammate socket closed before the chat line")
			}
			if frame.MID != mids.MIDChatFromFriend {
				continue
			}
			fields, strictErr := frame.Params.(*amf3.Object).StrictMap()
			if strictErr != nil {
				t.Fatal(strictErr)
			}
			if fields["friend_id"] != float64(host) || fields["message"] != message {
				t.Fatalf("chat frame %#v", fields)
			}
			return
		case <-deadline:
			t.Fatal("teammate never received the host's line after reconnecting")
		}
	}
}
