//go:build postgres && river && socialintegration

package socialactivation_test

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
)

// bug127Room seeds one Adventure defense room with the host in seat 0 and the
// teammate in seat 1, the same shared-room rows the production 515 path reads.
func bug127Room(t *testing.T, f *fixture, host, teammate identity.PlayerID) int64 {
	t.Helper()
	payload := `{"room_type":2,"special_data":0,"master_level":1,"phase":"","chat_serial":0}`
	var roomID int64
	if e := f.p.QueryRow(ctx, `INSERT INTO shared_rooms(logical_server_id,family,slot,owner_player,status,capacity,expires_at,state_version,notice_version,payload,created_at,updated_at)
VALUES(1,'adventure',1,$1,'OPEN',3,clock_timestamp()+interval '1 hour',1,1,$2::jsonb,clock_timestamp(),clock_timestamp()) RETURNING room_id`,
		int64(host), payload).Scan(&roomID); e != nil {
		t.Fatal(e)
	}
	for index, player := range []identity.PlayerID{host, teammate} {
		if _, e := f.p.Raw().Exec(ctx, `INSERT INTO shared_room_seats(room_id,seat_index,player_id,family,slot,stage,ready,joined_at,updated_at)
VALUES($1,$2,$3,'adventure',1,'SEATED',false,clock_timestamp(),clock_timestamp())`, roomID, index, int64(player)); e != nil {
			t.Fatal(e)
		}
	}
	return roomID
}

// bug127Start runs the deployed API and realtime candidates. The combat entropy
// keys are an API startup requirement for the Adventure routes to register.
func bug127Start(t *testing.T) (api, poll string) {
	t.Helper()
	apiBinary := os.Getenv("GXB_I7B6A_API_BINARY")
	if apiBinary == "" {
		t.Fatal("GXB_I7B6A_API_BINARY must name the exact candidate API binary")
	}
	realtimeBinary := os.Getenv("GXB_I7B6A_REALTIME_BINARY")
	if realtimeBinary == "" {
		realtimeBinary = os.Getenv("GXB_REALTIME_BINARY")
	}
	if realtimeBinary == "" {
		realtimeBinary = filepath.Join(filepath.Dir(apiBinary), "gxb-realtime")
	}
	if _, e := os.Stat(realtimeBinary); e != nil {
		t.Fatalf("realtime candidate unavailable: %v", e)
	}
	api, world, poll := freeAddr(t), freeAddr(t), freeAddr(t)
	for name, value := range map[string]string{
		"GXB_REALTIME_HTTP_ADDR":         poll,
		"GXB_REALTIME_HTTP_IDLE_TIMEOUT": "20s",
		"GXB_REALTIME_HTTP_HOLD_TIMEOUT": "10s",
		"GXB_COMBAT_ENTROPY_KEYS":        "bug127=7663000000000000000000000000000000000000000000000000000000000001",
		"GXB_COMBAT_ENTROPY_KEY_CURRENT": "bug127",
	} {
		if e := os.Setenv(name, value); e != nil {
			t.Fatal(e)
		}
		defer os.Unsetenv(name)
	}
	startProcess(t, apiBinary, api, world)
	startProcess(t, realtimeBinary, api, world)
	return api, poll
}

func bug127Chat(t *testing.T, api, token string, target identity.PlayerID, roomID int64, text string) (int, any) {
	t.Helper()
	body, e := json.Marshal(map[string]any{"message": text, "msgType": 0, "selectType": 4, "roomID": roomID})
	if e != nil {
		t.Fatal(e)
	}
	return postProcess(t, api, token, 1, 515, map[string]any{"player_id": int64(target), "msg": string(body)})
}

