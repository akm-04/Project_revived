package stockruntime

import (
	"context"
	"fmt"
	"net/http"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/protocol/mids"
)

// abandonedSendContext is a send request whose client gave up after the frames reached the socket loop: the first
// Done call (the handoff) never fires, every later one (the wait for the apply) is already cancelled.
type abandonedSendContext struct {
	context.Context
	calls     int
	cancelled chan struct{}
}

func (c *abandonedSendContext) Done() <-chan struct{} {
	c.calls++
	if c.calls == 1 {
		return nil
	}
	return c.cancelled
}

func (c *abandonedSendContext) Err() error { return context.Canceled }

func TestHTTPPollRetryAfterAbandonedSendAppliesOnce(t *testing.T) {
	server, err := NewHTTPPollServer(t.Context(), newRealtimeTestServer(t), 5*time.Second, 100*time.Millisecond)
	if err != nil {
		t.Fatal(err)
	}
	defer server.Close()
	handler := server.Handler()

	alphaSession, _ := loginSocket(t, handler, "alpha", "world", 1)
	betaSession, betaSequence := loginSocket(t, handler, "beta", "world", 1)
	server.mutex.Lock()
	session := server.sessions[alphaSession]
	server.mutex.Unlock()

	const sends = 20
	cancelled := make(chan struct{})
	close(cancelled)
	for index := 0; index < sends; index++ {
		sequence := uint64(100 + index)
		frames := makePollFrames(t, "world", realtimeChatRequest(fmt.Sprintf("message %d", index)))
		_ = session.deliver(&abandonedSendContext{Context: context.Background(), cancelled: cancelled}, sequence, frames)
		if err := session.deliver(context.Background(), sequence, frames); err != nil {
			t.Fatalf("retry of send %d: %v", sequence, err)
		}
	}

	received := 0
	deadline := time.Now().Add(3 * time.Second)
	for time.Now().Before(deadline) {
		status, reply := sendPollRequest(t, handler, pollRequest{SessionID: betaSession, Ack: betaSequence, Hold: true})
		if status != http.StatusOK {
			t.Fatalf("poll status=%d", status)
		}
		if len(reply.Frames) == 0 && received >= sends {
			break
		}
		for index, frame := range decodePollFrames(t, reply.Frames) {
			if frame.MID == mids.MIDChatMessage {
				received++
			}
			betaSequence = reply.Frames[index].Sequence
		}
	}
	if received != sends {
		t.Fatalf("recipient received %d chat messages for %d sends retried with the same client_sequence", received, sends)
	}
}

func TestHTTPPollFullQueueStillCarriesSocketClose(t *testing.T) {
	server, err := NewHTTPPollServer(t.Context(), newRealtimeTestServer(t), 5*time.Second, 100*time.Millisecond)
	if err != nil {
		t.Fatal(err)
	}
	defer server.Close()
	sessionID, _ := loginSocket(t, server.Handler(), "alpha", "world", 1)
	server.mutex.Lock()
	session := server.sessions[sessionID]
	server.mutex.Unlock()
	for session.enqueue("world", []byte(`{}`)) == nil {
	}
	if err := session.enqueueClosed("world"); err != nil {
		t.Fatalf("a full queue dropped the socket close marker: %v", err)
	}
}

func TestHTTPPollSocketWithDeadWriterIsClosed(t *testing.T) {
	server, err := NewHTTPPollServer(t.Context(), newRealtimeTestServer(t), 5*time.Second, 100*time.Millisecond)
	if err != nil {
		t.Fatal(err)
	}
	defer server.Close()
	handler := server.Handler()
	alphaSession, _ := loginSocket(t, handler, "alpha", "world", 1)
	betaSession, _ := loginSocket(t, handler, "beta", "world", 1)
	server.mutex.Lock()
	session := server.sessions[alphaSession]
	server.mutex.Unlock()
	for session.enqueue("world", []byte(`{}`)) == nil {
	}
	if status, _ := sendChat(t, handler, betaSession, "world", 10, "overflow"); status != http.StatusOK {
		t.Fatalf("send status=%d", status)
	}
	deadline := time.Now().Add(2 * time.Second)
	for time.Now().Before(deadline) {
		session.mutex.Lock()
		open := len(session.sockets)
		closedMarker := len(session.outbound) > 0 && session.outbound[len(session.outbound)-1].closed
		session.mutex.Unlock()
		if open == 0 && closedMarker {
			return
		}
		time.Sleep(10 * time.Millisecond)
	}
	t.Fatal("a socket whose writer died on a full queue stayed open and the client was not told")
}

func TestHTTPPollSocketLimitRefusalLeavesSequenceUnapplied(t *testing.T) {
	server, err := NewHTTPPollServer(t.Context(), newRealtimeTestServer(t), 5*time.Second, 100*time.Millisecond)
	if err != nil {
		t.Fatal(err)
	}
	defer server.Close()
	sessionID, _ := loginSocket(t, server.Handler(), "alpha", "world", 1)
	server.mutex.Lock()
	session := server.sessions[sessionID]
	server.mutex.Unlock()

	frames := makePollFrames(t, "world", realtimeChatRequest("first tag"))
	for index := 0; index < maxPollSocketsPerSession; index++ {
		frames = append(frames, makePollFrames(t, fmt.Sprintf("extra%d", index), realtimeChatRequest("over the limit"))...)
	}
	const sequence = 100
	if err := session.deliver(context.Background(), sequence, frames); err != ErrHTTPPollSocketLimit {
		t.Fatalf("deliver over the socket limit: %v", err)
	}
	if session.wasApplied(sequence) {
		t.Fatal("a refused send was recorded as applied, so its retry would drop the frames")
	}
}
