package illusionstore

import (
	"context"
	"encoding/json"
	"time"

	cd "gxb.local/backend/v2/internal/domain/combat"
	d "gxb.local/backend/v2/internal/domain/herorecommend"
	"gxb.local/backend/v2/internal/domain/identity"
	di "gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Combat is the Combat owner's frozen-START read: the formation each attempt
// froze, joined here by the attempt id a settlement row names.
type Combat interface {
	FrozenAttemptsTx(context.Context, tx.Queryer, []ids.UUID) ([]cd.FrozenAttempt, error)
}

// HeroRecommendSourceTx is the bounded Fantasy (Illusion Campaign) surface.
// The credited damage is this mode's settlement; the formation comes from the
// Combat attempt that settlement names, never from a stored formation copy.
func (s Store) HeroRecommendSourceTx(c context.Context, q tx.Queryer, server identity.LogicalServerID, at time.Time, limit int) (d.Source, error) {
	out := d.Source{}
	if q == nil || s.Combat == nil || !server.Valid() || at.IsZero() || limit <= 0 || limit > d.MaxSourceScan {
		return out, d.ErrUnavailable
	}
	var raw string
	if e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_object('attempt_id',attempt_id::text,'player_id',player_id,'damage',damage) ORDER BY damage DESC,settled_at DESC,attempt_id),'[]'::jsonb)::text FROM(
		SELECT attempt_id,player_id,damage,settled_at FROM illusion_attempt_settlements
		WHERE player_id BETWEEN $1 AND $2 ORDER BY damage DESC,settled_at DESC,attempt_id LIMIT $3) settled`,
		int64(logicalserver.BandMin(server)), int64(logicalserver.BandMax(server)), limit).Scan(&raw); e != nil {
		return out, e
	}
	var rows []struct {
		AttemptID string `json:"attempt_id"`
		PlayerID  int64  `json:"player_id"`
		Damage    int64  `json:"damage"`
	}
	if e := json.Unmarshal([]byte(raw), &rows); e != nil {
		return out, e
	}
	attemptIDs := make([]ids.UUID, 0, len(rows))
	for _, row := range rows {
		id, err := ids.ParseUUID(row.AttemptID)
		if err != nil {
			return out, d.ErrUnavailable
		}
		attemptIDs = append(attemptIDs, id)
	}
	frozen, err := s.Combat.FrozenAttemptsTx(c, q, attemptIDs)
	if err != nil {
		return out, err
	}
	byID := make(map[ids.UUID]cd.FrozenAttempt, len(frozen))
	for _, attempt := range frozen {
		byID[attempt.Attempt.ID] = attempt
	}
	scores := map[int64]int64{}
	exemplars := map[int64]int64{}
	for _, row := range rows {
		id, err := ids.ParseUUID(row.AttemptID)
		if err != nil {
			continue
		}
		attempt, ok := byID[id]
		if !ok {
			continue
		}
		generation, ok := di.ParseAttemptGeneration(attempt.Attempt.GenerationRef)
		if !ok || generation.LogicalServerID != int64(server) {
			continue
		}
		partners := attempt.Formation
		if len(partners) == 0 {
			continue
		}
		out.Formations = append(out.Formations, d.Formation{PlayerID: row.PlayerID, PartnerIDs: partners, Weight: row.Damage, ParadiseID: generation.CampaignID})
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
