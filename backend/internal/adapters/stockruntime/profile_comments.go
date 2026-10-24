package stockruntime

import (
	"context"
	app "gxb.local/backend/v2/internal/application/profilefeedback"
	"gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"net/http"
)

type ProfileCommentCommands interface {
	ExecuteComment(context.Context, identity.ActorContext, app.CommentCommand, operation.Context) (app.CommentResult, error)
	ListComments(context.Context, identity.ActorContext, identity.PlayerID, app.PageRequest, operation.Context) (app.CommentPage, error)
}
type ProfileCommentDispatcher struct {
	Authority realtimeauth.GameplayAuthorityPort
	Service   ProfileCommentCommands
}

func (d ProfileCommentDispatcher) Dispatch(c context.Context, r httpedge.DispatchRequest) httpedge.Response {
	fail := func(status int) httpedge.Response {
		return httpedge.Response{HTTPStatus: status, Body: map[string]any{"error_code": int64(1), "error": "profile_feedback_request_failed"}}
	}
	if d.Authority == nil || d.Service == nil || r.Envelope.Claims.Token == "" {
		return fail(http.StatusUnauthorized)
	}
	a, e := d.Authority.ResolveGameplayBearer(c, r.Envelope.Claims.Token, r.Envelope.ReceivedAt)
	if e != nil || r.Envelope.Claims.Region != int64(a.LogicalServerID) {
		return fail(http.StatusForbidden)
	}
	allowed := map[string]bool{"mid": true, "token": true, "region": true}
	q := app.CommentCommand{}
	p := r.Envelope.Params
	switch r.Envelope.MID {
	case 1835:
		q.Kind = "post"
		allowed["to_player_id"] = true
		allowed["content"] = true
	case 1836:
		q.Kind = "react"
		allowed["to_player_id"] = true
		allowed["comment_id"] = true
	case 1839:
		allowed["to_player_id"] = true
		allowed["start"] = true
		allowed["offset"] = true
		allowed["comment_num"] = true
	case 1841:
		q.Kind = "delete"
		allowed["comment_id"] = true
	default:
		return fail(http.StatusNotImplemented)
	}
	for k := range p {
		if !allowed[k] {
			return fail(http.StatusBadRequest)
		}
	}
	if r.Envelope.MID != 1841 {
		target, e := feedbackInteger(p["to_player_id"], 1, 9007199254740991)
		if e != nil {
			return fail(http.StatusBadRequest)
		}
		q.Target = identity.PlayerID(target)
	}
	if r.Envelope.MID == 1839 {
		start, e := feedbackInteger(p["start"], 0, 9007199254740991)
		if e != nil {
			return fail(http.StatusBadRequest)
		}
		offset, e := feedbackInteger(p["offset"], 1, 20)
		if e != nil {
			return fail(http.StatusBadRequest)
		}
		page := app.PageRequest{Start: start, Offset: offset}
		if v, yes := p["comment_num"]; yes {
			n, e := feedbackInteger(v, 0, 9007199254740991)
			if e != nil {
				return fail(http.StatusBadRequest)
			}
			page.TotalHint = &n
		}
		out, e := d.Service.ListComments(c, a, q.Target, page, r.Envelope.Operation)
		if e != nil || out.Target != q.Target || out.Actor != a.PlayerID || out.Rows == nil || out.Best == nil || out.Count < 0 {
			return fail(http.StatusServiceUnavailable)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{"comment_list": out.Rows, "comment_num": out.Count}}
	}
	if q.Kind == "post" {
		text, ok := p["content"].(string)
		if !ok {
			return fail(http.StatusBadRequest)
		}
		q.Content = text
	} else {
		id, e := feedbackInteger(p["comment_id"], 1, 9007199254740991)
		if e != nil {
			return fail(http.StatusBadRequest)
		}
		q.CommentID = id
	}
	if q.Validate(a) != nil {
		return fail(http.StatusBadRequest)
	}
	out, e := d.Service.ExecuteComment(c, a, q, r.Envelope.Operation)
	if e != nil || out.Terminal.Kind != q.Kind || out.Terminal.Actor != a.PlayerID {
		return fail(http.StatusServiceUnavailable)
	}
	if q.Kind == "post" && (out.Current.Target != q.Target || out.Current.Best == nil || out.Current.Rows == nil) {
		return fail(http.StatusServiceUnavailable)
	}
	if q.Kind == "react" && (out.Affected == nil || out.Affected.ID != q.CommentID || out.Affected.Owner != q.Target || out.Affected.HasPraised != 1) {
		return fail(http.StatusServiceUnavailable)
	}
	return httpedge.Response{HTTPStatus: http.StatusOK, Body: out.Wire()}
}
