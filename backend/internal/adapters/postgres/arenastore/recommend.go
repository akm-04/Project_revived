package arenastore

import (
	"context"
	"encoding/json"
	"time"

	arena "gxb.local/backend/v2/internal/domain/arena"
	d "gxb.local/backend/v2/internal/domain/herorecommend"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/payload"
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
	if e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_object('table_id',table_id,'player_id',player_id,'score',score) ORDER BY score DESC,player_id,table_id),'[]'::jsonb)::text FROM(
		SELECT u.table_id,u.player_id,SUM(u.fights+2*u.wins+u.kill_count)AS score
		FROM arena_partner_usage u JOIN arena_players p ON p.player_id=u.player_id
		WHERE p.logical_server_id=$1
		GROUP BY u.player_id,u.table_id
		ORDER BY score DESC,u.player_id,u.table_id LIMIT $2
	)x`, int64(server), limit).Scan(&popularity); e != nil {
		return out, e
	}
	if e := json.Unmarshal([]byte(popularity), &out.Popularity); e != nil {
		return out, e
	}
	var formations string
	if e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_object('player_id',player_id,'defense',jsonb_build_object('payload',defense,'version',payload_version),'weight',weight) ORDER BY star DESC,point DESC,player_id),'[]'::jsonb)::text FROM(
		SELECT player_id,defense,payload_version,star*1000+point weight,star,point FROM arena_players
		WHERE logical_server_id=$1 AND jsonb_array_length(defense->'heroes')>0
		ORDER BY star DESC,point DESC,player_id LIMIT $2)x`, int64(server), limit).Scan(&formations); e != nil {
		return out, e
	}
	var rows []struct {
		PlayerID int64            `json:"player_id"`
		Defense  versionedPayload `json:"defense"`
		Weight   int64            `json:"weight"`
	}
	if e := json.Unmarshal([]byte(formations), &rows); e != nil {
		return out, e
	}
	for _, row := range rows {
		var lineup arena.Lineup
		if e := payload.Decode("arena_players", row.Defense.Version, row.Defense.Payload, &lineup); e != nil {
			return out, e
		}
		out.Formations = append(out.Formations, d.Formation{PlayerID: row.PlayerID, TableIDs: lineup.Heroes, PetID: lineup.Pet, Weight: row.Weight})
	}
	return out, nil
}
