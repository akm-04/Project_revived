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
	// GUILD_RANK answers before any view dependency: the client reads no field
	// and only checks transport success; refusing suppresses the World Boss
	// board (I9_GUILD_ACTIVITY_V1 C11).
	if req.Envelope.MID == 616 {
		return okGuild(map[string]any{})
	}
	if d.View == nil {
		return failureReply(defect(nil))
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
			return failureReply(refusal(unprovenRefusalCode))
		}
		return okGuild(guildproj.Detail2565(info))
	}

	if d.Core == nil {
		return failureReply(defect(nil))
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
		return failureReply(refusal(unprovenRefusalCode))
	}
}

func (d GuildDispatcher) guildActor(ctx context.Context, req httpedge.DispatchRequest) (identity.ActorContext, *httpedge.Response) {
	if d.Authority == nil {
		r := failureReply(defect(nil))
		return identity.ActorContext{}, &r
	}
	if req.Envelope.Claims.Token == "" {
		r := failureReply(sessionFailure())
		return identity.ActorContext{}, &r
	}
	a, err := d.Authority.ResolveGameplayBearer(ctx, req.Envelope.Claims.Token, req.Envelope.ReceivedAt)
	if err != nil {
		r := authFailure(err)
		return identity.ActorContext{}, &r
	}
	if req.Envelope.Claims.Region != int64(a.LogicalServerID) {
		r := failureReply(refusal(unprovenRefusalCode))
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
	return failureReply(malformed(code))
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
// Backend.lua treats any HTTP 200 as a successful transport callback; a stock
// callback therefore runs its success branch even though the body carries an
// error_code. These refusals answer 409 so the callback takes its error branch
// while Backend.lua still shows the message table's toast for error_code.
func sourceGuildProtocolError(err error) (httpedge.Response, bool) {
	var wait *guildcore.CantJoinError
	if errors.As(err, &wait) {
		switch wait.Kind {
		case guildcore.JoinCooldownOtherGuild:
			return failureReply(refusalWithBody(30010, map[string]any{"time": wait.RemainingSeconds})), true
		case guildcore.JoinCooldownSameGuild:
			return failureReply(refusal(30011)), true
		default:
			return httpedge.Response{}, false
		}
	}
	switch {
	case errors.Is(err, guildcore.ErrJoinLimit):
		return failureReply(refusal(30012)), true
	case errors.Is(err, guildcore.ErrApplicationLimit):
		return failureReply(refusal(30013)), true
	case errors.Is(err, guildcore.ErrGuildClosed):
		return failureReply(refusal(30014)), true
	case errors.Is(err, guildcore.ErrGuildNotFound), errors.Is(err, guildcore.ErrGuildRetired):
		return failureReply(refusal(30015)), true
	case errors.Is(err, guildcore.ErrGuildApplicationFull):
		return failureReply(refusal(30016)), true
	case errors.Is(err, guildcore.ErrDissolveRequiresSolo):
		return failureReply(refusal(30017)), true
	case errors.Is(err, guildcore.ErrDeputyLimit):
		return failureReply(refusal(30018)), true
	case errors.Is(err, guildcore.ErrGuildNameTaken):
		return failureReply(refusal(30019)), true
	case errors.Is(err, guildcore.ErrGuildFull):
		return failureReply(refusal(30020)), true
	default:
		return httpedge.Response{}, false
	}
}

// The mapper table marks Guild not-found and permission rows "preserve": their
// 404/403 statuses sit outside F4's refusal/fault classes, as do bootstrap auth
// statuses (D5 amendment, mapper table distinctions).
var guildFailureRows = []failureRow{
	{match: guildcore.ErrGuildClosed, class: failureRefusal, code: 30014},
	{match: guildcore.ErrGuildFull, class: failureRefusal, code: 30020},
	{match: guildcore.ErrGuildApplicationFull, class: failureRefusal, code: 30016},
	{match: guildcore.ErrGuildNameTaken, class: failureRefusal, code: 30019},
	{match: guildcore.ErrApplicationLimit, class: failureRefusal, code: 30013},
	{match: guildcore.ErrJoinLimit, class: failureRefusal, code: 30012},
	{match: guildcore.ErrDissolveRequiresSolo, class: failureRefusal, code: 30017},
	{match: guildcore.ErrDeputyLimit, class: failureRefusal, code: 30018},
	{match: guildcore.ErrAlreadyInGuild, class: failureRefusal, code: unprovenRefusalCode},
	{match: guildcore.ErrGuildRetired, class: failureRefusal, code: unprovenRefusalCode},
	{match: guildcore.ErrLevelTooLow, class: failureRefusal, code: unprovenRefusalCode},
	{match: guildcore.ErrApplicantLimit, class: failureRefusal, code: unprovenRefusalCode},
	{match: guildcore.ErrInviteExpired, class: failureRefusal, code: unprovenRefusalCode},
	{match: guildcore.ErrInviteLimit, class: failureRefusal, code: unprovenRefusalCode},
	{match: guildcore.ErrTargetAlreadyMember, class: failureRefusal, code: unprovenRefusalCode},
	{match: guildcore.ErrTargetNotMember, class: failureRefusal, code: unprovenRefusalCode},
	{match: guildcore.ErrCannotLeaveLeader, class: failureRefusal, code: unprovenRefusalCode},
	{match: guildcore.ErrInvalidRoleChange, class: failureMalformed, detail: "guild_invalid_parameter"},
	{match: guildcore.ErrInvalidDescription, class: failureMalformed, detail: "guild_invalid_parameter"},
	{match: guildcore.ErrInvalidSettings, class: failureMalformed, detail: "guild_invalid_parameter"},
	{match: guildcore.ErrInvalidGuildPolicyInput, class: failureMalformed, detail: "guild_invalid_parameter"},
	{match: economy.ErrInsufficientBalance, class: failureRefusal, balance: true},
}

// guildNotFoundCode is message.lua row 30015 ("Can't find the guild"), the
// only guild-specific not-found text in the stock table. There is no stock row
// for "not a member" or "no permission", so those refusals use 35028.
const guildNotFoundCode int64 = 30015

func failGuild(err error) httpedge.Response {
	switch {
	case errors.Is(err, guildcore.ErrGuildNotFound):
		return failureReply(refusal(guildNotFoundCode))
	case errors.Is(err, guildcore.ErrApplicationNotFound), errors.Is(err, guildcore.ErrInviteNotFound),
		errors.Is(err, guildcore.ErrGuildPermission), errors.Is(err, guildcore.ErrNotGuildMember), errors.Is(err, guildview.ErrForbidden):
		return failureReply(refusal(unprovenRefusalCode))
	}
	return failureFromRows(guildFailureRows, err)
}
