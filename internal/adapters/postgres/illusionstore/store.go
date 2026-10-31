// Package illusionstore owns the illusion tables; the player row locks at rank
// 605 and the one occurrence row of a logical server at 606.
package illusionstore

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{}

func (Store) ReadOccurrenceTx(ctx context.Context, q tx.Queryer, serverID int64) (d.Occurrence, bool, error) {
	return readOccurrence(q.QueryRow(ctx, `SELECT logical_server_id,campaign_id,pool_hp,pool_hurt,open_day,settled_open_day FROM illusion_occurrences WHERE logical_server_id=$1`, serverID))
}

func (Store) LockOccurrenceTx(ctx context.Context, t tx.Tx, serverID int64, at time.Time) (d.Occurrence, error) {
	if _, err := t.Exec(ctx, `INSERT INTO illusion_occurrences(logical_server_id,campaign_id,pool_hp,pool_hurt,open_day,settled_open_day,updated_at)VALUES($1,$2,$3,0,$4,0,$5) ON CONFLICT(logical_server_id)DO NOTHING`, serverID, d.FirstCampaignID, d.DefaultPoolHP, modes.Day(at), at); err != nil {
		return d.Occurrence{}, err
	}
	occurrence, _, err := readOccurrence(t.QueryRow(ctx, `SELECT logical_server_id,campaign_id,pool_hp,pool_hurt,open_day,settled_open_day FROM illusion_occurrences WHERE logical_server_id=$1 FOR UPDATE`, serverID))
	return occurrence, err
}

func (Store) SaveOccurrenceTx(ctx context.Context, t tx.Tx, occurrence d.Occurrence, at time.Time) error {
	if err := occurrence.Validate(); err != nil {
		return err
	}
	tag, err := t.Exec(ctx, `UPDATE illusion_occurrences SET campaign_id=$2,pool_hp=$3,pool_hurt=$4,open_day=$5,settled_open_day=$6,updated_at=$7 WHERE logical_server_id=$1`, occurrence.LogicalServerID, occurrence.CampaignID, occurrence.PoolHP, occurrence.PoolHurt, occurrence.OpenDay, occurrence.SettledOpenDay, at)
	if err == nil && tag.RowsAffected() != 1 {
		return d.ErrUnavailable
	}
	return err
}

func (Store) ReadPlayerTx(ctx context.Context, q tx.Queryer, playerID identity.PlayerID) (d.Player, bool, error) {
	return readPlayer(q.QueryRow(ctx, `SELECT player_id,day,chances,bought,best_hit,best_time FROM illusion_players WHERE player_id=$1`, int64(playerID)))
}

func (Store) LockPlayerTx(ctx context.Context, t tx.Tx, serverID int64, playerID identity.PlayerID, at time.Time) (d.Player, error) {
	if _, err := t.Exec(ctx, `INSERT INTO illusion_players(player_id,logical_server_id,day,chances,bought,best_hit,best_time,updated_at)VALUES($1,$2,0,$3,0,0,0,$4) ON CONFLICT(player_id)DO NOTHING`, int64(playerID), serverID, d.FreeChances, at); err != nil {
		return d.Player{}, err
	}
	player, _, err := readPlayer(t.QueryRow(ctx, `SELECT player_id,day,chances,bought,best_hit,best_time FROM illusion_players WHERE player_id=$1 FOR UPDATE`, int64(playerID)))
	return player, err
}

func (Store) SavePlayerTx(ctx context.Context, t tx.Tx, player d.Player, at time.Time) error {
	if err := player.Validate(); err != nil {
		return err
	}
	tag, err := t.Exec(ctx, `UPDATE illusion_players SET day=$2,chances=$3,bought=$4,best_hit=$5,best_time=$6,updated_at=$7 WHERE player_id=$1`, player.PlayerID, player.Day, player.Chances, player.Bought, player.BestHit, player.BestTime, at)
	if err == nil && tag.RowsAffected() != 1 {
		return d.ErrUnavailable
	}
	return err
}

func (Store) ReadResultTx(ctx context.Context, q tx.Queryer, serverID, openDay, campaignID int64, playerID identity.PlayerID) (d.Result, bool, error) {
	var result d.Result
	err := q.QueryRow(ctx, `SELECT player_id,hurt,cost_time FROM illusion_occurrence_results WHERE logical_server_id=$1 AND open_day=$2 AND campaign_id=$3 AND player_id=$4`, serverID, openDay, campaignID, int64(playerID)).Scan(&result.PlayerID, &result.Hurt, &result.CostTime)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return d.Result{}, false, nil
	}
	return result, err == nil, err
}

