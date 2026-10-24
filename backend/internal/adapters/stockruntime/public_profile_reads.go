package stockruntime

import (
	"context"
	"gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"net/http"
)

type PublicProfileReads interface {
	Read(context.Context, identity.ActorContext, publicprofile.ReadRequest, operation.Context) (map[string]any, error)
}
type PublicShowcaseCommands interface {
	Execute(context.Context, identity.ActorContext, publicprofile.Selection, operation.Context) (publicprofile.ShowcaseWireResult, error)
}
type PublicProfileReadDispatcher struct {
	Authority realtimeauth.GameplayAuthorityPort
	Service   PublicProfileReads
	Showcase  PublicShowcaseCommands
}

func (d PublicProfileReadDispatcher) Dispatch(c context.Context, r httpedge.DispatchRequest) httpedge.Response {
	fail := func(status int) httpedge.Response {
		return httpedge.Response{HTTPStatus: status, Body: map[string]any{"error_code": int64(1), "error": "public_profile_request_failed"}}
	}
	if d.Authority == nil || r.Envelope.Claims.Token == "" {
		return fail(http.StatusUnauthorized)
	}
	a, e := d.Authority.ResolveGameplayBearer(c, r.Envelope.Claims.Token, r.Envelope.ReceivedAt)
	if e != nil || r.Envelope.Claims.Region != int64(a.LogicalServerID) {
		return fail(http.StatusForbidden)
	}
	p := r.Envelope.Params
	allowed := map[string]bool{"mid": true, "token": true, "region": true}
	q := publicprofile.ReadRequest{MID: r.Envelope.MID, Target: a.PlayerID}
	switch q.MID {
	case 1829:
		allowed["to_player_id"] = true
		allowed["sub_type"] = true
		q.Subtype = 1
	case 1838:
		allowed["to_player_id"] = true
		allowed["index"] = true
	case 1840:
	case 1832:
		allowed["hero_ids"] = true
	default:
		return fail(http.StatusNotImplemented)
	}
	for k := range p {
		if !allowed[k] {
			return fail(http.StatusBadRequest)
		}
	}
	if q.MID == 1832 {
		if d.Showcase == nil {
			return fail(http.StatusBadRequest)
		}
		array, ok := p["hero_ids"].([]any)
		if !ok || len(array) != 6 {
			return fail(http.StatusBadRequest)
		}
		var sel publicprofile.Selection
		for i, v := range array {
			n, e := feedbackInteger(v, -9007199254740991, 9007199254740991)
			if e != nil {
				return fail(http.StatusBadRequest)
			}
			sel[i] = n
		}
		if sel.Validate() != nil {
			return fail(http.StatusBadRequest)
		}
		out, e := d.Showcase.Execute(c, a, sel, r.Envelope.Operation)
		if e != nil {
			return fail(http.StatusBadRequest)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{"error_code": int64(0), "show_case": out.Records}}
	}
	if d.Service == nil {
		return fail(http.StatusBadRequest)
	}
	if q.MID != 1840 {
		n, e := feedbackInteger(p["to_player_id"], 1, 9007199254740991)
		if e != nil {
			return fail(http.StatusBadRequest)
		}
		q.Target = identity.PlayerID(n)
	}
	if q.MID == 1829 {
		if v, yes := p["sub_type"]; yes {
			n, e := feedbackInteger(v, 1, 6)
			if e != nil {
				return fail(http.StatusBadRequest)
			}
			q.Subtype = int16(n)
		}
	}
	if q.MID == 1838 {
		n, e := feedbackInteger(p["index"], 1, 6)
		if e != nil {
			return fail(http.StatusBadRequest)
		}
		q.Index = int(n)
	}
	out, e := d.Service.Read(c, a, q, r.Envelope.Operation)
	if e != nil {
		return fail(http.StatusBadRequest)
	}
	body := make(map[string]any, len(out)+1)
	for k, v := range out {
		body[k] = v
	}
	body["error_code"] = int64(0)
	return httpedge.Response{HTTPStatus: http.StatusOK, Body: body}
}
