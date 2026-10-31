// Package occultstore owns the occult tables; the player row locks at rank 605
// and the live run state rides the shared room payload at rank 607.
package occultstore

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/occult"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Store keeps occult rows. Every list and count is scoped to a logical server.
type Store struct{}

// LockPlayerTx creates the player row on first use and locks it at rank 605.
func (Store) LockPlayerTx(ctx context.Context, t tx.Tx, serverID int64, playerID identity.PlayerID, at time.Time) (d.Scores, error) {
	if _, err := t.Exec(ctx, `INSERT INTO occult_players(player_id,logical_server_id,scores,updated_at)VALUES($1,$2,'{}'::jsonb,$3) ON CONFLICT(player_id)DO NOTHING`, int64(playerID), serverID, at); err != nil {
		return nil, err
	}
	var raw string
	if err := t.QueryRow(ctx, `SELECT scores::text FROM occult_players WHERE player_id=$1 FOR UPDATE`, int64(playerID)).Scan(&raw); err != nil {
		return nil, err
	}
	return d.LoadScores(json.RawMessage(raw))
}

func (Store) ReadScoresTx(ctx context.Context, q tx.Queryer, playerID identity.PlayerID) (d.Scores, error) {
	var raw string
	err := q.QueryRow(ctx, `SELECT scores::text FROM occult_players WHERE player_id=$1`, int64(playerID)).Scan(&raw)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return d.Scores{}, nil
	}
	if err != nil {
		return nil, err
	}
	return d.LoadScores(json.RawMessage(raw))
}

func (Store) SaveScoresTx(ctx context.Context, t tx.Tx, playerID identity.PlayerID, scores d.Scores, at time.Time) error {
	raw, err := json.Marshal(scores)
	if err != nil {
		return err
	}
	tag, err := t.Exec(ctx, `UPDATE occult_players SET scores=$2::jsonb,updated_at=$3 WHERE player_id=$1`, int64(playerID), string(raw), at)
	if err == nil && tag.RowsAffected() != 1 {
		return d.ErrUnavailable
	}
	return err
}

// InsertRunTx records a started room once; a repeated start of the same room
// is a no-op so a retried command never rewrites the start time.
func (Store) InsertRunTx(ctx context.Context, t tx.Tx, roomID, serverID, chapterID, campaignType int64, at time.Time) error {
	_, err := t.Exec(ctx, `INSERT INTO occult_runs(room_id,logical_server_id,chapter_id,campaign_type,started_at)VALUES($1,$2,$3,$4,$5) ON CONFLICT(room_id)DO NOTHING`, roomID, serverID, chapterID, campaignType, at)
	return err
}

func (Store) FinishRunTx(ctx context.Context, t tx.Tx, roomID int64, at time.Time) error {
	_, err := t.Exec(ctx, `UPDATE occult_runs SET finished_at=$2 WHERE room_id=$1 AND finished_at IS NULL`, roomID, at)
	return err
}

func (Store) InsertReportTx(ctx context.Context, t tx.Tx, reportID string, serverID, roomID int64, memberIDs []int64, content string, at time.Time) error {
	_, err := t.Exec(ctx, `INSERT INTO occult_reports(report_id,logical_server_id,room_id,member_ids,content,created_at,expires_at)VALUES($1,$2,$3,$4,$5::jsonb,$6,$6::timestamptz+interval '7 days')`, reportID, serverID, roomID, memberIDs, content, at)
	return err
}

// ReadReportTx answers only a room member of the same logical server and only
// before the retention window ends.
func (Store) ReadReportTx(ctx context.Context, q tx.Queryer, reportID string, serverID int64, playerID identity.PlayerID, at time.Time) (string, bool, error) {
	var content string
	err := q.QueryRow(ctx, `SELECT content::text FROM occult_reports WHERE report_id=$1 AND logical_server_id=$2 AND $3=ANY(member_ids) AND expires_at>$4`, reportID, serverID, int64(playerID), at).Scan(&content)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return "", false, nil
	}
	return content, err == nil, err
}

// PurgeExpiredReportsTx deletes one bounded batch past retention; only the
// reconciler calls it.
func (Store) PurgeExpiredReportsTx(ctx context.Context, t tx.Tx, at time.Time, limit int64) (int64, error) {
	if limit < 1 || limit > 10000 {
		return 0, d.ErrInvalid
	}
	tag, err := t.Exec(ctx, `DELETE FROM occult_reports WHERE report_id IN (SELECT report_id FROM occult_reports WHERE expires_at<=$1 ORDER BY expires_at,report_id LIMIT $2)`, at, limit)
	return tag.RowsAffected(), err
}

func (Store) InsertLogTx(ctx context.Context, t tx.Tx, serverID, roomID int64, logType int, playerID identity.PlayerID, content string, at time.Time) error {
	_, err := t.Exec(ctx, `INSERT INTO occult_logs(logical_server_id,room_id,log_type,player_id,content,created_at)VALUES($1,$2,$3,$4,$5::jsonb,$6)`, serverID, roomID, logType, int64(playerID), content, at)
	return err
}

// ReadLogsTx lists one player's newest logs, bounded.
func (Store) ReadLogsTx(ctx context.Context, q tx.Queryer, serverID int64, playerID identity.PlayerID, limit int64) ([]json.RawMessage, error) {
	if limit < 1 || limit > 200 {
		return nil, d.ErrInvalid
	}
	var raw string
	err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(content ORDER BY log_id DESC),'[]'::jsonb)::text FROM (SELECT log_id,content FROM occult_logs WHERE logical_server_id=$1 AND player_id=$2 ORDER BY log_id DESC LIMIT $3) newest`, serverID, int64(playerID), limit).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var logs []json.RawMessage
	err = json.Unmarshal([]byte(raw), &logs)
	return logs, err
}
