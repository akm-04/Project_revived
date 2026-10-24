// Package topfloor maps Top Floor views to the src_64 wire shapes of Arena.lua,
// ArenaWindow, ArenaSelectTeamNewWindow, ArenaRecordWindow and RankList.
package topfloor

import (
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/topfloor"
)

func unix(t *time.Time) int64 {
	if t == nil {
		return 0
	}
	return t.Unix()
}

func flag(b bool) int64 {
	if b {
		return 1
	}
	return 0
}

// heroes keeps source populate rows. A real player whose table_id falls in the
// client's robot range (<= 25000) has each row's partner_id carry its template
// table_id, because the client then reads heroes as robot rows.
func heroes(v d.Display) []map[string]any {
	out := []map[string]any{}
	looksRobot := !v.Occupant.IsRobot() && v.Occupant.TableID() <= d.RobotTableLimit
	for _, h := range v.Heroes {
		if !looksRobot {
			out = append(out, h)
			continue
		}
		row := make(map[string]any, len(h))
		for k, x := range h {
			row[k] = x
		}
		row["partner_id"] = h["table_id"]
		out = append(out, row)
	}
	return out
}

func Enemy(v d.Display) map[string]any {
	row := map[string]any{"table_id": v.Occupant.TableID(), "player_name": v.Name, "lev": v.Level, "avatar_id": v.AvatarID, "avatar_frame_id": v.FrameID, "win": v.Wins, "rank": v.Rank, "force": v.Force,
		"guild_name": v.GuildName, "ban_hero_id": int64(0), "conquer_lev": v.ConquerLevel, "conquer_loop_id": v.ConquerLoop, "heros": heroes(v), "book_shelf_lev": int64(0)}
	if v.Pet != nil {
		row["pet"] = v.Pet
	}
	return row
}

func Arena(p d.Player, rank int64, enemies []d.Display, serverTime time.Time) map[string]any {
	rows := []map[string]any{}
	for _, e := range enemies {
		rows = append(rows, Enemy(e))
	}
	return map[string]any{"rank": rank, "best_rank": p.BestRank, "defense": p.Defense, "left_time": p.TicketsLeft, "buy_num": p.Purchases, "last_match_time": unix(p.LastMatchAt),
		"update_count": p.RefreshCount, "enemies": rows, "pet_id": p.DefensePet, "server_time": serverTime.Unix(), "ban_hero_id": int64(0), "is_ban_open": int64(0),
		"set_formation_time": unix(p.DefenseSetAt), "fight_times": p.Fights}
}

func Enemies(enemies []d.Display) map[string]any {
	rows := []map[string]any{}
	for _, e := range enemies {
		rows = append(rows, Enemy(e))
	}
	return map[string]any{"enemies": rows}
}

func Ticket(p d.Player) map[string]any {
	return map[string]any{"left_time": p.TicketsLeft, "last_match_time": unix(p.LastMatchAt), "buy_num": p.Purchases}
}

func ResetTimer(p d.Player) map[string]any {
	return map[string]any{"last_match_time": unix(p.LastMatchAt)}
}

// report is the source battle_report array; empty while the result is pending,
// which makes the client repeat the same START after 3 s.
func report(raw []byte) []map[string]any {
	if raw == nil {
		return []map[string]any{}
	}
	return []map[string]any{{"content": string(raw)}}
}

func Fight(formation []map[string]any, raw []byte, win bool, award int64, enemy d.Display) map[string]any {
	enemyFormation := map[string]any{"player_name": enemy.Name, "guild_id": enemy.GuildID, "guild_name": enemy.GuildName, "is_robot": enemy.Occupant.IsRobot(), "heros": heroes(enemy), "conquer_lev": enemy.ConquerLevel}
	if enemy.Pet != nil {
		enemyFormation["pet"] = enemy.Pet
	}
	return map[string]any{"formation": formation, "battle_report": report(raw), "partner_favor": map[string]any{}, "award_crystal": award, "is_win": flag(win), "enemy_formation": enemyFormation, "items": []any{}}
}

func Report(raw []byte) map[string]any {
	if raw == nil {
		return map[string]any{}
	}
	return map[string]any{"report": report(raw)}
}

type Record struct {
	ID       int64
	Key      string
	At       time.Time
	Attack   bool
	Win      bool
	Self     d.Display
	Opponent d.Display
}

func side(prefix string, v d.Display, row map[string]any) {
	row[prefix+"_name"], row[prefix+"_avatar"], row[prefix+"_avatar_frame"] = v.Name, v.AvatarID, v.FrameID
	row[prefix+"_lev"], row[prefix+"_conquer_lev"], row[prefix+"_conquer_loop_id"] = v.Level, v.ConquerLevel, v.ConquerLoop
}

func Records(records []Record) map[string]any {
	rows := []map[string]any{}
	for _, r := range records {
		row := map[string]any{"id": r.ID, "time": r.At.Unix(), "is_attack": flag(r.Attack), "win": flag(r.Win), "report_key": r.Key}
		attacker, defender := r.Self, r.Opponent
		if !r.Attack {
			attacker, defender = r.Opponent, r.Self
		}
		side("attack", attacker, row)
		side("defend", defender, row)
		rows = append(rows, row)
	}
	return map[string]any{"records": rows}
}

func RecordInfo(v d.Display, canAvenge bool, avengeType int64) map[string]any {
	row := Enemy(v)
	row["can_avenge"], row["avenge_type"], row["is_robot"] = flag(canAvenge), avengeType, v.Occupant.IsRobot()
	return map[string]any{"records": row}
}

func Formation(v d.Display) map[string]any {
	return Enemy(v)
}

// RankList is LOAD_RANK_LIST sub_type 1; the client reads my_rank as a number and score as the rank.
func RankList(rows []d.Display, myRank int64, server identity.LogicalServerID) map[string]any {
	out := []map[string]any{}
	for _, v := range rows {
		id := int64(v.Occupant.Player)
		if v.Occupant.IsRobot() {
			id = v.Occupant.Robot + int64(server)*d.RegionStride
		}
		out = append(out, map[string]any{"player_id": id, "player_name": v.Name, "level": v.Level, "avatar_id": v.AvatarID, "avatar_frame_id": v.FrameID, "conquer_lev": v.ConquerLevel, "conquer_loop_id": v.ConquerLoop, "score": v.Rank, "rank": v.Rank})
	}
	return map[string]any{"rank_list": []map[string]any{{"rank_type": int64(1), "rank_info": map[string]any{"my_rank": myRank, "rank_info": out}}}}
}