func (Store) LockResultTx(ctx context.Context, t tx.Tx, serverID, openDay, campaignID int64, playerID identity.PlayerID, at time.Time) (d.Result, error) {
	if _, err := t.Exec(ctx, `INSERT INTO illusion_occurrence_results(logical_server_id,open_day,campaign_id,player_id,hurt,cost_time,updated_at)VALUES($1,$2,$3,$4,0,0,$5) ON CONFLICT(logical_server_id,open_day,player_id)DO NOTHING`, serverID, openDay, campaignID, int64(playerID), at); err != nil {
		return d.Result{}, err
	}
	var result d.Result
	err := t.QueryRow(ctx, `SELECT player_id,hurt,cost_time FROM illusion_occurrence_results WHERE logical_server_id=$1 AND open_day=$2 AND player_id=$3 FOR UPDATE`, serverID, openDay, int64(playerID)).Scan(&result.PlayerID, &result.Hurt, &result.CostTime)
	return result, err
}

func (Store) SaveResultTx(ctx context.Context, t tx.Tx, serverID, openDay, campaignID int64, result d.Result, at time.Time) error {
	tag, err := t.Exec(ctx, `UPDATE illusion_occurrence_results SET hurt=$4,cost_time=$5,campaign_id=$6,updated_at=$7 WHERE logical_server_id=$1 AND open_day=$2 AND player_id=$3`, serverID, openDay, result.PlayerID, result.Hurt, result.CostTime, campaignID, at)
	if err == nil && tag.RowsAffected() != 1 {
		return d.ErrUnavailable
	}
	return err
}

func (Store) ReadRankTx(ctx context.Context, q tx.Queryer, serverID, openDay, limit int64) ([]d.Result, error) {
	if limit < 1 || limit > 100000 {
		return nil, d.ErrInvalid
	}
	var raw string
	err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object('player_id',player_id,'hurt',hurt,'cost_time',cost_time) ORDER BY hurt DESC,cost_time,player_id),'[]'::jsonb)::text FROM (SELECT player_id,hurt,cost_time FROM illusion_occurrence_results WHERE logical_server_id=$1 AND open_day=$2 ORDER BY hurt DESC,cost_time,player_id LIMIT $3) ranked`, serverID, openDay, limit).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var results []d.Result
	if err = json.Unmarshal([]byte(raw), &results); err != nil {
		return nil, err
	}
	return results, nil
}

// ListOccurrencesTx lists one bounded batch of logical-server occurrences for
// the settlement reconciler.
func (Store) ListOccurrencesTx(ctx context.Context, q tx.Queryer, limit int64) ([]d.Occurrence, error) {
	if limit < 1 || limit > 10000 {
		return nil, d.ErrInvalid
	}
	var raw string
	err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object('logical_server_id',logical_server_id,'campaign_id',campaign_id,'pool_hp',pool_hp,'pool_hurt',pool_hurt,'open_day',open_day,'settled_open_day',settled_open_day) ORDER BY logical_server_id),'[]'::jsonb)::text FROM (SELECT * FROM illusion_occurrences ORDER BY logical_server_id LIMIT $1) occurrence`, limit).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var occurrences []d.Occurrence
	if err = json.Unmarshal([]byte(raw), &occurrences); err != nil {
		return nil, err
	}
	return occurrences, nil
}

// InsertAttemptTx replaces the player's abandoned open attempt: a new start
// supersedes it and it can no longer receive a result.
func (Store) InsertAttemptTx(ctx context.Context, t tx.Tx, attempt d.Attempt) error {
	if err := attempt.Validate(); err != nil {
		return err
	}
	if _, err := t.Exec(ctx, `DELETE FROM illusion_attempts WHERE player_id=$1 AND NOT resolved`, attempt.PlayerID); err != nil {
		return err
	}
	_, err := t.Exec(ctx, `INSERT INTO illusion_attempts(attempt_id,player_id,logical_server_id,open_day,campaign_id,room_id,formation,frozen_at,resolved,damage)VALUES($1,$2,$3,$4,$5,NULLIF($6,0),$7,$8,$9,$10)`, attempt.ID, attempt.PlayerID, attempt.LogicalServerID, attempt.OpenDay, attempt.CampaignID, attempt.RoomID, attempt.Formation, attempt.FrozenAt, attempt.Resolved, attempt.Damage)
	return err
}

