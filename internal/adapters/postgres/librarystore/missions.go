package librarystore

import (
	"context"

	library "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// EnsureMissionTx materializes one auto-accepted mission row without touching
// an existing progress or state.
func (Store) EnsureMissionTx(ctx context.Context, t tx.Tx, f library.MissionFact) (bool, error) {
	if t == nil || f.Validate() != nil {
		return false, library.ErrInvalidFacts
	}
	tag, e := t.Exec(ctx, `INSERT INTO player_library_partner_missions(player_id,partner_id,mission_id,process,mission_state,updated_at)VALUES($1,$2,$3,$4,$5,$6)ON CONFLICT(player_id,partner_id,mission_id)DO NOTHING`, int64(f.PlayerID), f.PartnerID, f.MissionID, f.Process, f.MissionState, f.UpdatedAt.UTC())
	if e != nil {
		return false, e
	}
	return tag.RowsAffected() == 1, nil
}
