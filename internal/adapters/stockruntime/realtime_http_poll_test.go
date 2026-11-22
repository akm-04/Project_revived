package stockruntime

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"sync/atomic"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	app "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
	wireRT "gxb.local/backend/v2/internal/protocol/realtime"
)

func makePollFrames(t *testing.T, socket string, frames ...wireRT.Frame) []pollRequestFrame {
	t.Helper()
	encoded := make([]pollRequestFrame, len(frames))
	for index, frame := range frames {
		body, err := wireRT.EncodeJSONFrame(frame, limits.Default())
		if err != nil {
			t.Fatal(err)
		}
		encoded[index] = pollRequestFrame{Socket: socket, Frame: body}
	}
	return encoded
}

type pollResult struct {
	status int
	reply  pollReply
}

func sendPollRequest(t *testing.T, handler http.Handler, request pollRequest) (int, pollReply) {
	t.Helper()
	body, err := json.Marshal(request)
	if err != nil {
		t.Fatal(err)
	}
	httpRequest := httptest.NewRequest(http.MethodPost, HTTPPollPath, bytes.NewReader(body))
	httpRequest.Header.Set("Content-Type", "application/json")
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, httpRequest)
	var reply pollReply
	if response.Code == http.StatusOK {
		if err := json.Unmarshal(response.Body.Bytes(), &reply); err != nil {
			t.Fatalf("decode poll reply: %v", err)
		}
	}
	return response.Code, reply
}

func startPollRequest(t *testing.T, handler http.Handler, request pollRequest) <-chan pollResult {
	t.Helper()
	result := make(chan pollResult, 1)
	go func() {
		status, reply := sendPollRequest(t, handler, request)
		result <- pollResult{status: status, reply: reply}
	}()
	return result
}

func awaitPollResult(t *testing.T, result <-chan pollResult, within time.Duration) pollResult {
	t.Helper()
	select {
	case value := <-result:
		return value
	case <-time.After(within):
		t.Fatalf("poll did not answer within %s", within)
		return pollResult{}
	}
}

func decodePollFrames(t *testing.T, frames []pollOutboundFrame) []wireRT.Frame {
	t.Helper()
	decoded := make([]wireRT.Frame, len(frames))
	for index, outbound := range frames {
		frame, err := wireRT.DecodeJSONFrame(outbound.Frame, limits.Default())
		if err != nil {
			t.Fatal(err)
		}
		decoded[index] = frame
	}
	return decoded
}

func frameMIDs(frames []wireRT.Frame) []uint16 {
	values := make([]uint16, len(frames))
	for index, frame := range frames {
		values[index] = frame.MID
	}
	return values
}

func waitForHeldPoll(t *testing.T, server *HTTPPollServer, sessionID string) {
	t.Helper()
	deadline := time.Now().Add(2 * time.Second)
	for time.Now().Before(deadline) {
		server.mutex.Lock()
		session := server.sessions[sessionID]
		server.mutex.Unlock()
		if session != nil {
			session.mutex.Lock()
			held := session.waiter != nil
			session.mutex.Unlock()
			if held {
				return
			}
		}
		time.Sleep(time.Millisecond)
	}
	t.Fatal("held poll did not become active")
}

func loginSocket(t *testing.T, handler http.Handler, token, socket string, roomID int32) (string, uint64) {
	t.Helper()
	login := realtimeLoginFrame(token, roomID)
	status, reply := sendPollRequest(t, handler, pollRequest{Frames: makePollFrames(t, socket, login), ClientSequence: 1})
	if status != http.StatusOK || reply.SessionID == "" {
		t.Fatalf("login status=%d session=%q", status, reply.SessionID)
	}
	ready := awaitPollResult(t, startPollRequest(t, handler, pollRequest{SessionID: reply.SessionID, Hold: true}), 2*time.Second)
	if ready.status != http.StatusOK {
		t.Fatalf("ready poll status=%d", ready.status)
	}
	frames := decodePollFrames(t, ready.reply.Frames)
	if len(frames) != 1 || frames[0].MID != mids.MIDChatRoomEntered {
		t.Fatalf("login ready frames=%v", frameMIDs(frames))
	}
	return reply.SessionID, ready.reply.Frames[0].Sequence
}

func realtimeLoginFrame(token string, roomID int32) wireRT.Frame {
	return wireRT.Frame{MID: mids.MIDTCPLogin, Params: &amf3.Object{Properties: []amf3.Property{
		{Name: "token", Value: token}, {Name: "region", Value: int32(1)}, {Name: "room_id", Value: roomID},
	}}}
}

