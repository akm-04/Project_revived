package stockruntime

import (
	"context"
	"errors"
	"net/http"

	guildproj "gxb.local/backend/v2/internal/adapters/guildwire"
	"gxb.local/backend/v2/internal/application/guildcore"
	"gxb.local/backend/v2/internal/application/guildview"
	apprealtime "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// GuildCorePort is the mutation surface I6C exposes to the stock adapter. The
// adapter owns only request/response compatibility; Guild remains gameplay
// authority in the application/domain layer.
type GuildCorePort interface {
	Create(context.Context, identity.ActorContext, guildcore.CreateRequest, operation.Context) (guildcore.CreateResult, error)
	ApplyOrJoin(context.Context, identity.ActorContext, guild.ID, operation.Context) (guildcore.ApplyResult, error)
	CancelApplication(context.Context, identity.ActorContext, guild.ID, operation.Context) (guildcore.AckResult, error)
	RefuseApplication(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (guildcore.AckResult, error)
	AcceptApplication(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (guildcore.AckResult, error)
	Leave(context.Context, identity.ActorContext, operation.Context) (guildcore.AckResult, error)
	Dissolve(context.Context, identity.ActorContext, operation.Context) (guildcore.AckResult, error)
	UpdateDescription(context.Context, identity.ActorContext, string, operation.Context) (guildcore.AckResult, error)
	UpdateSettings(context.Context, identity.ActorContext, guildcore.SettingsRequest, operation.Context) (guildcore.AckResult, error)
	Kick(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (guildcore.AckResult, error)
	SetRole(context.Context, identity.ActorContext, guildcore.RoleRequest, operation.Context) (guildcore.AckResult, error)
	Invite(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (guildcore.AckResult, error)
	AcceptInvite(context.Context, identity.ActorContext, guild.ID, operation.Context) (guildcore.AckResult, error)
}

// GuildViewPort is intentionally read-only. Presentation-only fields are added
// by the Guild wire adapter and never become Guild canonical state.
type GuildViewPort interface {
	Self(context.Context, identity.ActorContext) (guildview.SelfGuild, bool, error)
	Other(context.Context, identity.ActorContext, guild.ID) (guildview.SelfGuild, bool, error)
	Members(context.Context, identity.ActorContext) (guildview.GuildInfo, []guildview.Member, error)
	Guilds(context.Context, identity.ActorContext, int) ([]guildview.GuildInfo, error)
	Applicants(context.Context, identity.ActorContext) ([]guildview.Applicant, error)
	PlayerApplications(context.Context, identity.ActorContext) ([]guildview.GuildInfo, error)
	GuildForPlayer(context.Context, identity.ActorContext, identity.PlayerID) (guildview.GuildInfo, bool, error)
}

type GuildDispatcher struct {
	Authority apprealtime.GameplayAuthorityPort
	Core      GuildCorePort
	View      GuildViewPort
}

func (d GuildDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	actor, fail := d.guildActor(ctx, req)
	if fail != nil {
		return *fail
	}
	if d.View == nil {
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "guild_view_unavailable"}}
	}

	switch req.Envelope.MID {
	case 576: // LOAD_ALL_TEAMS
		rows, err := d.View.Guilds(ctx, actor, 200)
		if err != nil {
			return failGuild(err)
		}
		return okGuild(map[string]any{"guild_infos": guildproj.InfoList(rows)})
	case 579: // LOAD_TEAM_BY_ID: canonical self Guild/member roster
		info, members, err := d.View.Members(ctx, actor)
		if err != nil {
			return failGuild(err)
		}
		return okGuild(guildproj.Roster(info, members))
	case 581: // LOAD_APPLY_LIST_TEAM
		rows, err := d.View.Applicants(ctx, actor)
		if err != nil {
			return failGuild(err)
		}
		return jsonGuild(guildproj.ApplicantList(rows))
	case 598: // PLAYER_LOAD_APPLY_LIST_TEAM
		rows, err := d.View.PlayerApplications(ctx, actor)
		if err != nil {
			return failGuild(err)
		}
		return jsonGuild(guildproj.InfoList(rows))
	case 612: // GET_SELF_GUILD; stock also uses guild_id to inspect another Guild
		if raw, ok := req.Envelope.Params["guild_id"]; ok && raw != nil {
			gid, err := requiredInt64(req.Envelope.Params, "guild_id")
			if err != nil || gid <= 0 {
				return badGuild("invalid_guild_id")
			}
			out, found, err := d.View.Other(ctx, actor, guild.ID(gid))
			if err != nil {
				return failGuild(err)
			}
			if !found {
				return okGuild(guildproj.EmptySelf())
			}
			return okGuild(guildproj.Other(out))
		}
		out, found, err := d.View.Self(ctx, actor)
		if err != nil {
			return failGuild(err)
		}
		if !found {
			return okGuild(guildproj.EmptySelf())
		}
		return okGuild(guildproj.Self(out))
	case 2565: // GET_GUILD_INFO by player_id
		pid, err := requiredInt64(req.Envelope.Params, "player_id")
		if err != nil || pid <= 0 {
			return badGuild("invalid_player_id")
		}
		info, found, err := d.View.GuildForPlayer(ctx, actor, identity.PlayerID(pid))
		if err != nil {
			return failGuild(err)
		}
		if !found {
			return httpedge.Response{HTTPStatus: http.StatusNotFound, Body: map[string]any{"error": "guild_not_found"}}
		}
		return okGuild(guildproj.Detail2565(info))
	}

	if d.Core == nil {
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "guild_core_unavailable"}}
	}
	op := req.Envelope.Operation
	switch req.Envelope.MID {
	case 577: // CREATE_TEAM
		name, _ := req.Envelope.Params["name"].(string)
		icon, e1 := requiredInt64(req.Envelope.Params, "icon")
		frame, e2 := requiredInt64(req.Envelope.Params, "icon_frame")
		if e1 != nil || e2 != nil || name == "" {
			return badGuild("invalid_create")
		}
		_, err := d.Core.Create(ctx, actor, guildcore.CreateRequest{Name: name, Icon: icon, IconFrame: frame}, op)
		return guildMutationResult(err)
	case 578: // DISSOLUTION_TEAM
		_, err := d.Core.Dissolve(ctx, actor, op)
		return guildMutationResult(err)
	case 580: // APPLY_TEAM
		gid, err := requiredInt64(req.Envelope.Params, "guild_id")
		if err != nil || gid <= 0 {
			return badGuild("invalid_guild_id")
		}
		_, err = d.Core.ApplyOrJoin(ctx, actor, guild.ID(gid), op)
		return guildMutationResult(err)
	case 582: // ACCEPT_APPLY_TEAM
		pid, err := requiredInt64(req.Envelope.Params, "apply_player_id")
		if err != nil || pid <= 0 {
			return badGuild("invalid_player_id")
		}
		if _, err = d.Core.AcceptApplication(ctx, actor, identity.PlayerID(pid), op); err != nil {
			return guildMutationResult(err)
		}
		rows, err := d.View.Applicants(ctx, actor)
		if err != nil {
			return failGuild(err)
		}
		return jsonGuild(guildproj.ApplicantList(rows))
	case 583: // REFUSE_APPLY_TEAM
		pid, err := requiredInt64(req.Envelope.Params, "apply_player_id")
		if err != nil || pid <= 0 {
			return badGuild("invalid_player_id")
		}
		if _, err = d.Core.RefuseApplication(ctx, actor, identity.PlayerID(pid), op); err != nil {
			return guildMutationResult(err)
		}
		rows, err := d.View.Applicants(ctx, actor)
		if err != nil {
			return failGuild(err)
		}
		return jsonGuild(guildproj.ApplicantList(rows))
	case 584: // LEAVE_TEAM
		_, err := d.Core.Leave(ctx, actor, op)
		return guildMutationResult(err)
	case 585: // UPDATE_DES_TEAM
		des, ok := req.Envelope.Params["des"].(string)
		if !ok {
			return badGuild("invalid_description")
		}
		_, err := d.Core.UpdateDescription(ctx, actor, des, op)
		return guildMutationResult(err)
	case 586: // APPOINT_JOB_TEAM
		pid, e1 := requiredInt64(req.Envelope.Params, "member_id")
		role, e2 := requiredInt64(req.Envelope.Params, "job")
		if e1 != nil || e2 != nil || pid <= 0 || role < int64(guild.Member) || role > int64(guild.Deputy) {
			return badGuild("invalid_role_change")
		}
		if _, err := d.Core.SetRole(ctx, actor, guildcore.RoleRequest{MemberID: identity.PlayerID(pid), Role: guild.Role(role)}, op); err != nil {
			return guildMutationResult(err)
		}
		_, members, err := d.View.Members(ctx, actor)
		if err != nil {
			return failGuild(err)
		}
		return jsonGuild(guildproj.MemberList(members))
	case 587: // KICK_TEAM
		pid, err := requiredInt64(req.Envelope.Params, "member_id")
		if err != nil || pid <= 0 {
			return badGuild("invalid_player_id")
		}
		if _, err = d.Core.Kick(ctx, actor, identity.PlayerID(pid), op); err != nil {
			return guildMutationResult(err)
		}
		_, members, err := d.View.Members(ctx, actor)
		if err != nil {
			return failGuild(err)
		}
		return jsonGuild(guildproj.MemberList(members))
	case 589: // SETTING_TEAM
		name, _ := req.Envelope.Params["name"].(string)
		icon, e1 := requiredInt64(req.Envelope.Params, "icon")
		frame, e2 := requiredInt64(req.Envelope.Params, "icon_frame")
		minLevel, e3 := requiredInt64(req.Envelope.Params, "min_allow_level")
		applyType, e4 := requiredInt64(req.Envelope.Params, "apply_type")
		if e1 != nil || e2 != nil || e3 != nil || e4 != nil || name == "" || applyType < 0 || applyType > 2 {
			return badGuild("invalid_settings")
		}
		_, err := d.Core.UpdateSettings(ctx, actor, guildcore.SettingsRequest{Name: name, Icon: icon, IconFrame: frame, MinAllowLevel: minLevel, ApplyType: guild.ApplyType(applyType)}, op)
		return guildMutationResult(err)
	case 599: // CANCEL_APPLY_TEAM
		gid, err := requiredInt64(req.Envelope.Params, "guild_id")
		if err != nil || gid <= 0 {
			return badGuild("invalid_guild_id")
		}
		_, err = d.Core.CancelApplication(ctx, actor, guild.ID(gid), op)
		return guildMutationResult(err)
	case 2563: // INVITE_TO_GUILD
		pid, err := requiredInt64(req.Envelope.Params, "player_id")
		if err != nil || pid <= 0 {
			return badGuild("invalid_player_id")
		}
		_, err = d.Core.Invite(ctx, actor, identity.PlayerID(pid), op)
		return guildMutationResult(err)
	case 2564: // ACCEPT_INVITE_TO_GUILD
		gid, err := requiredInt64(req.Envelope.Params, "guild_id")
		if err != nil || gid <= 0 {
			return badGuild("invalid_guild_id")
		}
		_, err = d.Core.AcceptInvite(ctx, actor, guild.ID(gid), op)
		return guildMutationResult(err)
	default:
		return httpedge.Response{HTTPStatus: http.StatusNotImplemented, Body: map[string]any{"error": "not_i6c_guild_mid"}}
	}
}

func (d GuildDispatcher) guildActor(ctx context.Context, req httpedge.DispatchRequest) (identity.ActorContext, *httpedge.Response) {
	if d.Authority == nil || req.Envelope.Claims.Token == "" {
		r := httpedge.Response{HTTPStatus: http.StatusUnauthorized, Body: map[string]any{"error": "gameplay_auth_required"}}
		return identity.ActorContext{}, &r
	}
	a, err := d.Authority.ResolveGameplayBearer(ctx, req.Envelope.Claims.Token, req.Envelope.ReceivedAt)
	if err != nil {
		r := authFailure(err)
		return identity.ActorContext{}, &r
	}
	if req.Envelope.Claims.Region != int64(a.LogicalServerID) {
		r := httpedge.Response{HTTPStatus: http.StatusForbidden, Body: map[string]any{"error": "region_mismatch"}}
		return identity.ActorContext{}, &r
	}
	return a, nil
}

func okGuild(body map[string]any) httpedge.Response {
	return httpedge.Response{HTTPStatus: http.StatusOK, Body: body}
}
func jsonGuild(v any) httpedge.Response {
	return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{}, JSON: v}
}
func badGuild(code string) httpedge.Response {
	return httpedge.Response{HTTPStatus: http.StatusBadRequest, Body: map[string]any{"error": code}}
}
func guildMutationResult(err error) httpedge.Response {
	if err == nil {
		return okGuild(map[string]any{})
	}
	if r, ok := sourceGuildProtocolError(err); ok {
		return r
	}
	return failGuild(err)
}

