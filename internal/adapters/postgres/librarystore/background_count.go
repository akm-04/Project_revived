package librarystore

import (
	"context"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// BackgroundCountTx is the Library-owned count used by Mentor mission category
// 3. It reads only this owner's table.
func (Store) BackgroundCountTx(ctx context.Context, q tx.Queryer, player identity.PlayerID) (int64, error) {
	if q == nil || !player.Valid() {
		return 0, nil
	}
	var count int64
	err := q.QueryRow(ctx, `SELECT count(*) FROM player_library_backgrounds WHERE player_id=$1`, int64(player)).Scan(&count)
	return count, err
}
