package i4store

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ProjectConquerTx writes the Conquer School owner's progress into the I4
// directory row (rank 740), after every Conquer and I5 lock of the caller.
func (DirectoryLevelProjection) ProjectConquerTx(c context.Context, t tx.Tx, pid identity.PlayerID, level, loop int64, at time.Time) error {
	if t == nil || !pid.Valid() || level < 0 || loop < 1 || at.IsZero() {
		return errors.New("invalid directory conquer projection")
	}
	var oldLevel, oldLoop, version int64
	var updated time.Time
	if e := t.QueryRow(c, `SELECT conquer_lev,conquer_loop_id,state_version,updated_at FROM player_directory_profiles WHERE player_id=$1 FOR UPDATE`, int64(pid)).Scan(&oldLevel, &oldLoop, &version, &updated); e != nil {
		return e
	}
	if version < 1 || updated.After(at) {
		return errors.New("directory conquer observation conflict")
	}
	if oldLevel == level && oldLoop == loop {
		return nil
	}
	tag, e := t.Exec(c, `UPDATE player_directory_profiles SET conquer_lev=$2,conquer_loop_id=$3,state_version=state_version+1,updated_at=$4 WHERE player_id=$1 AND state_version=$5`, int64(pid), level, loop, at.UTC(), version)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return errors.New("directory conquer CAS conflict")
	}
	return nil
}
