// Package rankingstore owns Ranking snapshots, observation runs and awards.
// Character scores, canonical I4 player identity and display selection remain
// behind their existing typed owner ports.
package rankingstore

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/ranking"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{}

func (Store) LockGirlsRootTx(c context.Context, t tx.Tx, server identity.LogicalServerID, at time.Time) (d.GirlsRoot, error) {
	seed, e := d.NewGirlsRoot(server, at)
	if t == nil || e != nil {
		return seed, d.ErrSnapshot
	}
	raw, e := json.Marshal(seed)
	if e != nil {
		return seed, e
	}
	if _, e = t.Exec(c, `INSERT INTO ranking_girls_roots(logical_server_id,policy_id,state_version,payload)VALUES($1,$2,1,$3::jsonb) ON CONFLICT(logical_server_id,policy_id)DO NOTHING`, int64(server), d.GirlsPolicy, string(raw)); e != nil {
		return seed, e
	}
	var data string
	var version int64
	if e = t.QueryRow(c, `SELECT payload::text,state_version FROM ranking_girls_roots WHERE logical_server_id=$1 AND policy_id=$2 FOR UPDATE`, int64(server), d.GirlsPolicy).Scan(&data, &version); e != nil {
		return seed, e
	}
	var r d.GirlsRoot
	if e = json.Unmarshal([]byte(data), &r); e != nil {
		return r, e
	}
	if r.Validate() != nil || r.Server != server || r.Policy != d.GirlsPolicy || r.StateVersion != version {
		return r, d.ErrSnapshot
	}
	return r, nil
}
func (Store) SaveGirlsRootTx(c context.Context, t tx.Tx, r d.GirlsRoot, old int64) error {
	if t == nil || r.Validate() != nil || r.StateVersion != old+1 {
		return d.ErrSnapshot
	}
	raw, e := json.Marshal(r)
	if e != nil {
		return e
	}
	tag, e := t.Exec(c, `UPDATE ranking_girls_roots SET state_version=$3,payload=$4::jsonb WHERE logical_server_id=$1 AND policy_id=$2 AND state_version=$5`, int64(r.Server), r.Policy, r.StateVersion, string(raw), old)
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return d.ErrSnapshot
	}
	return nil
}
func (Store) InsertGirlsSnapshotTx(c context.Context, t tx.Tx, s d.GirlsSnapshot) error {
	if t == nil || s.Validate() != nil {
		return d.ErrSnapshot
	}
	raw, e := json.Marshal(s)
	if e != nil {
		return e
	}
	tag, e := t.Exec(c, `INSERT INTO ranking_girls_snapshots(logical_server_id,policy_id,generation,operation_id,content_revision,observed_at,digest,payload)VALUES($1,$2,$3,$4,$5,$6,$7,$8::jsonb)`, int64(s.Server), s.Policy, s.Generation, s.OperationID.String(), s.Revision, s.ObservedAt, s.Digest, string(raw))
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return d.ErrSnapshot
	}
	return nil
}
func decodeSnapshot(row tx.Row) (d.GirlsSnapshot, bool, error) {
	var out d.GirlsSnapshot
	var raw, hash string
	e := row.Scan(&raw, &hash)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return out, false, nil
	}
	if e != nil {
		return out, false, e
	}
	if e = json.Unmarshal([]byte(raw), &out); e != nil {
		return out, true, e
	}
	if out.Validate() != nil || out.Digest != hash {
		return out, true, d.ErrSnapshot
	}
	return out, true, nil
}
func (Store) ReadGirlsSnapshotTx(c context.Context, q tx.Queryer, server identity.LogicalServerID, gen int64) (d.GirlsSnapshot, bool, error) {
	if q == nil || !server.Valid() || gen < 1 {
		return d.GirlsSnapshot{}, false, d.ErrSnapshot
	}
	s, ok, e := decodeSnapshot(q.QueryRow(c, `SELECT payload::text,digest FROM ranking_girls_snapshots WHERE logical_server_id=$1 AND policy_id=$2 AND generation=$3`, int64(server), d.GirlsPolicy, gen))
	if e == nil && ok && (s.Server != server || s.Generation != gen) {
		return s, ok, d.ErrSnapshot
	}
	return s, ok, e
}
func (Store) FindGirlsSnapshotByOperationTx(c context.Context, q tx.Queryer, op ids.UUID) (d.GirlsSnapshot, bool, error) {
	if q == nil || op.IsZero() {
		return d.GirlsSnapshot{}, false, d.ErrSnapshot
	}
	s, ok, e := decodeSnapshot(q.QueryRow(c, `SELECT payload::text,digest FROM ranking_girls_snapshots WHERE operation_id=$1`, op.String()))
	if e == nil && ok && s.OperationID != op {
		return s, ok, d.ErrSnapshot
	}
	return s, ok, e
}

