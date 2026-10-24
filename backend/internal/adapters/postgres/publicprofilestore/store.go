package publicprofilestore

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	app "gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{}

var _ app.Store = Store{}

const readSQL = `SELECT player_id,intro,show_type_ids,hide_subtypes,share_switch,is_first_time,state_version,policy_version,created_at,updated_at FROM player_public_profile_roots WHERE player_id=$1`

func read(c context.Context, q tx.Queryer, pid identity.PlayerID, lock bool) (app.Root, bool, error) {
	if q == nil || !pid.Valid() {
		return app.Root{}, false, app.ErrInvalidState
	}
	sql := readSQL
	if lock {
		sql += " FOR UPDATE"
	}
	var r app.Root
	var id int64
	e := q.QueryRow(c, sql, int64(pid)).Scan(&id, &r.Preferences.Intro, &r.Preferences.ShowTypeIDs, &r.Preferences.HideSubtypes, &r.Preferences.ShareSwitch, &r.Preferences.IsFirstTime, &r.StateVersion, &r.Preferences.PolicyVersion, &r.CreatedAt, &r.UpdatedAt)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return app.Root{}, false, nil
	}
	if e != nil {
		return app.Root{}, false, e
	}
	r.PlayerID = identity.PlayerID(id)
	r.CreatedAt = r.CreatedAt.UTC()
	r.UpdatedAt = r.UpdatedAt.UTC()
	if r.PlayerID != pid {
		return app.Root{}, false, app.ErrInvalidState
	}
	return r, true, r.Validate()
}
func (Store) ReadRootTx(c context.Context, q tx.Queryer, pid identity.PlayerID) (app.Root, bool, error) {
	return read(c, q, pid, false)
}
func (Store) LockRootTx(c context.Context, t tx.Tx, pid identity.PlayerID) (app.Root, bool, error) {
	return read(c, t, pid, true)
}
func (Store) InsertRootTx(c context.Context, t tx.Tx, r app.Root) error {
	if t == nil || r.Validate() != nil || r.StateVersion != 1 || !r.CreatedAt.Equal(r.UpdatedAt) {
		return app.ErrInvalidState
	}
	p := r.Preferences.Clone()
	tag, e := t.Exec(c, `INSERT INTO player_public_profile_roots(player_id,intro,show_type_ids,hide_subtypes,share_switch,is_first_time,state_version,policy_version,created_at,updated_at)VALUES($1,$2,$3,$4,$5,$6,1,$7,$8,$8)`, int64(r.PlayerID), p.Intro, p.ShowTypeIDs, p.HideSubtypes, p.ShareSwitch, p.IsFirstTime, p.PolicyVersion, r.CreatedAt)
	if e == nil && tag.RowsAffected() != 1 {
		return app.ErrStaleRoot
	}
	return e
}
func (Store) UpdateRootTx(c context.Context, t tx.Tx, old, r app.Root) error {
	if t == nil || old.Validate() != nil || r.Validate() != nil || old.PlayerID != r.PlayerID || r.StateVersion <= old.StateVersion || r.StateVersion-old.StateVersion != 1 || !r.CreatedAt.Equal(old.CreatedAt) || r.UpdatedAt.Before(old.UpdatedAt) {
		return app.ErrInvalidState
	}
	p := r.Preferences.Clone()
	tag, e := t.Exec(c, `UPDATE player_public_profile_roots SET intro=$2,show_type_ids=$3,hide_subtypes=$4,share_switch=$5,is_first_time=$6,state_version=$7,policy_version=$8,updated_at=$9 WHERE player_id=$1 AND state_version=$10`, int64(r.PlayerID), p.Intro, p.ShowTypeIDs, p.HideSubtypes, p.ShareSwitch, p.IsFirstTime, r.StateVersion, p.PolicyVersion, r.UpdatedAt, old.StateVersion)
	if e == nil && tag.RowsAffected() != 1 {
		return app.ErrStaleRoot
	}
	return e
}
