// Package championsleague projects the actual src_64 ChampionsLeague callers.
package championsleague

import (
	d "gxb.local/backend/v2/internal/domain/championsleague"
	"gxb.local/backend/v2/internal/domain/identity"
)

func flag(b bool) int64 {
	if b {
		return 1
	}
	return 0
}
func Face(f d.Face) map[string]any {
	return map[string]any{"player_id": int64(f.ID), "player_name": f.Name, "lev": f.Level, "level": f.Level, "avatar_id": f.Avatar, "avatar_frame_id": f.Frame, "conquer_lev": f.Conquer, "conquer_loop_id": f.Loop, "guild_id": f.GuildID, "guild_name": f.GuildName}
}
func Enemy(v d.EnemyView) map[string]any {
	row := Face(v.Face)
	row["rank"] = v.Rank
	row["point"] = v.Player.Points
	row["last_attacked_time"] = stamp(v.Player.LastAttacked.Unix())
	rows := v.Heroes
	if rows == nil {
		rows = []map[string]any{}
	}
	row["heros"] = rows
	if v.Pet != nil {
		row["pet"] = v.Pet
	}
	return row
}
func stamp(t int64) int64 {
	if t < 0 {
		return 0
	}
	return t
}
func Info(v d.InfoView) map[string]any {
	enemies := []map[string]any{}
	for _, x := range v.Enemies {
		enemies = append(enemies, Enemy(x))
	}
	p := v.Player
	day := int64((v.At.Unix() + 28800 - 79200) / 86400)
	boundary := day*86400 - 28800 + 79200
	rank := map[string]any{"group": p.Group, "rank": v.Rank, "point": p.Points, "group_check": flag(p.ChoicePending)}
	if v.Final.Group > 0 && v.Final.Rank > 0 {
		rank["ori_group"] = v.Final.Group
		rank["ori_rank"] = v.Final.Rank
	}
	return map[string]any{"base_info": map[string]any{"season_count": p.Season, "total_fight": p.Fights, "win_fight": p.Wins, "last_attacked_time": stamp(p.LastAttacked.Unix()), "last_win_time": stamp(p.LastWin.Unix()), "can_daily_award": flag(p.ClaimedDay < day && p.LastWin.Unix() > boundary), "last_day_group": p.LastDay.Group, "last_day_rank": p.LastDay.Rank}, "rank_info": rank, "defense_info": Enemy(v.Defense), "enemy_info": enemies, "stage": int64(2) - flag(v.Active), "server_time": v.At.Unix()}
}
func report(raw []byte) []map[string]any {
	if len(raw) == 0 {
		return []map[string]any{}
	}
	return []map[string]any{{"content": string(raw)}}
}
func Fight(v d.Reply) map[string]any {
	m := v.Match
	enemy := Face(m.EnemyFace)
	enemy["heros"] = m.EnemyRows
	enemy["is_robot"] = false
	if m.EnemyPet != nil {
		enemy["pet"] = m.EnemyPet
	}
	key := ""
	if len(v.Report) > 0 {
		key = m.Attempt.String()
	}
	return map[string]any{"self_formation": m.SelfRows, "enemy_formation": enemy, "battle_report": report(v.Report), "report_key": key, "is_win": flag(m.Win), "partner_favor": map[string]any{}, "award_crystal": int64(0), "items": []any{}}
}
func RecordRows(records []d.Match, self identity.PlayerID) map[string]any {
	out := []map[string]any{}
	for _, m := range records {
		attack := m.Attacker == self
		win, delta := m.Win, m.Delta
		if !attack {
			win, delta = !win, -delta
		}
		row := map[string]any{"id": m.WireID, "is_attack": flag(attack), "win": flag(win), "change_point": delta, "time": m.SettledAt.Unix()}
		for prefix, f := range map[string]d.Face{"attack": m.SelfFace, "defend": m.EnemyFace} {
			row[prefix+"_name"] = f.Name
			row[prefix+"_avatar"] = f.Avatar
			row[prefix+"_avatar_frame"] = f.Frame
			row[prefix+"_lev"] = f.Level
			row[prefix+"_conquer_lev"] = f.Conquer
			row[prefix+"_conquer_loop_id"] = f.Loop
		}
		out = append(out, row)
	}
	return map[string]any{"records": out, "reports": map[string]any{}}
}
func Report(raw []byte) map[string]any {
	if len(raw) == 0 {
		return map[string]any{}
	}
	return map[string]any{"report": report(raw)}
}
func Honor(rows []d.SettlementRow) []map[string]any {
	out := []map[string]any{}
	for _, r := range rows {
		row := map[string]any{"player_info": Face(r.Face), "heros": r.Heroes, "rank": r.Placement.Rank}
		if r.Pet != nil {
			row["pet"] = r.Pet
		}
		out = append(out, row)
	}
	return out
}
