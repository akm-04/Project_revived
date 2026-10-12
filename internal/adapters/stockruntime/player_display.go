package stockruntime

import (
	"context"
	"encoding/json"
	"errors"
	app "gxb.local/backend/v2/internal/application/playerdisplay"
	auth "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/finitejson"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"net/http"
)

type PlayerDisplayCommands interface {
	Execute(context.Context, identity.ActorContext, app.Command, operation.Context) (app.Result, error)
	Read(context.Context, identity.ActorContext, string, operation.Context) (map[string]any, error)
}
type PlayerDisplayDispatcher struct {
	Authority auth.GameplayAuthorityPort
	Service   PlayerDisplayCommands
}

func (d PlayerDisplayDispatcher) Dispatch(c context.Context, r httpedge.DispatchRequest) httpedge.Response {
	fail := func(status int) httpedge.Response {
		return httpedge.Response{HTTPStatus: status, Body: map[string]any{"error_code": int64(1), "error": "player_display_request_failed"}}
	}
	if d.Authority == nil || d.Service == nil || r.Envelope.Claims.Token == "" {
		return fail(http.StatusUnauthorized)
	}
	a, e := d.Authority.ResolveGameplayBearer(c, r.Envelope.Claims.Token, r.Envelope.ReceivedAt)
	if e != nil || r.Envelope.Claims.Region != int64(a.LogicalServerID) {
		return fail(http.StatusForbidden)
	}
	q := app.Command{}
	fields := []string{}
	read := ""
	switch r.Envelope.MID {
	case 23:
		q.Kind = "rename"
		fields = []string{"player_name"}
	case 98:
		q.Kind = "avatar"
		fields = []string{"table_id", "avatar_id", "avatar_type"}
	case 100:
		q.Kind = "frame"
		fields = []string{"avatar_frame_id"}
	case 656:
		q.Kind = "purchase"
		fields = []string{"id"}
	case 2492:
		q.Kind = "title"
		fields = []string{"title_id", "unique_id"}
	case 2494:
		q.Kind = "bubble"
		fields = []string{"bubble_id"}
	case 119:
		read = "names"
	case 2490:
		read = "titles"
	case 2493:
		read = "bubbles"
	default:
		return fail(http.StatusNotImplemented)
	}
	for _, key := range []string{"player_id", "to_player_id", "target_player_id"} {
		if _, yes := r.Envelope.Params[key]; yes {
			return fail(http.StatusBadRequest)
		}
	}
	for _, key := range fields {
		if _, yes := r.Envelope.Params[key]; !yes {
			return fail(http.StatusBadRequest)
		}
	}
	n := func(k string) (int64, error) {
		v, ok := r.Envelope.Params[k].(json.Number)
		if !ok {
			return 0, app.ErrRequest
		}
		i, e := finitejson.ExactInteger(v)
		if e != nil || i < 0 {
			return 0, app.ErrRequest
		}
		return i, nil
	}
	if read != "" {
		out, e := d.Service.Read(c, a, read, r.Envelope.Operation)
		if e != nil {
			return fail(http.StatusServiceUnavailable)
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: out}
	}
	switch q.Kind {
	case "rename":
		v, ok := r.Envelope.Params["player_name"].(string)
		if !ok {
			return fail(http.StatusBadRequest)
		}
		q.Name = v
	case "avatar":
		q.ID, e = n("table_id")
		if e == nil {
			q.Icon, e = n("avatar_id")
		}
		if e == nil {
			q.Category, e = n("avatar_type")
		}
	case "frame":
		q.ID, e = n("avatar_frame_id")
	case "purchase":
		q.ID, e = n("id")
	case "title":
		q.ID, e = n("title_id")
		if e == nil {
			q.UniqueID, e = n("unique_id")
		}
	case "bubble":
		q.ID, e = n("bubble_id")
	}
	if e != nil || q.Validate() != nil {
		return fail(http.StatusBadRequest)
	}
	out, e := d.Service.Execute(c, a, q, r.Envelope.Operation)
	if e != nil {
		if errors.Is(e, app.ErrRequest) {
			return fail(http.StatusBadRequest)
		}
		if errors.Is(e, app.ErrUnavailable) || errors.Is(e, app.ErrConflict) {
			return fail(http.StatusConflict)
		}
		return fail(http.StatusServiceUnavailable)
	}
	if out.Actor != a || out.Command != q || out.Wire == nil {
		return fail(http.StatusServiceUnavailable)
	}
	return httpedge.Response{HTTPStatus: http.StatusOK, Body: out.Wire}
}
