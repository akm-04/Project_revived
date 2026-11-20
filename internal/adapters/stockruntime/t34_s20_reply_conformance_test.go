package stockruntime

import (
	"context"
	"net/http"
	"testing"
	"time"

	app "gxb.local/backend/v2/internal/application/guildcampaign"
	"gxb.local/backend/v2/internal/application/guildrental"
	"gxb.local/backend/v2/internal/application/guildtea"
	"gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/replyconformance"
	"gxb.local/backend/v2/internal/protocol/wire"
)

// S20 reply-conformance: every correct dispatcher body below must satisfy the
// stock client's obligations, over the production dispatcher path.

type s20CampaignStub struct {
	GuildCampaignPort
	started app.Started
	server  app.ServerView
	logs    []app.LogRow
	detail  app.DetailView
	claim   app.ClaimView
}

func (s20CampaignStub) BindContent(_ context.Context, op operation.Context) (operation.Context, error) {
	return op, nil
}

func (s *s20CampaignStub) Start(context.Context, identity.ActorContext, app.Fight, operation.Context) (app.Started, error) {
	return s.started, nil
}
func (s *s20CampaignStub) AllServerRank(context.Context, identity.ActorContext, int64, operation.Context) (app.ServerView, error) {
	return s.server, nil
}
func (s *s20CampaignStub) GuildLog(context.Context, identity.ActorContext, operation.Context) ([]app.LogRow, error) {
	return s.logs, nil
}
func (s *s20CampaignStub) MapDetail(context.Context, identity.ActorContext, int64, operation.Context) (app.DetailView, error) {
	return s.detail, nil
}
func (s *s20CampaignStub) Claim(context.Context, identity.ActorContext, int64, operation.Context) (app.ClaimView, error) {
	return s.claim, nil
}

func s20CampaignDispatch(t *testing.T, service GuildCampaignPort, mid uint16, params map[string]any) httpedge.Response {
	t.Helper()
	actor := actorForHTTP(t)
	all := map[string]any{"token": "bearer", "region": int64(actor.LogicalServerID)}
	for key, value := range params {
		all[key] = value
	}
	now := time.Unix(1700000000, 0).UTC()
	dispatcher := GuildCampaignDispatcher{Authority: httpAuthority{actor: actor}, Service: service}
	return dispatcher.Dispatch(context.Background(), httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{
		Operation: operation.Context{StartedAt: now}, MID: mid, Params: all,
		Claims: wire.CredentialClaims{Token: "bearer", Region: int64(actor.LogicalServerID)}, ReceivedAt: now}})
}

func s20RequireConforming(t *testing.T, mid uint16, response httpedge.Response, requests ...map[string]any) {
	t.Helper()
	if response.HTTPStatus != http.StatusOK {
		t.Fatalf("MID %d status %d body %+v", mid, response.HTTPStatus, response.Body)
	}
	var violations []string
	if len(requests) > 0 {
		violations = (replyconformance.Checker{}).CheckRequest(mid, requests[0], response.Body)
	} else {
		violations = (replyconformance.Checker{}).Check(mid, response.Body)
	}
	if len(violations) != 0 {
		t.Fatalf("MID %d reply violates %v", mid, violations)
	}
}

func TestS20GuildCampaignReplyObligations(t *testing.T) {
	at := time.Unix(1700000000, 0)
	waves := map[int64][]app.EnemyRow{1: {{TableID: 80000010, Lev: 60, Star: 5, Color: 6, Health: 0}},
		2: {{TableID: 80000011, Lev: 60, Star: 5, Color: 6, Health: 0}}}
	stub := &s20CampaignStub{started: app.Started{CopyID: 700028, CurrentIndex: 1, Waves: waves},
		logs:   []app.LogRow{{Type: 1, Profile: app.ProfileView{Name: "p"}, MemberName: "m", PlayerJob: 1, ChapterID: 7, At: time.Unix(1700000000, 0)}},
		detail: app.DetailView{CopyID: 700028, ChapterID: 7, CurrentIndex: 1, IsOpen: true},
		claim:  app.ClaimView{Stage: 1, HolderID: 0, LastFight: &at, FightInfo: app.ProfileView{}}}

	s20RequireConforming(t, 604, s20CampaignDispatch(t, stub, 604, map[string]any{"copy_id": int64(700028), "chapter_id": int64(7), "campaign_type": int64(7), "formation": "10001001"}))
	s20RequireConforming(t, 608, s20CampaignDispatch(t, stub, 608, map[string]any{"copy_id": int64(700028)}))
	s20RequireConforming(t, 609, s20CampaignDispatch(t, stub, 609, nil))
	s20RequireConforming(t, 613, s20CampaignDispatch(t, stub, 613, map[string]any{"copy_id": int64(700028)}))
	s20RequireConforming(t, 614, s20CampaignDispatch(t, stub, 614, map[string]any{"copy_id": int64(700028)}))
}

func TestS20GuildRentalPetRecallReplyObligation(t *testing.T) {
	lender := identity.PlayerID(7)
	probe := &rentalProbe{own: []guildrental.Row{rentalPetRow(lender, 51)}}
	dispatcher := GuildRentalDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: probe}
	response := dispatcher.Dispatch(context.Background(), heroReq(t, 620, map[string]any{"pet_id": int64(51)}))
	s20RequireConforming(t, 620, response)
}

func TestS20Guildless612AndSelfTea1808ReplyObligations(t *testing.T) {
	guild := GuildDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Core: &fakeGuildCore{}, View: fakeGuildView{}}
	s20RequireConforming(t, 612, guild.Dispatch(context.Background(), env(612, nil, time.Unix(100, 0).UTC())))

	tea := GuildTeaDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: s20TeaStub{state: guildtea.State{SelfOnly: true}}}
	s20RequireConforming(t, 1808, tea.Dispatch(context.Background(), heroReq(t, 1808, map[string]any{"is_self": int64(1)})))
}

