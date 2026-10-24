package i4store

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	dm "gxb.local/backend/v2/internal/application/generaldm"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

// Canonical liveness comes from I4, with the exact caller transaction and strict
// session expiry predicates. Presence leases never substitute these identities.
func ReadGeneralBinding(c context.Context, q tx.Queryer, id identity.PlayerID, b dm.Binding, at time.Time) (dm.Binding, bool, error) {
	e := q.QueryRow(c, `SELECT c.session_id::text,c.context_generation,s.liveness_version,c.liveness_version,c.logical_server_id
 FROM gameplay_contexts c JOIN account_sessions s USING(session_id) JOIN accounts a ON a.account_id=c.account_id
 WHERE c.context_id=$1::uuid AND c.player_id=$2 AND c.ended_at IS NULL AND s.revoked_at IS NULL AND a.status='ACTIVE' AND a.disabled_at IS NULL
 AND (s.absolute_expires_at IS NULL OR $3<s.absolute_expires_at)
 AND (s.idle_timeout_seconds IS NULL OR $3<s.last_activity_at+make_interval(secs=>s.idle_timeout_seconds::double precision))`, b.ContextID, int64(id), at).Scan(&b.SessionID, &b.ContextGeneration, &b.SessionLiveness, &b.ContextLiveness, &b.LogicalServerID)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return dm.Binding{}, false, nil
	}
	if e != nil {
		return dm.Binding{}, false, e
	}
	return b, b.Valid(), nil
}