// Root600 serializes the first snapshot bound to each private week. A fresh
// read later in the week publishes a new generation without replacing winners.
func (Store) BindGirlsPeriodTx(c context.Context, t tx.Tx, s d.GirlsSnapshot) error {
	if t == nil || s.Validate() != nil {
		return d.ErrSnapshot
	}
	w, e := d.GirlsWeek(s.ObservedAt)
	if e != nil {
		return e
	}
	_, e = t.Exec(c, `INSERT INTO ranking_girls_periods(logical_server_id,policy_id,week_start,snapshot_generation)VALUES($1,$2,$3,$4) ON CONFLICT(logical_server_id,policy_id,week_start)DO NOTHING`, int64(s.Server), s.Policy, w, s.Generation)
	return e
}
func (Store) PendingGirlsPeriodsTx(c context.Context, q tx.Queryer, server identity.LogicalServerID) ([]d.GirlsPeriod, error) {
	if q == nil || !server.Valid() {
		return nil, d.ErrSnapshot
	}
	var raw string
	e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_object('Server',logical_server_id,'Policy',policy_id,'Week',week_start,'Generation',snapshot_generation) ORDER BY week_start),'[]'::jsonb)::text FROM ranking_girls_periods WHERE logical_server_id=$1 AND policy_id=$2 AND settled_at IS NULL`, int64(server), d.GirlsPolicy).Scan(&raw)
	if e != nil {
		return nil, e
	}
	out := []d.GirlsPeriod{}
	if e = json.Unmarshal([]byte(raw), &out); e != nil {
		return nil, e
	}
	for _, p := range out {
		if p.Server != int64(server) || p.Policy != d.GirlsPolicy || p.Generation < 1 || p.Week.IsZero() {
			return nil, d.ErrSnapshot
		}
	}
	return out, nil
}
func (Store) ReadGirlsPeriodTx(c context.Context, q tx.Queryer, server identity.LogicalServerID, week time.Time) (d.GirlsPeriod, bool, error) {
	var p d.GirlsPeriod
	if q == nil || !server.Valid() || week.IsZero() {
		return p, false, d.ErrSnapshot
	}
	p.Server = int64(server)
	p.Policy = d.GirlsPolicy
	p.Week = week.UTC()
	e := q.QueryRow(c, `SELECT snapshot_generation,settled_at FROM ranking_girls_periods WHERE logical_server_id=$1 AND policy_id=$2 AND week_start=$3`, int64(server), d.GirlsPolicy, week.UTC()).Scan(&p.Generation, &p.SettledAt)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return p, false, nil
	}
	return p, e == nil, e
}

// The caller holds sorted I4 winner roots315, then Ranking600. These immutable
// award rows and the PlayerDisplay trusted recipient writes share that callerTx.
func (Store) SettleGirlsPeriodTx(c context.Context, t tx.Tx, s d.GirlsSnapshot, p d.GirlsPeriod, at time.Time) error {
	if t == nil || p.Validate(s) != nil || p.SettledAt != nil || at.Before(s.ObservedAt) {
		return d.ErrSnapshot
	}
	awards, e := s.Awards()
	if e != nil {
		return e
	}
	for _, a := range awards {
		if _, e = t.Exec(c, `INSERT INTO ranking_girls_awards(logical_server_id,policy_id,week_start,player_id,rank,title_id,origin_key,starts_at,end_time)VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9)`, int64(s.Server), s.Policy, p.Week, int64(a.Player), a.Rank, a.TitleID, a.OriginKey, a.StartsAt, a.EndTime); e != nil {
			return e
		}
	}
	tag, e := t.Exec(c, `UPDATE ranking_girls_periods SET settled_at=$5 WHERE logical_server_id=$1 AND policy_id=$2 AND week_start=$3 AND snapshot_generation=$4 AND settled_at IS NULL`, int64(s.Server), s.Policy, p.Week, p.Generation, at.UTC())
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return d.ErrSnapshot
	}
	return nil
}
func (Store) GirlsAwardEvidenceTx(c context.Context, q tx.Queryer, pid identity.PlayerID) ([]d.GirlsAwardEvidence, error) {
	if q == nil || !pid.Valid() {
		return nil, d.ErrSnapshot
	}
	var raw string
	e := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_object('Server',s.logical_server_id,'Generation',s.generation,'SnapshotDigest',s.digest,'SettledAt',p.settled_at,'Snapshot',s.payload,'Award',jsonb_build_object('Player',a.player_id,'Rank',a.rank,'TitleID',a.title_id,'OriginKey',a.origin_key,'StartsAt',a.starts_at,'EndTime',a.end_time)) ORDER BY a.week_start,a.origin_key),'[]'::jsonb)::text FROM ranking_girls_awards a JOIN ranking_girls_periods p ON p.logical_server_id=a.logical_server_id AND p.policy_id=a.policy_id AND p.week_start=a.week_start JOIN ranking_girls_snapshots s ON s.logical_server_id=p.logical_server_id AND s.policy_id=p.policy_id AND s.generation=p.snapshot_generation WHERE a.player_id=$1 AND a.policy_id=$2 AND p.settled_at IS NOT NULL`, int64(pid), d.GirlsPolicy).Scan(&raw)
	if e != nil {
		return nil, e
	}
	out := []d.GirlsAwardEvidence{}
	if e = json.Unmarshal([]byte(raw), &out); e != nil {
		return nil, e
	}
	seen := map[string]bool{}
	for _, v := range out {
		if v.Validate() != nil || v.Award.Player != pid || seen[v.Award.OriginKey] {
			return nil, d.ErrSnapshot
		}
		seen[v.Award.OriginKey] = true
	}
	return out, nil
}
func (Store) FreshGirlsTrackingTx(c context.Context, t tx.Tx, pid identity.PlayerID, server identity.LogicalServerID, at time.Time) error {
	if t == nil || !pid.Valid() || !server.Valid() || at.Unix() <= 0 {
		return d.ErrSnapshot
	}
	tag, e := t.Exec(c, `INSERT INTO ranking_girls_birth_tracking(player_id,logical_server_id,policy_id,started_at)VALUES($1,$2,$3,$4)`, int64(pid), int64(server), d.GirlsPolicy, at.UTC())
	if e != nil {
		return e
	}
	if tag.RowsAffected() != 1 {
		return d.ErrSnapshot
	}
	return nil
}
func (Store) GirlsTrackingTx(c context.Context, q tx.Queryer, pid identity.PlayerID, server identity.LogicalServerID, at time.Time) (bool, error) {
	if q == nil || !pid.Valid() || !server.Valid() || at.Unix() <= 0 {
		return false, d.ErrSnapshot
	}
	var start time.Time
	var gotServer int64
	e := q.QueryRow(c, `SELECT logical_server_id,started_at FROM ranking_girls_birth_tracking WHERE player_id=$1 AND policy_id=$2`, int64(pid), d.GirlsPolicy).Scan(&gotServer, &start)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return false, nil
	}
	if e != nil {
		return false, e
	}
	if gotServer != int64(server) || start.After(at) || start.Unix() <= 0 {
		return false, d.ErrSnapshot
	}
	return true, nil
}
