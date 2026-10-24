package presencestore

import (
	"context"
	"encoding/json"
	dm "gxb.local/backend/v2/internal/application/generaldm"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

// Discovery is bounded and presence-owned. Identity enrichment belongs to I4.
func (Store) ReadGeneralWorldLeases(c context.Context, q tx.Queryer, id identity.PlayerID, at time.Time) ([]dm.Binding, error) {
	var raw []byte
	e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_object('context_id',gameplay_context_id::text,'realtime_instance_id',realtime_instance_id::text,'connection_generation',connection_generation,'owner_fence',realtime_owner_fence) ORDER BY gameplay_context_id),'[]'::jsonb) FROM (SELECT * FROM realtime_presence_leases WHERE player_id=$1 AND physical_role='WORLD' AND lease_expires_at>$2 ORDER BY gameplay_context_id LIMIT 65) q`, int64(id), at).Scan(&raw)
	if e != nil {
		return nil, e
	}
	var out []dm.Binding
	e = json.Unmarshal(raw, &out)
	if e != nil || len(out) > 64 {
		return nil, dm.ErrUnavailable
	}
	return out, nil
}
