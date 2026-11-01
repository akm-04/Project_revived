package stockruntime

import (
	"context"
	"errors"
	"net/http"
	"strconv"

	"gxb.local/backend/v2/internal/application/guildcampaign"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// GuildCampaignMIDs are the stock Guild Campaign callbacks (ledger 1).
var GuildCampaignMIDs = []uint16{601, 602, 603, 604, 605, 606, 607, 608, 609, 610, 611, 613, 614, 615}

// GuildCampaignPort is the gameplay surface of the Guild Campaign owner.
type GuildCampaignPort interface {
	Open(context.Context, identity.ActorContext, int64, operation.Context) (int64, error)
	Reset(context.Context, identity.ActorContext, int64, operation.Context) (int64, error)
	Claim(context.Context, identity.ActorContext, int64, operation.Context) (guildcampaign.ClaimView, error)
	Start(context.Context, identity.ActorContext, guildcampaign.Fight, operation.Context) (guildcampaign.Started, error)
	Settle(context.Context, identity.ActorContext, guildcampaign.Result, operation.Context) (guildcampaign.Settled, error)
	CampaignLists(context.Context, identity.ActorContext, operation.Context) (guildcampaign.Lists, error)
	GuildMap(context.Context, identity.ActorContext, operation.Context) (guildcampaign.Lists, error)
	DamageRank(context.Context, identity.ActorContext, int64, operation.Context) ([]guildcampaign.RankRow, error)
	AllServerRank(context.Context, identity.ActorContext, int64, operation.Context) (guildcampaign.ServerView, error)
	GuildLog(context.Context, identity.ActorContext, operation.Context) ([]guildcampaign.LogRow, error)
	MapDetail(context.Context, identity.ActorContext, int64, operation.Context) (guildcampaign.DetailView, error)
	AwardRead(context.Context, identity.ActorContext, int64, operation.Context) (guildcampaign.AwardBody, error)
	ApplyReward(context.Context, identity.ActorContext, int64, int64, operation.Context) (guildcampaign.AwardBody, error)
	DistributeRecord(context.Context, identity.ActorContext, operation.Context) ([]guildcampaign.Distribution, error)
}

type GuildCampaignDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   GuildCampaignPort
}

