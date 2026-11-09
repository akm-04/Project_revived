package stockruntime

import (
	"context"
	"encoding/json"
	"net"
	"sync"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/illusion"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
)

type illusionChatService struct{ view IllusionRoomNotice }

func (s illusionChatService) ReadRoomNotice(context.Context, string) (IllusionRoomNotice, bool, error) {
	return s.view, true, nil
}

type illusionClientFrame struct {
	player identity.PlayerID
	frame  rt.Frame
}

// TestIllusionRoomChatPushesToBothRecipients proves the production handler
// publishes one direct 516 per addressed team mate.
func TestIllusionRoomChatPushesToBothRecipients(t *testing.T) {
	registry := NewConnectionRegistry()
	defer registry.CloseAll()
	events, err := NewIllusionRoomNoticeRegistry()
	if err != nil {
		t.Fatal(err)
	}
	const sender = identity.PlayerID(100001)
	recipients := []identity.PlayerID{100002, 100003}
	frames := make(chan illusionClientFrame, 8)
	var readers sync.WaitGroup
	for index, player := range recipients {
		writer, _, client := newRegistryPipeWriter(t)
		defer client.Close()
		admission := registryAdmission(t, []string{"33333333-3333-4333-8333-333333333333", "44444444-4444-4444-8444-444444444444"}[index], player, domainrt.World, 1)
		if _, err := registry.Replace(admission, writer); err != nil {
			t.Fatal(err)
		}
		readers.Add(1)
		go func(c net.Conn, player identity.PlayerID) {
			defer readers.Done()
			decoder, _ := rt.NewStreamDecoder(limits.Default())
			buf := make([]byte, 4096)
			c.SetReadDeadline(time.Now().Add(3 * time.Second))
			for count := 0; count < 2; {
				n, e := c.Read(buf)
				if e != nil {
					return
				}
				out, e := decoder.Feed(buf[:n])
				if e != nil {
					return
				}
				for _, frame := range out {
					frames <- illusionClientFrame{player: player, frame: frame}
					count++
				}
			}
		}(client, player)
	}
	view := IllusionRoomNotice{RoomID: 9, Status: 1, Seated: recipients, Ready: map[identity.PlayerID]bool{},
		Chats: []d.ChatMessage{
			{Serial: 1, Sender: int64(sender), Recipients: []int64{int64(recipients[0])}, Message: `{"msgType":0,"message":"one","selectType":1}`, At: 1700000000},
			{Serial: 2, Sender: int64(sender), Recipients: []int64{int64(recipients[1])}, Message: `{"msgType":0,"message":"two","selectType":1}`, At: 1700000001},
		}}
	handler := IllusionRoomNoticeHandler{Service: illusionChatService{view: view}, Registry: registry,
		Publisher: RealtimePublisher{Registry: events, Limits: limits.Default()}, Authority: deliveryAuthority{},
		Time: deliveryClock{}, MaxHandles: 10, Delivered: NewRoomNoticeLedger()}
	if err := handler.ReloadAndDeliver(context.Background(), "9"); err != nil {
		t.Fatal(err)
	}
	readers.Wait()
	close(frames)
	delivered := map[identity.PlayerID]string{}
	for got := range frames {
		if got.frame.MID != mids.MIDChatFromFriend {
			continue
		}
		fields, err := got.frame.Params.(*amf3.Object).StrictMap()
		if err != nil {
			t.Fatal(err)
		}
		if fields["friend_id"] != float64(sender) {
			t.Fatalf("chat sender %#v", fields)
		}
		message, _ := fields["message"].(string)
		delivered[got.player] = message
	}
	if len(delivered) != 2 {
		t.Fatalf("chat deliveries %#v", delivered)
	}
	if delivered[recipients[0]] != view.Chats[0].Message || delivered[recipients[1]] != view.Chats[1].Message {
		t.Fatalf("chat frames %#v", delivered)
	}
}

func TestIllusionMessageFollowsPlayerSeatsAndReady(t *testing.T) {
	teamInfo, err := json.Marshal(map[string]any{
		"room_id": int64(9), "status": int64(1),
		"master_id": int64(1), "master_id_info": map[string]any{"player_id": int64(1), "player_name": "p1"},
		"master_status": int64(1), "master_partner": "101", "master_partner_detail": []map[string]any{{"table_id": int64(101)}},
		"master_pet": int64(55), "master_pet_detail": map[string]any{"pet_id": int64(55)},
		"mate_1": int64(2), "mate_1_info": map[string]any{"player_id": int64(2), "player_name": "p2"},
		"mate_1_status": int64(1), "mate_1_partner": "201|202", "mate_1_partner_detail": []map[string]any{{"table_id": int64(201)}},
		"mate_2": int64(3), "mate_2_info": map[string]any{"player_id": int64(3), "player_name": "p3"},
		"mate_2_status": int64(0), "mate_2_partner": "301", "mate_2_partner_detail": []map[string]any{{"table_id": int64(301)}},
	})
	if err != nil {
		t.Fatal(err)
	}
	view := IllusionRoomNotice{RoomID: 9, Status: 1, Seated: []identity.PlayerID{1, 3},
		Ready: map[identity.PlayerID]bool{1: true, 3: false}, TeamInfo: teamInfo}
	message, err := illusionMessage(view)
	if err != nil {
		t.Fatal(err)
	}
	if message["status"] != float64(1) {
		t.Fatalf("room status changed %#v", message["status"])
	}
	if message["master_id"] != int64(1) || message["master_status"] != int64(1) || message["mate_1"] != int64(3) ||
		message["mate_1_status"] != int64(0) || message["mate_2"] != int64(0) || message["mate_2_status"] != int64(0) {
		t.Fatalf("seats %#v", message)
	}
	mateInfo, ok := message["mate_1_info"].(map[string]any)
	if !ok || mateInfo["player_id"] != float64(3) || message["mate_1_partner"] != "301" {
		t.Fatalf("mate one kept another player's row %#v", message)
	}
	detail, ok := message["mate_1_partner_detail"].([]any)
	if !ok || len(detail) != 1 {
		t.Fatalf("mate one detail %#v", message["mate_1_partner_detail"])
	}
	if row, ok := detail[0].(map[string]any); !ok || row["table_id"] != float64(301) {
		t.Fatalf("mate one detail row %#v", detail[0])
	}
	if message["mate_2_info"] != int64(0) || message["mate_2_partner"] != "" {
		t.Fatalf("vacated mate two not zeroed %#v", message)
	}
	if detail, ok := message["mate_2_partner_detail"].([]any); !ok || len(detail) != 0 {
		t.Fatalf("vacated mate two detail %#v", message["mate_2_partner_detail"])
	}
	if message["master_pet"] != float64(55) {
		t.Fatalf("master pet lost %#v", message["master_pet"])
	}
	var cached map[string]any
	if err = json.Unmarshal(teamInfo, &cached); err != nil {
		t.Fatal(err)
	}
	delete(cached, "master_pet")
	withoutPet, err := json.Marshal(cached)
	if err != nil {
		t.Fatal(err)
	}
	view.TeamInfo = withoutPet
	message, err = illusionMessage(view)
	if err != nil {
		t.Fatal(err)
	}
	if message["master_pet"] != int64(0) {
		t.Fatalf("a mate promoted to master sent a null pet %#v", message["master_pet"])
	}
}
