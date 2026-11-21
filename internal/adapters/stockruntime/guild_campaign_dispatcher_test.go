package stockruntime

import (
	"context"
	"net/http"
	"testing"
	"time"

	app "gxb.local/backend/v2/internal/application/guildcampaign"
	d "gxb.local/backend/v2/internal/domain/guildcampaign"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/replyconformance"
	"gxb.local/backend/v2/internal/protocol/wire"
)

func TestI9_9CSettleRefusalsAre409AndLateIs30021(t *testing.T) {
	late := campaignSettleFailure(app.ErrLate)
	if late.HTTPStatus != http.StatusConflict || late.Body["error_code"] != int64(30021) {
		t.Fatalf("late %+v", late)
	}
	refused := campaignSettleFailure(d.ErrRefused)
	if refused.HTTPStatus != http.StatusConflict || refused.Body["error_code"] != int64(35028) {
		t.Fatalf("refused %+v", refused)
	}
	if unavailable := campaignSettleFailure(app.ErrUnavailable); unavailable.HTTPStatus != http.StatusInternalServerError || unavailable.Body["error_code"] != int64(35028) {
		t.Fatalf("unavailable %+v", unavailable)
	}
}

func TestI9_9CApplyRewardRefusalIs409(t *testing.T) {
	stub := &campaignStub{applyErr: d.ErrRefused}
	got := campaignDispatch(t, stub, 606, map[string]any{"chapter_id": int64(7), "award_id": int64(20001091)})
	if got.HTTPStatus != http.StatusConflict || got.Body["error_code"] != int64(35028) || got.Body["error_msg"] != "" {
		t.Fatalf("606 refusal %+v", got)
	}
}

func TestI9_9CNoticeRefRoundTrips(t *testing.T) {
	ref := GuildCampaignNoticeRef(11, 7, 700028, 123)
	guild, chapter, copy, player, err := decodeGuildCampaignNoticeRef(ref)
	if err != nil || guild != 11 || chapter != 7 || copy != 700028 || int64(player) != 123 {
		t.Fatalf("ref %q %+v %v", ref, []int64{guild, chapter, copy, int64(player)}, err)
	}
}

type campaignStub struct {
	GuildCampaignPort
	lists           app.Lists
	started         app.Started
	settled         app.Settled
	detail          app.DetailView
	award           app.AwardBody
	applyErr        error
	ranks           []app.RankRow
	server          app.ServerView
	logs            []app.LogRow
	distributions   []app.Distribution
	startedRequest  app.Fight
	settledRequest  app.Result
	startedRecorded bool
	settledRecorded bool
}

func (s *campaignStub) CampaignLists(context.Context, identity.ActorContext, operation.Context) (app.Lists, error) {
	return s.lists, nil
}
func (s *campaignStub) GuildMap(context.Context, identity.ActorContext, operation.Context) (app.Lists, error) {
	return s.lists, nil
}
func (s *campaignStub) Start(_ context.Context, _ identity.ActorContext, request app.Fight, _ operation.Context) (app.Started, error) {
	s.startedRequest, s.startedRecorded = request, true
	return s.started, nil
}
func (s *campaignStub) Settle(_ context.Context, _ identity.ActorContext, request app.Result, _ operation.Context) (app.Settled, error) {
	s.settledRequest, s.settledRecorded = request, true
	return s.settled, nil
}
func (s *campaignStub) MapDetail(context.Context, identity.ActorContext, int64, operation.Context) (app.DetailView, error) {
	return s.detail, nil
}
func (s *campaignStub) AwardRead(context.Context, identity.ActorContext, int64, operation.Context) (app.AwardBody, error) {
	return s.award, nil
}
func (s *campaignStub) ApplyReward(context.Context, identity.ActorContext, int64, int64, operation.Context) (app.AwardBody, error) {
	return s.award, s.applyErr
}
func (s *campaignStub) DamageRank(context.Context, identity.ActorContext, int64, operation.Context) ([]app.RankRow, error) {
	return s.ranks, nil
}
func (s *campaignStub) AllServerRank(context.Context, identity.ActorContext, int64, operation.Context) (app.ServerView, error) {
	return s.server, nil
}
func (s *campaignStub) GuildLog(context.Context, identity.ActorContext, operation.Context) ([]app.LogRow, error) {
	return s.logs, nil
}
func (s *campaignStub) DistributeRecord(context.Context, identity.ActorContext, operation.Context) ([]app.Distribution, error) {
	return s.distributions, nil
}

