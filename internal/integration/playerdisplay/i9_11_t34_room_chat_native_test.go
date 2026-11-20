//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"fmt"
	"strconv"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/stockruntime"
	d "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/domain/friendmessage"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

type t34RoomChatAuthority map[identity.PlayerID]identity.ActorContext

func (a t34RoomChatAuthority) ResolveGameplayBearer(_ context.Context, token string, _ time.Time) (identity.ActorContext, error) {
	id, err := strconv.ParseInt(token, 10, 64)
	if err != nil {
		return identity.ActorContext{}, err
	}
	actor, ok := a[identity.PlayerID(id)]
	if !ok {
		return identity.ActorContext{}, fmt.Errorf("unknown token %q", token)
	}
	return actor, nil
}

func t34RoomChatCanonical(t *testing.T, text string, selectType int64, roomID int64) string {
	t.Helper()
	message, err := friendmessage.Message{Kind: 0, Text: text, SelectType: selectType, RoomID: roomID, HasRoomID: true}.Canonical()
	if err != nil {
		t.Fatal(err)
	}
	return message
}

func t34RoomChatDispatch(t *testing.T, dispatcher stockruntime.FriendDMDispatcher, sender, recipient identity.ActorContext, server identity.LogicalServerID, roomID int64, selectType int64, text string) httpedge.Response {
	t.Helper()
	return dispatcher.Dispatch(ctx, httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{
		MID: 515, ReceivedAt: time.Now(), Operation: op(),
		Claims: wire.CredentialClaims{Token: fmt.Sprint(sender.PlayerID), Region: int64(server)},
		Params: map[string]any{"player_id": json.Number(fmt.Sprint(recipient.PlayerID)),
			"msg": t34RoomChatCanonical(t, text, selectType, roomID)},
	}})
}

// TestI9_11T34OccultRoomChatNative names A-182: an Occult member's 515 is
// stored on the shared room and a non-member is refused 409.
func TestI9_11T34OccultRoomChatNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, _ := occultOwner(t, p, server, 2)
	b, _ := occultOwner(t, p, server, 2)
	outsider, _ := occultOwner(t, p, server, 2)
	mode, _ := occultTestMode(t, p)

	created, err := mode.CreateTeam(ctx, a, 2, op())
	if err != nil {
		t.Fatal(err)
	}
	roomID := occultRoomID(t, created)
	if _, err = mode.Invite(ctx, a, b.PlayerID, op()); err != nil {
		t.Fatal(err)
	}
	if _, err = mode.JoinRoom(ctx, b, roomID, op()); err != nil {
		t.Fatal(err)
	}
	dispatcher := stockruntime.FriendDMDispatcher{Authority: t34RoomChatAuthority{a.PlayerID: a, b.PlayerID: b, outsider.PlayerID: outsider},
		OccultRoomChat: mode}
	response := t34RoomChatDispatch(t, dispatcher, a, b, server, 0, friendmessage.SelectOccult, "occult hello")
	if response.HTTPStatus != 200 {
		t.Fatalf("occult room chat %d %#v", response.HTTPStatus, response.Body)
	}
	notice := occultReadNotice(t, p, roomID)
	if len(notice.Chats) != 1 {
		t.Fatalf("occult chat rows %#v", notice.Chats)
	}
	if notice.Chats[0].Message != t34RoomChatCanonical(t, "occult hello", friendmessage.SelectOccult, 0) ||
		len(notice.Chats[0].Recipients) != 1 || notice.Chats[0].Recipients[0] != int64(b.PlayerID) {
		t.Fatalf("occult chat row %#v", notice.Chats[0])
	}
	refused := t34RoomChatDispatch(t, dispatcher, a, outsider, server, 0, friendmessage.SelectOccult, "not a mate")
	if refused.HTTPStatus != 409 || refused.Body["error_code"] != int64(35028) {
		t.Fatalf("outsider chat %d %#v", refused.HTTPStatus, refused.Body)
	}
	mismatched := t34RoomChatDispatch(t, dispatcher, a, b, server, roomID+1000, friendmessage.SelectOccult, "wrong room")
	if mismatched.HTTPStatus != 409 {
		t.Fatalf("roomID mismatch %d %#v", mismatched.HTTPStatus, mismatched.Body)
	}
}

// TestI9_11T34AdventureDefenseRoomChatNative names A-182 for selectType 4
// through the production 515 routing.
func TestI9_11T34AdventureDefenseRoomChatNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, _ := adventureOwner(t, p, server, 100, 10001001, 10001002)
	b, _ := adventureOwner(t, p, server, 100, 10001003, 10001004)
	outsider, _ := adventureOwner(t, p, server, 100, 10001005, 10001006)
	clock := &leagueClock{at: time.Now().UTC().Add(2 * time.Minute)}
	mode := adventureTestMode(t, p, clock, adventureOpponents{})
	now := clock.at
	exec(t, p, `UPDATE player_directory_profiles SET lev=11 WHERE player_id IN ($1,$2)`, int64(a.PlayerID), int64(b.PlayerID))
	putAdventureOccurrence(t, p, a.PlayerID, d.EventDefense, 0, now, now.Add(time.Hour), "t34-defense-a")
	opContext := opPinned(installed(t, p))
	opContext.StartedAt = clock.at
	info, err := mode.Info(ctx, a, d.EventDefense, opContext)
	if err != nil {
		t.Fatal(err)
	}
	roomID := adventureRoomID(t, info)
	putAdventureOccurrence(t, p, b.PlayerID, d.EventDefense, 0, now, now.Add(time.Hour), "t34-defense-b")
	if _, err = mode.EnterDefense(ctx, b, roomID, opContext); err != nil {
		t.Fatal(err)
	}
	dispatcher := stockruntime.FriendDMDispatcher{Authority: t34RoomChatAuthority{a.PlayerID: a, b.PlayerID: b, outsider.PlayerID: outsider},
		AdventureRoomChat: mode}
	response := t34RoomChatDispatch(t, dispatcher, a, b, server, roomID, friendmessage.SelectAdventureDefense, "defense hello")
	if response.HTTPStatus != 200 {
		t.Fatalf("defense room chat %d %#v", response.HTTPStatus, response.Body)
	}
	notice, found, err := mode.ReadRoomNotice(ctx, fmt.Sprint(roomID))
	if err != nil || !found || len(notice.Chats) != 1 {
		t.Fatalf("defense notice %#v %v %v", notice, found, err)
	}
	if notice.Chats[0].Message != t34RoomChatCanonical(t, "defense hello", friendmessage.SelectAdventureDefense, roomID) {
		t.Fatalf("defense chat row %#v", notice.Chats[0])
	}
	refused := t34RoomChatDispatch(t, dispatcher, a, outsider, server, roomID, friendmessage.SelectAdventureDefense, "not a mate")
	if refused.HTTPStatus != 409 || refused.Body["error_code"] != int64(35028) {
		t.Fatalf("defense outsider chat %d %#v", refused.HTTPStatus, refused.Body)
	}
}