func sendChat(t *testing.T, handler http.Handler, sessionID, socket string, sequence uint64, message string) (int, pollReply) {
	t.Helper()
	return sendPollRequest(t, handler, pollRequest{
		SessionID: sessionID, ClientSequence: sequence, Frames: makePollFrames(t, socket, realtimeChatRequest(message)),
	})
}

func TestHTTPPollAnswersQueuedFramesAndHoldsEmptyPolls(t *testing.T) {
	server, err := NewHTTPPollServer(t.Context(), newRealtimeTestServer(t), 5*time.Second, time.Second)
	if err != nil {
		t.Fatal(err)
	}
	defer server.Close()
	handler := server.Handler()

	sessionID, loginSequence := loginSocket(t, handler, "alpha", "world", 1)

	started := time.Now()
	status, reply := sendPollRequest(t, handler, pollRequest{SessionID: sessionID, Ack: loginSequence, Hold: true})
	if status != http.StatusOK || len(reply.Frames) != 0 {
		t.Fatalf("empty poll status=%d frames=%d", status, len(reply.Frames))
	}
	if elapsed := time.Since(started); elapsed < 800*time.Millisecond {
		t.Fatalf("empty poll returned after %s, want hold near 1s", elapsed)
	}
}

func TestHTTPPollSendWakesHeldPoll(t *testing.T) {
	server, err := NewHTTPPollServer(t.Context(), newRealtimeTestServer(t), 5*time.Second, 2*time.Second)
	if err != nil {
		t.Fatal(err)
	}
	defer server.Close()
	handler := server.Handler()

	alphaSession, alphaSequence := loginSocket(t, handler, "alpha", "world", 1)
	betaSession, _ := loginSocket(t, handler, "beta", "world", 1)

	held := startPollRequest(t, handler, pollRequest{SessionID: alphaSession, Ack: alphaSequence, Hold: true})
	waitForHeldPoll(t, server, alphaSession)
	if status, _ := sendChat(t, handler, betaSession, "world", 2, "wake up"); status != http.StatusOK {
		t.Fatalf("beta send status=%d", status)
	}
	result := awaitPollResult(t, held, eventWaitTimeout)
	if result.status != http.StatusOK {
		t.Fatalf("held poll status=%d", result.status)
	}
	frames := decodePollFrames(t, result.reply.Frames)
	if len(frames) != 1 || frames[0].MID != mids.MIDChatMessage {
		t.Fatalf("held poll frames=%v", frameMIDs(frames))
	}
	if result.reply.Frames[0].Socket != "world" {
		t.Fatalf("frame socket=%q", result.reply.Frames[0].Socket)
	}
}

func TestHTTPPollSecondPollReplacesHeldPoll(t *testing.T) {
	server, err := NewHTTPPollServer(t.Context(), newRealtimeTestServer(t), 5*time.Second, 2*time.Second)
	if err != nil {
		t.Fatal(err)
	}
	defer server.Close()
	handler := server.Handler()

	alphaSession, alphaSequence := loginSocket(t, handler, "alpha", "world", 1)
	betaSession, _ := loginSocket(t, handler, "beta", "world", 1)

	first := startPollRequest(t, handler, pollRequest{SessionID: alphaSession, Ack: alphaSequence, Hold: true})
	waitForHeldPoll(t, server, alphaSession)
	second := startPollRequest(t, handler, pollRequest{SessionID: alphaSession, Ack: alphaSequence, Hold: true})
	replaced := awaitPollResult(t, first, eventWaitTimeout)
	if replaced.status != http.StatusOK || len(replaced.reply.Frames) != 0 {
		t.Fatalf("replaced poll status=%d frames=%d", replaced.status, len(replaced.reply.Frames))
	}
	waitForHeldPoll(t, server, alphaSession)
	if status, _ := sendChat(t, handler, betaSession, "world", 2, "second poll"); status != http.StatusOK {
		t.Fatalf("beta send status=%d", status)
	}
	result := awaitPollResult(t, second, eventWaitTimeout)
	if result.status != http.StatusOK || len(result.reply.Frames) != 1 {
		t.Fatalf("replacement poll status=%d frames=%d", result.status, len(result.reply.Frames))
	}
}

