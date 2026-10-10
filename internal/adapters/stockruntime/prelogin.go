package stockruntime

import (
	"context"
	"net/http"
	"strings"

	"gxb.local/backend/v2/internal/projection/lobby"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/mids"
)

// PreloginDispatcher owns only the stock-client public pre-context HTTP plane.
// These responses carry no account/gameplay authority and perform no mutation.
type PreloginDispatcher struct {
	PublicEngineURL string
	Tracker         *lobby.BootTracker
}

func (d PreloginDispatcher) Dispatch(_ context.Context, req httpedge.DispatchRequest) httpedge.Response {
	if d.Tracker != nil {
		_ = d.Tracker.Record(lobby.BootEvent{MID: req.Envelope.MID, Kind: lobby.BootPrelogin, Phase: lobby.PhaseClientRequestObserved, At: req.Envelope.ReceivedAt})
	}
	switch req.Envelope.MID {
	case mids.MIDCenterDiscovery:
		if strings.TrimSpace(d.PublicEngineURL) == "" {
			return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "public_engine_url_unconfigured"}}
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{
			"url": d.PublicEngineURL, "server_id": int64(1), "back_domain": "", "res_download_url": "",
		}}
	case mids.MIDVersionCheck:
		// Honest no-update projection. I4 owns compatibility/bootstrap, not OTA publishing.
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{
			"is_appstore": int64(0), "is_inapp": int64(0), "is_review": int64(0), "need_restart": int64(0),
		}}
	case 7: // LOAD_ANNOUNCE: LoginWindow json-decodes this field.
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{"contents": "{\"contents\":[]}"}}
	case 2864: // GET_PLAYER_GROUP_BY_KEY: source consumes a JSON scalar.
		key, _ := req.Envelope.Params["unique_key"].(string)
		if strings.EqualFold(strings.TrimSpace(key), "mtspy") {
			return httpedge.Response{HTTPStatus: http.StatusOK, JSON: "B"}
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, JSON: "A"}
	default:
		return httpedge.Response{HTTPStatus: http.StatusNotImplemented, Body: map[string]any{"error": "not_prelogin_mid"}}
	}
}
