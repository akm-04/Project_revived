package leaguestore

import (
	"context"
	"encoding/json"
	"time"

	league "gxb.local/backend/v2/internal/domain/championsleague"
	d "gxb.local/backend/v2/internal/domain/herorecommend"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/payload"
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
	if e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_object('player_id',player_id,'payload',payload,'version',payload_version) ORDER BY points DESC,player_id),'[]'::jsonb)::text FROM(
		SELECT player_id,payload,payload_version,(payload->>'Points')::bigint points
		FROM league_players WHERE logical_server_id=$1
		AND jsonb_array_length(COALESCE(payload->'Defense'->'Heroes','[]'::jsonb))>0
		ORDER BY (payload->>'Points')::bigint DESC,player_id LIMIT $2)x`, int64(server), limit).Scan(&defense); e != nil {
		return out, e
	}
	var formations []struct {
		PlayerID int64            `json:"player_id"`
		Payload  versionedPayload `json:"payload"`
	}
	if e := json.Unmarshal([]byte(defense), &formations); e != nil {
		return out, e
	}
	for _, row := range formations {
		var player league.Player
		if e := payload.Decode("league_players", row.Payload.Version, row.Payload.Payload, &player); e != nil {
			return out, e
		}
		out.Formations = append(out.Formations, d.Formation{PlayerID: row.PlayerID, PartnerIDs: player.Defense.Heroes, PetID: player.Defense.Pet, Weight: player.Points})
	}
	var matches string
	if e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_object('attacker',attacker,'payload',payload,'version',payload_version) ORDER BY wire_id DESC),'[]'::jsonb)::text FROM(
		SELECT m.attacker,m.payload,m.payload_version,m.wire_id FROM league_matches m
		JOIN league_players p ON p.player_id=m.attacker
		WHERE p.logical_server_id=$1 AND m.payload->>'Status'='SETTLED'
		ORDER BY m.wire_id DESC LIMIT $2)x`, int64(server), limit).Scan(&matches); e != nil {
		return out, e
	}
	var observed []struct {
		Attacker int64            `json:"attacker"`
		Payload  versionedPayload `json:"payload"`
	}
	if e := json.Unmarshal([]byte(matches), &observed); e != nil {
		return out, e
	}
	scores := map[int64]int64{}
	exemplars := map[int64]int64{}
	for _, row := range observed {
		var match league.Match
		if e := payload.Decode("league_matches", row.Payload.Version, row.Payload.Payload, &match); e != nil {
			return out, e
		}
		for _, hero := range match.Attack.Heroes {
			scores[hero]++
			exemplars[hero] = row.Attacker
		}
	}
	for hero, score := range scores {
		out.Popularity = append(out.Popularity, d.Popularity{PlayerID: exemplars[hero], PartnerID: hero, Score: score})
	}
	return out, nil
}
