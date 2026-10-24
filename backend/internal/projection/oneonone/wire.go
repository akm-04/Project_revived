// Package oneonone maps 1 on 1 views to the src_64 wire shapes of PeakArena.lua,
// PeakArenaWindow, ChangeEnemyWindow, SelectPeakTeamWindow, PeakArenaReportWindow,
// NewArenaRecordWindow (SUPER_ARENA) and NewRankWindow.
package oneonone

import (
	"strconv"
	"strings"
	"time"

	d "gxb.local/backend/v2/internal/domain/oneonone"
)

// putUnix omits an unset time: stock decodes JSON null to the truthy cjson.null, and PeakArena:setCoolTime and
// PeakArenaWindow add to these times when present.
func putUnix(out map[string]any, key string, t *time.Time) {
	if t == nil {
		return
	}
	out[key] = t.Unix()
}

func flag(b bool) int64 {
	if b {
		return 1
	}
	return 0
}

func RankInfo(r d.Ranked) map[string]any {
	return map[string]any{"rank_level": r.Level, "rank": r.Global, "region_rank": r.ServerRank, "rank_point": r.Points}
}

func BaseInfo(v d.ArenaView) map[string]any {
	p := v.Player
	out := map[string]any{"buy_times": p.Purchases, "left_times": p.TriesLeft, "mode": p.Mode, "promote_challenge_times": p.Challenges, "promote_wins": p.PromotionWins}
	putUnix(out, "last_fight_time", p.LastFightAt)
	putUnix(out, "last_promote_fight_time", p.LastPromotionAt)
	putUnix(out, "promote_end_time", v.PromotionEnd)
	return out
}

// Formations encodes teams as generatePartnerIds strings "id|id@pet".
func Formations(teams []d.Team) []string {
	out := []string{}
	for _, t := range teams {
		parts := []string{}
		for _, h := range t.Heroes {
			parts = append(parts, strconv.FormatInt(h, 10))
		}
		text := strings.Join(parts, "|")
		if t.Pet > 0 {
			text += "@" + strconv.FormatInt(t.Pet, 10)
		}
		out = append(out, text)
	}
	return out
}

// ParseFormations reads generatePartnerIds strings; the empty pet is omitted.
func ParseFormations(raw []string) ([]d.Team, bool) {
	out := []d.Team{}
	for _, text := range raw {
		heroes, pet, _ := strings.Cut(text, "@")
		t := d.Team{Heroes: []int64{}}
		for _, part := range strings.Split(heroes, "|") {
			n, err := strconv.ParseInt(part, 10, 64)
			if err != nil {
				return nil, false
			}
			t.Heroes = append(t.Heroes, n)
		}
		if pet != "" {
			n, err := strconv.ParseInt(pet, 10, 64)
			if err != nil {
				return nil, false
			}
			t.Pet = n
		}
		out = append(out, t)
	}
	return out, true
}

func Load(v d.ArenaView) map[string]any {
	return map[string]any{"rank_info": RankInfo(v.Ranked), "base_info": BaseInfo(v), "defense": Formations(v.Player.Teams)}
}

func PlayerInfo(f d.Face) map[string]any {
	return map[string]any{"player_id": int64(f.Player), "player_name": f.Name, "avatar_id": f.AvatarID, "avatar_frame_id": f.FrameID, "lev": f.Level, "conquer_lev": f.ConquerLevel, "conquer_loop_id": f.ConquerLoop}
}

func Matches(rows []d.Entry) map[string]any {
	out := []map[string]any{}
	for _, r := range rows {
		out = append(out, map[string]any{"player_info": PlayerInfo(r.Face), "rank_info": RankInfo(r.Ranked)})
	}
	return map[string]any{"match_infos": out}
}

func Teams(teams []d.TeamView) []map[string]any {
	out := []map[string]any{}
	for _, t := range teams {
		pet := map[string]any{}
		if t.Pet != nil {
			pet = t.Pet
		}
		heroes := t.Heroes
		if heroes == nil {
			heroes = []map[string]any{}
		}
		out = append(out, map[string]any{"formation_info": heroes, "pet_info": pet})
	}
	return out
}

func Start(v d.MatchView) map[string]any {
	return map[string]any{"rank_info": RankInfo(v.Arena.Ranked), "base_info": BaseInfo(v.Arena), "report_keys": v.ReportKeys, "is_win": flag(v.Win), "wins": v.Wins,
		"items": []any{}, "partner_favor": map[string]any{}}
}

// Report is the round's report JSON string; an expired one answers empty.
func Report(raw []byte) map[string]any {
	if raw == nil {
		return map[string]any{}
	}
	return map[string]any{"report": string(raw)}
}

// ReportKeys is the bare array SelfPlayer:loadPeakArenaReports iterates.
func ReportKeys(keys []string) []map[string]any {
	out := []map[string]any{}
	for _, k := range keys {
		out = append(out, map[string]any{"report_key": k})
	}
	return out
}

func Records(records []d.RecordView) map[string]any {
	out := []map[string]any{}
	for _, r := range records {
		out = append(out, map[string]any{"record_id": r.Record.ID, "attack_player_info": PlayerInfo(r.Attacker), "defense_player_info": PlayerInfo(r.Defender),
			"is_win": flag(r.Record.Win), "mode": r.Record.Mode, "time": r.Record.At.Unix()})
	}
	return map[string]any{"battle_records": out}
}

func RecordDetail(v d.RecordDetail) map[string]any {
	return map[string]any{"report_keys": v.ReportKeys, "wins": v.Wins, "attack_formations": Teams(v.Attack), "defense_formations": Teams(v.Defense)}
}

// RankList is the 301 body for rank_types 3 (global) or 4 (server); score is
// the slot for Master/Senior and points for Juniors, as PeakArenaWindow shows.
func RankList(list d.RankList, rankType int64) map[string]any {
	position := func(r d.Ranked) int64 {
		if rankType == 4 {
			return r.ServerRank
		}
		return r.Global
	}
	score := func(r d.Ranked) int64 {
		if r.Level < d.LevelJunior1 {
			return r.Global
		}
		return r.Points
	}
	rows := []map[string]any{}
	for _, r := range list.Rows {
		row := PlayerInfo(r.Face)
		row["level"], row["rank_level"], row["rank"], row["score"], row["server_id"] = r.Face.Level, r.Ranked.Level, position(r.Ranked), score(r.Ranked), int64(r.Ranked.Server)
		rows = append(rows, row)
	}
	return map[string]any{"rank_list": []map[string]any{{"rank_type": rankType, "rank_info": map[string]any{"my_rank": position(list.Mine), "rank_info": rows}}}}
}