func campaignDispatch(t *testing.T, stub *campaignStub, mid uint16, params map[string]any) httpedge.Response {
	t.Helper()
	actor := actorForHTTP(t)
	all := map[string]any{"token": "bearer", "region": int64(actor.LogicalServerID)}
	for key, value := range params {
		all[key] = value
	}
	now := time.Unix(1700000000, 0).UTC()
	dispatcher := GuildCampaignDispatcher{Authority: httpAuthority{actor: actor}, Service: stub}
	return dispatcher.Dispatch(context.Background(), httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{
		Operation: operation.Context{StartedAt: now}, MID: mid, Params: all,
		Claims: wire.CredentialClaims{Token: "bearer", Region: int64(actor.LogicalServerID)}, ReceivedAt: now}})
}

func TestI9_9CDispatcherChapterAndCopyJSON(t *testing.T) {
	stub := &campaignStub{lists: app.Lists{Chapters: []app.ChapterRow{{ChapterID: 7, IsOpen: true, IsWin: true, HaveWin: true, Percent: 1,
		StartTime: 100, EndTime: 200, ChallengeTimes: 1, ChapterVersion: 1, OpenCost: 40000}},
		Copies: []app.CopyRowView{{CopyID: 700028, IsOpen: false, IsWin: true, Percent: 1}}}}
	got := campaignDispatch(t, stub, 601, nil)
	if got.HTTPStatus != http.StatusOK {
		t.Fatalf("601 %+v", got)
	}
	// MapWindow.lua:761-768 reads is_open and is_win from the same won chapter.
	row := got.Body["chapter_list"].([]any)[0].(map[string]any)
	if row["is_open"] != int64(1) || row["is_win"] != int64(1) || row["chapter_id"] != int64(7) {
		t.Fatalf("601 row %+v", row)
	}
	mapBody := campaignDispatch(t, stub, 603, nil)
	copies := mapBody.Body["copy_list"].(map[string]any)
	if copies["700028"].(map[string]any)["is_win"] != int64(1) {
		t.Fatalf("603 copy_list %+v", copies)
	}

	waves := map[int64][]app.EnemyRow{1: {{PartnerID: 1, TableID: 91071010, Lev: 60, Star: 5, Color: 6, Health: 0}},
		2: {{PartnerID: 2, TableID: 91071022, Lev: 60, Star: 5, Color: 6, Health: 0}},
		3: {{PartnerID: 3, TableID: 91071060, Lev: 60, Star: 5, Color: 6, Health: 0}}}
	stub.started = app.Started{CopyID: 700028, CurrentIndex: 1, Waves: waves}
	started := campaignDispatch(t, stub, 604, map[string]any{"copy_id": int64(700028), "chapter_id": int64(7), "campaign_type": int64(7), "formation": "10001001"})
	// SelectTeamNewWindow.lua:6819 indexes enemy_status by wave number, so it
	// is an array of waves, not an object. Each row owes the battle monster and
	// the partner_id Hero.populate keeps as getHeroID (NormalHero.lua:142).
	enemies := started.Body["enemy_status"].([]any)
	last := enemies[2].([]any)[0].(map[string]any)
	if len(enemies) != 3 || len(enemies[0].([]any)) != 1 || last["table_id"] != int64(91071060) || last["partner_id"] != int64(3) ||
		last["lev"] != int64(60) || last["star"] != int64(5) || last["color"] != int64(6) {
		t.Fatalf("604 enemy_status %+v", enemies)
	}

	stub.detail = app.DetailView{CopyID: 700028, ChapterID: 7, CurrentIndex: 2, Waves: waves, IsOpen: true, CurrentFight: 9, Stage: 2}
	detail := campaignDispatch(t, stub, 613, map[string]any{"copy_id": int64(700028)})
	// GuildMapDetailWindow.lua:30 does monsterStatus[waveIndex].
	status := detail.Body["monster_status"].([]any)
	if len(status) != 3 || detail.Body["current_index"] != int64(2) || detail.Body["stage"] != int64(2) {
		t.Fatalf("613 %+v", detail.Body)
	}
	pushed := campaignDispatch(t, stub, 613, map[string]any{"copy_id": int64(700028), "chapter_id": int64(7), "player_id": int64(9)})
	if pushed.HTTPStatus != 200 {
		t.Fatalf("613 with the forwarded push body %d %+v", pushed.HTTPStatus, pushed.Body)
	}
}

