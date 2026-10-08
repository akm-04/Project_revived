package stockruntime

import (
	"context"
	"encoding/json"
	dm "gxb.local/backend/v2/internal/application/generaldm"
	"gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/finitejson"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"time"
)

type GeneralDMSender interface {
	Accept(context.Context, int64, int64, string, operation.Context) (dm.Intent, error)
	Wait(context.Context, dm.Intent) (dm.Intent, error)
}
type GeneralDMEmitter interface {
	EmitGeneralDM(context.Context, dm.Intent)
}
type GeneralDMDispatcher struct {
	Authority realtimeauth.GameplayAuthorityPort
	Service   GeneralDMSender
	Slots     chan struct{}
	Emitter   GeneralDMEmitter
}

func (d GeneralDMDispatcher) Dispatch(c context.Context, r httpedge.DispatchRequest) httpedge.Response {
	fail := func(code int, name string) httpedge.Response {
		return httpedge.Response{HTTPStatus: code, Body: map[string]any{"error": name}}
	}
	if d.Authority == nil || r.Envelope.Claims.Token == "" {
		return fail(401, "gameplay_auth_required")
	}
	a, e := d.Authority.ResolveGameplayBearer(c, r.Envelope.Claims.Token, r.Envelope.ReceivedAt)
	if e != nil {
		return authFailure(e)
	}
	if r.Envelope.Claims.Region != int64(a.LogicalServerID) {
		return fail(403, "region_mismatch")
	}
	if r.Envelope.MID != 513 || d.Service == nil || d.Slots == nil || cap(d.Slots) != 16 {
		return fail(409, "general_message_unavailable")
	}
	params, e := socialFields(r.Envelope.Params, "message", "to_player_id", "channel")
	if e != nil {
		return fail(400, "invalid_general_message")
	}
	raw, e := json.Marshal(params)
	if e != nil {
		return fail(400, "invalid_general_message")
	}
	if _, e = finitejson.Decode(string(raw), 2048, 2, 16, 3); e != nil {
		return fail(400, "invalid_general_message")
	}
	if len(params) < 2 || len(params) > 3 {
		return fail(400, "invalid_general_message")
	}
	for k := range params {
		if k != "message" && k != "to_player_id" && k != "channel" {
			return fail(400, "invalid_general_message")
		}
	}
	to, ok := params["to_player_id"].(json.Number)
	if !ok {
		return fail(400, "invalid_general_message")
	}
	recipient, e := finitejson.ExactInteger(to)
	if e != nil || recipient < 1 || recipient > (1<<53-1) || recipient == int64(a.PlayerID) {
		return fail(400, "invalid_general_message")
	}
	message, ok := params["message"].(string)
	if !ok || dm.ValidateMessage(message) != nil {
		return fail(400, "invalid_general_message")
	}
	if v, exists := params["channel"]; exists {
		n, ok := v.(json.Number)
		if !ok {
			return fail(400, "invalid_general_message")
		}
		x, e := finitejson.ExactInteger(n)
		if e != nil || x != 1 {
			return fail(400, "invalid_general_message")
		}
	}
	select {
	case d.Slots <- struct{}{}:
		defer func() { <-d.Slots }()
	default:
		return fail(503, "general_message_capacity")
	}
	bounded, cancel := context.WithTimeout(c, 12*time.Second)
	defer cancel()
	i, e := d.Service.Accept(bounded, int64(a.PlayerID), recipient, message, r.Envelope.Operation)
	if e != nil {
		return fail(409, "general_message_unavailable")
	}
	if d.Emitter != nil && !i.Status.Terminal() {
		d.Emitter.EmitGeneralDM(bounded, i)
	}
	result, e := d.Service.Wait(bounded, i)
	if e != nil || bounded.Err() != nil || result.ID != i.ID || result.Digest != i.Digest || result.Status != dm.WrittenBeforeDeadline || result.CompletionUpper == nil || !result.CompletionUpper.Before(i.ExpiresAt) {
		return fail(409, "general_message_unavailable")
	}
	return httpedge.Response{HTTPStatus: 200, Body: map[string]any{}}
}
