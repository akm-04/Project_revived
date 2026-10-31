// Package worldbossstore owns the worldboss tables; occurrence rows lock at
// shared rank 606 and player rows at 605 (F14).
package worldbossstore

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/worldboss"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{}

func (Store) ReadOccurrenceTx(ctx context.Context, q tx.Queryer, serverID int64) (d.Occurrence, bool, error) {
	return readOccurrence(q.QueryRow(ctx, `SELECT logical_server_id,generation,current_boss,courage,courage_day FROM worldboss_occurrences WHERE logical_server_id=$1`, serverID))
}

func (Store) LockOccurrenceTx(ctx context.Context, t tx.Tx, serverID int64, at time.Time) (d.Occurrence, error) {
	if _, err := t.Exec(ctx, `INSERT INTO worldboss_occurrences(logical_server_id,generation,current_boss,courage,courage_day,updated_at)VALUES($1,1,$2,0,$3,$4) ON CONFLICT(logical_server_id)DO NOTHING`, serverID, d.FirstBossID, d.CourageDayFor(at), at); err != nil {
		return d.Occurrence{}, err
	}
	occurrence, _, err := readOccurrence(t.QueryRow(ctx, `SELECT logical_server_id,generation,current_boss,courage,courage_day FROM worldboss_occurrences WHERE logical_server_id=$1 FOR UPDATE`, serverID))
	return occurrence, err
}

func (Store) SaveOccurrenceTx(ctx context.Context, t tx.Tx, occurrence d.Occurrence, at time.Time) error {
	if err := occurrence.Validate(); err != nil {
		return err
	}
	tag, err := t.Exec(ctx, `UPDATE worldboss_occurrences SET generation=$2,current_boss=$3,courage=$4,courage_day=$5,updated_at=$6 WHERE logical_server_id=$1`, occurrence.LogicalServerID, occurrence.Generation, occurrence.CurrentBoss, occurrence.Courage, occurrence.CourageDay, at)
	if err == nil && tag.RowsAffected() != 1 {
		return d.ErrUnavailable
	}
	return err
}

