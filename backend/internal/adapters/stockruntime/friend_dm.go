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
type FriendDMDispatcher struct {
	Authority realtimeauth.GameplayAuthorityPort
	Service   FriendDMSender
	Emitter   FriendDMEmitter
}

func (d FriendDMDispatcher) Dispatch(c context.Context, r httpedge.DispatchRequest) httpedge.Response {
	bad := func() httpedge.Response {
		return httpedge.Response{HTTPStatus: 400, Body: map[string]any{"error": "invalid_private_message"}}
	}
	unavailable := func() httpedge.Response {
		return httpedge.Response{HTTPStatus: 409, Body: map[string]any{"error": "private_message_unavailable"}}
	}
	if d.Authority == nil || r.Envelope.Claims.Token == "" {
		return httpedge.Response{HTTPStatus: 401, Body: map[string]any{"error": "gameplay_auth_required"}}
	}
	a, e := d.Authority.ResolveGameplayBearer(c, r.Envelope.Claims.Token, r.Envelope.ReceivedAt)
	if e != nil {
		return authFailure(e)
	}
	if r.Envelope.Claims.Region != int64(a.LogicalServerID) {
		return httpedge.Response{HTTPStatus: 403, Body: map[string]any{"error": "region_mismatch"}}
	}
	if r.Envelope.MID != 515 {
		return bad()
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
	if d.Service == nil {
		return unavailable()
	}
	o, e := d.Service.Accept(c, a, identity.PlayerID(pid), msg, r.Envelope.Operation)
	if e != nil {
		return unavailable()
	}
	if d.Emitter != nil {
		d.Emitter.EmitFriendDM(c, o)
	}
	return httpedge.Response{HTTPStatus: 200, Body: map[string]any{}}
}
