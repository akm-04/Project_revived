package i5store

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (s Store) LockSignInTx(c context.Context, t tx.Tx, pid identity.PlayerID, initial objective.SignRoot) (objective.SignRoot, error) {
	if err := initial.Validate(); err != nil {
		return objective.SignRoot{}, err
	}
	if _, err := t.Exec(c, `INSERT INTO player_signin_roots(player_id,month,day,content_revision)VALUES($1,$2,$3,$4) ON CONFLICT(player_id)DO NOTHING`, int64(pid), initial.Month, initial.Day, initial.ContentRevision); err != nil {
		return objective.SignRoot{}, err
	}
	return readSignIn(c, t, pid, true)
}
func (Store) ReadSignInTx(c context.Context, q tx.Queryer, pid identity.PlayerID) (objective.SignRoot, error) {
	return readSignIn(c, q, pid, false)
}
func readSignIn(c context.Context, q tx.Queryer, pid identity.PlayerID, lock bool) (objective.SignRoot, error) {
	if q == nil || !pid.Valid() {
		return objective.SignRoot{}, errors.New("invalid sign-in read")
	}
	sql := `SELECT month,day,sign_times,is_signed,content_revision,state_version FROM player_signin_roots WHERE player_id=$1`
	if lock {
		sql += " FOR UPDATE"
	}
	var out objective.SignRoot
	err := q.QueryRow(c, sql, int64(pid)).Scan(&out.Month, &out.Day, &out.Count, &out.Signed, &out.ContentRevision, &out.StateVersion)
	if err != nil {
		return out, err
	}
	return out, out.Validate()
}
func (Store) SaveSignInTx(c context.Context, t tx.Tx, pid identity.PlayerID, s objective.SignRoot, old int64) error {
	if err := s.Validate(); err != nil {
		return err
	}
	tag, err := t.Exec(c, `UPDATE player_signin_roots SET month=$2,day=$3,sign_times=$4,is_signed=$5,content_revision=$6,state_version=$7 WHERE player_id=$1 AND state_version=$8`, int64(pid), s.Month, s.Day, s.Count, s.Signed, s.ContentRevision, s.StateVersion, old)
	if err != nil {
		return err
	}
	return rowsOne(tag, "sign-in root")
}
