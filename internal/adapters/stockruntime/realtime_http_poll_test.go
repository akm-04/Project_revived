package stockruntime

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
	wireRT "gxb.local/backend/v2/internal/protocol/realtime"
)

type httpPollTestRequest struct {
	SessionID string            `json:"session_id,omitempty"`
	Frames    []json.RawMessage `json:"frames"`
}

func sendHTTPPoll(t *testing.T, handler http.Handler, sessionID string, frames ...wireRT.Frame) (int, pollReply) {
	t.Helper()
	encodedFrames := make([]json.RawMessage, len(frames))
	for index, frame := range frames {
		encoded, err := wireRT.EncodeJSONFrame(frame, limits.Default())
		if err != nil {
			t.Fatal(err)
		}
		encodedFrames[index] = encoded
	}
	body, err := json.Marshal(httpPollTestRequest{SessionID: sessionID, Frames: encodedFrames})
	if err != nil {
		t.Fatal(err)
	}
	request := httptest.NewRequest(http.MethodPost, HTTPPollPath, bytes.NewReader(body))
	request.Header.Set("Content-Type", "application/json")
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	var reply pollReply
	if response.Code == http.StatusOK {
		if err := json.Unmarshal(response.Body.Bytes(), &reply); err != nil {
			t.Fatalf("decode poll reply: %v", err)
		}
	}
	return response.Code, reply
}

func decodeHTTPPollFrames(t *testing.T, frames []json.RawMessage) []wireRT.Frame {
	t.Helper()
	decoded := make([]wireRT.Frame, len(frames))
	for index, encoded := range frames {
		frame, err := wireRT.DecodeJSONFrame(encoded, limits.Default())
		if err != nil {
			t.Fatal(err)
		}
		decoded[index] = frame
	}
	return decoded
}

func receiveHTTPPollFrames(t *testing.T, handler http.Handler, sessionID string, count int) []wireRT.Frame {
	t.Helper()
	deadline := time.Now().Add(time.Second)
	var frames []wireRT.Frame
	for time.Now().Before(deadline) && len(frames) < count {
		status, reply := sendHTTPPoll(t, handler, sessionID)
		if status != http.StatusOK {
			t.Fatalf("poll status=%d", status)
		}
		frames = append(frames, decodeHTTPPollFrames(t, reply.Frames)...)
		time.Sleep(10 * time.Millisecond)
	}
	if len(frames) < count {
		t.Fatalf("received %d frames, want at least %d", len(frames), count)
	}
	return frames
}

func TestHTTPPollChatAndPushReachOtherHTTPPollSession(t *testing.T) {
	server, err := NewHTTPPollServer(t.Context(), newRealtimeTestServer(t), time.Second)
	if err != nil {
		t.Fatal(err)
	}
	defer server.Close()
	handler := server.Handler()

	alphaStatus, alphaLogin := sendHTTPPoll(t, handler, "", realtimeLoginRequest("alpha"))
	if alphaStatus != http.StatusOK || alphaLogin.SessionID == "" {
		t.Fatalf("alpha login status=%d session=%q", alphaStatus, alphaLogin.SessionID)
	}
	if frames := decodeHTTPPollFrames(t, alphaLogin.Frames); len(frames) != 1 || frames[0].MID != mids.MIDChatRoomEntered {
		t.Fatalf("alpha login frames=%v", frames)
	}

	betaStatus, betaLogin := sendHTTPPoll(t, handler, "", realtimeLoginRequest("beta"))
	if betaStatus != http.StatusOK || betaLogin.SessionID == "" {
		t.Fatalf("beta login status=%d session=%q", betaStatus, betaLogin.SessionID)
	}
	if frames := decodeHTTPPollFrames(t, betaLogin.Frames); len(frames) != 1 || frames[0].MID != mids.MIDChatRoomEntered {
		t.Fatalf("beta login frames=%v", frames)
	}

	chatStatus, chatReply := sendHTTPPoll(t, handler, alphaLogin.SessionID, realtimeChatRequest("hello from HTTP polling"))
	if chatStatus != http.StatusOK {
		t.Fatalf("chat status=%d", chatStatus)
	}
	alphaFrames := decodeHTTPPollFrames(t, chatReply.Frames)
	if len(alphaFrames) < 2 {
		alphaFrames = append(alphaFrames, receiveHTTPPollFrames(t, handler, alphaLogin.SessionID, 2-len(alphaFrames))...)
	}
	betaFrames := receiveHTTPPollFrames(t, handler, betaLogin.SessionID, 1)
	if alphaFrames[0].MID != mids.MIDChatMessage || alphaFrames[1].MID != mids.MIDChatFromPlayer {
		t.Fatalf("alpha frame order=%d,%d", alphaFrames[0].MID, alphaFrames[1].MID)
	}
	if betaFrames[0].MID != mids.MIDChatMessage {
		t.Fatalf("beta frame mid=%d", betaFrames[0].MID)
	}
}

func TestHTTPPollActivityRefreshesIdleTimeoutAndSessionExpires(t *testing.T) {
	server, err := NewHTTPPollServer(t.Context(), newRealtimeTestServer(t), 120*time.Millisecond)
	if err != nil {
		t.Fatal(err)
	}
	defer server.Close()
	handler := server.Handler()
	status, login := sendHTTPPoll(t, handler, "", realtimeLoginRequest("alpha"))
	if status != http.StatusOK {
		t.Fatalf("login status=%d", status)
	}
	if registered := server.server.Registry.ByRoomRole(1, domainrt.World); len(registered) != 1 {
		t.Fatalf("registry has %d world sessions after login, want 1", len(registered))
	}

	time.Sleep(70 * time.Millisecond)
	if status, _ := sendHTTPPoll(t, handler, login.SessionID); status != http.StatusOK {
		t.Fatalf("active empty poll status=%d", status)
	}
	time.Sleep(70 * time.Millisecond)
	if status, _ := sendHTTPPoll(t, handler, login.SessionID); status != http.StatusOK {
		t.Fatalf("second active empty poll status=%d", status)
	}

	time.Sleep(200 * time.Millisecond)
	if status, _ := sendHTTPPoll(t, handler, login.SessionID); status != http.StatusConflict {
		t.Fatalf("expired session status=%d", status)
	}
	if registered := server.server.Registry.ByRoomRole(1, domainrt.World); len(registered) != 0 {
		t.Fatalf("registry has %d world sessions after expiry, want 0", len(registered))
	}
}

func TestHTTPPollRejectsUnknownSessionAndOversizedRequest(t *testing.T) {
	server, err := NewHTTPPollServer(t.Context(), newRealtimeTestServer(t), time.Second)
	if err != nil {
		t.Fatal(err)
	}
	defer server.Close()
	handler := server.Handler()
	status, _ := sendHTTPPoll(t, handler, "not-a-session")
	if status != http.StatusConflict {
		t.Fatalf("unknown session status=%d", status)
	}

	request := httptest.NewRequest(http.MethodPost, HTTPPollPath, bytes.NewReader(bytes.Repeat([]byte{' '}, limits.Default().RealtimeBufferedBytes+1)))
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	if response.Code != http.StatusRequestEntityTooLarge {
		t.Fatalf("oversized request status=%d", response.Code)
	}
}