func (Store) FindAttemptTx(ctx context.Context, q tx.Queryer, playerID identity.PlayerID, serverID, openDay, campaignID int64) (d.Attempt, bool, error) {
	var attempt d.Attempt
	err := q.QueryRow(ctx, `SELECT attempt_id,player_id,logical_server_id,open_day,campaign_id,COALESCE(room_id,0),formation,frozen_at,resolved,damage FROM illusion_attempts WHERE player_id=$1 AND logical_server_id=$2 AND open_day=$3 AND campaign_id=$4 ORDER BY resolved,attempt_sequence DESC LIMIT 1`, int64(playerID), serverID, openDay, campaignID).Scan(&attempt.ID, &attempt.PlayerID, &attempt.LogicalServerID, &attempt.OpenDay, &attempt.CampaignID, &attempt.RoomID, &attempt.Formation, &attempt.FrozenAt, &attempt.Resolved, &attempt.Damage)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return d.Attempt{}, false, nil
	}
	return attempt, err == nil, err
}

// FindLatestAttemptTx returns the player's open attempt first, otherwise the
// newest resolved one, so a late result can still credit its frozen occurrence.
func (Store) FindLatestAttemptTx(ctx context.Context, q tx.Queryer, playerID identity.PlayerID) (d.Attempt, bool, error) {
	var attempt d.Attempt
	err := q.QueryRow(ctx, `SELECT attempt_id,player_id,logical_server_id,open_day,campaign_id,COALESCE(room_id,0),formation,frozen_at,resolved,damage FROM illusion_attempts WHERE player_id=$1 ORDER BY resolved,attempt_sequence DESC LIMIT 1`, int64(playerID)).Scan(&attempt.ID, &attempt.PlayerID, &attempt.LogicalServerID, &attempt.OpenDay, &attempt.CampaignID, &attempt.RoomID, &attempt.Formation, &attempt.FrozenAt, &attempt.Resolved, &attempt.Damage)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return d.Attempt{}, false, nil
	}
	return attempt, err == nil, err
}

func (Store) SaveAttemptTx(ctx context.Context, t tx.Tx, attempt d.Attempt) error {
	tag, err := t.Exec(ctx, `UPDATE illusion_attempts SET resolved=$2,damage=$3 WHERE attempt_id=$1`, attempt.ID, attempt.Resolved, attempt.Damage)
	if err == nil && tag.RowsAffected() != 1 {
		return d.ErrUnavailable
	}
	return err
}

func (Store) InsertReportTx(ctx context.Context, t tx.Tx, reportID string, serverID, openDay, campaignID int64, content string, at time.Time) error {
	_, err := t.Exec(ctx, `INSERT INTO illusion_reports(report_id,logical_server_id,open_day,campaign_id,content,created_at,expires_at)VALUES($1,$2,$3,$4,$5::jsonb,$6,$6::timestamptz+interval '7 days')`, reportID, serverID, openDay, campaignID, content, at)
	return err
}

func (Store) ReadReportTx(ctx context.Context, q tx.Queryer, reportID string, at time.Time) (string, bool, error) {
	var content string
	err := q.QueryRow(ctx, `SELECT content::text FROM illusion_reports WHERE report_id=$1 AND expires_at>$2`, reportID, at).Scan(&content)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return "", false, nil
	}
	return content, err == nil, err
}

// SettleMemberTx inserts the member's settlement marker once; false means the
// member was already settled for this occurrence.
func (Store) SettleMemberTx(ctx context.Context, t tx.Tx, serverID, openDay int64, playerID identity.PlayerID, at time.Time) (bool, error) {
	tag, err := t.Exec(ctx, `INSERT INTO illusion_settlements(logical_server_id,open_day,player_id,settled_at)VALUES($1,$2,$3,$4) ON CONFLICT(logical_server_id,open_day,player_id)DO NOTHING`, serverID, openDay, int64(playerID), at)
	return tag.RowsAffected() == 1, err
}

func readOccurrence(row tx.Row) (d.Occurrence, bool, error) {
	var occurrence d.Occurrence
	err := row.Scan(&occurrence.LogicalServerID, &occurrence.CampaignID, &occurrence.PoolHP, &occurrence.PoolHurt, &occurrence.OpenDay, &occurrence.SettledOpenDay)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return d.Occurrence{}, false, nil
	}
	return occurrence, err == nil, err
}

func readPlayer(row tx.Row) (d.Player, bool, error) {
	var player d.Player
	err := row.Scan(&player.PlayerID, &player.Day, &player.Chances, &player.Bought, &player.BestHit, &player.BestTime)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return d.Player{}, false, nil
	}
	return player, err == nil, err
}