func (d GuildCampaignDispatcher) Dispatch(c context.Context, r httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: d.Authority}).actor(c, r)
	if fail != nil {
		return *fail
	}
	if d.Service == nil {
		return campaignUnavailable()
	}
	p, op := r.Envelope.Params, r.Envelope.Operation
	switch r.Envelope.MID {
	case 601:
		if !onlyStockGameplayParams(p) {
			return campaignBad()
		}
		lists, err := d.Service.CampaignLists(c, a, op)
		if err != nil {
			return campaignFailure(err)
		}
		return okI5(map[string]any{"chapter_list": chapterList(lists.Chapters)})
	case 602, 611:
		chapterID, err := requiredInt64(p, "chapter_id")
		if err != nil || chapterID <= 0 || !onlyStockGameplayParams(p, "chapter_id") {
			return campaignBad()
		}
		var balance int64
		if r.Envelope.MID == 602 {
			balance, err = d.Service.Reset(c, a, chapterID, op)
		} else {
			balance, err = d.Service.Open(c, a, chapterID, op)
		}
		if err != nil {
			return campaignFailure(err)
		}
		lists, err := d.Service.CampaignLists(c, a, op)
		if err != nil {
			return campaignFailure(err)
		}
		return okI5(map[string]any{"guild_huoyue": balance, "chapter_list": chapterList(lists.Chapters)})
	case 603:
		if !onlyStockGameplayParams(p) {
			return campaignBad()
		}
		lists, err := d.Service.GuildMap(c, a, op)
		if err != nil {
			return campaignFailure(err)
		}
		return okI5(map[string]any{"chapter_list": chapterList(lists.Chapters), "copy_list": copyList(lists.Copies)})
	case 604:
		request, ok := guildCampaignFight(p)
		if !ok {
			return campaignBad()
		}
		started, err := d.Service.Start(c, a, request, op)
		if err != nil {
			return campaignFailure(err)
		}
		return okI5(map[string]any{"enemy_status": enemyStatus(started.Waves), "current_index": started.CurrentIndex,
			"normal_drop": []any{}, "guild_drop": []any{}, "monster_drop": []any{}})
	case 605:
		chapterID, err := requiredInt64(p, "chapter_id")
		if err != nil || chapterID <= 0 || !onlyStockGameplayParams(p, "chapter_id") {
			return campaignBad()
		}
		body, err := d.Service.AwardRead(c, a, chapterID, op)
		if err != nil {
			return campaignFailure(err)
		}
		return okI5(awardWire(body))
	case 606:
		chapterID, err := requiredInt64(p, "chapter_id")
		if err != nil {
			return campaignBad()
		}
		awardID, err := requiredInt64(p, "award_id")
		if err != nil || chapterID <= 0 || awardID <= 0 || !onlyStockGameplayParams(p, "chapter_id", "award_id") {
			return campaignBad()
		}
		body, err := d.Service.ApplyReward(c, a, chapterID, awardID, op)
		if err != nil {
			return campaignFailure(err)
		}
		return okI5(awardWire(body))
	case 607:
		chapterID, err := requiredInt64(p, "chapter_id")
		if err != nil || chapterID <= 0 || !onlyStockGameplayParams(p, "chapter_id") {
			return campaignBad()
		}
		rows, err := d.Service.DamageRank(c, a, chapterID, op)
		if err != nil {
			return campaignFailure(err)
		}
		return okI5(map[string]any{"rank_list": damageRank(rows)})
	case 608:
		copyID, err := requiredInt64(p, "copy_id")
		if err != nil || copyID <= 0 || !onlyStockGameplayParams(p, "copy_id") {
			return campaignBad()
		}
		view, err := d.Service.AllServerRank(c, a, copyID, op)
		if err != nil {
			return campaignFailure(err)
		}
		return okI5(serverRank(view))
	case 609:
		if !onlyStockGameplayParams(p) {
			return campaignBad()
		}
		rows, err := d.Service.GuildLog(c, a, op)
		if err != nil {
			return campaignFailure(err)
		}
		return okI5(map[string]any{"guild_log": guildLog(rows)})
	case 610:
		request, ok := guildCampaignResult(p)
		if !ok {
			return campaignBad()
		}
		settled, err := d.Service.Settle(c, a, request, op)
		if err != nil {
			return campaignSettleFailure(err)
		}
		return okI5(settled.Body)
	case 613:
		copyID, err := requiredInt64(p, "copy_id")
		if err != nil || copyID <= 0 || !onlyStockGameplayParams(p, "copy_id") {
			return campaignBad()
		}
		view, err := d.Service.MapDetail(c, a, copyID, op)
		if err != nil {
			return campaignFailure(err)
		}
		return okI5(detailWire(view))
	case 614:
		copyID, err := requiredInt64(p, "copy_id")
		if err != nil || copyID <= 0 || !onlyStockGameplayParams(p, "copy_id") {
			return campaignBad()
		}
		view, err := d.Service.Claim(c, a, copyID, op)
		if err != nil {
			return campaignFailure(err)
		}
		return okI5(claimWire(view))
	case 615:
		if !onlyStockGameplayParams(p) {
			return campaignBad()
		}
		rows, err := d.Service.DistributeRecord(c, a, op)
		if err != nil {
			return campaignFailure(err)
		}
		logs := make([]any, 0, len(rows))
		for _, row := range rows {
			logs = append(logs, map[string]any{"item_id": row.ItemID, "player_name": row.PlayerName, "time": row.Distributed.Unix()})
		}
		return okI5(map[string]any{"logs": logs})
	default:
		return httpedge.Response{HTTPStatus: http.StatusNotImplemented, Body: map[string]any{"error": "not_i9_9c_mid"}}
	}
}

