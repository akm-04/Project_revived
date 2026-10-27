package petcampaign

import (
	"context"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/petcampaign"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type RankCandidate struct {
	Player identity.PlayerID
	Floor  int64
}
type RankStore interface {
	RanksTx(context.Context, tx.Queryer, identity.LogicalServerID, d.State) ([]RankCandidate, int64, error)
}
type RankDirectory interface {
	ProfileTx(context.Context, tx.Queryer, identity.PlayerID) (playerdirectory.Profile, bool, error)
}

func (s Mode) RankList(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	return s.run(c, a, "rank", struct{}{}, nil, 0, op, func(c context.Context, sc gen.TimedScope, v view, r *d.State) (map[string]any, error) {
		store, ok := s.Store.(RankStore)
		if !ok || s.Directory == nil {
			return nil, d.ErrUnavailable
		}
		candidates, rank, e := store.RanksTx(c, sc.Tx, a.LogicalServerID, *r)
		if e != nil {
			return nil, e
		}
		rows := []map[string]any{}
		for i, row := range candidates {
			p, found, e := s.Directory.ProfileTx(c, sc.Tx, row.Player)
			if e != nil {
				return nil, e
			}
			if !found {
				return nil, d.ErrUnavailable
			}
			rows = append(rows, map[string]any{"player_id": int64(p.PlayerID), "player_name": p.Name, "level": p.Level, "avatar_id": p.AvatarID, "avatar_frame_id": p.AvatarFrameID, "conquer_lev": p.ConquerLevel, "conquer_loop_id": p.ConquerLoopID, "rank": int64(i + 1), "max_floor": row.Floor, "score": row.Floor})
		}
		return map[string]any{"rank_list": []map[string]any{{"rank_type": int64(22), "rank_info": map[string]any{"my_rank": map[string]any{"rank": rank, "my_floor": r.Max}, "rank_info": rows}}}}, nil
	})
}
