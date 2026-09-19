package stockruntime

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"net/http"
	"strconv"

	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"

	apprealtime "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/projection/lobby"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// DiscoveryDispatcher implements the stock MID192 room discovery facade. Room
// and region remain claims only; endpoint selection follows canonical I3 actor
// authority through realtimeauth.Service.
type DiscoveryDispatcher struct {
	Realtime apprealtime.Service
	Tracker  *lobby.BootTracker
}

func (d DiscoveryDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	room, err := requiredInt64(req.Envelope.Params, "room_id")
	if err != nil || room <= 0 {
		return httpedge.Response{HTTPStatus: http.StatusBadRequest, Body: map[string]any{"error": "invalid_room"}}
	}
	adm, err := d.Realtime.Discover(ctx, apprealtime.Claims{
		Bearer: req.Envelope.Claims.Token,
		Region: req.Envelope.Claims.Region,
		RoomID: room,
	}, req.Envelope.ReceivedAt)
	if err != nil {
		return authFailure(err)
	}
	if d.Tracker != nil {
		_ = d.Tracker.Record(d.Tracker.Correlate(lobby.BootEvent{MID: 192, Kind: lobby.BootDiscovery, Phase: lobby.PhaseClientRequestObserved, At: req.Envelope.ReceivedAt, Key: string(adm.Domain.Role)}, adm.Domain.Actor.SessionID.UUID().String(), adm.Domain.Actor.ContextID.UUID().String(), ""))
	}
	return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{
		"host": adm.Endpoint.Host, "port": int64(adm.Endpoint.Port), "room_id": adm.Domain.RoomID,
	}}
}

// LobbyDispatcher exposes only source-observed read-only Wave-S startup MIDs.
// It resolves the gameplay bearer on every request and never accepts the client
// region as identity authority.
type LobbyDispatcher struct {
	Authority  apprealtime.GameplayAuthorityPort
	Tracker    *lobby.BootTracker
	PlayerName func(context.Context, int64) (string, error)
}

func (d LobbyDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	if d.Authority == nil || req.Envelope.Claims.Token == "" {
		return httpedge.Response{HTTPStatus: http.StatusUnauthorized, Body: map[string]any{"error": "gameplay_auth_required"}}
	}
	actor, err := d.Authority.ResolveGameplayBearer(ctx, req.Envelope.Claims.Token, req.Envelope.ReceivedAt)
	if err != nil {
		return authFailure(err)
	}
	if req.Envelope.Claims.Region != int64(actor.LogicalServerID) {
		return httpedge.Response{HTTPStatus: http.StatusForbidden, Body: map[string]any{"error": "region_mismatch"}}
	}
	name := ""
	if d.PlayerName != nil {
		name, err = d.PlayerName(ctx, int64(actor.PlayerID))
		if err != nil {
			return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "projection_unavailable"}}
		}
	}
	body, ok := lobby.Explicit(req.Envelope.MID, lobby.BootstrapView{Actor: actor, PlayerName: name, Now: req.Envelope.ReceivedAt})
	if !ok {
		return httpedge.Response{HTTPStatus: http.StatusNotImplemented, Body: map[string]any{"error": "not_wave_s_facade", "mid": int64(req.Envelope.MID)}}
	}
	obj, ok := body.(map[string]any)
	if !ok {
		// Every I4 explicit facade is intentionally an object. Embedded MID1
		// records may contain arrays, but those are not routed here.
		return httpedge.Response{HTTPStatus: http.StatusInternalServerError, Body: map[string]any{"error": "invalid_wave_s_shape"}}
	}
	if d.Tracker != nil {
		kind := lobby.BootExplicitHTTP
		if req.Envelope.MID == 1056 || req.Envelope.MID == 124 {
			kind = lobby.BootLegitTimer
		}
		_ = d.Tracker.Record(d.Tracker.Correlate(lobby.BootEvent{MID: req.Envelope.MID, Kind: kind, Phase: lobby.PhaseClientRequestObserved, At: req.Envelope.ReceivedAt}, actor.SessionID.UUID().String(), actor.ContextID.UUID().String(), ""))
	}
	return httpedge.Response{HTTPStatus: http.StatusOK, Body: obj}
}

func authFailure(err error) httpedge.Response {
	if err == nil {
		err = errors.New("authentication failed")
	}
	// Do not reflect credential or canonical actor details to stock callers.
	return httpedge.Response{HTTPStatus: http.StatusForbidden, Body: map[string]any{"error": "realtime_auth_failed"}}
}

