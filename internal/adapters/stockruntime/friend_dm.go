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
	RoomChat  RoomChatSender
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
	if msg.SelectType == friendmessage.SelectIllusion {
		if d.RoomChat == nil {
			return failureReply(defect(nil))
		}
		if e = d.RoomChat.SendRoomChat(c, a, identity.PlayerID(pid), msg, r.Envelope.Operation); e != nil {
			return failureFromRows(nil, e)
		}
		return httpedge.Response{HTTPStatus: 200, Body: map[string]any{}}
	}
	if msg.SelectType != friendmessage.SelectSocialSystem {
		return bad()
	}
	if d.Service == nil {
		return failureReply(defect(nil))
	}
	o, e := d.Service.Accept(c, a, identity.PlayerID(pid), msg, r.Envelope.Operation)
	if e != nil {
		return failureFromRows(nil, e)
	}
	if d.Emitter != nil {
		d.Emitter.EmitFriendDM(c, o)
	}
	return httpedge.Response{HTTPStatus: 200, Body: map[string]any{}}
}
