package stockruntime

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/application/guildbroadcast"
	"gxb.local/backend/v2/internal/application/realtimeauth"
	gb "gxb.local/backend/v2/internal/domain/guildbroadcast"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"net/http"
)

const GuildBroadcastStockGroup = "GUILD_BROADCAST_STOCK_I7A8A"

type GuildBroadcastCommands interface {
	Submit(context.Context, identity.ActorContext, gb.Request, operation.Context) (guildbroadcast.SubmitResult, error)
}

// PreparedGuildBroadcast is constructed only from complete source dependencies.
// Enable validates the active catalog; it never installs or changes its pointer.
type PreparedGuildBroadcast struct {
	service   guildbroadcast.Service
	authority realtimeauth.GameplayAuthorityPort
	prepared  bool
}
type GuildBroadcastDispatcher struct {
	command   GuildBroadcastCommands
	authority realtimeauth.GameplayAuthorityPort
	ready     bool
}

func PrepareGuildBroadcast(a realtimeauth.GameplayAuthorityPort, s guildbroadcast.Service) (PreparedGuildBroadcast, error) {
	if a == nil || s.Timed.Binder.Time == nil || s.Timed.Runner.DB == nil || s.Reads.DB == nil || s.Fresh == nil || s.Store == nil || s.Guild == nil || s.Names == nil || s.Players == nil || s.Fence == nil || s.Receipts == nil || s.Content == nil || s.Enqueue == nil {
		return PreparedGuildBroadcast{}, errors.New("incomplete " + GuildBroadcastStockGroup)
	}
	return PreparedGuildBroadcast{service: s, authority: a, prepared: true}, nil
}
func (p PreparedGuildBroadcast) Enable(c context.Context, q tx.Queryer) (GuildBroadcastDispatcher, error) {
	if !p.prepared || q == nil {
		return GuildBroadcastDispatcher{}, errors.New("unprepared " + GuildBroadcastStockGroup)
	}
	if e := p.service.Store.ValidateSchema(c, q); e != nil {
		return GuildBroadcastDispatcher{}, e
	}
	rev, e := p.service.Content.ActiveRevision(c, q)
	if e != nil {
		return GuildBroadcastDispatcher{}, e
	}
	policy, e := p.service.Content.ReadBroadcastPolicy(c, q, rev)
	if e != nil {
		return GuildBroadcastDispatcher{}, e
	}
	if e = policy.Validate(); e != nil {
		return GuildBroadcastDispatcher{}, e
	}
	return GuildBroadcastDispatcher{command: p.service, authority: p.authority, ready: true}, nil
}
func (d GuildBroadcastDispatcher) Dispatch(c context.Context, r httpedge.DispatchRequest) httpedge.Response {
	if !d.ready || d.command == nil || d.authority == nil {
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "guild_broadcast_unavailable"}}
	}
	if r.Envelope.MID != 588 {
		return httpedge.Response{HTTPStatus: http.StatusNotImplemented, Body: map[string]any{"error": "not_guild_broadcast_mid"}}
	}
	actor, fail := (GuildDispatcher{Authority: d.authority}).guildActor(c, r)
	if fail != nil {
		return *fail
	}
	fields, e := socialFields(r.Envelope.Params, "title", "content")
	if e != nil || len(fields) != 2 {
		return badGuild("invalid_broadcast_fields")
	}
	title, ok := fields["title"].(string)
	if !ok {
		return badGuild("invalid_broadcast_title")
	}
	content, ok := fields["content"].(string)
	if !ok {
		return badGuild("invalid_broadcast_content")
	}
	request := gb.Request{Title: title, Content: content}
	if e = request.Validate(); e != nil {
		return badGuild("invalid_broadcast_text")
	}
	_, e = d.command.Submit(c, actor, request, r.Envelope.Operation)
	if e == nil {
		return okGuild(map[string]any{})
	}
	if errors.Is(e, guildbroadcast.ErrLeader) {
		return httpedge.Response{HTTPStatus: http.StatusForbidden, Body: map[string]any{"error": "guild_leader_required"}}
	}
	return failGuild(e)
}
