package i4store

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (l PlayerRootLocker) LockBoundRecipientTx(c context.Context, t tx.Tx, server identity.LogicalServerID, pid identity.PlayerID) (playerroot.RecipientRoot, error) {
	out := playerroot.RecipientRoot{}
	if !pid.Valid() || !server.Valid() || int64(pid)/100000 != int64(server) {
		return out, playerroot.ErrPlayerServerMismatch
	}
	roots, e := l.LockPlayerRootsTx(c, t, server, []identity.PlayerID{pid})
	if e == nil {
		if len(roots) != 1 {
			return out, playerroot.ErrInvalidPlayerRootRequest
		}
		out.Root = roots[0]
		return out, nil
	}
	if !errors.Is(e, playerroot.ErrPlayerRootNotFound) {
		return out, e
	}
	// Read on the same transaction snapshot. No logical-server write/lock and no
	// fallback to current guild membership is involved in target delivery.
	var next, max int64
	if e = t.QueryRow(c, `SELECT next_player_id,max_player_id FROM logical_servers WHERE logical_server_id=$1`, int32(server)).Scan(&next, &max); e != nil {
		return out, e
	}
	if next <= int64(pid) || max < int64(pid) || next > max+1 {
		return out, playerroot.ErrInvalidPlayerRootRequest
	}
	out.NonReusedAbsent = true
	return out, nil
}

var _ playerroot.RecipientLocker = PlayerRootLocker{}
