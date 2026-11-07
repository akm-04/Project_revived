//go:build postgres && river && socialintegration

package socialactivation_test

import (
	"bytes"
	"encoding/json"
	"fmt"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
	"net/http"
	"os"
	"testing"
	"time"
)

// Mirrors of the /realtime/poll wire shape (the server structs are unexported).
type bug35PollFrame struct {
	Socket string          `json:"socket"`
	Frame  json.RawMessage `json:"frame"`
}
type bug35PollOutbound struct {
	Socket   string          `json:"socket"`
	Sequence uint64          `json:"sequence"`
	Frame    json.RawMessage `json:"frame"`
	Closed   bool            `json:"closed"`
}
type bug35PollRequest struct {
	SessionID      string           `json:"session_id"`
	Ack            uint64           `json:"ack"`
	ClientSequence uint64           `json:"client_sequence"`
	Hold           bool             `json:"hold"`
	Frames         []bug35PollFrame `json:"frames"`
}
type bug35PollReply struct {
	SessionID string              `json:"session_id"`
	Frames    []bug35PollOutbound `json:"frames"`
}

func bug35PollPost(t *testing.T, address string, request bug35PollRequest) (int, bug35PollReply) {
	t.Helper()
	body, e := json.Marshal(request)
	if e != nil {
		t.Fatal(e)
	}
	response, e := http.Post("http://"+address+"/realtime/poll", "application/json", bytes.NewReader(body))
	if e != nil {
		return 0, bug35PollReply{}
	}
	defer response.Body.Close()
	var reply bug35PollReply
	if e := json.NewDecoder(response.Body).Decode(&reply); e != nil {
		t.Fatal(e)
	}
	return response.StatusCode, reply
}

func bug35LoginOverPoll(t *testing.T, address, token string, room int64) (string, uint64) {
	t.Helper()
	login, e := rt.EncodeJSONFrame(rt.Frame{MID: mids.MIDTCPLogin, Params: &amf3.Object{Properties: []amf3.Property{
		{Name: "token", Value: token}, {Name: "region", Value: float64(room)}, {Name: "room_id", Value: float64(room)}}}}, limits.Default())
	if e != nil {
		t.Fatal(e)
	}
	var status int
	var reply bug35PollReply
	deadline := time.Now().Add(5 * time.Second)
	for time.Now().Before(deadline) {
		status, reply = bug35PollPost(t, address, bug35PollRequest{ClientSequence: 1, Frames: []bug35PollFrame{{Socket: "world", Frame: login}}})
		if status == http.StatusOK {
			break
		}
		time.Sleep(20 * time.Millisecond)
	}
	if status != http.StatusOK || reply.SessionID == "" {
		t.Fatalf("poll login status=%d session=%q", status, reply.SessionID)
	}
	status, reply = bug35PollPost(t, address, bug35PollRequest{SessionID: reply.SessionID, Hold: true})
	if status != http.StatusOK || len(reply.Frames) != 1 {
		t.Fatalf("poll login ready status=%d frames=%d", status, len(reply.Frames))
	}
	frame, e := rt.DecodeJSONFrame(reply.Frames[0].Frame, limits.Default())
	if e != nil || frame.MID != mids.MIDChatRoomEntered {
		t.Fatalf("poll login ready frame=%v err=%v", frame, e)
	}
	return reply.SessionID, reply.Frames[0].Sequence
}

func bug35HeldPoll(address, session string, ack uint64, want uint16) (rt.Frame, error) {
	body, e := json.Marshal(bug35PollRequest{SessionID: session, Ack: ack, Hold: true})
	if e != nil {
		return rt.Frame{}, e
	}
	response, e := http.Post("http://"+address+"/realtime/poll", "application/json", bytes.NewReader(body))
	if e != nil {
		return rt.Frame{}, e
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusOK {
		return rt.Frame{}, fmt.Errorf("held poll status=%d", response.StatusCode)
	}
	var reply bug35PollReply
	if e := json.NewDecoder(response.Body).Decode(&reply); e != nil {
		return rt.Frame{}, e
	}
	for _, outbound := range reply.Frames {
		if outbound.Closed || len(outbound.Frame) == 0 {
			continue
		}
		frame, e := rt.DecodeJSONFrame(outbound.Frame, limits.Default())
		if e != nil {
			return rt.Frame{}, e
		}
		if frame.MID == want {
			return frame, nil
		}
	}
	return rt.Frame{}, fmt.Errorf("held poll did not carry MID %d: %d frames", want, len(reply.Frames))
}

// BUGS #35: a same-server non-friend sends MID 513 from the HTTP API and the
// online recipient receives MID 514 on the chat socket carried by /realtime/poll.
func TestBUG35NonFriendPrivateMessageOverHTTPPoll(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.player(100002)
	_, sender := f.live(100001)
	_, recipient := f.live(100002)
	apiBin, rtBin := os.Getenv("GXB_I7A4D_API_BINARY"), os.Getenv("GXB_I7A4D_REALTIME_BINARY")
	if apiBin == "" || rtBin == "" {
		t.Fatal("exact candidate binaries required")
	}
	api, world, poll := freeAddr(t), freeAddr(t), freeAddr(t)
	for name, value := range map[string]string{
		"GXB_REALTIME_HTTP_ADDR":         poll,
		"GXB_REALTIME_HTTP_IDLE_TIMEOUT": "2s",
		"GXB_REALTIME_HTTP_HOLD_TIMEOUT": "15s",
	} {
		if e := os.Setenv(name, value); e != nil {
			t.Fatal(e)
		}
		defer os.Unsetenv(name)
	}
	startProcess(t, apiBin, api, world)
	startProcess(t, rtBin, api, world)
	session, ack := bug35LoginOverPoll(t, poll, recipient, 1)

	// Keep the socket held, then outlive the poll idle limit. The presence lease
	// that general DM admission reads must follow the stock heartbeat budget
	// (20.5 min), not the 2 s poll idle limit.
	held := make(chan struct {
		frame rt.Frame
		err   error
	}, 1)
	go func() {
		frame, e := bug35HeldPoll(poll, session, ack, mids.MIDChatFromPlayer)
		held <- struct {
			frame rt.Frame
			err   error
		}{frame, e}
	}()
	time.Sleep(5 * time.Second)
	code, body := postProcess(t, api, sender, 1, 513, map[string]any{"to_player_id": 100002, "message": "hello nonfriend"})
	if code != http.StatusOK {
		t.Fatalf("MID513 status=%d body=%v", code, body)
	}
	result := <-held
	if result.err != nil {
		t.Fatal(result.err)
	}
	frame := result.frame
	if e := rt.ValidateGeneralDM(frame.Params); e != nil {
		t.Fatal(e)
	}
	object, _ := frame.Params.(*amf3.Object).StrictMap()
	if object["message"] != "hello nonfriend" || fmt.Sprint(object["from_player_id"]) != "100001" {
		t.Fatal(object)
	}
	if got := f.text(`SELECT status FROM personal_dm_delivery`); got != "WRITTEN_BEFORE_DEADLINE" {
		t.Fatalf("receipt=%q", got)
	}
}