func TestHTTPPollResendsUnackedFrames(t *testing.T) {
	server, err := NewHTTPPollServer(t.Context(), newRealtimeTestServer(t), 5*time.Second, 100*time.Millisecond)
	if err != nil {
		t.Fatal(err)
	}
	defer server.Close()
	handler := server.Handler()

	alphaSession, alphaSequence := loginSocket(t, handler, "alpha", "world", 1)
	betaSession, _ := loginSocket(t, handler, "beta", "world", 1)
	if status, _ := sendChat(t, handler, betaSession, "world", 2, "lost response"); status != http.StatusOK {
		t.Fatalf("beta send status=%d", status)
	}

	firstStatus, firstReply := sendPollRequest(t, handler, pollRequest{SessionID: alphaSession, Ack: alphaSequence, Hold: true})
	if firstStatus != http.StatusOK || len(firstReply.Frames) != 1 {
		t.Fatalf("first delivery status=%d frames=%d", firstStatus, len(firstReply.Frames))
	}
	sequence := firstReply.Frames[0].Sequence
	if sequence <= alphaSequence {
		t.Fatalf("delivered sequence=%d not after ack=%d", sequence, alphaSequence)
	}
	_, resendReply := sendPollRequest(t, handler, pollRequest{SessionID: alphaSession, Ack: alphaSequence, Hold: true})
	if len(resendReply.Frames) != 1 || resendReply.Frames[0].Sequence != sequence {
		t.Fatalf("resend frames=%v want sequence %d", resendReply.Frames, sequence)
	}
	status, acknowledgedReply := sendPollRequest(t, handler, pollRequest{SessionID: alphaSession, Ack: sequence, Hold: true})
	if status != http.StatusOK || len(acknowledgedReply.Frames) != 0 {
		t.Fatalf("acknowledged poll status=%d frames=%d", status, len(acknowledgedReply.Frames))
	}
}

func TestHTTPPollAppliesRetriedAndReorderedSendsOnce(t *testing.T) {
	server, err := NewHTTPPollServer(t.Context(), newRealtimeTestServer(t), 5*time.Second, 100*time.Millisecond)
	if err != nil {
		t.Fatal(err)
	}
	defer server.Close()
	handler := server.Handler()

	alphaSession, alphaSequence := loginSocket(t, handler, "alpha", "world", 1)
	betaSession, betaSequence := loginSocket(t, handler, "beta", "world", 1)

	if status, _ := sendChat(t, handler, alphaSession, "world", 10, "once"); status != http.StatusOK {
		t.Fatalf("first send status=%d", status)
	}
	alphaFrames := receiveFrames(t, handler, alphaSession, alphaSequence, 2)
	betaFrames := receiveFrames(t, handler, betaSession, betaSequence, 1)
	if len(alphaFrames) != 2 || len(betaFrames) != 1 {
		t.Fatalf("first delivery alpha=%d beta=%d", len(alphaFrames), len(betaFrames))
	}
	alphaSequence = alphaFrames[len(alphaFrames)-1].Sequence
	betaSequence = betaFrames[len(betaFrames)-1].Sequence

	if status, _ := sendChat(t, handler, alphaSession, "world", 10, "once"); status != http.StatusOK {
		t.Fatalf("retry send status=%d", status)
	}
	if frames := emptyPoll(t, handler, alphaSession, alphaSequence); len(frames) != 0 {
		t.Fatalf("retried send produced %d alpha frames", len(frames))
	}
	if frames := emptyPoll(t, handler, betaSession, betaSequence); len(frames) != 0 {
		t.Fatalf("retried send produced %d beta frames", len(frames))
	}

	if status, _ := sendChat(t, handler, alphaSession, "world", 12, "later"); status != http.StatusOK {
		t.Fatalf("reordered send status=%d", status)
	}
	if status, _ := sendChat(t, handler, alphaSession, "world", 11, "earlier"); status != http.StatusOK {
		t.Fatalf("reordered send status=%d", status)
	}
	messages := receiveFrames(t, handler, betaSession, betaSequence, 2)
	decoded := decodePollFrames(t, messages)
	if len(decoded) != 2 || decoded[0].MID != mids.MIDChatMessage || decoded[1].MID != mids.MIDChatMessage {
		t.Fatalf("reordered delivery frames=%v", frameMIDs(decoded))
	}
}

func receiveFrames(t *testing.T, handler http.Handler, sessionID string, ack uint64, count int) []pollOutboundFrame {
	t.Helper()
	frames := make([]pollOutboundFrame, 0, count)
	deadline := time.Now().Add(2 * time.Second)
	for len(frames) < count && time.Now().Before(deadline) {
		status, reply := sendPollRequest(t, handler, pollRequest{SessionID: sessionID, Ack: ack, Hold: true})
		if status != http.StatusOK {
			t.Fatalf("poll status=%d", status)
		}
		frames = append(frames, reply.Frames...)
	}
	if len(frames) < count {
		t.Fatalf("received %d frames, want %d", len(frames), count)
	}
	return frames
}

