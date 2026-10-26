// Package marchstore owns only march_players, under the caller's rank-605 lock.
package marchstore

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/march"
	"gxb.local/backend/v2/internal/foundation/tx"
	"strings"
	"time"
)

type Store struct{}

func read(row tx.Row) (d.Run, bool, error) {
	var raw string
	var r d.Run
	if err := row.Scan(&raw); errors.Is(err, kernelstore.ErrNoRows) {
		return r, false, nil
	} else if err != nil {
		return r, false, err
	}
	decoder := json.NewDecoder(strings.NewReader(raw))
	decoder.UseNumber()
	err := decoder.Decode(&r)
	return r, true, err
}
func (Store) ReadTx(c context.Context, q tx.Queryer, p identity.PlayerID) (d.Run, bool, error) {
	return read(q.QueryRow(c, `SELECT payload::text FROM march_players WHERE player_id=$1`, int64(p)))
}
func (Store) LockTx(c context.Context, t tx.Tx, p identity.PlayerID, at time.Time) (d.Run, error) {
	if _, err := t.Exec(c, `INSERT INTO march_players(player_id,payload,updated_at)VALUES($1,'{}',$2) ON CONFLICT(player_id) DO NOTHING`, int64(p), at); err != nil {
		return d.Run{}, err
	}
	r, _, err := read(t.QueryRow(c, `SELECT payload::text FROM march_players WHERE player_id=$1 FOR UPDATE`, int64(p)))
	return r, err
}
func (Store) SaveTx(c context.Context, t tx.Tx, p identity.PlayerID, r d.Run, at time.Time) error {
	raw, err := json.Marshal(r)
	if err != nil {
		return err
	}
	tag, err := t.Exec(c, `UPDATE march_players SET payload=$2::jsonb,updated_at=$3 WHERE player_id=$1`, int64(p), string(raw), at)
	if err == nil && tag.RowsAffected() != 1 {
		return d.ErrUnavailable
	}
	return err
}
