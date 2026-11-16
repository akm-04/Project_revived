package stockruntime

import (
	"context"
	"encoding/json"
	"testing"
	"time"

	dm "gxb.local/backend/v2/internal/application/frienddm"
	"gxb.local/backend/v2/internal/domain/friendmessage"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
)

type friendDMReplySender struct {
	occurrence dm.Occurrence
}

func (s friendDMReplySender) Accept(context.Context, identity.ActorContext, identity.PlayerID, friendmessage.Message, operation.Context) (dm.Occurrence, error) {
	return s.occurrence, nil
}

type friendDMReplyEmitter struct{}

func (friendDMReplyEmitter) EmitFriendDM(context.Context, dm.Occurrence) {}

func TestFriendDMAcceptanceReplyCarriesCommittedServerTime(t *testing.T) {
	message, err := friendmessage.Message{Text: "hello", SelectType: friendmessage.SelectSocialSystem}.Canonical()
	if err != nil {
		t.Fatal(err)
	}
	acceptedAt := time.Unix(1700000000, 0).UTC()
	dispatcher := FriendDMDispatcher{
		Authority: httpAuthority{actor: actorForHTTP(t)},
		Service:   friendDMReplySender{occurrence: dm.Occurrence{AcceptedAt: acceptedAt}},
		Emitter:   friendDMReplyEmitter{},
	}
	got := dispatcher.Dispatch(context.Background(), heroReq(t, 515, map[string]any{
		"player_id": json.Number("200001"),
		"msg":       message,
	}))
	if got.HTTPStatus != 200 {
		t.Fatalf("private message refusal %d %#v", got.HTTPStatus, got.Body)
	}
	if got.Body["server_time"] != acceptedAt.Unix() {
		t.Fatalf("server_time=%v want %d", got.Body["server_time"], acceptedAt.Unix())
	}
}