// TestBUG127AdventureTeamChatDeliversBothWays names BUGS #127: the host's line
// reaches the teammate over the HTTP poll chat socket even though the teammate's
// socket only comes up after the line was recorded, and the teammate's reply
// reaches the host. Host 125001 and teammate 125009 mirror the real-client run.
func TestBUG127AdventureTeamChatDeliversBothWays(t *testing.T) {
	if os.Getenv("GXB_I7A4D_TEST_DSN") == "" {
		for _, name := range []string{"GXB_I7B6A_DSN", "GXB_I94_DSN", "GXB_POSTGRES_DSN"} {
			if value := os.Getenv(name); value != "" {
				t.Setenv("GXB_I7A4D_TEST_DSN", value)
				break
			}
		}
	}
	f := fresh(t)
	f.player(125001)
	f.player(125009)
	_, hostToken := f.live(125001)
	_, teammateToken := f.live(125009)
	roomID := bug127Room(t, f, 125001, 125009)
	api, poll := bug127Start(t)
	time.Sleep(2 * time.Second)

	hostSession, hostAck := bug35LoginOverPoll(t, poll, hostToken, 1)
	code, body := bug127Chat(t, api, hostToken, 125009, roomID, "host line")
	if code != http.StatusOK {
		t.Fatalf("host 515 status=%d body=%v", code, body)
	}
	// The wakeup runs while the teammate has no world socket; the line must stay
	// undelivered for that member instead of being consumed.
	time.Sleep(time.Second)
	teammateSession, teammateAck := bug35LoginOverPoll(t, poll, teammateToken, 1)

	teammateFrames := make(chan rt.Frame, 1)
	go func() {
		frame, e := bug127AwaitChat(poll, teammateSession, teammateAck, 6*time.Second)
		if e != nil {
			t.Errorf("teammate poll: %v", e)
			return
		}
		teammateFrames <- frame
	}()
	time.Sleep(200 * time.Millisecond)
	code, body = bug127Chat(t, api, teammateToken, 125001, roomID, "teammate reply")
	if code != http.StatusOK {
		t.Fatalf("teammate 515 status=%d body=%v", code, body)
	}
	select {
	case frame := <-teammateFrames:
		assertBug127Chat(t, frame, 125001, roomID, "host line")
	case <-time.After(7 * time.Second):
		t.Fatal("teammate never received the host's line after reconnecting")
	}

	hostFrames := make(chan rt.Frame, 1)
	go func() {
		frame, e := bug127AwaitChat(poll, hostSession, hostAck, 6*time.Second)
		if e != nil {
			t.Errorf("host poll: %v", e)
			return
		}
		hostFrames <- frame
	}()
	select {
	case frame := <-hostFrames:
		assertBug127Chat(t, frame, 125009, roomID, "teammate reply")
	case <-time.After(7 * time.Second):
		t.Fatal("host never received the teammate's reply")
	}
}

// bug127AwaitChat keeps one held poll open and acknowledges every returned
// frame until the chat MID arrives, so a room-change notice in the same reply
// does not hide the chat line from the next poll.
func bug127AwaitChat(address, session string, ack uint64, timeout time.Duration) (rt.Frame, error) {
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		body, e := json.Marshal(bug35PollRequest{SessionID: session, Ack: ack, Hold: true})
		if e != nil {
			return rt.Frame{}, e
		}
		response, e := http.Post("http://"+address+"/realtime/poll", "application/json", bytes.NewReader(body))
		if e != nil {
			return rt.Frame{}, e
		}
		var reply bug35PollReply
		decodeError := json.NewDecoder(response.Body).Decode(&reply)
		response.Body.Close()
		if response.StatusCode != http.StatusOK {
			return rt.Frame{}, fmt.Errorf("held poll status=%d", response.StatusCode)
		}
		if decodeError != nil {
			return rt.Frame{}, decodeError
		}
		for _, outbound := range reply.Frames {
			if outbound.Sequence > ack {
				ack = outbound.Sequence
			}
			if outbound.Closed || len(outbound.Frame) == 0 {
				continue
			}
			frame, e := rt.DecodeJSONFrame(outbound.Frame, limits.Default())
			if e != nil {
				return rt.Frame{}, e
			}
			if frame.MID == mids.MIDChatFromFriend {
				return frame, nil
			}
		}
	}
	return rt.Frame{}, fmt.Errorf("no MID %d within %s", mids.MIDChatFromFriend, timeout)
}

func assertBug127Chat(t *testing.T, frame rt.Frame, sender identity.PlayerID, roomID int64, text string) {
	t.Helper()
	fields, e := frame.Params.(*amf3.Object).StrictMap()
	if e != nil {
		t.Fatal(e)
	}
	want := `{"msgType":0,"message":"` + text + `","selectType":4,"roomID":` + fmt.Sprint(roomID) + `}`
	if fields["message"] != want {
		t.Fatalf("chat frame %#v", fields)
	}
	if fmt.Sprint(fields["friend_id"]) != fmt.Sprint(int64(sender)) {
		t.Fatalf("chat sender %T %#v", fields["friend_id"], fields["friend_id"])
	}
}
