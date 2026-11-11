package dailyresetstore

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"

	"gxb.local/backend/v2/internal/application/dailyreset"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Store is the per-player game-day marker (migration 00158).
type Store struct{ Queryer tx.Queryer }

// Advance is one atomic conditional statement: the row is created or moved to day only when it lags behind, so
// exactly one concurrent reply sees the transition. An unchanged row returns no row (pgx.ErrNoRows).
func (store Store) Advance(ctx context.Context, player identity.PlayerID, day int64) (bool, error) {
	if store.Queryer == nil || !player.Valid() {
		return false, errors.New("daily reset marker: invalid input")
	}
	var stored int64
	err := store.Queryer.QueryRow(ctx, `INSERT INTO player_daily_reset_marks(player_id,last_day,updated_at)VALUES($1,$2,clock_timestamp()) ON CONFLICT(player_id) DO UPDATE SET last_day=EXCLUDED.last_day,updated_at=EXCLUDED.updated_at WHERE player_daily_reset_marks.last_day<EXCLUDED.last_day RETURNING last_day`, int64(player), day).Scan(&stored)
	if errors.Is(err, pgx.ErrNoRows) {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	return stored == day, nil
}

func (store Store) Set(ctx context.Context, player identity.PlayerID, day int64) error {
	if store.Queryer == nil || !player.Valid() {
		return errors.New("daily reset marker: invalid input")
	}
	var stored int64
	return store.Queryer.QueryRow(ctx, `INSERT INTO player_daily_reset_marks(player_id,last_day,updated_at)VALUES($1,$2,clock_timestamp()) ON CONFLICT(player_id) DO UPDATE SET last_day=EXCLUDED.last_day,updated_at=EXCLUDED.updated_at RETURNING last_day`, int64(player), day).Scan(&stored)
}

var _ dailyreset.MarkerStore = Store{}
