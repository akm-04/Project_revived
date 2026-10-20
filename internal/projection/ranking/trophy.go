package ranking

import "gxb.local/backend/v2/internal/application/achievement"

const trophyRankType int64 = 15

// TrophyList is RankList.lua's rank_types 15 shape; NewRankWindow reads point,
// region_name and region_id for SubRankType.ACHIEVEMENT_POINT rows.
func TrophyList(b achievement.TrophyBoard) map[string]any {
	rows := []map[string]any{}
	for _, v := range b.Rows {
		p := v.Profile
		rows = append(rows, map[string]any{"player_id": int64(v.Player), "player_name": p.Name, "level": p.Level, "avatar_id": p.AvatarID, "avatar_frame_id": p.AvatarFrameID, "conquer_lev": p.ConquerLevel, "conquer_loop_id": p.ConquerLoopID, "region_id": int64(b.Server), "region_name": b.Region, "point": v.Points, "rank": v.Rank})
	}
	mine := map[string]any{"rank": b.MyRank, "point": b.MyPoints}
	return map[string]any{"rank_list": []map[string]any{{"rank_type": trophyRankType, "rank_info": map[string]any{"my_rank": mine, "rank_info": rows}}}}
}
