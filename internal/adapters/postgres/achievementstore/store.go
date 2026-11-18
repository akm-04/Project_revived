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
	"gxb.local/backend/v2/internal/foundation/observability"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type Store struct {
	Metrics observability.Metrics
}

func (Store) ReadRootTx(c context.Context, q tx.Queryer, pid identity.PlayerID, lock bool) (d.Root, bool, error) {
	var r d.Root
	if q == nil || !pid.Valid() {
		return r, false, d.ErrUnavailable
	}
	sql := `SELECT player_id,content_revision,policy_id,progress,complete_times::text,state_version,created_at,updated_at,payload_version FROM achievement_roots WHERE player_id=$1`
	if lock {
		sql += " FOR UPDATE"
	}
	var raw string
	var version int16
	e := q.QueryRow(c, sql, int64(pid)).Scan(&r.PlayerID, &r.ContentRevision, &r.PolicyID, &r.Progress, &raw, &r.StateVersion, &r.CreatedAt, &r.UpdatedAt, &version)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return r, false, nil
	}
	if e != nil {
		return r, false, e
	}
	var times []*time.Time
	if e = payload.Decode("achievement_roots", version, []byte(raw), &times); e != nil || len(times) != 3 {
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
	raw, version, e := payload.Encode(r.CompleteTimes)
	if e != nil {
		return e
	}
	tag, e := t.Exec(c, `UPDATE achievement_roots SET progress=$3,complete_times=$4::jsonb,state_version=$5,updated_at=$6,payload_version=$10 WHERE player_id=$1 AND state_version=$2 AND content_revision=$7 AND policy_id=$8 AND created_at=$9`, int64(r.PlayerID), old, r.Progress, string(raw), r.StateVersion, r.UpdatedAt, r.ContentRevision, r.PolicyID, r.CreatedAt, version)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return d.ErrConflict
	}
	return nil
}

// PutBossFactTx records one qualified Fantasy fact once. The caller learns
// whether the row is new, so a settlement retry does no further work.
func (Store) PutBossFactTx(c context.Context, t tx.Tx, pid identity.PlayerID, achievementID, campaignID, occurrenceDay int64, at time.Time) (bool, error) {
	if t == nil || !pid.Valid() || achievementID != d.FantasyTopRankID && achievementID != d.FantasyDamageID || campaignID < 1 || occurrenceDay < 1 || at.Unix() <= 0 {
		return false, d.ErrUnavailable
	}
	tag, e := t.Exec(c, `INSERT INTO achievement_boss_facts(player_id,achievement_id,campaign_id,occurrence_day,created_at)VALUES($1,$2,$3,$4,$5) ON CONFLICT DO NOTHING`, int64(pid), achievementID, campaignID, occurrenceDay, at.UTC())
	if e != nil {
		return false, e
	}
	return tag.RowsAffected() == 1, nil
}

// CountBossFactsTx is the fact progress: at most one row per campaign.
func (Store) CountBossFactsTx(c context.Context, q tx.Queryer, pid identity.PlayerID, achievementID int64) (int64, error) {
	var count int64
	if q == nil || !pid.Valid() || achievementID != d.FantasyTopRankID && achievementID != d.FantasyDamageID {
		return 0, d.ErrUnavailable
	}
	if e := q.QueryRow(c, `SELECT count(*) FROM achievement_boss_facts WHERE player_id=$1 AND achievement_id=$2`, int64(pid), achievementID).Scan(&count); e != nil {
		return 0, e
	}
	return count, nil
}

// MarkNoticesDeliveredAtTx consumes every pending notice inside the login
// transaction; the MID1 detail projection reads back exactly this instant.
// shortcut: the login instant correlates the claim with the read-only detail
// projection; two logins in the same microsecond could show one popup twice.
// Add a delivery operation column if that ever matters.
func (Store) MarkNoticesDeliveredAtTx(c context.Context, t tx.Tx, pid identity.PlayerID, at time.Time) error {
	if t == nil || !pid.Valid() || at.IsZero() {
		return d.ErrUnavailable
	}
	_, e := t.Exec(c, `UPDATE achievement_notices SET delivered_at=$2 WHERE player_id=$1 AND delivered_at IS NULL`, int64(pid), at.UTC())
	return e
}

