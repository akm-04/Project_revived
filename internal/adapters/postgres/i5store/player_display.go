package i5store

import (
	"context"
	"encoding/json"
	app "gxb.local/backend/v2/internal/application/playerdisplay"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

var _ app.Store = Store{}

func (s Store) ReadDisplayStateTx(c context.Context, q tx.Queryer, pid identity.PlayerID, lock bool) (app.State, error) {
	var out app.State
	if q == nil || !pid.Valid() {
		return out, app.ErrRequest
	}
	if lock {
		var id int64
		if e := q.QueryRow(c, `SELECT player_id FROM player_profiles WHERE player_id=$1 FOR UPDATE`, int64(pid)).Scan(&id); e != nil {
			return out, e
		}
		if id != int64(pid) {
			return out, app.ErrConflict
		}
	}
	b, e := s.ReadPublicPlayerBasisTx(c, q, pid)
	if e != nil {
		return out, e
	}
	out.Basis = b
	out.Selection.BubbleID = 10001
	e = q.QueryRow(c, `SELECT avatar_table_id,avatar_category,title_id,title_unique_id,bubble_id FROM player_display_selections WHERE player_id=$1`, int64(pid)).Scan(&out.Selection.AvatarTableID, &out.Selection.AvatarCategory, &out.Selection.TitleID, &out.Selection.TitleUniqueID, &out.Selection.BubbleID)
	if noRows(e) {
		return out, out.Validate()
	}
	if e != nil {
		return out, e
	}
	out.Present = true
	return out, out.Validate()
}
func (Store) SaveDisplayStateTx(c context.Context, t tx.Tx, old, next app.State, at time.Time) error {
	if t == nil || old.Validate() != nil || next.Validate() != nil || old.Basis.Profile.PlayerID != next.Basis.Profile.PlayerID || at.IsZero() || at.Before(old.Basis.Profile.UpdatedAt) {
		return app.ErrConflict
	}
	p := next.Basis.Profile
	tag, e := t.Exec(c, `UPDATE player_profiles SET display_name=$2,avatar_id=$3,avatar_frame_id=$4,state_version=state_version+1,updated_at=$5 WHERE player_id=$1 AND state_version=$6`, int64(p.PlayerID), p.DisplayName, p.AvatarID, p.AvatarFrameID, at, old.Basis.Profile.StateVersion)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return app.ErrConflict
	}
	s := next.Selection
	_, e = t.Exec(c, `INSERT INTO player_display_selections(player_id,avatar_table_id,avatar_category,title_id,title_unique_id,bubble_id)VALUES($1,$2,$3,$4,$5,$6) ON CONFLICT(player_id) DO UPDATE SET avatar_table_id=EXCLUDED.avatar_table_id,avatar_category=EXCLUDED.avatar_category,title_id=EXCLUDED.title_id,title_unique_id=EXCLUDED.title_unique_id,bubble_id=EXCLUDED.bubble_id`, int64(p.PlayerID), s.AvatarTableID, s.AvatarCategory, s.TitleID, s.TitleUniqueID, s.BubbleID)
	return e
}
func (Store) ReadDisplayEntitlementsTx(c context.Context, q tx.Queryer, pid identity.PlayerID, family string) ([]app.Origin, error) {
	var raw string
	e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_object('player_id',player_id,'key',origin_key,'owner',origin_owner,'family',family,'catalog_id',catalog_id,'unique_id',unique_id,'starts_at',starts_at,'end_time',end_time,'revision',content_revision,'state_version',state_version) ORDER BY origin_key),'[]'::jsonb)::text FROM player_cosmetic_entitlements WHERE player_id=$1 AND family=$2`, int64(pid), family).Scan(&raw)
	if e != nil {
		return nil, e
	}
	var out []app.Origin
	if e = json.Unmarshal([]byte(raw), &out); e != nil {
		return nil, e
	}
	for _, o := range out {
		if o.Validate() != nil || o.PlayerID != pid || o.Family != family {
			return nil, app.ErrConflict
		}
	}
	return out, nil
}

// Trusted typed recipient only; no client route calls this method. Origin
// identity and family wire payload remain separate. Same origin is immutable.
func (Store) PutDisplayEntitlementTx(c context.Context, t tx.Tx, o app.Origin) error {
	if t == nil || o.Validate() != nil {
		return app.ErrConflict
	}
	tag, e := t.Exec(c, `INSERT INTO player_cosmetic_entitlements(player_id,origin_key,origin_owner,family,catalog_id,unique_id,starts_at,end_time,content_revision,state_version)VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) ON CONFLICT(player_id,origin_key)DO NOTHING`, int64(o.PlayerID), o.Key, o.Owner, o.Family, o.CatalogID, o.UniqueID, o.StartsAt, o.EndTime, o.Revision, o.StateVersion)
	if e != nil {
		return e
	}
	if tag.RowsAffected() == 1 {
		return nil
	}
	var equal bool
	e = t.QueryRow(c, `SELECT origin_owner=$3 AND family=$4 AND catalog_id=$5 AND unique_id=$6 AND starts_at IS NOT DISTINCT FROM $7::timestamptz AND end_time=$8 AND content_revision=$9 AND state_version=$10 FROM player_cosmetic_entitlements WHERE player_id=$1 AND origin_key=$2`, int64(o.PlayerID), o.Key, o.Owner, o.Family, o.CatalogID, o.UniqueID, o.StartsAt, o.EndTime, o.Revision, o.StateVersion).Scan(&equal)
	if e != nil {
		return e
	}
	if !equal {
		return app.ErrConflict
	}
	return nil
}
func (Store) ReadDisplayAdmissionTx(c context.Context, q tx.Queryer, id string, lock bool) (app.Admission, bool, error) {
	var out app.Admission
	sql := `SELECT payload::text,state FROM player_display_admissions WHERE operation_id=$1`
	if lock {
		sql += " FOR UPDATE"
	}
	var raw, state string
	e := q.QueryRow(c, sql, id).Scan(&raw, &state)
	if noRows(e) {
		return out, false, nil
	}
	if e != nil {
		return out, false, e
	}
	e = json.Unmarshal([]byte(raw), &out)
	out.State = state
	return out, true, e
}
func (s Store) PendingDisplayAdmissionTx(c context.Context, t tx.Tx, pid identity.PlayerID) (app.Admission, bool, error) {
	var id string
	e := t.QueryRow(c, `SELECT operation_id::text FROM player_display_admissions WHERE player_id=$1 AND state='PENDING' FOR UPDATE`, int64(pid)).Scan(&id)
	if noRows(e) {
		return app.Admission{}, false, nil
	}
	if e != nil {
		return app.Admission{}, false, e
	}
	return s.ReadDisplayAdmissionTx(c, t, id, false)
}
func (Store) InsertDisplayAdmissionTx(c context.Context, t tx.Tx, j app.Admission) error {
	raw, e := json.Marshal(j)
	if e != nil {
		return e
	}
	_, e = t.Exec(c, `INSERT INTO player_display_admissions(operation_id,player_id,payload,state)VALUES($1,$2,$3::jsonb,'PENDING')`, j.Operation.ID.String(), int64(j.Actor.PlayerID), string(raw))
	return e
}
func (Store) SetDisplayAdmissionTx(c context.Context, t tx.Tx, id, old, next string) error {
	tag, e := t.Exec(c, `UPDATE player_display_admissions SET state=$3 WHERE operation_id=$1 AND state=$2`, id, old, next)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return app.ErrConflict
	}
	return nil
}

var _ = player.DisplayPolicy
