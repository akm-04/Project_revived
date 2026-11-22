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
	EliteRanksTx(context.Context, tx.Queryer, identity.LogicalServerID, d.State) ([]RankCandidate, int64, error)
}
type RankDirectory interface {
	ProfileTx(context.Context, tx.Queryer, identity.PlayerID) (playerdirectory.Profile, bool, error)
}

const (
	normalRankSubtype int64 = 22
	eliteRankSubtype  int64 = 23
)

// RankList serves Sky Tower's two stock tabs: 22 ranks the normal highest
// floor, 23 ranks the elite highest floor. Both come from the same owner row.
func (s Mode) RankList(c context.Context, a identity.ActorContext, subtype int64, op operation.Context) (map[string]any, error) {
	if subtype != normalRankSubtype && subtype != eliteRankSubtype {
		return nil, d.ErrInvalid
	}
	return s.run(c, a, "rank", struct{ Subtype int64 }{subtype}, nil, 0, op, func(c context.Context, sc gen.TimedScope, v view, r *d.State) (map[string]any, error) {
		store, ok := s.Store.(RankStore)
		if !ok || s.Directory == nil {
			return nil, d.ErrUnavailable
		}
		candidates, rank, e := store.RanksTx(c, sc.Tx, a.LogicalServerID, *r)
		selfFloor := r.Max
		if subtype == eliteRankSubtype {
			candidates, rank, e = store.EliteRanksTx(c, sc.Tx, a.LogicalServerID, *r)
			selfFloor = r.EliteMax
		}
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
		return petcampaignRankListBody(subtype, rank, selfFloor, rows), nil
	})
}

// petcampaignRankListBody sends an empty my_rank table when the viewer is not
// ranked; the stock rank window hides the rank number for an empty table.
func petcampaignRankListBody(subtype, rank, selfFloor int64, rows []map[string]any) map[string]any {
	mine := map[string]any{}
	if rank > 0 {
		mine = map[string]any{"rank": rank, "my_floor": selfFloor}
	}
	return map[string]any{"rank_list": []map[string]any{{"rank_type": subtype, "rank_info": map[string]any{"my_rank": mine, "rank_info": rows}}}}
}
