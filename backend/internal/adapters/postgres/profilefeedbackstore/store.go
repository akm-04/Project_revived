package profilefeedbackstore

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	app "gxb.local/backend/v2/internal/application/profilefeedback"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/profilefeedback"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{}

var _ app.Store = Store{}

func read(c context.Context, q tx.Queryer, pid identity.PlayerID, lock bool) (d.Root, bool, error) {
	if q == nil || !pid.Valid() {
		return d.Root{}, false, app.ErrInvalid
	}
	sql := `SELECT player_id,state_version,created_at,updated_at FROM player_profile_feedback_roots WHERE player_id=$1`
	if lock {
		sql += " FOR UPDATE"
	}
	var r d.Root
	var id int64
	e := q.QueryRow(c, sql, int64(pid)).Scan(&id, &r.StateVersion, &r.CreatedAt, &r.UpdatedAt)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return d.Root{}, false, nil
	}
	if e != nil {
		return d.Root{}, false, e
	}
	r.PlayerID = identity.PlayerID(id)
	r.CreatedAt = r.CreatedAt.UTC()
	r.UpdatedAt = r.UpdatedAt.UTC()
	if r.PlayerID != pid {
		return r, false, app.ErrInvalid
	}
	return r, true, r.Validate()
}
func (Store) ReadRootTx(c context.Context, q tx.Queryer, pid identity.PlayerID) (d.Root, bool, error) {
	return read(c, q, pid, false)
}
func (Store) LockRootTx(c context.Context, t tx.Tx, pid identity.PlayerID) (d.Root, bool, error) {
	return read(c, t, pid, true)
}
func (Store) InsertRootTx(c context.Context, t tx.Tx, r d.Root) error {
	if t == nil || r.Validate() != nil || r.StateVersion != 1 || !r.CreatedAt.Equal(r.UpdatedAt) {
		return app.ErrInvalid
	}
	tag, e := t.Exec(c, `INSERT INTO player_profile_feedback_roots(player_id,state_version,created_at,updated_at)VALUES($1,1,$2,$2)`, int64(r.PlayerID), r.CreatedAt)
	if e == nil && tag.RowsAffected() != 1 {
		return app.ErrConflict
	}
	return e
}
func (Store) UpdateRootTx(c context.Context, t tx.Tx, old, r d.Root) error {
	if t == nil || old.Validate() != nil || r.Validate() != nil || old.PlayerID != r.PlayerID || r.StateVersion <= old.StateVersion || r.StateVersion-old.StateVersion != 1 || !r.CreatedAt.Equal(old.CreatedAt) || r.UpdatedAt.Before(old.UpdatedAt) {
		return app.ErrInvalid
	}
	tag, e := t.Exec(c, `UPDATE player_profile_feedback_roots SET state_version=$2,updated_at=$3 WHERE player_id=$1 AND state_version=$4`, int64(r.PlayerID), r.StateVersion, r.UpdatedAt, old.StateVersion)
	if e == nil && tag.RowsAffected() != 1 {
		return app.ErrConflict
	}
	return e
}
func (Store) FindPraiseTx(c context.Context, q tx.Queryer, target, actor identity.PlayerID) (d.Praise, bool, error) {
	if q == nil || !target.Valid() || !actor.Valid() {
		return d.Praise{}, false, app.ErrInvalid
	}
	var p d.Praise
	var t, a int64
	e := q.QueryRow(c, `SELECT target_player_id,actor_player_id,praise_time,root_version FROM player_profile_praises WHERE target_player_id=$1 AND actor_player_id=$2`, int64(target), int64(actor)).Scan(&t, &a, &p.FirstAt, &p.RootVersion)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return p, false, nil
	}
	if e != nil {
		return p, false, e
	}
	p.Target = identity.PlayerID(t)
	p.Actor = identity.PlayerID(a)
	p.FirstAt = p.FirstAt.UTC()
	if p.Target != target || p.Actor != actor {
		return p, true, app.ErrInvalid
	}
	return p, true, p.Validate()
}
func (Store) InsertPraiseTx(c context.Context, t tx.Tx, p d.Praise) error {
	if t == nil || p.Validate() != nil {
		return app.ErrInvalid
	}
	tag, e := t.Exec(c, `INSERT INTO player_profile_praises(target_player_id,actor_player_id,praise_time,root_version)VALUES($1,$2,$3,$4)`, int64(p.Target), int64(p.Actor), p.FirstAt, p.RootVersion)
	if e == nil && tag.RowsAffected() != 1 {
		return app.ErrConflict
	}
	return e
}
func (Store) CountTx(c context.Context, q tx.Queryer, target identity.PlayerID) (int64, error) {
	if q == nil || !target.Valid() {
		return 0, app.ErrInvalid
	}
	var n int64
	e := q.QueryRow(c, `SELECT count(*) FROM player_profile_praises WHERE target_player_id=$1`, int64(target)).Scan(&n)
	return n, e
}
func (Store) ListTx(c context.Context, q tx.Queryer, target identity.PlayerID, start, offset int64) ([]d.Praise, error) {
	out := []d.Praise{}
	if q == nil || !target.Valid() || start < 0 || start > 9007199254740991 || offset < 1 || offset > 20 {
		return nil, app.ErrRequest
	}
	var raw string
	e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_object('Target',target_player_id,'Actor',actor_player_id,'FirstAt',praise_time,'RootVersion',root_version) ORDER BY praise_time DESC,actor_player_id DESC),'[]'::jsonb)::text FROM (SELECT target_player_id,actor_player_id,praise_time,root_version FROM player_profile_praises WHERE target_player_id=$1 ORDER BY praise_time DESC,actor_player_id DESC LIMIT $2 OFFSET $3) page`, int64(target), offset, start).Scan(&raw)
	if e != nil {
		return nil, e
	}
	if e = json.Unmarshal([]byte(raw), &out); e != nil {
		return nil, e
	}
	for i, p := range out {
		out[i].FirstAt = p.FirstAt.UTC()
		if p.Target != target || p.Validate() != nil {
			return nil, app.ErrInvalid
		}
	}
	return out, nil
}
