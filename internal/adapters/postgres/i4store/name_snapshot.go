package i4store

import (
	"context"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (PlayerRootLocker) ReadNameSnapshotTx(c context.Context, q tx.Queryer, pid identity.PlayerID) (playerroot.NameSnapshot, error) {
	n := playerroot.NameSnapshot{PlayerID: pid}
	if q == nil || !pid.Valid() {
		return n, playerroot.ErrInvalidPlayerRootRequest
	}
	var rawPID int64
	var sid int32
	e := q.QueryRow(c, `SELECT p.player_id,p.logical_server_id,d.name,d.updated_at FROM players p JOIN player_directory_profiles d ON d.player_id=p.player_id WHERE p.player_id=$1`, int64(pid)).Scan(&rawPID, &sid, &n.Name, &n.ChangedAt)
	if e != nil {
		return n, e
	}
	n.PlayerID = identity.PlayerID(rawPID)
	n.Server = identity.LogicalServerID(sid)
	n.ChangedAt = n.ChangedAt.UTC()
	if n.PlayerID != pid {
		return n, playerroot.ErrPlayerRootNotFound
	}
	return n, n.Validate()
}

var _ playerroot.NameReader = PlayerRootLocker{}
