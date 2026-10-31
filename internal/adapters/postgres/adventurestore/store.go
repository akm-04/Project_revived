// Package adventurestore owns the adventure_occurrences table. Rows are
// insert-only and take the late rank 750 above every I5 rank (D369), so the
// trigger observer never waits on another family lock.
package adventurestore

import (
	"context"
	"encoding/json"
	"time"

	d "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{}

// ActiveTypesTx returns the event types still live at the given instant.
func (Store) ActiveTypesTx(ctx context.Context, q tx.Queryer, playerID identity.PlayerID, at time.Time) (map[int64]struct{}, error) {
	var raw string
	err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(event_type),'[]'::jsonb)::text FROM (SELECT event_type FROM adventure_occurrences WHERE player_id=$1 AND end_time>$2) active`, int64(playerID), at.UTC()).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var types []int64
	if err = json.Unmarshal([]byte(raw), &types); err != nil {
		return nil, err
	}
	active := make(map[int64]struct{}, len(types))
	for _, eventType := range types {
		active[eventType] = struct{}{}
	}
	return active, nil
}

// InsertOccurrenceTx inserts one occurrence. A repeated fact or instant is a
// no-op, so the caller can treat the fact as already recorded.
func (Store) InsertOccurrenceTx(ctx context.Context, t tx.Tx, occurrence d.Occurrence) (bool, error) {
	if err := occurrence.Validate(); err != nil {
		return false, err
	}
	tag, err := t.Exec(ctx, `INSERT INTO adventure_occurrences(player_id,event_type,occurred_at,end_time,source_key)VALUES($1,$2,$3,$4,$5) ON CONFLICT DO NOTHING`, int64(occurrence.PlayerID), occurrence.EventType, occurrence.OccurredAt.UTC(), occurrence.EndTime.UTC(), occurrence.SourceKey)
	if err != nil {
		return false, err
	}
	return tag.RowsAffected() == 1, nil
}
