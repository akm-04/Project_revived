package librarystore

import (
	"context"

	"gxb.local/backend/v2/internal/domain/identity"
	library "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// BumpHeroBattleCountTx adds one settled battle to a hero's durable count and
// returns the count before this call. The upsert takes the counter row lock,
// so concurrent settlements of the same hero serialize on it.
func (Store) BumpHeroBattleCountTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, partnerID int64) (int64, error) {
	if t == nil || !pid.Valid() || partnerID <= 0 {
		return 0, library.ErrInvalidFacts
	}
	var count int64
	e := t.QueryRow(ctx, `INSERT INTO library_hero_battle_counts(player_id,partner_id,count,payload_version)VALUES($1,$2,1,$3)ON CONFLICT(player_id,partner_id)DO UPDATE SET count=library_hero_battle_counts.count+1 RETURNING count`, int64(pid), partnerID, payload.Current).Scan(&count)
	if e != nil {
		return 0, e
	}
	return count - 1, nil
}
