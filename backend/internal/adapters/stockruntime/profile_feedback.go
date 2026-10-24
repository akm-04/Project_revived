package stockruntime

import (
	"context"
	"encoding/json"
	app "gxb.local/backend/v2/internal/application/profilefeedback"
	"gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"math"
	"net/http"
	"strconv"
	"strings"
)

type ProfileFeedbackCommands interface {
	Execute(context.Context, identity.ActorContext, app.Command, operation.Context) (app.CommandResult, error)
	List(context.Context, identity.ActorContext, app.PageRequest, operation.Context) (app.Page, error)
}
type ProfileFeedbackDispatcher struct {
	Authority realtimeauth.GameplayAuthorityPort
	Service   ProfileFeedbackCommands
}

func feedbackInteger(v any, min, max int64) (int64, error) {
	var n int64
	switch x := v.(type) {
	case json.Number:
		raw := x.String()
		if strings.ContainsAny(raw, ".eE+") {
			return 0, app.ErrRequest
		}
		var e error
		n, e = strconv.ParseInt(raw, 10, 64)
		if e != nil {
			return 0, app.ErrRequest
		}
	case float64:
		if math.IsNaN(x) || math.IsInf(x, 0) || math.Trunc(x) != x || x < float64(min) || x > float64(max) {
			return 0, app.ErrRequest
		}
		n = int64(x)
	case int64:
		n = x
	case int:
		n = int64(x)
	default:
		return 0, app.ErrRequest
	}
	if n < min || n > max {
		return 0, app.ErrRequest
	}
	return n, nil
}
func (d ProfileFeedbackDispatcher) Dispatch(c context.Context, r httpedge.DispatchRequest) httpedge.Response {
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
	params := r.Envelope.Params
	switch r.Envelope.MID {
	case 1830:
		for k := range params {
			if k != "mid" && k != "token" && k != "region" && k != "to_player_id" {
				return fail(http.StatusBadRequest)
			}
		}
		target, e := feedbackInteger(params["to_player_id"], 1, 9007199254740991)
		if e != nil {
			return fail(http.StatusBadRequest)
		}
		q := app.Command{Target: identity.PlayerID(target)}
		if q.Validate(a) != nil {
			return fail(http.StatusBadRequest)
		}
		out, e := d.Service.Execute(c, a, q, r.Envelope.Operation)
		if e != nil {
			return fail(http.StatusServiceUnavailable)
		}
		if out.Current.Target != q.Target || out.Current.Actor != a.PlayerID || !out.Current.HasPraised || out.Current.Count < 1 {
			return fail(http.StatusServiceUnavailable)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: out.Wire()}
	case 1842:
		for k := range params {
			if k != "mid" && k != "token" && k != "region" && k != "start" && k != "offset" && k != "total_num" {
				return fail(http.StatusBadRequest)
			}
		}
		start, e := feedbackInteger(params["start"], 0, 9007199254740991)
		if e != nil {
			return fail(http.StatusBadRequest)
		}
		offset, e := feedbackInteger(params["offset"], 1, 20)
		if e != nil {
			return fail(http.StatusBadRequest)
		}
		q := app.PageRequest{Start: start, Offset: offset}
		if v, ok := params["total_num"]; ok {
			hint, e := feedbackInteger(v, 0, 9007199254740991)
			if e != nil {
				return fail(http.StatusBadRequest)
			}
			q.TotalHint = &hint
		}
		out, e := d.Service.List(c, a, q, r.Envelope.Operation)
		if e != nil {
			return fail(http.StatusServiceUnavailable)
		}
		if out.Current.Target != a.PlayerID || out.Rows == nil || out.Current.Count < 0 {
			return fail(http.StatusServiceUnavailable)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: out.Wire()}
	default:
		return fail(http.StatusNotImplemented)
	}
}
