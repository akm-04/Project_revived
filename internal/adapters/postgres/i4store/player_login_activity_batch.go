package i4store

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// LastLoginAtTx is I4's batched login observation for activity-driven jobs.
func (PlayerLoginActivity) LastLoginAtTx(c context.Context, q tx.Queryer, players []identity.PlayerID) (map[identity.PlayerID]time.Time, error) {
	out := map[identity.PlayerID]time.Time{}
	if q == nil || len(players) == 0 {
		return out, errors.New("invalid player login activity read")
	}
	ids := make([]int64, 0, len(players))
	for _, player := range players {
		if !player.Valid() {
			return out, errors.New("invalid player login activity read")
		}
		ids = append(ids, int64(player))
	}
	var raw string
	if e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_object('player',player_id,'login',last_login_at)),'[]'::jsonb)::text FROM player_login_observations WHERE player_id=ANY($1)`, ids).Scan(&raw); e != nil {
		return nil, e
	}
	var rows []struct {
		Player int64     `json:"player"`
		Login  time.Time `json:"login"`
	}
	if e := json.Unmarshal([]byte(raw), &rows); e != nil {
		return nil, e
	}
	for _, x := range rows {
		id := identity.PlayerID(x.Player)
		if !id.Valid() || x.Login.IsZero() {
			return nil, errors.New("invalid player login activity row")
		}
		out[id] = x.Login.UTC()
	}
	return out, nil
}