func guildCampaignFight(p map[string]any) (guildcampaign.Fight, bool) {
	if !onlyStockGameplayParams(p, "copy_id", "campaign_type", "formation", "chapter_id", "pet_id",
		"rent_pet_player_id", "rent_pet_id", "rent_player_id", "rent_formation", "tutor_rent_hero") {
		return guildcampaign.Fight{}, false
	}
	copyID, err := requiredInt64(p, "copy_id")
	if err != nil || copyID <= 0 {
		return guildcampaign.Fight{}, false
	}
	chapterID, err := requiredInt64(p, "chapter_id")
	if err != nil || chapterID <= 0 {
		return guildcampaign.Fight{}, false
	}
	campaignType, err := requiredInt64(p, "campaign_type")
	if err != nil || campaignType != 7 {
		return guildcampaign.Fight{}, false
	}
	formation, ok := p["formation"].(string)
	if !ok {
		return guildcampaign.Fight{}, false
	}
	request := guildcampaign.Fight{ChapterID: chapterID, CopyID: copyID, CampaignType: campaignType, Formation: formation}
	request.PetID = optionalInt64(p, "pet_id")
	request.RentPlayer = optionalInt64(p, "rent_player_id")
	request.RentFormation = optionalInt64String(p, "rent_formation")
	request.RentPetPlayer = optionalInt64(p, "rent_pet_player_id")
	request.RentPetID = optionalInt64String(p, "rent_pet_id")
	return request, true
}

func guildCampaignResult(p map[string]any) (guildcampaign.Result, bool) {
	if !onlyStockGameplayParams(p, "total_damage", "star", "chapter_id", "copy_id", "current_index", "formation", "pet_id", "enemy_status") {
		return guildcampaign.Result{}, false
	}
	total, err := requiredInt64(p, "total_damage")
	if err != nil || total < 0 {
		return guildcampaign.Result{}, false
	}
	star, err := requiredInt64(p, "star")
	if err != nil || star < 0 || star > 3 {
		return guildcampaign.Result{}, false
	}
	chapterID, err := requiredInt64(p, "chapter_id")
	if err != nil || chapterID <= 0 {
		return guildcampaign.Result{}, false
	}
	copyID, err := requiredInt64(p, "copy_id")
	if err != nil || copyID <= 0 {
		return guildcampaign.Result{}, false
	}
	current, err := requiredInt64(p, "current_index")
	if err != nil || current < 1 || current > 3 {
		return guildcampaign.Result{}, false
	}
	formation, ok := p["formation"].(string)
	if !ok {
		return guildcampaign.Result{}, false
	}
	request := guildcampaign.Result{ChapterID: chapterID, CopyID: copyID, CurrentIndex: current, Formation: formation, TotalDamage: total, Star: star,
		PetID: optionalInt64(p, "pet_id")}
	raw, ok := p["enemy_status"].([]any)
	if !ok {
		return guildcampaign.Result{}, false
	}
	for _, entry := range raw {
		fields, ok := entry.(map[string]any)
		if !ok {
			return guildcampaign.Result{}, false
		}
		enemy := guildcampaign.ResultEnemy{HeroID: optionalInt64(fields, "hero_id"), HP: optionalInt64(fields, "hp"),
			IsReborn: optionalInt64(fields, "is_reborn"), Index: optionalInt64(fields, "index")}
		if enemy.HeroID <= 0 {
			return guildcampaign.Result{}, false
		}
		request.Enemies = append(request.Enemies, enemy)
	}
	return request, true
}

func optionalInt64(m map[string]any, key string) int64 {
	raw, present := m[key]
	if !present || raw == nil {
		return 0
	}
	value, err := requiredInt64(m, key)
	if err != nil {
		return 0
	}
	return value
}