func TestI9_9CEnemyStatusCarriesHPForRecordedRows(t *testing.T) {
	// SelectTeamNewWindow.lua:6795-6799 builds healthStatus from health/hp, and
	// BattleCreate.lua:1106-1111 applies hp only when health is 1, so a recorded
	// row owes health 1 with hp numeric; an untouched row keeps health 0 and no hp.
	waves := map[int64][]app.EnemyRow{1: {
		{PartnerID: 1, TableID: 91071010, Lev: 60, Star: 5, Color: 6, HP: 77},
		{PartnerID: 2, TableID: 91071011, Lev: 60, Star: 5, Color: 6, Health: 1},
		{PartnerID: 3, TableID: 91071012, Lev: 60, Star: 5, Color: 6},
	}}
	stub := &campaignStub{started: app.Started{CopyID: 700028, CurrentIndex: 1, Waves: waves},
		detail: app.DetailView{CopyID: 700028, ChapterID: 7, CurrentIndex: 1, Waves: waves, IsOpen: true}}
	replies := map[uint16]map[string]any{
		604: {"copy_id": int64(700028), "chapter_id": int64(7), "campaign_type": int64(7), "formation": "10001001"},
		613: {"copy_id": int64(700028)},
	}
	for mid, params := range replies {
		got := campaignDispatch(t, stub, mid, params)
		key := "enemy_status"
		if mid == 613 {
			key = "monster_status"
		}
		rows := got.Body[key].([]any)[0].([]any)
		damaged, dead, untouched := rows[0].(map[string]any), rows[1].(map[string]any), rows[2].(map[string]any)
		if damaged["health"] != int64(1) || damaged["hp"] != int64(77) || damaged["partner_id"] != int64(1) || damaged["table_id"] != int64(91071010) {
			t.Fatalf("%d damaged row %+v", mid, damaged)
		}
		if dead["health"] != int64(1) || dead["hp"] != int64(0) {
			t.Fatalf("%d dead row %+v", mid, dead)
		}
		if untouched["health"] != int64(0) || untouched["hp"] != nil {
			t.Fatalf("%d untouched row %+v", mid, untouched)
		}
	}
}

func TestI9_9CDetailCarriesFightInfoForTheLiveHolder(t *testing.T) {
	// MapWindow.lua:1100,1121-1130 and GuildMapDetailWindow.lua:60-82 index
	// fight_info whenever current_fight_player>0 and last_fight_time>0, so the
	// reply owes the shape even when the holder's profile row did not read back.
	stub := &campaignStub{detail: app.DetailView{CopyID: 700028, ChapterID: 7, CurrentIndex: 1, IsOpen: true,
		CurrentFight: 9, Stage: 1, LastFight: 1700000000, StartFight: 1700000000}}
	got := campaignDispatch(t, stub, 613, map[string]any{"copy_id": int64(700028)})
	if got.HTTPStatus != http.StatusOK {
		t.Fatalf("613 %d %+v", got.HTTPStatus, got.Body)
	}
	info, ok := got.Body["fight_info"].(map[string]any)
	if !ok {
		t.Fatalf("613 without a holder profile omitted fight_info: %+v", got.Body)
	}
	if info["player_name"] != "" || info["lev"] != int64(0) || info["avatar_id"] != int64(0) || info["conquer_lev"] != int64(0) {
		t.Fatalf("fight_info %+v", info)
	}
	stub.detail = app.DetailView{CopyID: 700028, ChapterID: 7, CurrentIndex: 1, IsOpen: true}
	if free := campaignDispatch(t, stub, 613, map[string]any{"copy_id": int64(700028)}); free.Body["fight_info"] != nil {
		t.Fatalf("613 without a holder carried fight_info: %+v", free.Body)
	}
}

