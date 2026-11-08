package i4store

import (
	"context"
	"encoding/json"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ListLogicalServersAfterTx enumerates at most limit servers with player roots.
func (PlayerRootLocker) ListLogicalServersAfterTx(c context.Context, q tx.Queryer, after identity.LogicalServerID, limit int) ([]identity.LogicalServerID, error) {
	var raw string
	if e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(logical_server_id ORDER BY logical_server_id),'[]'::jsonb)::text FROM (SELECT logical_server_id FROM logical_servers s WHERE logical_server_id>$1 AND EXISTS (SELECT 1 FROM players p WHERE p.player_id>s.logical_server_id::bigint*100000 AND p.player_id<(s.logical_server_id::bigint+1)*100000) ORDER BY logical_server_id LIMIT $2) servers`, int32(after), limit).Scan(&raw); e != nil {
		return nil, e
	}
	var rows []int32
	if e := json.Unmarshal([]byte(raw), &rows); e != nil {
		return nil, e
	}
	out := make([]identity.LogicalServerID, 0, len(rows))
	for _, row := range rows {
		server := identity.LogicalServerID(row)
		if !server.Valid() || server <= after {
			return nil, playerroot.ErrInvalidPlayerRootRequest
		}
		out = append(out, server)
	}
	return out, nil
}

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
