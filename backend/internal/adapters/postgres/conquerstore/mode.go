package conquerstore

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	d "gxb.local/backend/v2/internal/domain/conquerschool"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ReadModeTx reads the mode row; lock takes it after the I4 root and the facts row.
func (Store) ReadModeTx(c context.Context, q tx.Queryer, p identity.PlayerID, lock bool) (d.Mode, bool, error) {
	query := `SELECT state::text,state_version,created_at,updated_at FROM conquer_school_players WHERE player_id=$1`
	if lock {
		query += ` FOR UPDATE`
	}
	m := d.Mode{Player: p}
	var raw string
	err := q.QueryRow(c, query, int64(p)).Scan(&raw, &m.StateVersion, &m.CreatedAt, &m.UpdatedAt)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return d.Mode{}, false, nil
	}
	if err != nil {
		return d.Mode{}, false, err
	}
	return m, true, json.Unmarshal([]byte(raw), &m)
}

func (Store) InsertModeTx(c context.Context, t tx.Tx, m d.Mode, server identity.LogicalServerID, revision string) error {
	raw, err := json.Marshal(m)
	if err != nil {
		return err
	}
	_, err = t.Exec(c, `INSERT INTO conquer_school_players(player_id,logical_server_id,content_revision,state,state_version,created_at,updated_at)VALUES($1,$2,$3,$4::jsonb,1,$5,$5)`,
		int64(m.Player), int64(server), revision, string(raw), m.CreatedAt)
	return err
}

func (Store) SaveModeTx(c context.Context, t tx.Tx, m d.Mode, old int64) error {
	raw, err := json.Marshal(m)
	if err != nil {
		return err
	}
	tag, err := t.Exec(c, `UPDATE conquer_school_players SET state=$2::jsonb,state_version=$3,updated_at=$4 WHERE player_id=$1 AND state_version=$5 AND updated_at<=$4`,
		int64(m.Player), string(raw), m.StateVersion, m.UpdatedAt, old)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return d.ErrConflict
	}
	return nil
}

// InsertReportTx keeps a report and prunes its (loop, mission, team) to the best limit.
func (Store) InsertReportTx(c context.Context, t tx.Tx, r d.Report, limit int64) error {
	profile, err := json.Marshal(r.Profile)
	if err != nil {
		return err
	}
	_, err = t.Exec(c, `INSERT INTO conquer_school_reports(report_key,owner_player_id,loop_id,mission_id,team_id,score,profile,heroes,pet,report,attempt_id,recorded_at)
VALUES($1::uuid,$2,$3,$4,$5,$6,$7::jsonb,$8::jsonb,$9::jsonb,$10::jsonb,$11,$12)`,
		r.Key, int64(r.Owner), r.Loop, r.MissionID, r.TeamID, r.Score, string(profile), string(r.Heroes), string(r.Pet), string(r.Body), r.AttemptID, r.RecordedAt)
	if err != nil {
		return err
	}
	_, err = t.Exec(c, `DELETE FROM conquer_school_reports WHERE loop_id=$1 AND mission_id=$2 AND team_id=$3 AND report_id NOT IN(
SELECT report_id FROM conquer_school_reports WHERE loop_id=$1 AND mission_id=$2 AND team_id=$3 ORDER BY score DESC,report_id LIMIT $4)`, r.Loop, r.MissionID, r.TeamID, limit)
	return err
}

const reportCols = `report_key::text,owner_player_id,loop_id,mission_id,team_id,score,profile::text,heroes::text,pet::text,report::text,attempt_id,recorded_at`

func scanReport(row tx.Row) (d.Report, error) {
	var r d.Report
	var owner int64
	var profile, heroes, pet, body string
	if err := row.Scan(&r.Key, &owner, &r.Loop, &r.MissionID, &r.TeamID, &r.Score, &profile, &heroes, &pet, &body, &r.AttemptID, &r.RecordedAt); err != nil {
		return r, err
	}
	r.Owner, r.Heroes, r.Pet, r.Body = identity.PlayerID(owner), json.RawMessage(heroes), json.RawMessage(pet), json.RawMessage(body)
	return r, json.Unmarshal([]byte(profile), &r.Profile)
}

// ReportsTx lists the best reports, ties to the earlier report.
func (s Store) ReportsTx(c context.Context, q tx.Queryer, loop, mission, team, limit int64) ([]d.Report, error) {
	var raw string
	if err := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(report_key::text ORDER BY score DESC,report_id),'[]'::jsonb)::text FROM(
SELECT report_key,score,report_id FROM conquer_school_reports WHERE loop_id=$1 AND mission_id=$2 AND team_id=$3 ORDER BY score DESC,report_id LIMIT $4)best`, loop, mission, team, limit).Scan(&raw); err != nil {
		return nil, err
	}
	var keys []string
	if err := json.Unmarshal([]byte(raw), &keys); err != nil {
		return nil, err
	}
	out := make([]d.Report, 0, len(keys))
	for _, key := range keys {
		r, found, err := s.ReportTx(c, q, key)
		if err != nil || !found {
			return nil, errors.Join(err, d.ErrConflict)
		}
		out = append(out, r)
	}
	return out, nil
}

func (Store) ReportTx(c context.Context, q tx.Queryer, key string) (d.Report, bool, error) {
	r, err := scanReport(q.QueryRow(c, `SELECT `+reportCols+` FROM conquer_school_reports WHERE report_key=$1::uuid`, key))
	if errors.Is(err, kernelstore.ErrNoRows) {
		return d.Report{}, false, nil
	}
	return r, err == nil, err
}

// InsertViewTx records a viewer's first view of a report on a day.
func (Store) InsertViewTx(c context.Context, t tx.Tx, key string, viewer identity.PlayerID, day int64, at time.Time) (bool, error) {
	tag, err := t.Exec(c, `INSERT INTO conquer_school_report_views(report_key,viewer_player_id,day,viewed_at)VALUES($1::uuid,$2,$3,$4)ON CONFLICT DO NOTHING`, key, int64(viewer), day, at)
	if err != nil {
		return false, err
	}
	return tag.RowsAffected() == 1, nil
}
