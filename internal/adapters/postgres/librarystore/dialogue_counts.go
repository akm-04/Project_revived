package librarystore

import (
	"context"
	"encoding/json"
	"strconv"

	"gxb.local/backend/v2/internal/domain/identity"
	library "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// BumpHeroDialogueCountTx adds one completed dialogue to a hero's durable
// count and returns the count before this call. The upsert takes the counter
// row lock, so concurrent talks of the same hero serialize on it.
func (Store) BumpHeroDialogueCountTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, partnerID int64) (int64, error) {
	if t == nil || !pid.Valid() || partnerID <= 0 {
		return 0, library.ErrInvalidFacts
	}
	var count int64
	e := t.QueryRow(ctx, `INSERT INTO library_hero_dialogue_counts(player_id,partner_id,count,payload_version)VALUES($1,$2,1,$3)ON CONFLICT(player_id,partner_id)DO UPDATE SET count=library_hero_dialogue_counts.count+1 RETURNING count`, int64(pid), partnerID, payload.Current).Scan(&count)
	if e != nil {
		return 0, e
	}
	return count - 1, nil
}

// ListHeroDialogueCountsTx returns the player's completed-dialogue counts per
// girl. A player with no completed talk has no row and is simply absent.
func (Store) ListHeroDialogueCountsTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID) (map[int64]int64, error) {
	if q == nil || !pid.Valid() {
		return nil, library.ErrInvalidFacts
	}
	var raw string
	if e := q.QueryRow(ctx, `SELECT COALESCE(jsonb_object_agg(partner_id::text,count),'{}'::jsonb)::text FROM library_hero_dialogue_counts WHERE player_id=$1`, int64(pid)).Scan(&raw); e != nil {
		return nil, e
	}
	var encoded map[string]int64
	if e := json.Unmarshal([]byte(raw), &encoded); e != nil {
		return nil, e
	}
	out := make(map[int64]int64, len(encoded))
	for key, value := range encoded {
		id, e := strconv.ParseInt(key, 10, 64)
		if e != nil || id <= 0 || value < 0 {
			return nil, library.ErrInvalidFacts
		}
		out[id] = value
	}
	return out, nil
}