// NoticeIDsDeliveredAtTx returns the achievement ids this login consumed, in
// first-earned order and once per achievement (the notice-17 push dedupes the
// same way).
func (Store) NoticeIDsDeliveredAtTx(c context.Context, q tx.Queryer, pid identity.PlayerID, at time.Time) ([]int64, error) {
	out := []int64{}
	if q == nil || !pid.Valid() || at.IsZero() {
		return out, d.ErrUnavailable
	}
	var raw string
	e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(achievement_id ORDER BY first_notice),'[]'::jsonb)::text FROM (SELECT achievement_id,min(notice_id) AS first_notice FROM achievement_notices WHERE player_id=$1 AND delivered_at=$2 GROUP BY achievement_id) consumed`, int64(pid), at.UTC()).Scan(&raw)
	if e != nil {
		return out, e
	}
	return out, json.Unmarshal([]byte(raw), &out)
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

func (Store) ReadStreakTx(c context.Context, q tx.Queryer, pid identity.PlayerID, id int64, lock bool) (d.Streak, bool, error) {
	s := d.Streak{AchievementID: id}
	if q == nil || !pid.Valid() {
		return s, false, d.ErrUnavailable
	}
	sql := `SELECT player_id,content_revision,current,last_day,complete_times::text,state_version,created_at,updated_at,payload_version FROM achievement_streaks WHERE player_id=$1 AND achievement_id=$2`
	if lock {
		sql += " FOR UPDATE"
	}
	var raw string
	var version int16
	e := q.QueryRow(c, sql, int64(pid), id).Scan(&s.PlayerID, &s.ContentRevision, &s.Current, &s.LastDay, &raw, &s.StateVersion, &s.CreatedAt, &s.UpdatedAt, &version)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return s, false, nil
	}
	if e != nil {
		return s, false, e
	}
	var times []*time.Time
	if e = payload.Decode("achievement_streaks", version, []byte(raw), &times); e != nil || len(times) != 3 {
		return s, true, d.ErrConflict
	}
	copy(s.CompleteTimes[:], times)
	return s, true, s.Validate()
}

// SaveStreakTx inserts version 1 or advances an existing streak by exactly one version.
func (Store) SaveStreakTx(c context.Context, t tx.Tx, s d.Streak, old int64) error {
	if t == nil || s.Validate() != nil || s.StateVersion != old+1 {
		return d.ErrConflict
	}
	raw, version, e := payload.Encode(s.CompleteTimes)
	if e != nil {
		return e
	}
	sql := `UPDATE achievement_streaks SET current=$3,last_day=$4,complete_times=$5::jsonb,state_version=$6,updated_at=$7,payload_version=$9 WHERE player_id=$1 AND state_version=$2 AND achievement_id=$8`
	args := []any{int64(s.PlayerID), old, s.Current, s.LastDay, string(raw), s.StateVersion, s.UpdatedAt, s.AchievementID, version}
	if old == 0 {
		sql = `INSERT INTO achievement_streaks(player_id,achievement_id,policy_id,content_revision,current,last_day,complete_times,state_version,created_at,updated_at,payload_version)VALUES($1,$2,$3,$4,$5,$6,$7::jsonb,$8,$9,$10,$11)`
		args = []any{int64(s.PlayerID), s.AchievementID, d.StreakPolicy(s.AchievementID), s.ContentRevision, s.Current, s.LastDay, string(raw), s.StateVersion, s.CreatedAt, s.UpdatedAt, version}
	}
	tag, e := t.Exec(c, sql, args...)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return d.ErrConflict
	}
	return nil
}

// ActiveStreakPlayersTx lists the server's players with a running periodic streak observed before day.
func (Store) ActiveStreakPlayersTx(c context.Context, q tx.Queryer, server identity.LogicalServerID, id, day int64) ([]identity.PlayerID, error) {
	var raw string
	if e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(player_id ORDER BY player_id),'[]'::jsonb)::text FROM achievement_streaks WHERE player_id/100000=$1 AND achievement_id=$3 AND current>0 AND last_day<$2`, int64(server), day, id).Scan(&raw); e != nil {
		return nil, e
	}
	var out []identity.PlayerID
	return out, json.Unmarshal([]byte(raw), &out)
}