func optionalInt64String(m map[string]any, key string) int64 {
	raw, present := m[key]
	if !present || raw == nil {
		return 0
	}
	if text, ok := raw.(string); ok {
		value, err := strconv.ParseInt(text, 10, 64)
		if err != nil {
			return 0
		}
		return value
	}
	return optionalInt64(m, key)
}

func chapterList(rows []guildcampaign.ChapterRow) []any {
	out := make([]any, 0, len(rows))
	for _, row := range rows {
		out = append(out, map[string]any{"chapter_id": row.ChapterID, "is_open": flag(row.IsOpen), "is_win": flag(row.IsWin),
			"have_win": flag(row.HaveWin), "percent": row.Percent, "start_time": row.StartTime, "end_time": row.EndTime,
			"challenge_times": row.ChallengeTimes, "chapter_version": row.ChapterVersion})
	}
	return out
}

func copyList(rows []guildcampaign.CopyRowView) map[string]any {
	out := map[string]any{}
	for _, row := range rows {
		out[strconv.FormatInt(row.CopyID, 10)] = map[string]any{"is_open": flag(row.IsOpen), "is_win": flag(row.IsWin), "percent": row.Percent}
	}
	return out
}

func enemyStatus(waves map[int64][]guildcampaign.EnemyRow) map[string]any {
	out := map[string]any{}
	for wave, enemies := range waves {
		rows := make([]any, 0, len(enemies))
		for _, enemy := range enemies {
			row := map[string]any{"table_id": enemy.TableID, "lev": enemy.Lev, "star": enemy.Star, "color": enemy.Color, "health": enemy.Health}
			if enemy.HP > 0 {
				row["hp"] = enemy.HP
			}
			if enemy.Reborn != 0 {
				row["is_reborn"] = enemy.Reborn
			}
			rows = append(rows, row)
		}
		out[strconv.FormatInt(wave, 10)] = rows
	}
	return out
}

func awardWire(body guildcampaign.AwardBody) map[string]any {
	awards := make([]any, 0, len(body.Awards))
	for _, award := range body.Awards {
		members := make([]any, 0, len(award.Members))
		for _, member := range award.Members {
			members = append(members, map[string]any{"rank": member.Rank, "player_id": int64(member.Profile.PlayerID), "player_name": member.Profile.Name,
				"lev": member.Profile.Level, "avatar_id": member.Profile.AvatarID, "avatar_frame_id": member.Profile.AvatarFrameID,
				"conquer_lev": member.Profile.ConquerLevel, "conquer_loop_id": member.Profile.ConquerLoopID})
		}
		awards = append(awards, map[string]any{"award_id": award.AwardID, "award_num": award.AwardNum, "self_rank": award.SelfRank,
			"self_apply": award.SelfApply, "apply_member": members})
	}
	return map[string]any{"award_infos": awards, "award_next_time": body.NextApplyTime,
		"self_apply_info": map[string]any{"item_id": body.SelfItemID, "rank": body.SelfRank}, "guild_equip_apply_times": body.ApplyTimes}
}

func damageRank(rows []guildcampaign.RankRow) []any {
	out := make([]any, 0, len(rows))
	for _, row := range rows {
		out = append(out, map[string]any{"rank": row.Rank, "damage": row.Damage, "player_name": row.Profile.Name, "lev": row.Profile.Level,
			"avatar_id": row.Profile.AvatarID, "avatar_frame_id": row.Profile.AvatarFrameID, "conquer_lev": row.Profile.ConquerLevel,
			"conquer_loop_id": row.Profile.ConquerLoopID})
	}
	return out
}

