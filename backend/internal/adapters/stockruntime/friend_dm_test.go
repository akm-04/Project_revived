package stockruntime

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"testing"
	"time"

	dm "gxb.local/backend/v2/internal/application/frienddm"
	"gxb.local/backend/v2/internal/domain/friendmessage"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/replyconformance"
)

type friendDMReplySender struct {
	occurrence dm.Occurrence
}

func (s friendDMReplySender) Accept(context.Context, identity.ActorContext, identity.PlayerID, friendmessage.Message, operation.Context) (dm.Occurrence, error) {
	return s.occurrence, nil
}

type friendDMReplyEmitter struct{}

func (friendDMReplyEmitter) EmitFriendDM(context.Context, dm.Occurrence) {}

type recordedRoomChat struct {
	recipient  identity.PlayerID
	selectType int64
	roomID     int64
	hasRoomID  bool
}

type recordingRoomChat struct {
	calls []recordedRoomChat
	err   error
}

func (r *recordingRoomChat) SendRoomChat(_ context.Context, _ identity.ActorContext, recipient identity.PlayerID, message friendmessage.Message, _ operation.Context) error {
	r.calls = append(r.calls, recordedRoomChat{recipient: recipient, selectType: message.SelectType, roomID: message.RoomID, hasRoomID: message.HasRoomID})
	return r.err
}

// TestFriendDMRoutesRoomSelectTypes names A-182: selectType 1/2/3/4 reach their
// own room owner and nothing else, and the 200 carries the callback server_time.
func TestFriendDMRoutesRoomSelectTypes(t *testing.T) {
	for _, testCase := range []struct {
		selectType int64
		roomID     int64
		hasRoomID  bool
		field      string
	}{
		{friendmessage.SelectIllusion, 0, false, "RoomChat"},
		{friendmessage.SelectOccult, 0, true, "OccultRoomChat"},
		{friendmessage.SelectAdventureIllusion, 0, true, "AdventureRoomChat"},
		{friendmessage.SelectAdventureDefense, 77, true, "AdventureRoomChat"},
	} {
		illusion, occult, adventure := &recordingRoomChat{}, &recordingRoomChat{}, &recordingRoomChat{}
		dispatcher := FriendDMDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)},
			RoomChat: illusion, OccultRoomChat: occult, AdventureRoomChat: adventure}
		message, err := friendmessage.Message{Kind: 0, Text: "team", SelectType: testCase.selectType,
			RoomID: testCase.roomID, HasRoomID: testCase.hasRoomID}.Canonical()
		if err != nil {
			t.Fatal(err)
		}
		got := dispatcher.Dispatch(context.Background(), heroReq(t, 515, map[string]any{
			"player_id": json.Number("200001"), "msg": message}))
		if got.HTTPStatus != http.StatusOK || got.Body["server_time"] != int64(1000) {
			t.Fatalf("selectType %d reply %d %#v", testCase.selectType, got.HTTPStatus, got.Body)
		}
		replyconformance.Check(t, 515, got.Body)
		senders := map[string]*recordingRoomChat{"RoomChat": illusion, "OccultRoomChat": occult, "AdventureRoomChat": adventure}
		for name, sender := range senders {
			wantCalls := 0
			if name == testCase.field {
				wantCalls = 1
			}
			if len(sender.calls) != wantCalls {
				t.Fatalf("selectType %d routed %d calls to %s", testCase.selectType, len(sender.calls), name)
			}
		}
		call := senders[testCase.field].calls[0]
		if call.recipient != 200001 || call.selectType != testCase.selectType || call.hasRoomID != testCase.hasRoomID || call.roomID != testCase.roomID {
			t.Fatalf("selectType %d call %+v", testCase.selectType, call)
		}
	}
}

// TestFriendDMRoomRefusalIsConflict pins A-182's refusal: not a member, no room
// or a roomID mismatch is 409 through the shared mapper, never 400.
func TestFriendDMRoomRefusalIsConflict(t *testing.T) {
	dispatcher := FriendDMDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)},
		OccultRoomChat: &recordingRoomChat{err: errors.New("not a room mate")}}
	message, err := friendmessage.Message{Kind: 0, Text: "team", SelectType: friendmessage.SelectOccult, HasRoomID: true}.Canonical()
	if err != nil {
		t.Fatal(err)
	}
	got := dispatcher.Dispatch(context.Background(), heroReq(t, 515, map[string]any{"player_id": json.Number("200001"), "msg": message}))
	if got.HTTPStatus != http.StatusConflict || got.Body["error_code"] != unprovenRefusalCode {
		t.Fatalf("refusal %d %#v", got.HTTPStatus, got.Body)
	}
}

// TestFriendDMRoomWarCampAndRagnarokStayRefused keeps selectType 5/6 at
// today's 400 malformed reply.
func TestFriendDMRoomWarCampAndRagnarokStayRefused(t *testing.T) {
	for _, selectType := range []int64{friendmessage.SelectWarCamp, friendmessage.SelectRagnarok} {
		dispatcher := FriendDMDispatcher{Authority: httpAuthority{actor: actorForHTTP(t)}}
		message, err := friendmessage.Message{Kind: 0, Text: "team", SelectType: selectType}.Canonical()
		if err != nil {
			t.Fatal(err)
		}
		got := dispatcher.Dispatch(context.Background(), heroReq(t, 515, map[string]any{"player_id": json.Number("200001"), "msg": message}))
		if got.HTTPStatus != http.StatusBadRequest {
			t.Fatalf("selectType %d refusal %d %#v", selectType, got.HTTPStatus, got.Body)
		}
	}
}

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
