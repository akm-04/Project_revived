package i4store

import (
	"context"
	"encoding/json"
	"errors"

	appevents "gxb.local/backend/v2/internal/application/events"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// EventPlayerSource is the I4-owned bounded player enumeration the events
// settlement job pages through. It is an adapter edge: events never reads the
// players or directory tables itself.
type EventPlayerSource struct{}

const eventPlayersAfter = `SELECT COALESCE(jsonb_agg(jsonb_build_object('player',p.player_id,'level',COALESCE(d.lev,0)) ORDER BY p.player_id),'[]'::jsonb)::text
FROM (
	SELECT player_id FROM players WHERE logical_server_id=$1 AND player_id>$2 ORDER BY player_id LIMIT $3
) p
LEFT JOIN player_directory_profiles d ON d.player_id=p.player_id`

// PlayersOfServerAfterTx reads at most limit players of one server after a
// player id, joined with the directory level settlement compares to a tier.
func (EventPlayerSource) PlayersOfServerAfterTx(ctx context.Context, query tx.Queryer, server identity.LogicalServerID, after identity.PlayerID, limit int) ([]appevents.PlayerRef, error) {
	if query == nil || !server.Valid() || limit < 1 || limit > 500 {
		return nil, errors.New("invalid event player page request")
	}
	var afterID int64
	if after.Valid() {
		afterID = int64(after)
	}
	var raw string
	if err := query.QueryRow(ctx, eventPlayersAfter, int32(server), afterID, limit).Scan(&raw); err != nil {
		return nil, err
	}
	var rows []struct {
		Player int64 `json:"player"`
		Level  int64 `json:"level"`
	}
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make([]appevents.PlayerRef, 0, len(rows))
	for _, row := range rows {
		player := identity.PlayerID(row.Player)
		if !player.Valid() {
			return nil, errors.New("invalid event player row")
		}
		out = append(out, appevents.PlayerRef{PlayerID: player, Level: row.Level})
	}
	return out, nil
}