func emptyPoll(t *testing.T, handler http.Handler, sessionID string, ack uint64) []pollOutboundFrame {
	t.Helper()
	status, reply := sendPollRequest(t, handler, pollRequest{SessionID: sessionID, Ack: ack, Hold: true})
	if status != http.StatusOK {
		t.Fatalf("empty poll status=%d", status)
	}
	return reply.Frames
}

func TestHTTPPollHeldPollKeepsSessionPastIdleLimit(t *testing.T) {
	server, err := NewHTTPPollServer(t.Context(), newRealtimeTestServer(t), 100*time.Millisecond, 600*time.Millisecond)
	if err != nil {
		t.Fatal(err)
	}
	defer server.Close()
	handler := server.Handler()

	sessionID, sequence := loginSocket(t, handler, "alpha", "world", 1)
	held := startPollRequest(t, handler, pollRequest{SessionID: sessionID, Ack: sequence, Hold: true})
	waitForHeldPoll(t, server, sessionID)
	time.Sleep(300 * time.Millisecond)
	result := awaitPollResult(t, held, 2*time.Second)
	if result.status != http.StatusOK || len(result.reply.Frames) != 0 {
		t.Fatalf("held poll status=%d frames=%d", result.status, len(result.reply.Frames))
	}
	if status, reply := sendPollRequest(t, handler, pollRequest{SessionID: sessionID, Ack: sequence}); status != http.StatusOK || reply.SessionID != sessionID {
		t.Fatalf("session after held poll status=%d session=%q", status, reply.SessionID)
	}
	if registered := server.server.Registry.ByRoomRole(1, domainrt.World); len(registered) != 1 {
		t.Fatalf("registry has %d world sessions, want 1", len(registered))
	}
}

func TestHTTPPollCarriesEveryOpenSocketInOnePoll(t *testing.T) {
	server, err := NewHTTPPollServer(t.Context(), newRealtimeTestServer(t), 5*time.Second, 2*time.Second)
	if err != nil {
		t.Fatal(err)
	}
	defer server.Close()
	handler := server.Handler()

	status, created := sendPollRequest(t, handler, pollRequest{Frames: makePollFrames(t, "world", realtimeLoginFrame("alpha", 1)), ClientSequence: 1})
	if status != http.StatusOK || created.SessionID == "" {
		t.Fatalf("create status=%d session=%q", status, created.SessionID)
	}
	if status, _ := sendPollRequest(t, handler, pollRequest{
		SessionID: created.SessionID, ClientSequence: 2,
		Frames: makePollFrames(t, "service", realtimeLoginFrame("alpha", int32(domainrt.ServiceRoomID))),
	}); status != http.StatusOK {
		t.Fatalf("service login status=%d", status)
	}
	result := awaitPollResult(t, startPollRequest(t, handler, pollRequest{SessionID: created.SessionID, Hold: true}), 2*time.Second)
	if result.status != http.StatusOK || len(result.reply.Frames) != 2 {
		t.Fatalf("combined poll status=%d frames=%d", result.status, len(result.reply.Frames))
	}
	sockets := map[string]bool{}
	for _, frame := range result.reply.Frames {
		sockets[frame.Socket] = true
	}
	if !sockets["world"] || !sockets["service"] {
		t.Fatalf("combined poll sockets=%v", sockets)
	}
	if world := server.server.Registry.ByRoomRole(1, domainrt.World); len(world) != 1 {
		t.Fatalf("world registry=%d", len(world))
	}
	if service := server.server.Registry.ByRoomRole(domainrt.ServiceRoomID, domainrt.Service); len(service) != 1 {
		t.Fatalf("service registry=%d", len(service))
	}
}

type countingAuthority struct {
	resolvePort  app.GameplayAuthorityPort
	livenessPort app.GameplayLivenessPort
	resolve      atomic.Int64
	validate     atomic.Int64
}

func (authority *countingAuthority) ResolveGameplayBearer(ctx context.Context, token string, at time.Time) (identity.ActorContext, error) {
	authority.resolve.Add(1)
	return authority.resolvePort.ResolveGameplayBearer(ctx, token, at)
}

func (authority *countingAuthority) ValidateActor(ctx context.Context, actor identity.ActorContext, at time.Time) error {
	authority.validate.Add(1)
	return authority.livenessPort.ValidateActor(ctx, actor, at)
}

