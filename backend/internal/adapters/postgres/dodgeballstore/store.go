package dodgeballstore

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/domain/dodgeball"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type Store struct{}

func read(row tx.Row) (dodgeball.State, bool, error) {
	var raw string
	var state dodgeball.State
	err := row.Scan(&raw)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return state, false, nil
	}
	if err != nil {
		return state, false, err
	}
	err = json.Unmarshal([]byte(raw), &state)
	return state, true, err
}
func (Store) ReadTx(ctx context.Context, query tx.Queryer, player identity.PlayerID) (dodgeball.State, bool, error) {
	return read(query.QueryRow(ctx, `SELECT payload::text FROM dodgeball_players WHERE player_id=$1`, int64(player)))
}
func (Store) LockTx(ctx context.Context, transaction tx.Tx, player identity.PlayerID, at time.Time) (dodgeball.State, error) {
	if _, err := transaction.Exec(ctx, `INSERT INTO dodgeball_players(player_id,payload,updated_at)VALUES($1,'{}',$2) ON CONFLICT(player_id)DO NOTHING`, int64(player), at); err != nil {
		return dodgeball.State{}, err
	}
	state, _, err := read(transaction.QueryRow(ctx, `SELECT payload::text FROM dodgeball_players WHERE player_id=$1 FOR UPDATE`, int64(player)))
	return state, err
}
func (Store) SaveTx(ctx context.Context, transaction tx.Tx, player identity.PlayerID, state dodgeball.State, at time.Time) error {
	raw, err := json.Marshal(state)
	if err != nil {
		return err
	}
	result, err := transaction.Exec(ctx, `UPDATE dodgeball_players SET payload=$2::jsonb,updated_at=$3 WHERE player_id=$1`, int64(player), string(raw), at)
	if err == nil && result.RowsAffected() != 1 {
		return dodgeball.ErrUnavailable
	}
	return err
}
