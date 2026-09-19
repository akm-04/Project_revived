package i4store

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const lockCanonicalPlayerRoot = `SELECT player_id,logical_server_id FROM players WHERE player_id=$1 FOR UPDATE`

// PlayerRootLocker is the I4-owned implementation of the shared-domain player
// root lock seam. It returns only identity/server binding; gameplay state stays
// with its owning domains.
type PlayerRootLocker struct{}

func (PlayerRootLocker) LockPlayerRootsTx(ctx context.Context, t tx.Tx, server identity.LogicalServerID, playerIDs []identity.PlayerID) ([]playerroot.Root, error) {
	if t == nil || !server.Valid() {
		return nil, playerroot.ErrInvalidPlayerRootRequest
	}
	ids, err := playerroot.CanonicalPlayerIDs(playerIDs)
	if err != nil {
		return nil, err
	}
	out := make([]playerroot.Root, 0, len(ids))
	for _, pid := range ids {
		var rawPID int64
		var rawServer int32
		err := t.QueryRow(ctx, lockCanonicalPlayerRoot, int64(pid)).Scan(&rawPID, &rawServer)
		if err != nil {
			if errors.Is(err, kernelErrNoRows()) {
				return nil, playerroot.ErrPlayerRootNotFound
			}
			return nil, err
		}
		root := playerroot.Root{PlayerID: identity.PlayerID(rawPID), LogicalServerID: identity.LogicalServerID(rawServer)}
		if err := root.Validate(); err != nil {
			return nil, err
		}
		if root.PlayerID != pid {
			return nil, playerroot.ErrPlayerRootNotFound
		}
		if root.LogicalServerID != server {
			return nil, playerroot.ErrPlayerServerMismatch
		}
		out = append(out, root)
	}
	return out, nil
}

// kernelErrNoRows keeps the adapter coupled to the repository's normalized
// no-row sentinel rather than pgx directly.
func kernelErrNoRows() error { return kernelstore.ErrNoRows }
