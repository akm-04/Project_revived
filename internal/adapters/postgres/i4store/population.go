package i4store

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/foundation/tx"
)

// LevelAtLeastCountTx is the per-server level-90 population input of the world
// boss daily courage increment.
func (PlayerDirectoryReader) LevelAtLeastCountTx(ctx context.Context, q tx.Queryer, serverID, level int64) (int64, error) {
	if q == nil || serverID < 1 || level < 1 {
		return 0, errors.New("invalid directory population read")
	}
	var count int64
	err := q.QueryRow(ctx, `SELECT count(*) FROM player_directory_profiles profile JOIN players player USING(player_id) WHERE player.logical_server_id=$1 AND profile.lev>=$2`, serverID, level).Scan(&count)
	return count, err
}
