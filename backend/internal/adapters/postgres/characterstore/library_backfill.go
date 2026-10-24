package characterstore

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ListHeroRootPlayerIDsTx is the owning enumeration port for controlled Library
// backfill. Library adapters must not query Character tables themselves.
func (Store) ListHeroRootPlayerIDsTx(ctx context.Context, q tx.Queryer) ([]identity.PlayerID, error) {
	if q == nil {
		return nil, errors.New("character: nil backfill queryer")
	}
	var raw string
	if e := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(player_id ORDER BY player_id),'[]'::jsonb)::text FROM player_hero_roots`).Scan(&raw); e != nil {
		return nil, e
	}
	var values []int64
	if e := json.Unmarshal([]byte(raw), &values); e != nil {
		return nil, e
	}
	out := make([]identity.PlayerID, 0, len(values))
	var prior int64
	for _, v := range values {
		if v <= prior {
			return nil, errors.New("character: invalid root enumeration")
		}
		prior = v
		out = append(out, identity.PlayerID(v))
	}
	return out, nil
}
