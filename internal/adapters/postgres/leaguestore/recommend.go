package leaguestore

import (
	"context"
	"encoding/json"
	"time"

	d "gxb.local/backend/v2/internal/domain/herorecommend"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// HeroRecommendSourceTx is the bounded Champions League surface. The global
// competition is filtered to one logical server by the owning player rows.
func (Store) HeroRecommendSourceTx(c context.Context, q tx.Queryer, server identity.LogicalServerID, at time.Time, limit int) (d.Source, error) {
	out := d.Source{}
	if q == nil || !server.Valid() || at.IsZero() || limit <= 0 || limit > d.MaxSourceScan {
		return out, d.ErrUnavailable
	}
	var defense string
	if e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_object('player_id',player_id,'heroes',heroes,'pet',pet,'weight',points) ORDER BY points DESC,player_id),'[]'::jsonb)::text FROM(
		SELECT player_id,payload->'Defense'->'Heroes' heroes,COALESCE((payload->'Defense'->>'Pet')::bigint,0)pet,COALESCE((payload->>'Points')::bigint,0)points
		FROM league_players WHERE logical_server_id=$1
		AND jsonb_array_length(COALESCE(payload->'Defense'->'Heroes','[]'::jsonb))>0
		ORDER BY (payload->>'Points')::bigint DESC,player_id LIMIT $2)x`, int64(server), limit).Scan(&defense); e != nil {
		return out, e
	}
	var formations []struct {
		PlayerID int64   `json:"player_id"`
		Heroes   []int64 `json:"heroes"`
		Pet      int64   `json:"pet"`
		Weight   int64   `json:"weight"`
	}
	if e := json.Unmarshal([]byte(defense), &formations); e != nil {
		return out, e
	}
	for _, row := range formations {
		out.Formations = append(out.Formations, d.Formation{PlayerID: row.PlayerID, PartnerIDs: row.Heroes, PetID: row.Pet, Weight: row.Weight})
	}
	var matches string
	if e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_object('attacker',attacker,'attack',attack) ORDER BY wire_id DESC),'[]'::jsonb)::text FROM(
		SELECT m.attacker,m.payload->'Attack'->'Heroes' attack,m.wire_id FROM league_matches m
		JOIN league_players p ON p.player_id=m.attacker
		WHERE p.logical_server_id=$1 AND m.payload->>'Status'='SETTLED'
		ORDER BY m.wire_id DESC LIMIT $2)x`, int64(server), limit).Scan(&matches); e != nil {
		return out, e
	}
	var observed []struct {
		Attacker int64   `json:"attacker"`
		Attack   []int64 `json:"attack"`
	}
	if e := json.Unmarshal([]byte(matches), &observed); e != nil {
		return out, e
	}
	scores := map[int64]int64{}
	exemplars := map[int64]int64{}
	for _, row := range observed {
		for _, hero := range row.Attack {
			scores[hero]++
			exemplars[hero] = row.Attacker
		}
	}
	for hero, score := range scores {
		out.Popularity = append(out.Popularity, d.Popularity{PlayerID: exemplars[hero], PartnerID: hero, Score: score})
	}
	return out, nil
}
