package oneononestore

import (
	"context"
	"encoding/json"
	"time"

	d "gxb.local/backend/v2/internal/domain/herorecommend"
	"gxb.local/backend/v2/internal/domain/identity"
	team "gxb.local/backend/v2/internal/domain/oneonone"
	"gxb.local/backend/v2/internal/foundation/payload"
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
	if e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_object('partner_id',partner_id,'player_id',player_id,'score',score) ORDER BY score DESC,player_id,partner_id),'[]'::jsonb)::text FROM(
		SELECT u.partner_id,u.player_id,SUM(u.fights+2*u.wins+u.kill_count)AS score
		FROM one_on_one_partner_usage u JOIN one_on_one_players p ON p.player_id=u.player_id
		WHERE p.logical_server_id=$1
		GROUP BY u.player_id,u.partner_id
		ORDER BY score DESC,u.player_id,u.partner_id LIMIT $2
	)x`, int64(server), limit).Scan(&popularity); e != nil {
		return out, e
	}
	if e := json.Unmarshal([]byte(popularity), &out.Popularity); e != nil {
		return out, e
	}
	var teams string
	if e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_object('player_id',player_id,'teams',jsonb_build_object('payload',teams,'version',payload_version),'weight',points) ORDER BY level DESC,points DESC,player_id),'[]'::jsonb)::text FROM(
		SELECT player_id,teams,payload_version,points,level FROM one_on_one_players
		WHERE logical_server_id=$1 AND jsonb_array_length(teams)>0
		ORDER BY level DESC,points DESC,player_id LIMIT $2)x`, int64(server), limit).Scan(&teams); e != nil {
		return out, e
	}
	var rows []struct {
		PlayerID int64 `json:"player_id"`
		Teams    struct {
			Payload json.RawMessage `json:"payload"`
			Version int16           `json:"version"`
		} `json:"teams"`
		Weight int64 `json:"weight"`
	}
	if e := json.Unmarshal([]byte(teams), &rows); e != nil {
		return out, e
	}
	for _, row := range rows {
		var saved []team.Team
		if e := payload.Decode("one_on_one_players", row.Teams.Version, row.Teams.Payload, &saved); e != nil {
			return out, e
		}
		for _, lineup := range saved {
			out.Formations = append(out.Formations, d.Formation{PlayerID: row.PlayerID, PartnerIDs: lineup.Heroes, PetID: lineup.Pet, Weight: row.Weight})
		}
	}
	return out, nil
}
