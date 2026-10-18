// Package achievementstore exclusively owns canonical earned-tier persistence.
package achievementstore

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	app "gxb.local/backend/v2/internal/application/achievement"
	d "gxb.local/backend/v2/internal/domain/achievement"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type Store struct{}

func (Store) ReadRootTx(c context.Context, q tx.Queryer, pid identity.PlayerID, lock bool) (d.Root, bool, error) {
	var r d.Root
	if q == nil || !pid.Valid() {
		return r, false, d.ErrUnavailable
	}
	sql := `SELECT player_id,content_revision,policy_id,progress,complete_times::text,state_version,created_at,updated_at FROM achievement_roots WHERE player_id=$1`
	if lock {
		sql += " FOR UPDATE"
	}
	var raw string
	e := q.QueryRow(c, sql, int64(pid)).Scan(&r.PlayerID, &r.ContentRevision, &r.PolicyID, &r.Progress, &raw, &r.StateVersion, &r.CreatedAt, &r.UpdatedAt)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return r, false, nil
	}
	if e != nil {
		return r, false, e
	}
	var times []*time.Time
	if e = json.Unmarshal([]byte(raw), &times); e != nil || len(times) != 3 {
		return r, true, d.ErrConflict
	}
	copy(r.CompleteTimes[:], times)
	return r, true, r.Validate()
}
func (Store) InitFreshTx(c context.Context, t tx.Tx, pid identity.PlayerID, rev string, at time.Time) error {
	if t == nil {
		return d.ErrUnavailable
	}
	r, e := d.NewRoot(pid, rev, at)
	if e != nil {
		return e
	}
	tag, e := t.Exec(c, `INSERT INTO achievement_roots(player_id,content_revision,policy_id,progress,complete_times,state_version,created_at,updated_at)VALUES($1,$2,$3,0,'[null,null,null]'::jsonb,1,$4,$4)`, int64(r.PlayerID), r.ContentRevision, r.PolicyID, r.CreatedAt)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return d.ErrConflict
	}
	return nil
}
func (Store) SaveRootTx(c context.Context, t tx.Tx, r d.Root, old int64) error {
	if t == nil || r.Validate() != nil || r.StateVersion != old+1 {
		return d.ErrConflict
	}
	raw, e := json.Marshal(r.CompleteTimes)
	if e != nil {
		return e
	}
	tag, e := t.Exec(c, `UPDATE achievement_roots SET progress=$3,complete_times=$4::jsonb,state_version=$5,updated_at=$6 WHERE player_id=$1 AND state_version=$2 AND content_revision=$7 AND policy_id=$8 AND created_at=$9`, int64(r.PlayerID), old, r.Progress, string(raw), r.StateVersion, r.UpdatedAt, r.ContentRevision, r.PolicyID, r.CreatedAt)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return d.ErrConflict
	}
	return nil
}
func (Store) PutEventTx(c context.Context, t tx.Tx, e app.Event) error {
	if t == nil || e.Validate() != nil {
		return d.ErrConflict
	}
	s := e.Source
	tag, err := t.Exec(c, `INSERT INTO achievement_events(player_id,event_key,fingerprint,source_operation,partner_id,old_version,new_version,population,content_revision,decision_at)VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) ON CONFLICT(player_id,event_key)DO NOTHING`, int64(s.Player), e.Key, e.Fingerprint, s.OperationID.String(), s.PartnerID, s.OldVersion, s.NewVersion, e.Population, s.ContentRevision, s.DecisionAt)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 1 {
		return nil
	}
	var fp string
	if err = t.QueryRow(c, `SELECT fingerprint FROM achievement_events WHERE player_id=$1 AND event_key=$2`, int64(s.Player), e.Key).Scan(&fp); err != nil {
		return err
	}
	if fp != e.Fingerprint {
		return d.ErrConflict
	}
	return nil
}