// sourceGuildProtocolError exposes only Guild application codes whose semantics
// are present in the hash-bound effective-client message table. SOURCE_FACT:
// Backend.lua treats HTTP 200 as a successful transport callback while the body
// may still carry error_code. Fields beyond the recovered message semantics are
// intentionally not invented.
func sourceGuildProtocolError(err error) (httpedge.Response, bool) {
	body := map[string]any{}
	var wait *guildcore.CantJoinError
	if errors.As(err, &wait) {
		switch wait.Kind {
		case guildcore.JoinCooldownOtherGuild:
			body["error_code"] = int64(30010)
			body["time"] = wait.RemainingSeconds
			return okGuild(body), true
		case guildcore.JoinCooldownSameGuild:
			body["error_code"] = int64(30011)
			return okGuild(body), true
		default:
			return httpedge.Response{}, false
		}
	}
	var code int64
	switch {
	case errors.Is(err, guildcore.ErrJoinLimit):
		code = 30012
	case errors.Is(err, guildcore.ErrApplicationLimit):
		code = 30013
	case errors.Is(err, guildcore.ErrGuildClosed):
		code = 30014
	case errors.Is(err, guildcore.ErrGuildNotFound), errors.Is(err, guildcore.ErrGuildRetired):
		code = 30015
	case errors.Is(err, guildcore.ErrGuildApplicationFull):
		code = 30016
	case errors.Is(err, guildcore.ErrDissolveRequiresSolo):
		code = 30017
	case errors.Is(err, guildcore.ErrDeputyLimit):
		code = 30018
	case errors.Is(err, guildcore.ErrGuildNameTaken):
		code = 30019
	case errors.Is(err, guildcore.ErrGuildFull):
		code = 30020
	default:
		return httpedge.Response{}, false
	}
	body["error_code"] = code
	return okGuild(body), true
}

