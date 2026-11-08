package guildcampaignstore

import (
	"context"
	"encoding/json"
	"time"

	d "gxb.local/backend/v2/internal/domain/herorecommend"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// HeroRecommendSourceTx is the bounded Guild Event surface. Only records
// written after the request formation capture carry partners; historical rows
// keep their empty array and contribute nothing.
func (Store) HeroRecommendSourceTx(c context.Context, q tx.Queryer, server identity.LogicalServerID, at time.Time, limit int) (d.Source, error) {
	out := d.Source{}
	if q == nil || !server.Valid() || at.IsZero() || limit <= 0 || limit > d.MaxSourceScan {
		return out, d.ErrUnavailable
	}
	var raw string
	if e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_object('player_id',player_id,'partners',partners,'damage',damage,'chapter_id',chapter_id) ORDER BY damage DESC,hit_at),'[]'::jsonb)::text FROM(
		SELECT r.player_id,r.partners,r.damage,c.chapter_id,r.hit_at
		FROM guild_campaign_server_records r
		JOIN guild_campaign_copies c ON c.guild_id=r.guild_id AND c.copy_id=r.copy_id
		WHERE r.logical_server_id=$1 ORDER BY r.damage DESC,r.hit_at LIMIT $2)x`, int64(server), limit).Scan(&raw); e != nil {
		return out, e
	}
	var rows []struct {
		PlayerID  int64   `json:"player_id"`
		Partners  []int64 `json:"partners"`
		Damage    int64   `json:"damage"`
		ChapterID int64   `json:"chapter_id"`
	}
	if e := json.Unmarshal([]byte(raw), &rows); e != nil {
		return out, e
	}
	scores := map[int64]int64{}
	exemplars := map[int64]int64{}
	for _, row := range rows {
		if len(row.Partners) == 0 {
			continue
		}
		out.Formations = append(out.Formations, d.Formation{PlayerID: row.PlayerID, PartnerIDs: row.Partners, Weight: row.Damage, ChapterID: row.ChapterID})
		for _, partner := range row.Partners {
			scores[partner] += row.Damage
			if row.PlayerID > exemplars[partner] {
				exemplars[partner] = row.PlayerID
			}
		}
	}
	for partner, score := range scores {
		out.Popularity = append(out.Popularity, d.Popularity{PlayerID: exemplars[partner], PartnerID: partner, Score: score})
	}
	return out, nil
}