func TestI9_9CDispatcherAwardRankAndLogJSON(t *testing.T) {
	profile := app.ProfileView{PlayerID: 11, Name: "p", Level: 41, AvatarID: 1, AvatarFrameID: 0, ConquerLevel: 3, ConquerLoopID: 1}
	stub := &campaignStub{award: app.AwardBody{NextApplyTime: 60, SelfItemID: 20001091, SelfRank: 1, ApplyTimes: 1,
		Awards: []app.AwardInfo{{AwardID: 20001091, AwardNum: 2, SelfRank: 1, SelfApply: 1, Members: []app.AwardMember{{Rank: 1, Profile: profile}}}}}}
	award := campaignDispatch(t, stub, 605, map[string]any{"chapter_id": int64(7)})
	infos := award.Body["award_infos"].([]any)
	info := infos[0].(map[string]any)
	if len(infos) != 1 || len(info["apply_member"].([]any)) != 1 || award.Body["self_apply_info"].(map[string]any)["item_id"] != int64(20001091) {
		t.Fatalf("605 %+v", award.Body)
	}
	applied := campaignDispatch(t, stub, 606, map[string]any{"chapter_id": int64(7), "award_id": int64(20001091)})
	if applied.HTTPStatus != http.StatusOK || len(applied.Body["award_infos"].([]any)) != 1 {
		t.Fatalf("606 %+v", applied)
	}

	stub.ranks = []app.RankRow{{Rank: 1, Damage: 5000, Profile: profile}}
	rank := campaignDispatch(t, stub, 607, map[string]any{"chapter_id": int64(7)})
	rankRow := rank.Body["rank_list"].([]any)[0].(map[string]any)
	if rankRow["rank"] != int64(1) || rankRow["damage"] != int64(5000) {
		t.Fatalf("607 %+v", rank.Body)
	}

	at := time.Unix(1700000000, 0).UTC()
	stub.server = app.ServerView{Fast: &app.FastKiller{GuildID: 3, GuildName: "g", GuildIcon: 20010001, Seconds: 12},
		Boss: &app.Killer{Profile: profile, GuildID: 3, GuildName: "g", At: at},
		Ranks: []app.ServerRankRow{{Rank: 1, Damage: 5000, Profile: profile, GuildID: 3, GuildName: "g",
			Partners: []app.Partner{{TableID: 10001001, Color: 6, Star: 5, Level: 41, CurrentSkinID: 2, TwiceAwakeStage: 3}}}}}
	server := campaignDispatch(t, stub, 608, map[string]any{"copy_id": int64(700028)})
	serverRow := server.Body["rank_list"].([]any)[0].(map[string]any)
	fast := server.Body["fast_boss_killer"].(map[string]any)
	partner := serverRow["partners"].([]any)[0].(map[string]any)
	if fast["cost_time"] != int64(12) || fast["name"] != "g" || fast["icon"] != int64(20010001) ||
		server.Body["boss_killer"].(map[string]any)["time"] != at.Unix() || server.Body["boss_killer"].(map[string]any)["guild_name"] != "g" ||
		serverRow["guild_name"] != "g" || partner["table_id"] != int64(10001001) || partner["color"] != int64(6) ||
		partner["star"] != int64(5) || partner["lev"] != int64(41) || partner["current_skin_id"] != int64(2) || partner["twice_awake_stage"] != int64(3) {
		t.Fatalf("608 %+v", server.Body)
	}

	stub.logs = []app.LogRow{{Type: int64(d.LogOpenChapter), Profile: profile, PlayerJob: 1, ChapterID: 7, At: at}}
	logBody := campaignDispatch(t, stub, 609, nil)
	logRow := logBody.Body["guild_log"].([]any)[0].(map[string]any)
	if logRow["type"] != int64(d.LogOpenChapter) || logRow["chapter_id"] != int64(7) {
		t.Fatalf("609 %+v", logBody.Body)
	}

	stub.distributions = []app.Distribution{{ItemID: 20001091, PlayerName: "p", Distributed: at}}
	record := campaignDispatch(t, stub, 615, nil)
	if len(record.Body["logs"].([]any)) != 1 {
		t.Fatalf("615 %+v", record.Body)
	}
}

