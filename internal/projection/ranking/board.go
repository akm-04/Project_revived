package ranking

import (
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/ranking"
)

// BoardRows preserves RankList.lua's row fields and the board's value key. A
// published row without its canonical directory presentation stays unavailable.
func BoardRows(rows []d.ScoreRow, displays map[identity.PlayerID]d.BoardPresentation, rowValue string) ([]map[string]any, error) {
	out := make([]map[string]any, 0, len(rows))
	for i, row := range rows {
		p, ok := displays[row.Player]
		if !ok || !p.Valid() || p.Player != row.Player || !row.Player.Valid() || row.Score < 0 || rowValue == "" {
			return nil, d.ErrSnapshot
		}
		out = append(out, map[string]any{"player_id": int64(p.Player), "player_name": p.Name, "level": p.Level, "avatar_id": p.AvatarID, "avatar_frame_id": p.FrameID, "conquer_lev": p.ConquerLevel, "conquer_loop_id": p.ConquerLoopID, rowValue: row.Score, "rank": int64(i + 1)})
	}
	return out, nil
}

// BoardList is RankList.lua's nested rank_info/my_rank shape. my_rank is empty
// when the viewer has no stored row, at any rank outside the page included.
func BoardList(subType int64, rows []map[string]any, myRank map[string]any) map[string]any {
	return map[string]any{"rank_list": []map[string]any{{"rank_type": subType, "rank_info": map[string]any{"my_rank": myRank, "rank_info": rows}}}}
}
