package stockruntime

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/application/publicprofile"
	apprealtime "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"math"
	"net/http"
)

type PublicProfileCommands interface {
	Execute(context.Context, identity.ActorContext, publicprofile.Command, operation.Context) (publicprofile.CommandResult, error)
}
type PublicProfileDispatcher struct {
	Authority apprealtime.GameplayAuthorityPort
	Service   PublicProfileCommands
}

func profileIDs(v any, limit int) ([]int64, error) {
	if m, ok := v.(map[string]any); ok {
		if len(m) == 0 {
			return []int64{}, nil
		}
		return nil, publicprofile.ErrCommand
	}
	a, ok := v.([]any)
	if !ok || len(a) > limit {
		return nil, publicprofile.ErrCommand
	}
	out := make([]int64, len(a))
	for i, v := range a {
		var n float64
		switch q := v.(type) {
		case json.Number:
			f, e := q.Float64()
			if e != nil {
				return nil, e
			}
			n = f
		case float64:
			n = q
		case int64:
			n = float64(q)
		case int:
			n = float64(q)
		default:
			return nil, publicprofile.ErrCommand
		}
		if math.IsNaN(n) || math.IsInf(n, 0) || math.Trunc(n) != n || n < 0 || n > 1011 {
			return nil, publicprofile.ErrCommand
		}
		out[i] = int64(n)
	}
	return out, nil
}
func (d PublicProfileDispatcher) Dispatch(c context.Context, r httpedge.DispatchRequest) httpedge.Response {
	fail := func(status int) httpedge.Response {
		return httpedge.Response{HTTPStatus: status, Body: map[string]any{"error_code": int64(1), "error": "public_profile_request_failed"}}
	}
	if d.Authority == nil || d.Service == nil || r.Envelope.Claims.Token == "" {
		return fail(http.StatusUnauthorized)
	}
	a, e := d.Authority.ResolveGameplayBearer(c, r.Envelope.Claims.Token, r.Envelope.ReceivedAt)
	if e != nil {
		return fail(http.StatusForbidden)
	}
	if r.Envelope.Claims.Region != int64(a.LogicalServerID) {
		return fail(http.StatusForbidden)
	}
	for _, k := range []string{"to_player_id", "player_id", "target_player_id"} {
		if _, yes := r.Envelope.Params[k]; yes {
			return fail(http.StatusBadRequest)
		}
	}
	q := publicprofile.Command{}
	switch r.Envelope.MID {
	case 1834:
		q.Kind = publicprofile.IntroCommand
		v, ok := r.Envelope.Params["content"].(string)
		if !ok {
			return fail(http.StatusBadRequest)
		}
		q.Intro = v
	case 1833:
		q.Kind = publicprofile.HideCommand
		ids, e := profileIDs(r.Envelope.Params["sub_types"], 2)
		if e != nil {
			return fail(http.StatusBadRequest)
		}
		q.Hide = make([]int16, len(ids))
		for i, v := range ids {
			q.Hide[i] = int16(v)
		}
	case 1831:
		q.Kind = publicprofile.ShowCommand
		ids, e := profileIDs(r.Envelope.Params["show_types"], 4)
		if e != nil {
			return fail(http.StatusBadRequest)
		}
		q.Show = ids
	default:
		return fail(http.StatusNotImplemented)
	}
	q, e = q.Normalize()
	if e != nil {
		return fail(http.StatusBadRequest)
	}
	out, e := d.Service.Execute(c, a, q, r.Envelope.Operation)
	if e != nil {
		switch {
		case errors.Is(e, publicprofile.ErrContent):
			return fail(http.StatusConflict)
		case errors.Is(e, publicprofile.ErrCommand):
			return fail(http.StatusBadRequest)
		default:
			return fail(http.StatusServiceUnavailable)
		}
	}
	if out.Kind != q.Kind || out.PlayerID != int64(a.PlayerID) || out.Server != int32(a.LogicalServerID) || out.Wire() == nil {
		return fail(http.StatusServiceUnavailable)
	}
	return httpedge.Response{HTTPStatus: http.StatusOK, Body: out.Wire()}
}