func TestI9_9CDispatcherSettleBodyAndAlternativeNumbers(t *testing.T) {
	stub := &campaignStub{settled: app.Settled{Body: map[string]any{"rank_award": map[string]any{"crystal": int64(100), "guild_coin": int64(100)},
		"normal_drop": []any{}, "guild_drop": []any{}, "coin_award": int64(123), "exps": []any{}}}}
	// BattleCreate.lua:2985-3045 sends hero_id = enemy:getHeroID(), which is the
	// 604 row's partner_id, with a fractional hp and the wave index.
	params := map[string]any{"total_damage": 12.9, "star": int64(0), "chapter_id": int64(7), "copy_id": int64(700028),
		"current_index": int64(1), "formation": "10001001", "rent_formation": "10001002", "rent_player_id": int64(77),
		"enemy_status": []any{map[string]any{"hero_id": int64(2), "hp": 5.9, "is_reborn": int64(1), "index": int64(1)}}}
	got := campaignDispatch(t, stub, 610, params)
	if got.HTTPStatus != http.StatusOK || got.Body["rank_award"].(map[string]any)["crystal"] != int64(100) {
		t.Fatalf("610 %+v", got)
	}
	if !stub.settledRecorded || stub.settledRequest.TotalDamage != 12 || len(stub.settledRequest.Enemies) != 1 ||
		stub.settledRequest.Enemies[0].HeroID != 2 || stub.settledRequest.Enemies[0].HP != 5 || stub.settledRequest.Enemies[0].Index != 1 {
		t.Fatalf("610 request %+v", stub.settledRequest)
	}
}

func (campaignStub) BindContent(_ context.Context, op operation.Context) (operation.Context, error) {
	return op, nil
}

func awardParams(mid uint16) map[string]any {
	if mid == 606 {
		return map[string]any{"chapter_id": int64(7), "award_id": int64(20001091)}
	}
	return map[string]any{"chapter_id": int64(7)}
}

func TestI9_11T34AwardWireSelfApplyItemIDOnlyWhenApplied(t *testing.T) {
	// ApplyQueueWindow.lua:127-160 and ApplyRewardWindow.lua:119-150 test the
	// field's truthiness, and Lua treats 0 as true, so an unapplied member owes
	// no item_id key; rank stays required.
	unapplied := &campaignStub{award: app.AwardBody{NextApplyTime: 60, SelfRank: 2}}
	for _, mid := range []uint16{605, 606} {
		got := campaignDispatch(t, unapplied, mid, awardParams(mid))
		if got.HTTPStatus != http.StatusOK {
			t.Fatalf("%d unapplied %+v", mid, got)
		}
		info, ok := got.Body["self_apply_info"].(map[string]any)
		if !ok {
			t.Fatalf("%d self_apply_info=%+v", mid, got.Body)
		}
		if _, exists := info["item_id"]; exists {
			t.Fatalf("%d unapplied carried item_id: %+v", mid, info)
		}
		if info["rank"] != int64(2) {
			t.Fatalf("%d unapplied rank=%+v", mid, info)
		}
		replyconformance.Check(t, mid, got.Body)
	}

	applied := &campaignStub{award: app.AwardBody{NextApplyTime: 60, SelfItemID: 20001091, SelfRank: 1, ApplyTimes: 1}}
	for _, mid := range []uint16{605, 606} {
		got := campaignDispatch(t, applied, mid, awardParams(mid))
		if got.HTTPStatus != http.StatusOK {
			t.Fatalf("%d applied %+v", mid, got)
		}
		info := got.Body["self_apply_info"].(map[string]any)
		if info["item_id"] != int64(20001091) {
			t.Fatalf("%d applied item_id=%+v", mid, info)
		}
		replyconformance.Check(t, mid, got.Body)
	}
}
