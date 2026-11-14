package presencestore

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// LastSeenAtTx is the SocialPresence owner's batched activity read for jobs
// that must not borrow another owner's table.
func (Store) LastSeenAtTx(c context.Context, q tx.Queryer, players []identity.PlayerID) (map[identity.PlayerID]time.Time, error) {
	out := map[identity.PlayerID]time.Time{}
	if q == nil || len(players) == 0 {
		return out, errors.New("invalid presence activity read")
	}
	ids := make([]int64, 0, len(players))
	for _, player := range players {
		if !player.Valid() {
			return out, errors.New("invalid presence activity read")
		}
		ids = append(ids, int64(player))
	}
	var raw string
	if e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_object('player',player_id,'seen',last_seen_at)),'[]'::jsonb)::text FROM player_social_presence WHERE player_id=ANY($1) AND last_seen_at IS NOT NULL`, ids).Scan(&raw); e != nil {
		return nil, e
	}
	var rows []struct {
		Player int64      `json:"player"`
		Seen   *time.Time `json:"seen"`
	}
	if e := json.Unmarshal([]byte(raw), &rows); e != nil {
		return nil, e
	}
	for _, x := range rows {
		id := identity.PlayerID(x.Player)
		if !id.Valid() || x.Seen == nil || x.Seen.IsZero() {
			return nil, errors.New("invalid presence activity row")
		}
		out[id] = x.Seen.UTC()
	}
	return out, nil
}
