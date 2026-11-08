package illusionstore

import (
	"context"
	"encoding/json"
	"strconv"
	"strings"
	"time"

	d "gxb.local/backend/v2/internal/domain/herorecommend"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// HeroRecommendSourceTx is the bounded Fantasy (Illusion Campaign) surface.
// A result is not linked to the attempt that produced the best hit, so the
// stored attempt formation is the only recoverable hero signal.
func (Store) HeroRecommendSourceTx(c context.Context, q tx.Queryer, server identity.LogicalServerID, at time.Time, limit int) (d.Source, error) {
	out := d.Source{}
	if q == nil || !server.Valid() || at.IsZero() || limit <= 0 || limit > d.MaxSourceScan {
		return out, d.ErrUnavailable
	}
	var raw string
	if e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_object('player_id',player_id,'formation',formation,'damage',damage,'campaign_id',campaign_id) ORDER BY damage DESC,attempt_sequence DESC),'[]'::jsonb)::text FROM(
		SELECT player_id,formation,damage,campaign_id,attempt_sequence FROM illusion_attempts
		WHERE logical_server_id=$1 AND resolved ORDER BY damage DESC,attempt_sequence DESC LIMIT $2)x`, int64(server), limit).Scan(&raw); e != nil {
		return out, e
	}
	var rows []struct {
		PlayerID   int64  `json:"player_id"`
		Formation  string `json:"formation"`
		Damage     int64  `json:"damage"`
		CampaignID int64  `json:"campaign_id"`
	}
	if e := json.Unmarshal([]byte(raw), &rows); e != nil {
		return out, e
	}
	scores := map[int64]int64{}
	exemplars := map[int64]int64{}
	for _, row := range rows {
		partners := parseFormation(row.Formation)
		if len(partners) == 0 {
			continue
		}
		out.Formations = append(out.Formations, d.Formation{PlayerID: row.PlayerID, PartnerIDs: partners, Weight: row.Damage, ParadiseID: row.CampaignID})
		for _, partner := range partners {
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

func parseFormation(text string) []int64 {
	if text == "" {
		return nil
	}
	out := make([]int64, 0)
	for _, part := range strings.Split(text, "|") {
		id, err := strconv.ParseInt(part, 10, 64)
		if err != nil {
			return nil
		}
		out = append(out, id)
	}
	return out
}
