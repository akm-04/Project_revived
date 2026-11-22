//go:build postgres && socialintegration

package socialactivation_test

import (
	"context"
	"encoding/json"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	frienddm "gxb.local/backend/v2/internal/application/frienddm"
	"gxb.local/backend/v2/internal/domain/friendmessage"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

type friendDMWakeupSender struct {
	occurrence frienddm.Occurrence
}

func (s friendDMWakeupSender) Accept(context.Context, identity.ActorContext, identity.PlayerID, friendmessage.Message, operation.Context) (frienddm.Occurrence, error) {
	return s.occurrence, nil
}

// TestFriendDMWakeupEmitsThroughProductionEmitter proves a successful private
// message pushes the production recipient wakeup on the realtime channel.
func TestFriendDMWakeupEmitsThroughProductionEmitter(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.player(200001)
	_, token := f.live(100001)

	listener, err := f.p.Raw().Acquire(ctx)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(listener.Release)
	if _, err = listener.Exec(ctx, `LISTEN `+postgres.RealtimeWakeupChannel); err != nil {
		t.Fatal(err)
	}
	payloads := make(chan string, 1)
	go func() {
		notification, e := listener.Conn().WaitForNotification(ctx)
		if e == nil {
			payloads <- notification.Payload
		}
	}()

	identifier, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	message, err := friendmessage.Message{Kind: 0, Text: "hello", SelectType: friendmessage.SelectSocialSystem}.Canonical()
	if err != nil {
		t.Fatal(err)
	}
	occurrence := frienddm.Occurrence{ID: identifier.String(), Sender: 100001, Recipient: 200001, Sequence: 1,
		AcceptedAt: time.Now().UTC(), FriendshipGeneration: 1, Digest: strings.Repeat("a", 64), Message: message}
	dispatcher := stockruntime.FriendDMDispatcher{Authority: f.authority(), Service: friendDMWakeupSender{occurrence: occurrence},
		Emitter: postgres.FriendDMWakeupEmitter{Pool: f.p}}
	request := httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{MID: 515, ReceivedAt: time.Now(),
		Claims: wire.CredentialClaims{Token: token, Region: 1},
		Params: map[string]any{"player_id": json.Number("200001"), "msg": message}}}
	response := dispatcher.Dispatch(ctx, request)
	if response.HTTPStatus != 200 {
		t.Fatalf("private message status=%d body=%+v", response.HTTPStatus, response.Body)
	}
	if response.Body["server_time"] != occurrence.AcceptedAt.Unix() {
		t.Fatalf("private message server_time=%v want %d", response.Body["server_time"], occurrence.AcceptedAt.Unix())
	}
	select {
	case payload := <-payloads:
		if !strings.Contains(payload, frienddm.WakeupRoute) {
			t.Fatalf("wakeup payload %q", payload)
		}
	case <-time.After(3 * time.Second):
		t.Fatal("friend DM wakeup was not emitted")
	}
}
