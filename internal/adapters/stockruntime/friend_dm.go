package stockruntime

import (
	"context"
	"encoding/json"

	dm "gxb.local/backend/v2/internal/application/frienddm"
	"gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/friendmessage"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

type FriendDMSender interface {
	Accept(context.Context, identity.ActorContext, identity.PlayerID, friendmessage.Message, operation.Context) (dm.Occurrence, error)
}
type FriendDMEmitter interface {
	EmitFriendDM(context.Context, dm.Occurrence)
}

// RoomChatSender routes a room-scoped selectType to its room owner; a stock
// team-chat line is authorized by shared room membership, not friendship.
type RoomChatSender interface {
	SendRoomChat(context.Context, identity.ActorContext, identity.PlayerID, friendmessage.Message, operation.Context) error
}

type FriendDMDispatcher struct {
	Authority realtimeauth.GameplayAuthorityPort
	Service   FriendDMSender
	Emitter   FriendDMEmitter
	// RoomChat routes ILLUSION, OccultRoomChat OCCULT and AdventureRoomChat
	// ADVENTURE_ILLUSION/ADVENTURE_DEFENSE to their room owners.
	RoomChat          RoomChatSender
	OccultRoomChat    RoomChatSender
	AdventureRoomChat RoomChatSender
}

// roomChat routes one room-scoped selectType to its owner. A permanent refusal
// (no room, not a member, roomID mismatch) is 409 through refusalOrTransient.
func (d FriendDMDispatcher) roomChat(c context.Context, a identity.ActorContext, recipient int64, message friendmessage.Message, r httpedge.DispatchRequest, sender RoomChatSender) httpedge.Response {
	if sender == nil {
		return failureReply(defect(nil))
	}
	if e := sender.SendRoomChat(c, a, identity.PlayerID(recipient), message, r.Envelope.Operation); e != nil {
		return refusalOrTransient(e)
	}
	// The stock 515 callback reads server_time for the sender's own line.
	return httpedge.Response{HTTPStatus: 200, Body: map[string]any{"server_time": r.Envelope.ReceivedAt.Unix()}}
}

func (d FriendDMDispatcher) Dispatch(c context.Context, r httpedge.DispatchRequest) httpedge.Response {
	bad := func() httpedge.Response {
		return failureReply(malformed("invalid_private_message"))
	}
	unsupported := func() httpedge.Response {
		return failureReply(refusal(unprovenRefusalCode))
	}
	if d.Authority == nil {
		return failureReply(defect(nil))
	}
	if r.Envelope.Claims.Token == "" {
		return failureReply(sessionFailure())
	}
	a, e := d.Authority.ResolveGameplayBearer(c, r.Envelope.Claims.Token, r.Envelope.ReceivedAt)
	if e != nil {
		return authFailure(e)
	}
	if r.Envelope.Claims.Region != int64(a.LogicalServerID) {
		return failureReply(refusal(unprovenRefusalCode))
	}
	if r.Envelope.MID != 515 {
		return unsupported()
	}
	fields, e := socialFields(r.Envelope.Params, "player_id", "msg")
	if e != nil || len(fields) != 2 {
		return bad()
	}
	raw, e := json.Marshal(fields)
	if e != nil || len(raw) > 4608 {
		return bad()
	}
	number, ok := fields["player_id"].(json.Number)
	if !ok {
		return bad()
	}
	pid, e := friendmessage.ExactInteger(number)
	if e != nil {
		return bad()
	}
	text, ok := fields["msg"].(string)
	if !ok {
		return bad()
	}
	msg, e := friendmessage.Decode(text)
	if e != nil {
		return bad()
	}
	switch msg.SelectType {
	case friendmessage.SelectIllusion:
		return d.roomChat(c, a, pid, msg, r, d.RoomChat)
	case friendmessage.SelectOccult:
		return d.roomChat(c, a, pid, msg, r, d.OccultRoomChat)
	case friendmessage.SelectAdventureIllusion, friendmessage.SelectAdventureDefense:
		return d.roomChat(c, a, pid, msg, r, d.AdventureRoomChat)
	case friendmessage.SelectSocialSystem:
	default:
		return bad()
	}
	if d.Service == nil || d.Emitter == nil {
		return failureReply(defect(nil))
	}
	o, e := d.Service.Accept(c, a, identity.PlayerID(pid), msg, r.Envelope.Operation)
	if e != nil {
		return refusalOrTransient(e)
	}
	d.Emitter.EmitFriendDM(c, o)
	return httpedge.Response{HTTPStatus: 200, Body: map[string]any{"server_time": o.AcceptedAt.Unix()}}
}
