package stockruntime

import (
	"context"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/guildcore"
	"gxb.local/backend/v2/internal/application/guildview"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
)

type fakeGuildCore struct {
	applyErr error
	seenGID  guild.ID
}

func (f *fakeGuildCore) Create(context.Context, identity.ActorContext, guildcore.CreateRequest, operation.Context) (guildcore.CreateResult, error) {
	return guildcore.CreateResult{}, nil
}
func (f *fakeGuildCore) ApplyOrJoin(_ context.Context, _ identity.ActorContext, gid guild.ID, _ operation.Context) (guildcore.ApplyResult, error) {
	f.seenGID = gid
	return guildcore.ApplyResult{}, f.applyErr
}
func (f *fakeGuildCore) CancelApplication(context.Context, identity.ActorContext, guild.ID, operation.Context) (guildcore.AckResult, error) {
	return guildcore.AckResult{}, nil
}
func (f *fakeGuildCore) RefuseApplication(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (guildcore.AckResult, error) {
	return guildcore.AckResult{}, nil
}
func (f *fakeGuildCore) AcceptApplication(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (guildcore.AckResult, error) {
	return guildcore.AckResult{}, nil
}
func (f *fakeGuildCore) Leave(context.Context, identity.ActorContext, operation.Context) (guildcore.AckResult, error) {
	return guildcore.AckResult{}, nil
}
func (f *fakeGuildCore) Dissolve(context.Context, identity.ActorContext, operation.Context) (guildcore.AckResult, error) {
	return guildcore.AckResult{}, nil
}
func (f *fakeGuildCore) UpdateDescription(context.Context, identity.ActorContext, string, operation.Context) (guildcore.AckResult, error) {
	return guildcore.AckResult{}, nil
}
func (f *fakeGuildCore) UpdateSettings(context.Context, identity.ActorContext, guildcore.SettingsRequest, operation.Context) (guildcore.AckResult, error) {
	return guildcore.AckResult{}, nil
}
func (f *fakeGuildCore) Kick(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (guildcore.AckResult, error) {
	return guildcore.AckResult{}, nil
}
func (f *fakeGuildCore) SetRole(context.Context, identity.ActorContext, guildcore.RoleRequest, operation.Context) (guildcore.AckResult, error) {
	return guildcore.AckResult{}, nil
}
func (f *fakeGuildCore) Invite(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (guildcore.AckResult, error) {
	return guildcore.AckResult{}, nil
}
func (f *fakeGuildCore) AcceptInvite(context.Context, identity.ActorContext, guild.ID, operation.Context) (guildcore.AckResult, error) {
	return guildcore.AckResult{}, nil
}

type fakeGuildView struct {
	self guildview.SelfGuild
}

func (f fakeGuildView) Self(context.Context, identity.ActorContext) (guildview.SelfGuild, bool, error) {
	if f.self.GuildInfo.GuildID == 0 {
		return guildview.SelfGuild{}, false, nil
	}
	return f.self, true, nil
}
func (f fakeGuildView) Other(context.Context, identity.ActorContext, guild.ID) (guildview.SelfGuild, bool, error) {
	return f.self, f.self.GuildInfo.GuildID != 0, nil
}
func (f fakeGuildView) Members(context.Context, identity.ActorContext) (guildview.GuildInfo, []guildview.Member, error) {
	return f.self.GuildInfo, []guildview.Member{{PlayerID: 100001, Role: 1, LastTime: 0, SevenVitality: 0, CopyChallengeTime: 0}}, nil
}
func (f fakeGuildView) Guilds(context.Context, identity.ActorContext, int) ([]guildview.GuildInfo, error) {
	return []guildview.GuildInfo{f.self.GuildInfo}, nil
}
func (f fakeGuildView) Applicants(context.Context, identity.ActorContext) ([]guildview.Applicant, error) {
	return []guildview.Applicant{{PlayerID: 100002, Name: "p"}}, nil
}
func (f fakeGuildView) PlayerApplications(context.Context, identity.ActorContext) ([]guildview.GuildInfo, error) {
	return []guildview.GuildInfo{f.self.GuildInfo}, nil
}
func (f fakeGuildView) GuildForPlayer(context.Context, identity.ActorContext, identity.PlayerID) (guildview.GuildInfo, bool, error) {
	return f.self.GuildInfo, f.self.GuildInfo.GuildID != 0, nil
}

func guildReq(mid uint16, params map[string]any, now time.Time) interface{} { return nil }

func TestGuildDispatcherMID612AndDirectArrayShapes(t *testing.T) {
	actor := actorForHTTP(t)
	v := fakeGuildView{self: guildview.SelfGuild{GuildInfo: guildview.GuildInfo{GuildID: 1000001, Name: "g", MemberNum: 1, GuildLeader: 100001, GuildLeaderName: "p"}, SelfRole: 1, MemberNum: 1}}
	d := GuildDispatcher{Authority: httpAuthority{actor}, Core: &fakeGuildCore{}, View: v}
	now := time.Unix(100, 0).UTC()
	r := d.Dispatch(context.Background(), env(612, nil, now))
	if r.HTTPStatus != 200 || r.Body["member_nums"] != int64(1) {
		t.Fatalf("612=%+v", r)
	}
	r = d.Dispatch(context.Background(), env(581, nil, now))
	arr, ok := r.JSON.([]any)
	if r.HTTPStatus != 200 || !ok || len(arr) != 1 {
		t.Fatalf("581=%+v", r)
	}
	r = d.Dispatch(context.Background(), env(579, nil, now))
	if r.HTTPStatus != 200 || r.Body["guild_id"] != int64(1000001) {
		t.Fatalf("579=%+v", r)
	}
}

func TestGuildDispatcherRecoveredCooldownProtocolShapes(t *testing.T) {
	actor := actorForHTTP(t)
	core := &fakeGuildCore{applyErr: &guildcore.CantJoinError{Kind: guildcore.JoinCooldownOtherGuild, RemainingSeconds: 77}}
	d := GuildDispatcher{Authority: httpAuthority{actor}, Core: core, View: fakeGuildView{}}
	now := time.Unix(100, 0).UTC()
	rq := env(580, nil, now)
	rq.Envelope.Params["guild_id"] = int64(1000001)
	r := d.Dispatch(context.Background(), rq)
	if r.HTTPStatus != 409 || r.Body["error_code"] != int64(30010) || r.Body["time"] != int64(77) {
		t.Fatalf("other-guild cooldown=%+v", r)
	}
	if core.seenGID != guild.ID(1000001) {
		t.Fatalf("gid=%d", core.seenGID)
	}

	core.applyErr = &guildcore.CantJoinError{Kind: guildcore.JoinCooldownSameGuild, RemainingSeconds: 88}
	r = d.Dispatch(context.Background(), rq)
	if r.HTTPStatus != 409 || r.Body["error_code"] != int64(30011) {
		t.Fatalf("same-guild cooldown=%+v", r)
	}
	if _, exists := r.Body["time"]; exists {
		t.Fatalf("unrecovered 30011 time field was invented: %+v", r.Body)
	}
}

func TestGuildMutationResultMapsOnlySourceRecoveredGuildCodes(t *testing.T) {
	cases := []struct {
		name string
		err  error
		code int64
	}{
		{"join-limit", guildcore.ErrJoinLimit, 30012},
		{"application-limit", guildcore.ErrApplicationLimit, 30013},
		{"closed", guildcore.ErrGuildClosed, 30014},
		{"not-found", guildcore.ErrGuildNotFound, 30015},
		{"application-member-full", guildcore.ErrGuildApplicationFull, 30016},
		{"dissolve-solo", guildcore.ErrDissolveRequiresSolo, 30017},
		{"deputy-limit", guildcore.ErrDeputyLimit, 30018},
		{"name-taken", guildcore.ErrGuildNameTaken, 30019},
		{"join-member-full", guildcore.ErrGuildFull, 30020},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			r := guildMutationResult(tc.err)
			if r.HTTPStatus != 409 || r.Body["error_code"] != tc.code {
				t.Fatalf("response=%+v", r)
			}
		})
	}

	for _, err := range []error{guildcore.ErrApplicantLimit, guildcore.ErrLevelTooLow, guildcore.ErrInviteLimit} {
		r := guildMutationResult(err)
		if r.HTTPStatus != 409 || r.Body["error_code"] != int64(35028) {
			t.Fatalf("unproven refusal %v: %+v", err, r)
		}
	}
	unknown := guildMutationResult(errors.New("unknown"))
	if unknown.HTTPStatus != 500 || unknown.Body["error_code"] != int64(35028) {
		t.Fatalf("unknown failure: %+v", unknown)
	}
	if _, leaks := unknown.Body["error"]; leaks {
		t.Fatalf("unknown failure leaked backend detail: %+v", unknown)
	}
}

func TestGuildDispatcherRejectsForgedRegionBeforeViewOrCore(t *testing.T) {
	d := GuildDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Core: &fakeGuildCore{}, View: fakeGuildView{}}
	rq := env(576, nil, time.Unix(1, 0).UTC())
	rq.Envelope.Claims.Region = 2
	r := d.Dispatch(context.Background(), rq)
	if r.HTTPStatus != 409 {
		t.Fatalf("%+v", r)
	}
}

func TestFailGuildKeepsUnknownErrorsOpaque(t *testing.T) {
	r := failGuild(errors.New("sensitive backend detail"))
	if r.HTTPStatus != 500 || r.Body["error_code"] != int64(35028) || r.Body["error"] != nil {
		t.Fatalf("%+v", r)
	}
}

func TestFailGuildRefusesGuildlessViewRead(t *testing.T) {
	r := failGuild(guildview.ErrForbidden)
	if r.HTTPStatus != 409 || r.Body["error_code"] != int64(35028) {
		t.Fatalf("%+v", r)
	}
}

func TestGuildDispatcher616AlwaysAnswersEmptySuccess(t *testing.T) {
	actor := actorForHTTP(t)
	now := time.Unix(100, 0).UTC()
	d := GuildDispatcher{Authority: httpAuthority{actor}, View: fakeGuildView{}}
	r := d.Dispatch(context.Background(), env(616, nil, now))
	if r.HTTPStatus != 200 || len(r.Body) != 0 {
		t.Fatalf("616=%+v", r)
	}
	guildless := GuildDispatcher{Authority: httpAuthority{actor}}
	if got := guildless.Dispatch(context.Background(), env(616, nil, now)); got.HTTPStatus != 200 || len(got.Body) != 0 {
		t.Fatalf("616 guildless=%+v", got)
	}
}

type kickedGuildCore struct{ *fakeGuildCore }

func (kickedGuildCore) Leave(context.Context, identity.ActorContext, operation.Context) (guildcore.AckResult, error) {
	return guildcore.AckResult{}, guildcore.ErrNotGuildMember
}

// A player kicked between requests is no longer a member; the stock client must
// get a 409 refusal instead of a 200 body its guild mutation callback indexes.
func TestGuildDispatcherKickedMemberGuildActionIsRefusal(t *testing.T) {
	now := time.Unix(200, 0).UTC()
	d := GuildDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Core: kickedGuildCore{&fakeGuildCore{}}, View: fakeGuildView{}}
	got := d.Dispatch(context.Background(), env(584, nil, now))
	if got.HTTPStatus != 409 || got.Body["error_code"] != int64(35028) || got.Body["error_msg"] != "" {
		t.Fatalf("kicked member action=%+v", got)
	}
}
