package i5store

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) ReadPlayerIDsByExactNameTx(c context.Context, q tx.Queryer, name string, limit int) ([]identity.PlayerID, error) {
	if q == nil || limit < 1 || limit > 512 {
		return nil, errors.New("invalid Player name selection")
	}
	var raw []byte
	e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(player_id ORDER BY player_id),'[]'::jsonb) FROM (SELECT player_id FROM player_profiles WHERE display_name COLLATE "C"=$1 COLLATE "C" ORDER BY player_id LIMIT $2) p`, name, limit).Scan(&raw)
	if e != nil {
		return nil, e
	}
	out := []identity.PlayerID{}
	if e = json.Unmarshal(raw, &out); e != nil {
		return nil, e
	}
	var last identity.PlayerID
	for _, id := range out {
		if !id.Valid() || id <= last {
			return nil, errors.New("invalid canonical Player name candidates")
		}
		last = id
	}
	return out, nil
}

var _ i5.PublicPlayerNameReader = Store{}
