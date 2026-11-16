// Package illusionstore owns the illusion tables; the player row locks at rank
// 605 and the one occurrence row of a logical server at 606.
package illusionstore

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct {
	Combat Combat
}

func (Store) ReadOccurrenceTx(ctx context.Context, q tx.Queryer, serverID int64) (d.Occurrence, bool, error) {
	return readOccurrence(q.QueryRow(ctx, `SELECT logical_server_id,campaign_id,open_day,settled_open_day FROM illusion_occurrences WHERE logical_server_id=$1`, serverID))
}

func (Store) LockOccurrenceTx(ctx context.Context, t tx.Tx, serverID int64, at time.Time) (d.Occurrence, error) {
	if _, err := t.Exec(ctx, `INSERT INTO illusion_occurrences(logical_server_id,campaign_id,open_day,settled_open_day,updated_at)VALUES($1,$2,$3,0,$4) ON CONFLICT(logical_server_id)DO NOTHING`, serverID, d.FirstCampaignID, modes.Day(at), at); err != nil {
		return d.Occurrence{}, err
	}
	occurrence, _, err := readOccurrence(t.QueryRow(ctx, `SELECT logical_server_id,campaign_id,open_day,settled_open_day FROM illusion_occurrences WHERE logical_server_id=$1 FOR UPDATE`, serverID))
	return occurrence, err
}

func (Store) SaveOccurrenceTx(ctx context.Context, t tx.Tx, occurrence d.Occurrence, at time.Time) error {
	if err := occurrence.Validate(); err != nil {
		return err
	}
	tag, err := t.Exec(ctx, `UPDATE illusion_occurrences SET campaign_id=$2,open_day=$3,settled_open_day=$4,updated_at=$5 WHERE logical_server_id=$1`, occurrence.LogicalServerID, occurrence.CampaignID, occurrence.OpenDay, occurrence.SettledOpenDay, at)
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
	err := q.QueryRow(ctx, `SELECT player_id,hurt,cost_time,killed FROM illusion_occurrence_results WHERE logical_server_id=$1 AND open_day=$2 AND campaign_id=$3 AND player_id=$4`, serverID, openDay, campaignID, int64(playerID)).Scan(&result.PlayerID, &result.Hurt, &result.CostTime, &result.Killed)
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
	err := t.QueryRow(ctx, `SELECT player_id,hurt,cost_time,killed FROM illusion_occurrence_results WHERE logical_server_id=$1 AND open_day=$2 AND player_id=$3 FOR UPDATE`, serverID, openDay, int64(playerID)).Scan(&result.PlayerID, &result.Hurt, &result.CostTime, &result.Killed)
	return result, err
}