func serverRank(view guildcampaign.ServerView) map[string]any {
	body := map[string]any{}
	if view.Fast != nil {
		body["fast_boss_killer"] = map[string]any{"name": view.Fast.GuildName, "guild_id": view.Fast.GuildID, "icon": int64(0), "cost_time": view.Fast.Seconds}
	}
	if view.Boss != nil {
		body["boss_killer"] = map[string]any{"player_name": view.Boss.Profile.Name, "guild_name": view.Boss.GuildName, "lev": view.Boss.Profile.Level,
			"time": view.Boss.At.Unix(), "avatar_id": view.Boss.Profile.AvatarID, "avatar_frame_id": view.Boss.Profile.AvatarFrameID,
			"conquer_lev": view.Boss.Profile.ConquerLevel, "conquer_loop_id": view.Boss.Profile.ConquerLoopID}
	}
	rows := make([]any, 0, len(view.Ranks))
	for _, row := range view.Ranks {
		rows = append(rows, map[string]any{"rank": row.Rank, "damage": row.Damage, "player_name": row.Profile.Name, "guild_name": "",
			"lev": row.Profile.Level, "avatar_id": row.Profile.AvatarID, "avatar_frame_id": row.Profile.AvatarFrameID,
			"conquer_lev": row.Profile.ConquerLevel, "conquer_loop_id": row.Profile.ConquerLoopID, "partners": []any{}})
	}
	body["rank_list"] = rows
	return body
}

func guildLog(rows []guildcampaign.LogRow) []any {
	out := make([]any, 0, len(rows))
	for _, row := range rows {
		out = append(out, map[string]any{"type": row.Type, "time": row.At.Unix(), "player_name": row.Profile.Name,
			"player_job": row.PlayerJob, "member_name": "", "chapter_id": row.ChapterID})
	}
	return out
}

func detailWire(view guildcampaign.DetailView) map[string]any {
	body := map[string]any{"current_index": view.CurrentIndex, "monster_status": enemyStatus(view.Waves), "is_open": flag(view.IsOpen),
		"is_win": flag(view.IsWin), "current_fight_player": view.CurrentFight, "last_fight_time": view.LastFight,
		"start_fight_time": view.StartFight, "stage": view.Stage}
	if view.FightInfo.PlayerID.Valid() {
		body["fight_info"] = map[string]any{"player_name": view.FightInfo.Name, "lev": view.FightInfo.Level,
			"avatar_id": view.FightInfo.AvatarID, "conquer_lev": view.FightInfo.ConquerLevel}
	}
	return body
}

func claimWire(view guildcampaign.ClaimView) map[string]any {
	body := map[string]any{"stage": view.Stage, "current_fight_player": view.HolderID}
	if view.LastFight != nil {
		body["last_fight_time"] = view.LastFight.Unix()
	}
	if view.StartFight != nil {
		body["start_fight_time"] = view.StartFight.Unix()
	}
	body["fight_info"] = map[string]any{"player_name": view.FightInfo.Name, "lev": view.FightInfo.Level, "avatar_id": view.FightInfo.AvatarID,
		"conquer_lev": view.FightInfo.ConquerLevel}
	return body
}

func flag(value bool) int64 {
	if value {
		return 1
	}
	return 0
}

func campaignBad() httpedge.Response {
	return httpedge.Response{HTTPStatus: http.StatusBadRequest, Body: map[string]any{"error": "guild_campaign_invalid_parameter"}}
}

func campaignUnavailable() httpedge.Response {
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Body: map[string]any{"error": "guild_campaign_unavailable"}}
}

// campaignFailure refuses with 409: a 200 without the reply's fields crashes
// the stock callbacks (Backend.lua:562-566).
func campaignFailure(err error) httpedge.Response {
	if errors.Is(err, guildcampaign.ErrUnavailable) {
		return campaignUnavailable()
	}
	return conflictRefusal(1)
}

// campaignSettleFailure keeps 610's two client-visible codes: a late result is
// 30021 (BattleCreate.lua:3115), and every other refusal is 409. A duplicate
// arrives as a 200 body with error_code 30005 from Settle.
func campaignSettleFailure(err error) httpedge.Response {
	if errors.Is(err, guildcampaign.ErrLate) {
		return conflictRefusal(30021)
	}
	return campaignFailure(err)
}
