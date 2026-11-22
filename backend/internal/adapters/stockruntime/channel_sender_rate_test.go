package stockruntime

import (
	"context"
	"fmt"
	cc "gxb.local/backend/v2/internal/application/channelchat"
	ar "gxb.local/backend/v2/internal/application/realtimeauth"
	dr "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
	"net"
	"sync"
	"testing"
	"time"
)

// AuthorizeRecipientsTx keeps the fake reader usable for the ordinary chat
// path; every admitted recipient is authorized by this fixture.
func (structuredFixtureReader) AuthorizeRecipientsTx(_ context.Context, _ tx.Tx, admissions []ar.Admission) ([]bool, error) {
	authorized := make([]bool, len(admissions))
	for i := range authorized {
		authorized[i] = true
	}
	return authorized, nil
}

func TestChannelChatSenderRateKeepsOtherSendersDelivered(t *testing.T) {
	reg := NewConnectionRegistry()
	defer reg.CloseAll()
	svc := cc.Service{Runner: tx.Runner{DB: &structuredFixtureDB{}}, Operations: operation.Factory{Clock: clock.System{}}, Reader: structuredFixtureReader{}}
	events, err := rt.NewChannelChatEventRegistry()
	if err != nil {
		t.Fatal(err)
	}
	policy := DefaultChannelChatPolicy(16)
	policy.SenderInterval = time.Second
	policy.SenderBurst = 5
	dispatcher, err := NewChannelChatDispatcher(reg, svc, RealtimePublisher{Registry: events, Limits: limits.Default()}, policy)
	if err != nil {
		t.Fatal(err)
	}
	var mu sync.Mutex
	outcomes := map[ChannelChatOutcome]int{}
	dispatcher.OnReport = func(r ChannelChatReport) {
		mu.Lock()
		defer mu.Unlock()
		for outcome, count := range r.Outcomes {
			outcomes[outcome] += count
		}
	}
	flood := ar.Admission{Domain: registryAdmission(t, "33333333-3333-4333-8333-333333333333", 100001, dr.World, 1)}
	quiet := ar.Admission{Domain: registryAdmission(t, "44444444-4444-4444-8444-444444444444", 100002, dr.World, 1)}
	floodWriter, _, floodClient := newRegistryPipeWriter(t)
	defer floodClient.Close()
	floodHandle, err := reg.ReplaceAdmission(flood, floodWriter)
	if err != nil {
		t.Fatal(err)
	}
	quietWriter, _, quietClient := newRegistryPipeWriter(t)
	defer quietClient.Close()
	quietHandle, err := reg.ReplaceAdmission(quiet, quietWriter)
	if err != nil {
		t.Fatal(err)
	}
	send := func(handle SessionHandle, admission ar.Admission, message string) {
		if replies, err := dispatcher.HandleSessionClientFrame(context.Background(), handle, admission, chatFrame(message)); err != nil || len(replies) != 0 {
			t.Fatalf("send %q replies=%d err=%v", message, len(replies), err)
		}
	}
	// Drain both sockets while sending: the writer blocks on the unread pipe.
	floodFrames := readMessagesAsync(floodClient, 6)
	quietFrames := readMessagesAsync(quietClient, 6)
	for i := 0; i < 20; i++ {
		send(floodHandle, flood, fmt.Sprintf("flood%d", i))
	}
	send(quietHandle, quiet, "quiet")
	mu.Lock()
	limited := outcomes[ChatSenderLimited]
	mu.Unlock()
	if limited != 15 {
		t.Fatalf("limited outcomes=%d, want 15", limited)
	}
	quietMessages, err := quietFrames.result()
	if err != nil {
		t.Fatal(err)
	}
	if quietMessages[5] != "quiet" {
		t.Fatalf("quiet sender's own message not delivered last: %v", quietMessages)
	}
	for i, message := range quietMessages[:5] {
		if want := fmt.Sprintf("flood%d", i); message != want {
			t.Fatalf("flood message %d=%q want %q", i, message, want)
		}
	}
	floodMessages, err := floodFrames.result()
	if err != nil {
		t.Fatal(err)
	}
	if floodMessages[0] != "flood0" || floodMessages[4] != "flood4" || floodMessages[5] != "quiet" {
		t.Fatalf("flood socket frames=%v", floodMessages)
	}
}

type readResult struct {
	messages []string
	err      error
}

type framesRead struct{ done <-chan readResult }

func (r framesRead) result() ([]string, error) {
	value := <-r.done
	return value.messages, value.err
}

func readMessagesAsync(client net.Conn, count int) framesRead {
	done := make(chan readResult, 1)
	go func() {
		messages := make([]string, 0, count)
		for i := 0; i < count; i++ {
			frame, err := structuredFixtureRead(client)
			if err != nil {
				done <- readResult{err: err}
				return
			}
			properties, err := frame.Params.(*amf3.Object).StrictMap()
			if err != nil {
				done <- readResult{err: err}
				return
			}
			messages = append(messages, properties["message"].(string))
		}
		done <- readResult{messages: messages}
	}()
	return framesRead{done: done}
}

func TestChannelChatSenderRateEnvDefaultsAndOverride(t *testing.T) {
	policy := DefaultChannelChatPolicy(16)
	if policy.SenderInterval != time.Second || policy.SenderBurst != 5 {
		t.Fatalf("defaults interval=%v burst=%d", policy.SenderInterval, policy.SenderBurst)
	}
	if err := policy.ApplyEnv(func(string) string { return "" }); err != nil {
		t.Fatal(err)
	}
	values := map[string]string{"GXB_CHANNEL_CHAT_SENDER_INTERVAL": "250ms", "GXB_CHANNEL_CHAT_SENDER_BURST": "2"}
	if err := policy.ApplyEnv(func(name string) string { return values[name] }); err != nil || policy.SenderInterval != 250*time.Millisecond || policy.SenderBurst != 2 {
		t.Fatalf("override interval=%v burst=%d err=%v", policy.SenderInterval, policy.SenderBurst, err)
	}
	if err := policy.ApplyEnv(func(string) string { return "-1s" }); err == nil {
		t.Fatal("invalid interval accepted")
	}
}

func chatFrame(message string) rt.Frame {
	return rt.Frame{MID: mids.MIDSendChatMessage, Params: &amf3.Object{Properties: []amf3.Property{{Name: "message", Value: message}, {Name: "channel", Value: 0.0}}}}
}
