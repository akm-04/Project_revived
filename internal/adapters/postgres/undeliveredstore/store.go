// Package undeliveredstore is the PostgreSQL adapter for the R6 undelivered-reply
// cache (migration 00166). Its writes never share a gameplay transaction.
package undeliveredstore

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"gxb.local/backend/v2/internal/foundation/undelivered"
)

type Store struct{ Pool *pgxpool.Pool }

// Mark stores the reply only while the request's claim still holds. A later
// state request's take replaces the claim, so a late mark changes no row.
func (s Store) Mark(ctx context.Context, mark undelivered.Mark) error {
	if s.Pool == nil {
		return errors.New("undeliveredstore: nil pool")
	}
	if mark.PlayerID <= 0 || mark.Claim <= 0 || mark.SessionID == "" || mark.MID <= 0 || len(mark.Reply) == 0 || mark.MarkedAt.IsZero() {
		return errors.New("undeliveredstore: incomplete mark")
	}
	tag, err := s.Pool.Exec(ctx, `UPDATE player_undelivered_replies SET session_id=$2::uuid,mid=$3,params_fingerprint=$4,reply=$5,marked_at=$6 WHERE player_id=$1 AND claim=$7`,
		mark.PlayerID, mark.SessionID, mark.MID, mark.Fingerprint[:], mark.Reply, mark.MarkedAt.UTC(), mark.Claim)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return undelivered.ErrSuperseded
	}
	return nil
}

// takeMark locks the player's row, returns its displaced mark and takes the next
// claim in one statement. The count row forces the FOR UPDATE CTE to run first
// while always yielding the one source row the INSERT needs.
const takeMark = `
WITH previous AS MATERIALIZED (
    SELECT player_id, session_id, mid, params_fingerprint, reply, marked_at
      FROM player_undelivered_replies
     WHERE player_id = $1
       FOR UPDATE
), taken AS (
    INSERT INTO player_undelivered_replies (player_id)
    SELECT $1 FROM (SELECT count(*) FROM previous) AS present
    ON CONFLICT (player_id) DO UPDATE
       SET claim = EXCLUDED.claim,
           session_id = NULL,
           mid = NULL,
           params_fingerprint = NULL,
           reply = NULL,
           marked_at = NULL
    RETURNING claim
)
SELECT taken.claim, previous.session_id::text, previous.mid, previous.params_fingerprint, previous.reply, previous.marked_at
  FROM taken
  LEFT JOIN previous ON previous.player_id = $1`

// TakeMark locks the player's row, takes the next claim and returns the mark it
// displaced. Concurrent takes serialise on the row, so an old mark reaches at
// most one caller.
func (s Store) TakeMark(ctx context.Context, playerID int64) (undelivered.Take, error) {
	if s.Pool == nil {
		return undelivered.Take{}, errors.New("undeliveredstore: nil pool")
	}
	if playerID <= 0 {
		return undelivered.Take{}, errors.New("undeliveredstore: invalid player")
	}
	var take undelivered.Take
	var sessionID *string
	var mid *int64
	var fingerprint, reply []byte
	var markedAt *time.Time
	if err := s.Pool.QueryRow(ctx, takeMark, playerID).
		Scan(&take.Claim, &sessionID, &mid, &fingerprint, &reply, &markedAt); err != nil {
		return undelivered.Take{}, err
	}
	take.Mark.PlayerID = playerID
	if reply == nil {
		return take, nil
	}
	if sessionID == nil || mid == nil || markedAt == nil || len(fingerprint) != len(take.Mark.Fingerprint) {
		return undelivered.Take{}, fmt.Errorf("undeliveredstore: incomplete stored mark")
	}
	take.HasMark = true
	take.Mark.SessionID = *sessionID
	take.Mark.MID = *mid
	take.Mark.MarkedAt = *markedAt
	copy(take.Mark.Fingerprint[:], fingerprint)
	take.Mark.Reply = reply
	return take, nil
}
