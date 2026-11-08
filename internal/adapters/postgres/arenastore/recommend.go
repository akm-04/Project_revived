package arenastore

import (
	"context"
	"encoding/json"
	"time"

	d "gxb.local/backend/v2/internal/domain/herorecommend"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// HeroRecommendSourceTx is the bounded Arena surface for the recommendation
// owner. Arena usage already stores hero table ids, not partner ids.
func (Store) HeroRecommendSourceTx(c context.Context, q tx.Queryer, server identity.LogicalServerID, at time.Time, limit int) (d.Source, error) {
	out := d.Source{}
	if q == nil || !server.Valid() || at.IsZero() || limit <= 0 || limit > d.MaxSourceScan {
		return out, d.ErrUnavailable
	}
	var popularity string
	if e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_object('table_id',table_id,'player_id',player_id,'score',score) ORDER BY score DESC,table_id),'[]'::jsonb)::text FROM(
		SELECT table_id,player_id,score FROM(
			SELECT u.table_id,u.player_id,SUM(u.fights+2*u.wins+u.kill_count)OVER(PARTITION BY u.table_id)AS score,
			 ROW_NUMBER()OVER(PARTITION BY u.table_id ORDER BY(u.fights+2*u.wins+u.kill_count)DESC,u.player_id)AS rn
			FROM arena_partner_usage u JOIN arena_players p ON p.player_id=u.player_id
			WHERE p.logical_server_id=$1
		)ranked WHERE rn=1 ORDER BY score DESC,table_id LIMIT $2
	)x`, int64(server), limit).Scan(&popularity); e != nil {
		return out, e
	}
	if e := json.Unmarshal([]byte(popularity), &out.Popularity); e != nil {
		return out, e
	}
	var formations string
	if e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_object('player_id',player_id,'defense',defense,'weight',weight) ORDER BY star DESC,point DESC,player_id),'[]'::jsonb)::text FROM(
		SELECT player_id,defense,star*1000+point weight,star,point FROM arena_players
		WHERE logical_server_id=$1 AND jsonb_array_length(defense->'heroes')>0
		ORDER BY star DESC,point DESC,player_id LIMIT $2)x`, int64(server), limit).Scan(&formations); e != nil {
		return out, e
	}
	var rows []struct {
		PlayerID int64 `json:"player_id"`
		Defense  struct {
			Heroes []int64 `json:"heroes"`
			Pet    int64   `json:"pet"`
		} `json:"defense"`
		Weight int64 `json:"weight"`
	}
	if e := json.Unmarshal([]byte(formations), &rows); e != nil {
		return out, e
	}
	for _, row := range rows {
		out.Formations = append(out.Formations, d.Formation{PlayerID: row.PlayerID, TableIDs: row.Defense.Heroes, PetID: row.Defense.Pet, Weight: row.Weight})
	}
	return out, nil
}
