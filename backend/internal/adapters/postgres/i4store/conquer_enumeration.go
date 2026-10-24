package i4store

import (
	"context"
	"encoding/json"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ListPlayerRootsTx is I4-owned enumeration for explicit specialist deployment.
// Directory fields never establish canonical specialist progress.
func (PlayerRootLocker) ListPlayerRootsTx(c context.Context, q tx.Queryer) ([]playerroot.Root, error) {
	var raw string
	if e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_object('player',player_id,'server',logical_server_id) ORDER BY player_id),'[]'::jsonb)::text FROM players`).Scan(&raw); e != nil {
		return nil, e
	}
	var rows []struct {
		Player int64 `json:"player"`
		Server int64 `json:"server"`
	}
	if e := json.Unmarshal([]byte(raw), &rows); e != nil {
		return nil, e
	}
	out := make([]playerroot.Root, 0, len(rows))
	for _, x := range rows {
		r := playerroot.Root{PlayerID: identity.PlayerID(x.Player), LogicalServerID: identity.LogicalServerID(x.Server)}
		if e := r.Validate(); e != nil {
			return nil, e
		}
		out = append(out, r)
	}
	return out, nil
}
