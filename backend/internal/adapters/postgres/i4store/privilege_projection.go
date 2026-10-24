package i4store

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/application/directorysync"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type preparedVIPProjection struct {
	pid                    identity.PlayerID
	before, after, version int64
	at                     time.Time
}

func (DirectoryLevelProjection) PrepareVIPProjectionTx(c context.Context, t tx.Tx, pid identity.PlayerID, vip int64, at time.Time) (directorysync.PreparedVIPProjection, error) {
	if t == nil || !pid.Valid() || vip < 0 || vip > 15 || at.IsZero() {
		return nil, errors.New("invalid directory VIP projection")
	}
	var old, version int64
	var updated time.Time
	// Existing directory row/rank740, after planned Economy700/Temporal721.
	if e := t.QueryRow(c, `SELECT vip,state_version,updated_at FROM player_directory_profiles WHERE player_id=$1 FOR UPDATE`, int64(pid)).Scan(&old, &version, &updated); e != nil {
		return nil, e
	}
	if old < 0 || old > 15 || version < 1 || updated.After(at) {
		return nil, errors.New("directory VIP observation conflict")
	}
	return preparedVIPProjection{pid: pid, before: old, after: vip, version: version, at: at.UTC()}, nil
}
func (p preparedVIPProjection) Apply(c context.Context, t tx.Tx) error {
	if t == nil {
		return errors.New("missing directory VIP transaction")
	}
	if p.before == p.after {
		return nil
	}
	tag, e := t.Exec(c, `UPDATE player_directory_profiles SET vip=$2,state_version=state_version+1,updated_at=$3 WHERE player_id=$1 AND state_version=$4`, int64(p.pid), p.after, p.at, p.version)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return errors.New("directory VIP CAS conflict")
	}
	return nil
}

var _ directorysync.VIPProjectionPort = DirectoryLevelProjection{}
