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
	if _, err := t.Exec(ctx, `INSERT INTO worldboss_occurrences(logical_server_id,generation,current_boss,courage,courage_day,updated_at)VALUES($1,1,$2,0,0,$3) ON CONFLICT(logical_server_id)DO NOTHING`, serverID, d.FirstBossID, at); err != nil {
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

func (Store) ReadPlayerTx(ctx context.Context, q tx.Queryer, playerID identity.PlayerID) (d.Player, bool, error) {
	return readPlayer(q.QueryRow(ctx, `SELECT player_id,day,attempts,bought,swept_day,best_hit,best_hit_at FROM worldboss_players WHERE player_id=$1`, int64(playerID)))
}

func (Store) LockPlayerTx(ctx context.Context, t tx.Tx, playerID identity.PlayerID, at time.Time) (d.Player, error) {
	if _, err := t.Exec(ctx, `INSERT INTO worldboss_players(player_id,day,attempts,bought,swept_day,best_hit,best_hit_at,updated_at)VALUES($1,0,$2,0,0,0,0,$3) ON CONFLICT(player_id)DO NOTHING`, int64(playerID), d.AttemptsPerDay, at); err != nil {
		return d.Player{}, err
	}
	player, _, err := readPlayer(t.QueryRow(ctx, `SELECT player_id,day,attempts,bought,swept_day,best_hit,best_hit_at FROM worldboss_players WHERE player_id=$1 FOR UPDATE`, int64(playerID)))
	return player, err
}

func (Store) SavePlayerTx(ctx context.Context, t tx.Tx, player d.Player, at time.Time) error {
	if err := player.Validate(); err != nil {
		return err
	}
	tag, err := t.Exec(ctx, `UPDATE worldboss_players SET day=$2,attempts=$3,bought=$4,swept_day=$5,best_hit=$6,best_hit_at=$7,updated_at=$8 WHERE player_id=$1`, player.PlayerID, player.Day, player.Attempts, player.Bought, player.SweptDay, player.BestHit, player.BestHitAt, at)
	if err == nil && tag.RowsAffected() != 1 {
		return d.ErrUnavailable
	}
	return err
}

func (Store) LockTotalTx(ctx context.Context, t tx.Tx, serverID, generation int64, playerID identity.PlayerID, at time.Time) (d.Total, error) {
	if _, err := t.Exec(ctx, `INSERT INTO worldboss_player_totals(logical_server_id,generation,player_id,hurt,first_hurt_at,updated_at)VALUES($1,$2,$3,0,0,$4) ON CONFLICT(logical_server_id,generation,player_id)DO NOTHING`, serverID, generation, int64(playerID), at); err != nil {
		return d.Total{}, err
	}
	return readTotal(t.QueryRow(ctx, `SELECT logical_server_id,generation,player_id,hurt,first_hurt_at FROM worldboss_player_totals WHERE logical_server_id=$1 AND generation=$2 AND player_id=$3 FOR UPDATE`, serverID, generation, int64(playerID)))
}

func (Store) SaveTotalTx(ctx context.Context, t tx.Tx, total d.Total, at time.Time) error {
	tag, err := t.Exec(ctx, `UPDATE worldboss_player_totals SET hurt=$4,first_hurt_at=$5,updated_at=$6 WHERE logical_server_id=$1 AND generation=$2 AND player_id=$3`, total.LogicalServerID, total.Generation, total.PlayerID, total.Hurt, total.FirstHurtAt, at)
	if err == nil && tag.RowsAffected() != 1 {
		return d.ErrUnavailable
	}
	return err
}

func (Store) ReadRankTx(ctx context.Context, q tx.Queryer, serverID, generation int64, limit int64) ([]d.RankEntry, error) {
	if limit < 1 || limit > 1000 {
		return nil, d.ErrInvalid
	}
	var raw string
	err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object('player_id',player_id,'hurt',hurt,'first_hurt_at',first_hurt_at) ORDER BY hurt DESC,first_hurt_at,player_id),'[]'::jsonb)::text FROM (SELECT player_id,hurt,first_hurt_at FROM worldboss_player_totals WHERE logical_server_id=$1 AND generation=$2 ORDER BY hurt DESC,first_hurt_at,player_id LIMIT $3) ranked`, serverID, generation, limit).Scan(&raw)
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

func (Store) InsertAttemptTx(ctx context.Context, t tx.Tx, attempt d.Attempt) error {
	if err := attempt.Validate(); err != nil {
		return err
	}
	_, err := t.Exec(ctx, `INSERT INTO worldboss_attempts(attempt_id,player_id,logical_server_id,generation,campaign_id,formation,frozen_at,resolved)VALUES($1,$2,$3,$4,$5,$6,$7,$8)`, attempt.ID, attempt.PlayerID, attempt.LogicalServerID, attempt.Generation, attempt.CampaignID, attempt.Formation, attempt.FrozenAt, attempt.Resolved)
	return err
}

func (Store) LockAttemptTx(ctx context.Context, t tx.Tx, attemptID string) (d.Attempt, bool, error) {
	var attempt d.Attempt
	err := t.QueryRow(ctx, `SELECT attempt_id,player_id,logical_server_id,generation,campaign_id,formation,frozen_at,resolved FROM worldboss_attempts WHERE attempt_id=$1 FOR UPDATE`, attemptID).Scan(&attempt.ID, &attempt.PlayerID, &attempt.LogicalServerID, &attempt.Generation, &attempt.CampaignID, &attempt.Formation, &attempt.FrozenAt, &attempt.Resolved)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return d.Attempt{}, false, nil
	}
	return attempt, err == nil, err
}

func (Store) SaveAttemptTx(ctx context.Context, t tx.Tx, attempt d.Attempt) error {
	tag, err := t.Exec(ctx, `UPDATE worldboss_attempts SET resolved=$2 WHERE attempt_id=$1`, attempt.ID, attempt.Resolved)
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
	err := row.Scan(&player.PlayerID, &player.Day, &player.Attempts, &player.Bought, &player.SweptDay, &player.BestHit, &player.BestHitAt)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return d.Player{}, false, nil
	}
	return player, err == nil, err
}

func readTotal(row tx.Row) (d.Total, error) {
	var total d.Total
	err := row.Scan(&total.LogicalServerID, &total.Generation, &total.PlayerID, &total.Hurt, &total.FirstHurtAt)
	return total, err
}
