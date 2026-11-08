package oneononestore

import (
	"context"
	"encoding/json"
	"time"

	d "gxb.local/backend/v2/internal/domain/herorecommend"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// HeroRecommendSourceTx is the bounded 1 on 1 surface for the recommendation
// owner. The competition is global; rows are filtered to one logical server.
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
			FROM one_on_one_partner_usage u JOIN one_on_one_players p ON p.player_id=u.player_id
			WHERE p.logical_server_id=$1
		)ranked WHERE rn=1 ORDER BY score DESC,partner_id LIMIT $2
	)x`, int64(server), limit).Scan(&popularity); e != nil {
		return out, e
	}
	if e := json.Unmarshal([]byte(popularity), &out.Popularity); e != nil {
		return out, e
	}
	var teams string
	if e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_object('player_id',player_id,'teams',teams,'weight',points) ORDER BY level DESC,points DESC,player_id),'[]'::jsonb)::text FROM(
		SELECT player_id,teams,points,level FROM one_on_one_players
		WHERE logical_server_id=$1 AND jsonb_array_length(teams)>0
		ORDER BY level DESC,points DESC,player_id LIMIT $2)x`, int64(server), limit).Scan(&teams); e != nil {
		return out, e
	}
	var rows []struct {
		PlayerID int64 `json:"player_id"`
		Teams    []struct {
			Heroes []int64 `json:"heroes"`
			Pet    int64   `json:"pet"`
		} `json:"teams"`
		Weight int64 `json:"weight"`
	}
	if e := json.Unmarshal([]byte(teams), &rows); e != nil {
		return out, e
	}
	for _, row := range rows {
		for _, team := range row.Teams {
			out.Formations = append(out.Formations, d.Formation{PlayerID: row.PlayerID, PartnerIDs: team.Heroes, PetID: team.Pet, Weight: row.Weight})
		}
	}
	return out, nil
}