func (Store) SaveResultTx(ctx context.Context, t tx.Tx, serverID, openDay, campaignID int64, result d.Result, at time.Time) error {
	tag, err := t.Exec(ctx, `UPDATE illusion_occurrence_results SET hurt=$4,cost_time=$5,campaign_id=$6,updated_at=$7,killed=$8 WHERE logical_server_id=$1 AND open_day=$2 AND player_id=$3`, serverID, openDay, result.PlayerID, result.Hurt, result.CostTime, campaignID, at, result.Killed)
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
	err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object('player_id',player_id,'hurt',hurt,'cost_time',cost_time,'killed',killed) ORDER BY killed DESC,CASE WHEN killed THEN 0 ELSE hurt END DESC,cost_time,CASE WHEN killed THEN hurt ELSE 0 END DESC,player_id),'[]'::jsonb)::text FROM (SELECT player_id,hurt,cost_time,killed FROM illusion_occurrence_results WHERE logical_server_id=$1 AND open_day=$2 ORDER BY killed DESC,CASE WHEN killed THEN 0 ELSE hurt END DESC,cost_time,CASE WHEN killed THEN hurt ELSE 0 END DESC,player_id LIMIT $3) ranked`, serverID, openDay, limit).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var results []d.Result
	if err = json.Unmarshal([]byte(raw), &results); err != nil {
		return nil, err
	}
	return results, nil
}

// RankOfTx returns the player's positional rank on the same ordering
// ReadRankTx publishes, counting better rows instead of reading them all.
func (Store) RankOfTx(ctx context.Context, q tx.Queryer, serverID, openDay int64, playerID identity.PlayerID) (int64, error) {
	var rank int64
	err := q.QueryRow(ctx, `WITH target AS (
		SELECT killed,hurt,cost_time FROM illusion_occurrence_results
		WHERE logical_server_id=$1 AND open_day=$2 AND player_id=$3
	)
	SELECT CASE WHEN NOT EXISTS (SELECT 1 FROM target) THEN 0 ELSE
		1+(SELECT COUNT(*) FROM illusion_occurrence_results r CROSS JOIN target t
		WHERE r.logical_server_id=$1 AND r.open_day=$2
		AND (r.killed>t.killed
		 OR (r.killed=t.killed AND (CASE WHEN r.killed THEN 0 ELSE r.hurt END)>(CASE WHEN t.killed THEN 0 ELSE t.hurt END))
		 OR (r.killed=t.killed AND (CASE WHEN r.killed THEN 0 ELSE r.hurt END)=(CASE WHEN t.killed THEN 0 ELSE t.hurt END) AND r.cost_time<t.cost_time)
		 OR (r.killed=t.killed AND (CASE WHEN r.killed THEN 0 ELSE r.hurt END)=(CASE WHEN t.killed THEN 0 ELSE t.hurt END) AND r.cost_time=t.cost_time AND (CASE WHEN r.killed THEN r.hurt ELSE 0 END)>(CASE WHEN t.killed THEN t.hurt ELSE 0 END))
		 OR (r.killed=t.killed AND (CASE WHEN r.killed THEN 0 ELSE r.hurt END)=(CASE WHEN t.killed THEN 0 ELSE t.hurt END) AND r.cost_time=t.cost_time AND (CASE WHEN r.killed THEN r.hurt ELSE 0 END)=(CASE WHEN t.killed THEN t.hurt ELSE 0 END) AND r.player_id<$3)))
	END`, serverID, openDay, int64(playerID)).Scan(&rank)
	return rank, err
}

// ListOccurrencesTx lists one bounded batch of logical-server occurrences for
// the settlement reconciler.
func (Store) ListOccurrencesTx(ctx context.Context, q tx.Queryer, limit int64) ([]d.Occurrence, error) {
	if limit < 1 || limit > 10000 {
		return nil, d.ErrInvalid
	}
	var raw string
	err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object('logical_server_id',logical_server_id,'campaign_id',campaign_id,'open_day',open_day,'settled_open_day',settled_open_day) ORDER BY logical_server_id),'[]'::jsonb)::text FROM (SELECT * FROM illusion_occurrences ORDER BY open_day,logical_server_id LIMIT $1) occurrence`, limit).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var occurrences []d.Occurrence
	if err = json.Unmarshal([]byte(raw), &occurrences); err != nil {
		return nil, err
	}
	return occurrences, nil
}

// InsertSettlementTx records the damage the RESULT credited to one terminal
// Combat attempt; the transaction is Combat's attest transaction.
func (Store) InsertSettlementTx(ctx context.Context, t tx.Tx, attemptID ids.UUID, playerID identity.PlayerID, damage int64, settledAt time.Time) error {
	if t == nil || attemptID.IsZero() || playerID <= 0 || damage < 0 || damage > d.DamageCap || settledAt.IsZero() {
		return d.ErrInvalid
	}
	_, err := t.Exec(ctx, `INSERT INTO illusion_attempt_settlements(attempt_id,player_id,damage,settled_at)VALUES($1,$2,$3,$4)`, attemptID.String(), int64(playerID), damage, settledAt.UTC())
	return err
}

