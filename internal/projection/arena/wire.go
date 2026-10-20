// Package arena maps Arena views to the src_64 wire shapes of RegionArena.lua,
// RegionArenaWindow, FoundEnemyWindow, SelectTeamRearenaWindow,
// RegionArenaHeroShopWindow, RegionBattleScoresWindow and NewRankWindow.
package arena

import (
	"strconv"

	d "gxb.local/backend/v2/internal/domain/arena"
)

func flag(b bool) int64 {
	if b {
		return 1
	}
	return 0
}

func awards(p d.Player) []map[string]any {
	out := []map[string]any{}
	for _, a := range p.Awards {
		out = append(out, map[string]any{"table_id": a.TableID, "add_star": a.AddStar, "is_awake": flag(a.Awake), "is_summon": flag(a.Summon), "region_arena_times": a.Picks})
	}
	return out
}

func missions(p d.Player) []map[string]any {
	out := []map[string]any{}
	for _, m := range p.Missions {
		out = append(out, map[string]any{"mission_id": m.MissionID, "current_num": m.Current, "is_complete": flag(m.Complete)})
	}
	return out
}

// Info is GET_REARENA_INFO (RegionArena.onGetRegionArenaInfo_ and SubArenaWindow).
func Info(v d.InfoView) map[string]any {
	p := v.Player
	days := int64(v.At.Sub(v.Season.OpensAt).Hours()/24) + 1
	body := map[string]any{"daily_fight": p.DailyFights, "defence_formation": p.Defense.Heroes, "pet_id": p.Defense.Pet, "index": int64(1), "win_times": p.WinTimes,
		"total_fight": p.TotalFight, "keep_win_times": p.KeepWin, "point": p.Point, "star": p.Star, "total": v.Total, "my_rank": v.Rank, "count": v.Season.Number,
		"day_count": max(days, 0), "missions": missions(p), "mission_time": p.MissionTime.Unix(), "awards": awards(p), "king_coin": v.KingCoin, "is_close": flag(v.Closed)}
	for i, times := range p.ExchangeTimes {
		body["exchange_times_"+strconv.Itoa(i+1)] = times
	}
	return body
}

// Missions answers 666/848/849 with the mission list, mission time and the
// exchange award or claimed coins; economy_ refreshes SelfPlayer.kingCoin.
func Missions(v d.MissionsView) map[string]any {
	body := map[string]any{"missions": missions(v.Player), "mission_time": v.Player.MissionTime.Unix(), "economy_": map[string]any{"king_coin": v.KingCoin}}
	if v.Coins > 0 {
		// AlertAwardWindow shows a named currency as table_id -1 with its eco_type key.
		body["awards"] = []map[string]any{{"table_id": int64(-1), "item_num": v.Coins, "king_coin": v.Coins}}
	}
	if v.Award != nil {
		body["award"] = map[string]any{"table_id": v.Award.TableID, "add_star": v.Award.AddStar, "is_awake": flag(v.Award.Awake), "is_summon": flag(v.Award.Summon), "region_arena_times": v.Award.Picks}
	}
	return body
}

// Partners is GET_REARENA_PARTNERS (RegionBattleScoresWindow).
func Partners(v d.PartnersView) map[string]any {
	rows := []map[string]any{}
	for _, u := range v.Usage {
		damage, _ := strconv.ParseFloat(u.Harms, 64)
		rows = append(rows, map[string]any{"table_id": u.TableID, "total_fight": u.Fights, "win_fight": u.Wins, "total_damage": int64(damage), "total_kill": u.Kills})
	}
	return map[string]any{"partner_info": rows, "arena_info": map[string]any{"total_fight": v.Player.TotalFight, "win_times": v.Player.WinTimes, "point": v.Player.Point}}
}

// Enemy is REARENA_MATCH_ENEMY (RegionArenaWindow match_btn -> FoundEnemyWindow).
func Enemy(v d.EnemyView) map[string]any {
	heroes := v.Heroes
	if heroes == nil {
		heroes = []map[string]any{}
	}
	body := map[string]any{"heros": heroes, "pet_id": int64(0), "avatar_id": v.Face.AvatarID, "avatar_frame": v.Face.FrameID, "win_times": v.Standing.WinTimes,
		"total_fight": v.Standing.TotalFight, "player_name": v.Face.Name, "region_name": v.Face.ServerName, "guild_name": v.Face.GuildName, "player_id": int64(v.Face.Player),
		"self_region_name": v.SelfServerName, "region": int64(v.Face.Server)}
	if v.Pet != nil {
		body["pet_id"], body["pet_info"] = v.Pet["pet_id"], v.Pet
	}
	return body
}

// Fight is REARENA_FIGHT: battle_report[1].content is the report JSON the
// loading window decodes; an empty list makes the client re-send FIGHT.
func Fight(v d.FightView) map[string]any {
	if v.Unresolved {
		return map[string]any{"battle_report": []any{}}
	}
	return map[string]any{"battle_report": []map[string]any{{"content": string(v.Report)}}, "is_win": flag(v.Win),
		"arena_info": map[string]any{"star": v.Player.Star, "point": v.Player.Point, "win_times": v.Player.WinTimes, "total_fight": v.Player.TotalFight, "keep_win_times": v.Player.KeepWin},
		"award":      []map[string]any{}, "economy_": map[string]any{"region_coin": v.RegionCoin}}
}

// Records is REARENA_FIGHT_RECORDS for RegionBattleScoresWindow.
func Records(records []d.RecordView) map[string]any {
	out := []map[string]any{}
	for _, r := range records {
		out = append(out, map[string]any{"player_name": r.Opponent.Name, "time": r.Record.At.Unix(), "avatar_id": r.Opponent.AvatarID, "avatar_frame_id": r.Opponent.FrameID,
			"win": flag(r.Record.Win), "report_key": r.ReportKey, "player_id": int64(r.Opponent.Player)})
	}
	return map[string]any{"records": out}
}

// Report is REARENA_FIGHT_REPORT: report[1].content (replayRecord decodes it).
func Report(raw []byte) map[string]any {
	if raw == nil {
		return map[string]any{}
	}
	return map[string]any{"report": []map[string]any{{"content": string(raw)}}}
}

func rankRow(e d.RankEntry) map[string]any {
	return map[string]any{"player_id": int64(e.Face.Player), "player_name": e.Face.Name, "avatar_id": e.Face.AvatarID, "avatar_frame_id": e.Face.FrameID, "lev": e.Face.Level,
		"level": e.Level, "star": e.Standing.Star, "point": e.Standing.Point, "total_fight": e.Standing.TotalFight, "win_times": e.Standing.WinTimes, "region": int64(e.Face.Server),
		"region_name": e.Face.ServerName, "guild_name": e.Face.GuildName, "conquer_lev": e.Face.ConquerLevel, "conquer_loop_id": e.Face.ConquerLoop, "rank": e.Rank}
}

// RankList is the 301 body for rank_types 6 (SubRankType.REGION_ARENA_RANK).
func RankList(list d.RankList) map[string]any {
	rows := []map[string]any{}
	for _, e := range list.Rows {
		rows = append(rows, rankRow(e))
	}
	return map[string]any{"rank_list": []map[string]any{{"rank_type": int64(6), "rank_info": map[string]any{"my_rank": list.Mine.Rank, "rank_info": rows}}}}
}
