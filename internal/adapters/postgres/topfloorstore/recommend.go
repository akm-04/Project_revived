package topfloorstore

import (
	"context"
	"encoding/json"
	"time"

	d "gxb.local/backend/v2/internal/domain/herorecommend"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// HeroRecommendSourceTx is the bounded Top Floor surface for the recommendation
// owner: server-scoped partner usage and the best defended formations.
func (Store) HeroRecommendSourceTx(c context.Context, q tx.Queryer, server identity.LogicalServerID, at time.Time, limit int) (d.Source, error) {
	out := d.Source{}
	if q == nil || !server.Valid() || at.IsZero() || limit <= 0 || limit > d.MaxSourceScan {
		return out, d.ErrUnavailable
	}
	var popularity string
	if e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_object('partner_id',partner_id,'player_id',player_id,'score',score) ORDER BY score DESC,partner_id),'[]'::jsonb)::text FROM(
		SELECT partner_id,player_id,score FROM(
			SELECT u.partner_id,u.player_id,SUM(u.fights+2*u.wins+u.kill_count)OVER(PARTITION BY u.partner_id)AS score,
			 ROW_NUMBER()OVER(PARTITION BY u.partner_id ORDER BY(u.fights+2*u.wins+u.kill_count)DESC,u.player_id)AS rn
			FROM top_floor_partner_usage u JOIN top_floor_players p ON p.player_id=u.player_id
			WHERE p.logical_server_id=$1
		)ranked WHERE rn=1 ORDER BY score DESC,partner_id LIMIT $2
	)x`, int64(server), limit).Scan(&popularity); e != nil {
		return out, e
	}
	if e := json.Unmarshal([]byte(popularity), &out.Popularity); e != nil {
		return out, e
	}
	var formations string
	if e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_object('player_id',player_id,'partners',partners,'pet_id',pet_id,'weight',weight) ORDER BY rank),'[]'::jsonb)::text FROM(
		SELECT p.player_id,p.defense partners,p.defense_pet pet_id,COALESCE(u.score,0)weight,r.rank
		FROM top_floor_ranks r JOIN top_floor_players p ON p.player_id=r.player_id
		LEFT JOIN LATERAL(
		 SELECT SUM(fights+2*wins+kill_count)AS score FROM top_floor_partner_usage WHERE player_id=p.player_id
		)u ON TRUE
		WHERE r.logical_server_id=$1 AND r.player_id IS NOT NULL
		ORDER BY r.rank LIMIT $2)x`, int64(server), limit).Scan(&formations); e != nil {
		return out, e
	}
	var rows []struct {
		PlayerID int64   `json:"player_id"`
		Partners []int64 `json:"partners"`
		PetID    int64   `json:"pet_id"`
		Weight   int64   `json:"weight"`
	}
	if e := json.Unmarshal([]byte(formations), &rows); e != nil {
		return out, e
	}
	for _, row := range rows {
		out.Formations = append(out.Formations, d.Formation{PlayerID: row.PlayerID, PartnerIDs: row.Partners, PetID: row.PetID, Weight: row.Weight})
	}
	return out, nil
}
