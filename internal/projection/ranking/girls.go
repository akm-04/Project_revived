package ranking

import (
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/ranking"
)

// GirlsList preserves RankList.lua's nested rank_info/my_rank structure and
// subtype37 identity. Source/internal snapshot evidence is never a wire field.
func GirlsList(s d.GirlsSnapshot, viewer identity.PlayerID) (map[string]any, error) {
	if s.Validate() != nil || !viewer.Valid() {
		return nil, d.ErrSnapshot
	}
	rows := []map[string]any{}
	mine := map[string]any{}
	found := false
	for i, v := range s.Entries {
		rank := int64(i + 1)
		p := v.Display
		rows = append(rows, map[string]any{"player_id": int64(p.Player), "player_name": p.Name, "level": p.Level, "avatar_id": p.AvatarID, "avatar_frame_id": p.FrameID, "conquer_lev": p.ConquerLevel, "conquer_loop_id": p.ConquerLoopID, "score": v.Metric.Value, "rank": rank})
		if p.Player == viewer {
			found = true
			mine = map[string]any{"rank": rank, "score": v.Metric.Value}
		}
	}
	if !found {
		return nil, d.ErrSnapshot
	}
	return map[string]any{"rank_list": []map[string]any{{"rank_type": int64(37), "rank_info": map[string]any{"my_rank": mine, "rank_info": rows}}}}, nil
}