func requiredInt64(m map[string]any, key string) (int64, error) {
	v, ok := m[key]
	if !ok {
		return 0, fmt.Errorf("missing %s", key)
	}
	switch n := v.(type) {
	case json.Number:
		return n.Int64()
	case int:
		return int64(n), nil
	case int32:
		return int64(n), nil
	case int64:
		return n, nil
	case float64:
		if math.IsNaN(n) || math.IsInf(n, 0) || math.Trunc(n) != n || n > math.MaxInt64 || n < math.MinInt64 {
			return 0, fmt.Errorf("non-integral %s", key)
		}
		return int64(n), nil
	case string:
		return strconv.ParseInt(n, 10, 64)
	default:
		return 0, fmt.Errorf("invalid %s type %T", key, v)
	}
}

// BootstrapDispatcher owns only the account-scope stock bootstrap MIDs 18 and
// 1. It deliberately ignores any injected gameplay token/region claim for
// account authority; MID18/MID1 authenticate the explicit SID+login_token pair.
type BootstrapDispatcher struct {
	Bootstrap    appboot.RuntimePort
	Tracker      *lobby.BootTracker
	ClientLogURL string
}

func (d BootstrapDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	if d.Bootstrap == nil {
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "bootstrap_unavailable"}}
	}
	creds := appboot.AccountCredentials{SID: stringParam(req.Envelope.Params, "sid"), LoginToken: stringParam(req.Envelope.Params, "login_token")}
	switch req.Envelope.MID {
	case 18:
		view, err := d.Bootstrap.MID18(ctx, creds, req.Envelope.Operation)
		if err != nil {
			return bootstrapFailure(err)
		}
		regions := make([]any, 0, len(view.Regions))
		for _, r := range view.Regions {
			regions = append(regions, map[string]any{"region_id": int64(r.RegionID), "name": r.Name, "cur_id": r.CurID, "max_player_id": r.MaxPlayerID})
		}
		players := make([]any, 0, len(view.Players))
		for _, p := range view.Players {
			players = append(players, map[string]any{"id": p.ID, "region": int64(p.Region), "lev": p.Level, "vip": p.VIP, "name": p.Name, "avatar_id": p.AvatarID, "avatar_frame_id": p.AvatarFrameID, "conquer_lev": p.ConquerLevel, "conquer_loop_id": p.ConquerLoopID})
		}
		recall := make([]any, 0, len(view.RecallRegions))
		for _, r := range view.RecallRegions {
			recall = append(recall, int64(r))
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{"regions": regions, "players": players, "recall_regions": recall}}
	case 1:
		region, err := requiredInt64(req.Envelope.Params, "region")
		if err != nil || region <= 0 || region > math.MaxInt32 {
			return httpedge.Response{HTTPStatus: http.StatusBadRequest, Body: map[string]any{"error": "invalid_region"}}
		}
		out, err := d.Bootstrap.MID1(ctx, appboot.RuntimeMID1Request{Credentials: creds, Region: identity.LogicalServerID(region), Operation: req.Envelope.Operation})
		if err != nil {
			return bootstrapFailure(err)
		}
		if d.Tracker != nil {
			for _, mid := range lobby.EmbeddedMID1Records {
				_ = d.Tracker.Record(d.Tracker.Correlate(lobby.BootEvent{MID: mid, Kind: lobby.BootEmbedded, Phase: lobby.PhaseServerIntent, At: req.Envelope.ReceivedAt}, out.ContextPlan.Selected.SessionID.UUID().String(), out.ContextPlan.Selected.ID.UUID().String(), ""))
			}
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{
			"token": out.Token, "region": int64(out.Region), "log_url": d.ClientLogURL,
			"uid": out.UID, "detail": out.Detail, "is_new": out.IsNew,
			// These stock-consumed/defaulted sideband fields are source-backed.
			// server_time is the canonical request-time epoch; the remaining values
			// are the source defaults and introduce no gameplay authority.
			"server_time": req.Envelope.ReceivedAt.Unix(), "story_type": int64(0),
			"is_debug": int64(0), "is_old_top": int64(0),
		}}
	default:
		return httpedge.Response{HTTPStatus: http.StatusNotImplemented, Body: map[string]any{"error": "not_bootstrap_mid"}}
	}
}

func stringParam(m map[string]any, key string) string {
	v, _ := m[key].(string)
	return v
}

func bootstrapFailure(err error) httpedge.Response {
	switch {
	case errors.Is(err, logicalserver.ErrServerFull):
		// Recovered stock semantic: new-character capacity failure only.
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{"error_code": int64(20018), "error_msg": ""}}
	case errors.Is(err, appboot.ErrAccountAuth):
		// Exact private auth semantic code is not source-recovered. Keep auth
		// rejection as transport failure rather than inventing a stock code.
		return httpedge.Response{HTTPStatus: http.StatusForbidden, Body: map[string]any{"error": "account_auth_failed"}}
	case errors.Is(err, logicalserver.ErrObservationRequired):
		return httpedge.Response{HTTPStatus: http.StatusConflict, Body: map[string]any{"error": "server_observation_required"}}
	case errors.Is(err, logicalserver.ErrExistingLoginClosed):
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "server_login_closed"}}
	default:
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "bootstrap_failed"}}
	}
}