func failGuild(err error) httpedge.Response {
	switch {
	case errors.Is(err, guildcore.ErrGuildNotFound), errors.Is(err, guildcore.ErrApplicationNotFound), errors.Is(err, guildcore.ErrInviteNotFound):
		return httpedge.Response{HTTPStatus: http.StatusNotFound, Body: map[string]any{"error": "guild_not_found"}}
	case errors.Is(err, guildcore.ErrGuildPermission), errors.Is(err, guildcore.ErrNotGuildMember):
		return httpedge.Response{HTTPStatus: http.StatusForbidden, Body: map[string]any{"error": "guild_forbidden"}}
	case errors.Is(err, guildcore.ErrAlreadyInGuild), errors.Is(err, guildcore.ErrGuildRetired), errors.Is(err, guildcore.ErrGuildClosed),
		errors.Is(err, guildcore.ErrGuildFull), errors.Is(err, guildcore.ErrGuildApplicationFull), errors.Is(err, guildcore.ErrGuildNameTaken), errors.Is(err, guildcore.ErrApplicationLimit), errors.Is(err, guildcore.ErrJoinLimit),
		errors.Is(err, guildcore.ErrLevelTooLow), errors.Is(err, guildcore.ErrApplicantLimit), errors.Is(err, guildcore.ErrInviteExpired),
		errors.Is(err, guildcore.ErrInviteLimit), errors.Is(err, guildcore.ErrTargetAlreadyMember), errors.Is(err, guildcore.ErrTargetNotMember),
		errors.Is(err, guildcore.ErrCannotLeaveLeader), errors.Is(err, guildcore.ErrDissolveRequiresSolo), errors.Is(err, guildcore.ErrDeputyLimit), errors.Is(err, guildcore.ErrInvalidRoleChange),
		errors.Is(err, guildcore.ErrInvalidDescription), errors.Is(err, guildcore.ErrInvalidSettings), errors.Is(err, guildcore.ErrInvalidGuildPolicyInput),
		errors.Is(err, economy.ErrInsufficientBalance):
		// Exact historical numeric codes for these policy denials are not
		// source-recovered. Keep them fail-closed instead of fabricating codes.
		return httpedge.Response{HTTPStatus: http.StatusConflict, Body: map[string]any{"error": "guild_policy_rejected"}}
	default:
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: err, Body: map[string]any{"error": "guild_operation_failed"}}
	}
}