func TestHTTPPollEmptyAndHeldPollsDoNoAuthorityWork(t *testing.T) {
	base := newRealtimeTestServer(t)
	counting := &countingAuthority{resolvePort: base.Auth.Authority, livenessPort: base.Auth.Authority.(app.GameplayLivenessPort)}
	base.Auth = app.Service{Authority: counting, Endpoints: base.Auth.Endpoints}
	server, err := NewHTTPPollServer(t.Context(), base, 5*time.Second, 50*time.Millisecond)
	if err != nil {
		t.Fatal(err)
	}
	defer server.Close()
	handler := server.Handler()

	sessionID, sequence := loginSocket(t, handler, "alpha", "world", 1)
	resolveAfterLogin := counting.resolve.Load()
	validateAfterLogin := counting.validate.Load()
	for attempt := 0; attempt < 3; attempt++ {
		if status, _ := sendPollRequest(t, handler, pollRequest{SessionID: sessionID, Ack: sequence, Hold: true}); status != http.StatusOK {
			t.Fatalf("empty poll %d status=%d", attempt, status)
		}
	}
	if counting.resolve.Load() != resolveAfterLogin || counting.validate.Load() != validateAfterLogin {
		t.Fatalf("empty polls ran authority work: resolve %d->%d validate %d->%d",
			resolveAfterLogin, counting.resolve.Load(), validateAfterLogin, counting.validate.Load())
	}
}

// flippingAuthority turns a live admission into the real authority's revoked
// answer, like a session.logout the socket loop notices on its next liveness
// check.
type flippingAuthority struct {
	resolvePort app.GameplayAuthorityPort
	revoked     atomic.Bool
}

func (authority *flippingAuthority) ResolveGameplayBearer(ctx context.Context, token string, at time.Time) (identity.ActorContext, error) {
	return authority.resolvePort.ResolveGameplayBearer(ctx, token, at)
}

func (authority *flippingAuthority) ValidateActor(context.Context, identity.ActorContext, time.Time) error {
	if authority.revoked.Load() {
		return i4store.ErrGameplayBearerNotLive
	}
	return nil
}

// An idle lobby only polls. A revoked session must still learn the proven
// relogin signal (HTTP 401, message.lua 20003 with its non-empty text).
func TestHTTPPollRefusesRevokedSessionWithTheReloginSignal(t *testing.T) {
	base := newRealtimeTestServer(t)
	authority := &flippingAuthority{resolvePort: base.Auth.Authority}
	base.Auth = app.Service{Authority: authority, Endpoints: base.Auth.Endpoints}
	base.Policy.LivenessInterval = 20 * time.Millisecond
	base.Policy.LivenessQueryTimeout = time.Second
	server, err := NewHTTPPollServer(t.Context(), base, 5*time.Second, 100*time.Millisecond)
	if err != nil {
		t.Fatal(err)
	}
	defer server.Close()
	handler := server.Handler()

	sessionID, sequence := loginSocket(t, handler, "alpha", "world", 1)
	if status, _ := sendPollRequest(t, handler, pollRequest{SessionID: sessionID, Ack: sequence, Hold: true}); status != http.StatusOK {
		t.Fatalf("live session poll status=%d", status)
	}

	authority.revoked.Store(true)
	deadline := time.Now().Add(eventWaitTimeout)
	for {
		server.mutex.Lock()
		session := server.sessions[sessionID]
		server.mutex.Unlock()
		if session != nil && session.failed() {
			break
		}
		if time.Now().After(deadline) {
			t.Fatal("the poll never noticed the revocation")
		}
		time.Sleep(time.Millisecond)
	}

	body, err := json.Marshal(pollRequest{SessionID: sessionID, Ack: sequence})
	if err != nil {
		t.Fatal(err)
	}
	httpRequest := httptest.NewRequest(http.MethodPost, HTTPPollPath, bytes.NewReader(body))
	httpRequest.Header.Set("Content-Type", "application/json")
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, httpRequest)
	if response.Code != http.StatusUnauthorized {
		t.Fatalf("revoked poll status = %d, want 401", response.Code)
	}
	var refusal map[string]any
	if err := json.Unmarshal(response.Body.Bytes(), &refusal); err != nil {
		t.Fatalf("decode refusal: %v", err)
	}
	if refusal["error_code"] != float64(20003) || refusal["error_msg"] != sessionFailureMessage {
		t.Fatalf("refusal body = %v", refusal)
	}
}

func TestHTTPPollRejectsUnknownSessionAndOversizedRequest(t *testing.T) {
	server, err := NewHTTPPollServer(t.Context(), newRealtimeTestServer(t), 5*time.Second, time.Second)
	if err != nil {
		t.Fatal(err)
	}
	defer server.Close()
	handler := server.Handler()
	status, _ := sendPollRequest(t, handler, pollRequest{SessionID: "not-a-session"})
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
