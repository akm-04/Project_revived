package librarystore

import (
	"context"

	library "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// InsertActAwardTx reports whether this call inserted the once-per-hero/act award.
func (Store) InsertActAwardTx(ctx context.Context, t tx.Tx, f library.ActAwardFact) (bool, error) {
	if t == nil || f.Validate() != nil {
		return false, library.ErrInvalidFacts
	}
	tag, e := t.Exec(ctx, `INSERT INTO player_library_act_awards(player_id,partner_id,act_id,awarded_at)VALUES($1,$2,$3,$4)ON CONFLICT(player_id,partner_id,act_id)DO NOTHING`, int64(f.PlayerID), f.PartnerID, f.ActID, f.AwardedAt.UTC())
	if e != nil {
		return false, e
	}
	return tag.RowsAffected() == 1, nil
}
