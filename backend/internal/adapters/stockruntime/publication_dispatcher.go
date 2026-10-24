package stockruntime

import (
	"context"
	app "gxb.local/backend/v2/internal/application/publication"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	pub "gxb.local/backend/v2/internal/domain/publication"
	"gxb.local/backend/v2/internal/projection/lobby"
	proj "gxb.local/backend/v2/internal/projection/publication"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

type PublicationDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   app.Service
	Tracker   *lobby.BootTracker
}

func (d PublicationDispatcher) Dispatch(c context.Context, r httpedge.DispatchRequest) httpedge.Response {
	if !onlyStockGameplayParams(r.Envelope.Params) {
		return httpedge.Response{HTTPStatus: 400, Body: map[string]any{"error": "invalid_publication_params"}}
	}
	if r.Envelope.MID == 7 && d.Tracker != nil {
		_ = d.Tracker.Record(lobby.BootEvent{MID: 7, Kind: lobby.BootPrelogin, Phase: lobby.PhaseClientRequestObserved, At: r.Envelope.ReceivedAt})
	}
	var actor identity.ActorContext
	if r.Envelope.MID != 7 {
		if d.Authority == nil || r.Envelope.Claims.Token == "" {
			return httpedge.Response{HTTPStatus: 401, Body: map[string]any{"error": "gameplay_auth_required"}}
		}
		var e error
		actor, e = d.Authority.ResolveGameplayBearer(c, r.Envelope.Claims.Token, r.Envelope.ReceivedAt)
		if e != nil {
			return authFailure(e)
		}
		if r.Envelope.Claims.Region != int64(actor.LogicalServerID) {
			return httpedge.Response{HTTPStatus: 403, Body: map[string]any{"error": "region_mismatch"}}
		}
	}
	unavailable := func() httpedge.Response {
		return httpedge.Response{HTTPStatus: 503, Body: map[string]any{"error": "publication_unavailable"}}
	}
	if r.Envelope.MID == 8194 {
		if e := d.Service.Mark(c, r.Envelope.Operation, actor); e != nil {
			return unavailable()
		}
		return httpedge.Response{HTTPStatus: 200, Body: map[string]any{}}
	}
	family := pub.Announcement
	switch r.Envelope.MID {
	case 7:
	case 1537:
		family = pub.Board
	case 8193:
		family = pub.Picture
	default:
		return httpedge.Response{HTTPStatus: 501, Body: map[string]any{"error": "not_publication"}}
	}
	v, e := d.Service.Read(c, r.Envelope.Operation, family, actor.LogicalServerID, actor.PlayerID)
	if e != nil {
		return unavailable()
	}
	var body map[string]any
	switch family {
	case pub.Announcement:
		body, e = proj.Announcement(v)
	case pub.Board:
		body, e = proj.Board(v)
	case pub.Picture:
		body = proj.Picture(v)
	}
	if e != nil {
		return unavailable()
	}
	if r.Envelope.MID == 8193 && d.Tracker != nil {
		_ = d.Tracker.Record(d.Tracker.Correlate(lobby.BootEvent{MID: 8193, Kind: lobby.BootExplicitHTTP, Phase: lobby.PhaseClientRequestObserved, At: r.Envelope.ReceivedAt}, actor.SessionID.UUID().String(), actor.ContextID.UUID().String(), ""))
	}
	return httpedge.Response{HTTPStatus: 200, Body: body}
}