func (Store) ListOccurrencesTx(ctx context.Context, q tx.Queryer, limit int64) ([]d.Occurrence, error) {
	if limit < 1 || limit > 1000 {
		return nil, d.ErrInvalid
	}
	var raw string
	err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object('logical_server_id',logical_server_id,'generation',generation,'current_boss',current_boss,'courage',courage,'courage_day',courage_day) ORDER BY logical_server_id),'[]'::jsonb)::text FROM (SELECT logical_server_id,generation,current_boss,courage,courage_day FROM worldboss_occurrences ORDER BY logical_server_id LIMIT $1) listed`, limit).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var rows []struct {
		ServerID    int64 `json:"logical_server_id"`
		Generation  int64 `json:"generation"`
		CurrentBoss int64 `json:"current_boss"`
		Courage     int64 `json:"courage"`
		CourageDay  int64 `json:"courage_day"`
	}
	if err = json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make([]d.Occurrence, 0, len(rows))
	for _, row := range rows {
		out = append(out, d.Occurrence{LogicalServerID: row.ServerID, Generation: row.Generation, CurrentBoss: row.CurrentBoss, Courage: row.Courage, CourageDay: row.CourageDay})
	}
	return out, nil
}

func (Store) ReadPlayerTx(ctx context.Context, q tx.Queryer, playerID identity.PlayerID) (d.Player, bool, error) {
	return readPlayer(q.QueryRow(ctx, `SELECT player_id,day,attempts,bought,swept_day,best_hit,best_hit_at,challenged_day FROM worldboss_players WHERE player_id=$1`, int64(playerID)))
}

func (Store) LockPlayerTx(ctx context.Context, t tx.Tx, serverID int64, playerID identity.PlayerID, at time.Time) (d.Player, error) {
	if _, err := t.Exec(ctx, `INSERT INTO worldboss_players(player_id,logical_server_id,challenged_day,day,attempts,bought,swept_day,best_hit,best_hit_at,updated_at)VALUES($1,$2,0,0,$3,0,0,0,0,$4) ON CONFLICT(player_id)DO NOTHING`, int64(playerID), serverID, d.AttemptsPerDay, at); err != nil {
		return d.Player{}, err
	}
	player, _, err := readPlayer(t.QueryRow(ctx, `SELECT player_id,day,attempts,bought,swept_day,best_hit,best_hit_at,challenged_day FROM worldboss_players WHERE player_id=$1 FOR UPDATE`, int64(playerID)))
	return player, err
}

func (Store) SavePlayerTx(ctx context.Context, t tx.Tx, player d.Player, at time.Time) error {
	if err := player.Validate(); err != nil {
		return err
	}
	tag, err := t.Exec(ctx, `UPDATE worldboss_players SET day=$2,attempts=$3,bought=$4,swept_day=$5,best_hit=$6,best_hit_at=$7,challenged_day=$8,updated_at=$9 WHERE player_id=$1`, player.PlayerID, player.Day, player.Attempts, player.Bought, player.SweptDay, player.BestHit, player.BestHitAt, player.ChallengedDay, at)
	if err == nil && tag.RowsAffected() != 1 {
		return d.ErrUnavailable
	}
	return err
}

func (Store) ReadTotalTx(ctx context.Context, q tx.Queryer, board d.Board, playerID identity.PlayerID) (d.Total, bool, error) {
	total, err := readTotal(q.QueryRow(ctx, `SELECT player_id,hurt,first_hurt_at FROM worldboss_player_totals WHERE logical_server_id=$1 AND generation=$2 AND boss_id=$3 AND player_id=$4`, board.LogicalServerID, board.Generation, board.BossID, int64(playerID)), board)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return d.Total{}, false, nil
	}
	return total, err == nil, err
}

func (Store) LockTotalTx(ctx context.Context, t tx.Tx, board d.Board, playerID identity.PlayerID, at time.Time) (d.Total, error) {
	if _, err := t.Exec(ctx, `INSERT INTO worldboss_player_totals(logical_server_id,generation,boss_id,player_id,hurt,first_hurt_at,updated_at)VALUES($1,$2,$3,$4,0,0,$5) ON CONFLICT(logical_server_id,generation,boss_id,player_id)DO NOTHING`, board.LogicalServerID, board.Generation, board.BossID, int64(playerID), at); err != nil {
		return d.Total{}, err
	}
	return readTotal(t.QueryRow(ctx, `SELECT player_id,hurt,first_hurt_at FROM worldboss_player_totals WHERE logical_server_id=$1 AND generation=$2 AND boss_id=$3 AND player_id=$4 FOR UPDATE`, board.LogicalServerID, board.Generation, board.BossID, int64(playerID)), board)
}

func (Store) SaveTotalTx(ctx context.Context, t tx.Tx, total d.Total, at time.Time) error {
	tag, err := t.Exec(ctx, `UPDATE worldboss_player_totals SET hurt=$5,first_hurt_at=$6,updated_at=$7 WHERE logical_server_id=$1 AND generation=$2 AND boss_id=$3 AND player_id=$4`, total.Board.LogicalServerID, total.Board.Generation, total.Board.BossID, total.PlayerID, total.Hurt, total.FirstHurtAt, at)
	if err == nil && tag.RowsAffected() != 1 {
		return d.ErrUnavailable
	}
	return err
}

func (Store) ReadRankTx(ctx context.Context, q tx.Queryer, board d.Board, limit int64) ([]d.RankEntry, error) {
	if limit < 1 || limit > 100000 {
		return nil, d.ErrInvalid
	}
	var raw string
	err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object('player_id',player_id,'hurt',hurt,'first_hurt_at',first_hurt_at) ORDER BY hurt DESC,first_hurt_at,player_id),'[]'::jsonb)::text FROM (SELECT player_id,hurt,first_hurt_at FROM worldboss_player_totals WHERE logical_server_id=$1 AND generation=$2 AND boss_id=$3 ORDER BY hurt DESC,first_hurt_at,player_id LIMIT $4) ranked`, board.LogicalServerID, board.Generation, board.BossID, limit).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var rows []struct {
		PlayerID    int64 `json:"player_id"`
		Hurt        int64 `json:"hurt"`
		FirstHurtAt int64 `json:"first_hurt_at"`
	}
	if err = json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make([]d.RankEntry, 0, len(rows))
	for _, row := range rows {
		out = append(out, d.RankEntry{PlayerID: row.PlayerID, TotalHurt: row.Hurt, FirstHurtAt: row.FirstHurtAt})
	}
	return out, nil
}

