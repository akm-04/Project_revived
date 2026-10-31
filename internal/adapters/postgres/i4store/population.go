package i4store

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/foundation/tx"
)

// LevelAtLeastCountTx is the level-90 population input of the world boss daily
// courage increment.
func (PlayerDirectoryReader) LevelAtLeastCountTx(ctx context.Context, q tx.Queryer, level int64) (int64, error) {
	if q == nil || level < 1 {
		return 0, errors.New("invalid directory population read")
	}
	var count int64
	err := q.QueryRow(ctx, `SELECT count(*) FROM player_directory_profiles WHERE lev >= $1`, level).Scan(&count)
	return count, err
}
