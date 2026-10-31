package worldboss

import (
	"context"

	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/worldboss"
	"gxb.local/backend/v2/internal/foundation/operation"
)

// BossRank projects the shared 276 boss_rank aggregate for all five bosses.
func (s Mode) BossRank(c context.Context, a identity.ActorContext, _ operation.Context) ([]map[string]any, error) {
	if s.Fresh == nil || s.Store == nil || s.Directory == nil {
		return nil, d.ErrUnavailable
	}
	occurrence, found, err := s.Store.ReadOccurrenceTx(c, s.Fresh, int64(a.LogicalServerID))
	if err != nil {
		return nil, err
	}
	if !found {
		occurrence = d.Occurrence{LogicalServerID: int64(a.LogicalServerID), Generation: 1, CurrentBoss: d.FirstBossID}
	}
	ranks, err := s.Store.ReadRankTx(c, s.Fresh, occurrence.LogicalServerID, occurrence.Generation, rankLimit)
	if err != nil {
		return nil, err
	}
	ordered := d.OrderRank(ranks)
	infos := make([]map[string]any, 0, len(ordered))
	for index, entry := range ordered {
		profile, found, err := s.Directory.ProfileTx(c, s.Fresh, identity.PlayerID(entry.PlayerID))
		if err != nil {
			return nil, err
		}
		if !found {
			continue
		}
		infos = append(infos, map[string]any{"player_id": entry.PlayerID, "player_name": profile.Name, "level": profile.Level, "avatar_id": profile.AvatarID,
			"avatar_frame_id": profile.AvatarFrameID, "total_hurt": entry.TotalHurt, "title_info": "", "conquer_lev": profile.ConquerLevel,
			"conquer_loop_id": profile.ConquerLoopID, "rank": int64(index + 1)})
	}
	rank, _ := d.RankOf(ranks, int64(a.PlayerID))
	hurt, err := s.personalHurt(c, s.Fresh, occurrence, int64(a.PlayerID))
	if err != nil {
		return nil, err
	}
	boards := make([]map[string]any, 0, 5)
	for bossID := int64(d.FirstBossID); bossID <= d.LastBossID; bossID++ {
		boards = append(boards, map[string]any{"boss_id": bossID, "infos": infos, "my_rank": rank, "my_hurt": hurt})
	}
	return boards, nil
}