// InsertAttemptTx replaces the player's abandoned open attempt: Combat already
// superseded it, so it can no longer receive a result.
func (Store) InsertAttemptTx(ctx context.Context, t tx.Tx, attempt d.Attempt) error {
	if err := attempt.Validate(); err != nil {
		return err
	}
	if _, err := t.Exec(ctx, `DELETE FROM worldboss_attempts WHERE player_id=$1 AND NOT resolved`, attempt.PlayerID); err != nil {
		return err
	}
	_, err := t.Exec(ctx, `INSERT INTO worldboss_attempts(attempt_id,player_id,logical_server_id,generation,campaign_id,formation,frozen_at,resolved,damage)VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9)`, attempt.ID, attempt.PlayerID, attempt.LogicalServerID, attempt.Generation, attempt.CampaignID, attempt.Formation, attempt.FrozenAt, attempt.Resolved, attempt.Damage)
	return err
}

// FindAttemptTx prefers the open attempt, then the newest resolved one that a
// repeated result would be a duplicate of.
func (Store) FindAttemptTx(ctx context.Context, q tx.Queryer, playerID identity.PlayerID, serverID, campaignID int64) (d.Attempt, bool, error) {
	var attempt d.Attempt
	err := q.QueryRow(ctx, `SELECT attempt_id,player_id,logical_server_id,generation,campaign_id,formation,frozen_at,resolved,damage FROM worldboss_attempts WHERE player_id=$1 AND logical_server_id=$2 AND campaign_id=$3 ORDER BY resolved,attempt_sequence DESC LIMIT 1`, int64(playerID), serverID, campaignID).Scan(&attempt.ID, &attempt.PlayerID, &attempt.LogicalServerID, &attempt.Generation, &attempt.CampaignID, &attempt.Formation, &attempt.FrozenAt, &attempt.Resolved, &attempt.Damage)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return d.Attempt{}, false, nil
	}
	return attempt, err == nil, err
}

func (Store) CountChallengersTx(ctx context.Context, q tx.Queryer, serverID, day int64) (int64, error) {
	var count int64
	err := q.QueryRow(ctx, `SELECT count(*) FROM worldboss_players WHERE logical_server_id=$1 AND challenged_day=$2`, serverID, day).Scan(&count)
	return count, err
}

func (Store) SaveAttemptTx(ctx context.Context, t tx.Tx, attempt d.Attempt) error {
	tag, err := t.Exec(ctx, `UPDATE worldboss_attempts SET resolved=$2,damage=$3 WHERE attempt_id=$1`, attempt.ID, attempt.Resolved, attempt.Damage)
	if err == nil && tag.RowsAffected() != 1 {
		return d.ErrUnavailable
	}
	return err
}

func readOccurrence(row tx.Row) (d.Occurrence, bool, error) {
	var occurrence d.Occurrence
	err := row.Scan(&occurrence.LogicalServerID, &occurrence.Generation, &occurrence.CurrentBoss, &occurrence.Courage, &occurrence.CourageDay)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return d.Occurrence{}, false, nil
	}
	return occurrence, err == nil, err
}

func readPlayer(row tx.Row) (d.Player, bool, error) {
	var player d.Player
	err := row.Scan(&player.PlayerID, &player.Day, &player.Attempts, &player.Bought, &player.SweptDay, &player.BestHit, &player.BestHitAt, &player.ChallengedDay)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return d.Player{}, false, nil
	}
	return player, err == nil, err
}

func readTotal(row tx.Row, board d.Board) (d.Total, error) {
	total := d.Total{Board: board}
	err := row.Scan(&total.PlayerID, &total.Hurt, &total.FirstHurtAt)
	return total, err
}