func TestS20OccultReplyObligations(t *testing.T) {
	stub := s20OccultStub{
		info: map[string]any{"base_info": map[string]any{"room_id": int64(0), "chapter_id": int64(0), "cost_energy": int64(0), "max_points": []any{}, "dispatch_limit": int64(3)},
			"occult_ticket": int64(0), "progress": float64(0)},
		teamFight: map[string]any{"battle_report": "{}"},
	}
	dispatcher := OccultDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: stub}
	stage := map[string]any{"campaign_id": int64(1), "sub_id": int64(1)}
	s20RequireConforming(t, 2362, dispatcher.Dispatch(context.Background(), heroReq(t, 2362, nil)))
	s20RequireConforming(t, 2374, dispatcher.Dispatch(context.Background(), heroReq(t, 2374, stage)))
	s20RequireConforming(t, 2377, dispatcher.Dispatch(context.Background(), heroReq(t, 2377, stage)))
	s20RequireConforming(t, 2379, dispatcher.Dispatch(context.Background(), heroReq(t, 2379, stage)))
}

func TestS20Profile1829RequestBranches(t *testing.T) {
	basic := map[string]any{"intro": "", "praise_num": int64(0), "share_switch": int64(0), "show_case": []any{},
		"show_types": map[string]any{}, "hide_types": []any{}, "is_first_time": int64(0), "is_in_blacklist": false,
		"is_has_praise": int64(0), "open_functions": []any{}, "avatar_file_path": "u", "avatar_md5_code": "m",
		"player_info": map[string]any{"player_id": int64(1), "player_name": "n", "avatar_id": int64(1), "avatar_frame_id": int64(0),
			"lev": int64(1), "exp": int64(0), "guild_id": int64(0), "guild_name": "", "guild_job": int64(0), "title_info": map[string]any{}}}
	bodies := map[int64]map[string]any{
		1: basic,
		2: {"arena_performance": map[string]any{}, "region_arena_performance": map[string]any{}, "super_arena_performance": map[string]any{}},
		4: {"best_comments": []any{}, "comment_list": []any{}, "comment_num": int64(0)},
	}
	for subType, body := range bodies {
		service := profileReadsFunc(func(context.Context, identity.ActorContext, publicprofile.ReadRequest, operation.Context) (map[string]any, error) {
			return body, nil
		})
		dispatcher := PublicProfileReadDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: service}
		params := map[string]any{"to_player_id": int64(100002), "sub_type": subType}
		response := dispatcher.Dispatch(context.Background(), heroReq(t, 1829, params))
		s20RequireConforming(t, 1829, response, map[string]any{"sub_type": subType})
	}
}

func TestS20Illusion301OmitsMyFloor(t *testing.T) {
	body := map[string]any{"rank_list": []map[string]any{{"rank_type": int64(24), "rank_info": map[string]any{
		"my_rank": map[string]any{"rank": int64(1)}, "rank_info": []map[string]any{}}}}}
	dispatcher := RankingDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: unusedBoardRankingFixture{}, Illusion: s20IllusionRank{body: body}}
	response := dispatcher.Dispatch(context.Background(), heroReq(t, 301, map[string]any{"rank_types": []any{int64(24)}}))
	s20RequireConforming(t, 301, response)
}

func TestS20NonClass183OmitsMasterInfo(t *testing.T) {
	dispatcher := giftClaimDispatcher(t, &giftClaimProbe{}, &scalarProbe{})
	response := dispatcher.Dispatch(context.Background(), heroReq(t, 183, map[string]any{"player_id": int64(100002)}))
	s20RequireConforming(t, 183, response)
}

func TestS20AMissingRequiredLeafStillFails(t *testing.T) {
	body := map[string]any{"guild_info": map[string]any{"guild_id": int64(0), "apply_type": int64(0), "des": "",
		"guild_leader": int64(0), "guild_leader_name": "", "huoyue": int64(0), "icon": "", "icon_frame": "",
		"min_allow_level": int64(0)}, "member_nums": int64(0),
		"self_info": map[string]any{"job": int64(0), "join_time": int64(0), "today_huoyue": int64(0), "huoyue_num": int64(0)}}
	violations := (replyconformance.Checker{}).Check(612, body)
	if len(violations) != 1 || violations[0] != "guild_info.name" {
		t.Fatalf("missing name violations = %v", violations)
	}
}

type s20TeaStub struct {
	GuildTeaPort
	state guildtea.State
}

func (s s20TeaStub) Info(context.Context, identity.ActorContext, operation.Context, bool) (guildtea.State, error) {
	return s.state, nil
}

type s20OccultStub struct {
	OccultPort
	info       map[string]any
	invite     map[string]any
	startFight map[string]any
	teamFight  map[string]any
}

func (s s20OccultStub) Info(context.Context, identity.ActorContext, operation.Context) (map[string]any, error) {
	return s.info, nil
}
func (s s20OccultStub) TeamInvite(context.Context, identity.ActorContext, int64, int64, operation.Context) (map[string]any, error) {
	return s.invite, nil
}
func (s s20OccultStub) StartFight(context.Context, identity.ActorContext, int64, int64, operation.Context) (map[string]any, error) {
	return s.startFight, nil
}
func (s s20OccultStub) StartTeamFight(context.Context, identity.ActorContext, int64, int64, operation.Context) (map[string]any, error) {
	return s.teamFight, nil
}

type s20IllusionRank struct {
	body map[string]any
}

func (s s20IllusionRank) RankList(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error) {
	return s.body, nil
}
