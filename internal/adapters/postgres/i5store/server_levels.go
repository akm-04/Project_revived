package i5store

import (
	"context"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ServerHasLevelAtLeastTx answers the bounded server-wide level fact used by
// composite function gates. The player-id range is one logical server's stock
// band, so the PK index bounds the scan.
func (Store) ServerHasLevelAtLeastTx(ctx context.Context, q tx.Queryer, server identity.LogicalServerID, level int64) (bool, error) {
	if q == nil || !server.Valid() || level < 1 {
		return false, nil
	}
	low := int64(server) * 100000
	high := low + 99999
	var exists bool
	err := q.QueryRow(ctx, `SELECT EXISTS(SELECT 1 FROM player_progression WHERE player_id BETWEEN $1 AND $2 AND level>=$3)`, low, high, level).Scan(&exists)
	return exists, err
}