// ReadSettlementTx answers a duplicate RESULT from the settlement row, not
// from the occurrence that may have advanced since the attempt.
func (Store) ReadSettlementTx(ctx context.Context, q tx.Queryer, attemptID ids.UUID) (int64, bool, error) {
	if q == nil || attemptID.IsZero() {
		return 0, false, d.ErrInvalid
	}
	var damage int64
	err := q.QueryRow(ctx, `SELECT damage FROM illusion_attempt_settlements WHERE attempt_id=$1`, attemptID.String()).Scan(&damage)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return 0, false, nil
	}
	if err != nil {
		return 0, false, err
	}
	if damage < 0 || damage > d.DamageCap {
		return 0, true, fmt.Errorf("illusion: settlement damage %d out of range", damage)
	}
	return damage, true, nil
}

func (Store) InsertReportTx(ctx context.Context, t tx.Tx, reportID string, serverID, openDay, campaignID int64, content string, at time.Time) error {
	_, err := t.Exec(ctx, `INSERT INTO illusion_reports(report_id,logical_server_id,open_day,campaign_id,content,created_at,expires_at)VALUES($1,$2,$3,$4,$5::jsonb,$6,$6::timestamptz+interval '7 days')`, reportID, serverID, openDay, campaignID, content, at)
	return err
}

// ReadReportTx answers only a player of the report's logical server and only
// before the retention window ends.
func (Store) ReadReportTx(ctx context.Context, q tx.Queryer, reportID string, serverID int64, at time.Time) (string, bool, error) {
	var content string
	err := q.QueryRow(ctx, `SELECT content::text FROM illusion_reports WHERE report_id=$1 AND logical_server_id=$2 AND expires_at>$3`, reportID, serverID, at).Scan(&content)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return "", false, nil
	}
	return content, err == nil, err
}

// reportRetention is I9_ILLUSION_POLICY_V1 settlement.reports_retention_days
// before the R8 cap (U4) may shorten it.
const reportRetention = 7 * 24 * time.Hour

// PurgeExpiredReportsTx deletes one bounded batch past retention; only the
// reconciler calls it. The window is min(I9_ILLUSION_POLICY_V1, retention days).
func (Store) PurgeExpiredReportsTx(ctx context.Context, t tx.Tx, at time.Time, retentionDays int, limit int64) (int64, error) {
	if limit < 1 || limit > 10000 {
		return 0, d.ErrInvalid
	}
	window := reportRetention
	if retentionDays > 0 && time.Duration(retentionDays)*24*time.Hour < window {
		window = time.Duration(retentionDays) * 24 * time.Hour
	}
	tag, err := t.Exec(ctx, `DELETE FROM illusion_reports WHERE report_id IN (SELECT report_id FROM illusion_reports WHERE expires_at<=$1 OR created_at<=$2 ORDER BY expires_at,report_id LIMIT $3)`, at, at.Add(-window), limit)
	return tag.RowsAffected(), err
}

// SettleMemberTx inserts the member's settlement marker once; false means the
// member was already settled for this occurrence.
func (Store) SettleMemberTx(ctx context.Context, t tx.Tx, serverID, openDay int64, playerID identity.PlayerID, at time.Time) (bool, error) {
	tag, err := t.Exec(ctx, `INSERT INTO illusion_settlements(logical_server_id,open_day,player_id,settled_at)VALUES($1,$2,$3,$4) ON CONFLICT(logical_server_id,open_day,player_id)DO NOTHING`, serverID, openDay, int64(playerID), at)
	return tag.RowsAffected() == 1, err
}

func readOccurrence(row tx.Row) (d.Occurrence, bool, error) {
	var occurrence d.Occurrence
	err := row.Scan(&occurrence.LogicalServerID, &occurrence.CampaignID, &occurrence.OpenDay, &occurrence.SettledOpenDay)
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
