// Package undeliveredstore is the PostgreSQL adapter for the R6 undelivered-reply
// cache (migration 00166). Its writes never share a gameplay transaction.
package undeliveredstore

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"gxb.local/backend/v2/internal/foundation/undelivered"
)

type Store struct{ Pool *pgxpool.Pool }

func (s Store) Mark(ctx context.Context, mark undelivered.Mark) error {
	if s.Pool == nil {
		return errors.New("undeliveredstore: nil pool")
	}
	if mark.PlayerID <= 0 || mark.SessionID == "" || mark.MID <= 0 || len(mark.Reply) == 0 || mark.MarkedAt.IsZero() {
		return errors.New("undeliveredstore: incomplete mark")
	}
	_, err := s.Pool.Exec(ctx, `INSERT INTO player_undelivered_replies(player_id,session_id,mid,params_fingerprint,reply,marked_at) VALUES($1,$2::uuid,$3,$4,$5,$6) ON CONFLICT(player_id) DO UPDATE SET session_id=EXCLUDED.session_id,mid=EXCLUDED.mid,params_fingerprint=EXCLUDED.params_fingerprint,reply=EXCLUDED.reply,marked_at=EXCLUDED.marked_at`,
		mark.PlayerID, mark.SessionID, mark.MID, mark.Fingerprint[:], mark.Reply, mark.MarkedAt.UTC())
	return err
}

// TakeMark deletes and returns the player's mark in one statement, so two
// concurrent identical resends hand it to exactly one caller.
func (s Store) TakeMark(ctx context.Context, playerID int64) (undelivered.Mark, bool, error) {
	if s.Pool == nil {
		return undelivered.Mark{}, false, errors.New("undeliveredstore: nil pool")
	}
	if playerID <= 0 {
		return undelivered.Mark{}, false, errors.New("undeliveredstore: invalid player")
	}
	var mark undelivered.Mark
	var fingerprint []byte
	err := s.Pool.QueryRow(ctx, `DELETE FROM player_undelivered_replies WHERE player_id=$1 RETURNING session_id::text,mid,params_fingerprint,reply,marked_at`, playerID).
		Scan(&mark.SessionID, &mark.MID, &fingerprint, &mark.Reply, &mark.MarkedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return undelivered.Mark{}, false, nil
	}
	if err != nil {
		return undelivered.Mark{}, false, err
	}
	if len(fingerprint) != len(mark.Fingerprint) {
		return undelivered.Mark{}, false, fmt.Errorf("undeliveredstore: stored fingerprint length %d", len(fingerprint))
	}
	copy(mark.Fingerprint[:], fingerprint)
	mark.PlayerID = playerID
	return mark, true, nil
}
