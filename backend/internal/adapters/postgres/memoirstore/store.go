package memoirstore

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/memoir"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type Store struct{}

func read(row tx.Row) (d.State, bool, error) {
	var raw string
	var version int16
	var r d.State
	if err := row.Scan(&raw, &version); errors.Is(err, kernelstore.ErrNoRows) {
		return r, false, nil
	} else if err != nil {
		return r, false, err
	}
	err := payload.DecodeNumbers("memoir_players", version, []byte(raw), &r)
	return r, true, err
}
func (Store) ReadTx(c context.Context, q tx.Queryer, p identity.PlayerID) (d.State, bool, error) {
	return read(q.QueryRow(c, `SELECT payload::text,payload_version FROM memoir_players WHERE player_id=$1`, int64(p)))
}
func (Store) LockTx(c context.Context, t tx.Tx, p identity.PlayerID, at time.Time) (d.State, error) {
	if _, err := t.Exec(c, `INSERT INTO memoir_players(player_id,payload,updated_at)VALUES($1,'{}',$2) ON CONFLICT(player_id) DO NOTHING`, int64(p), at); err != nil {
		return d.State{}, err
	}
	r, _, err := read(t.QueryRow(c, `SELECT payload::text,payload_version FROM memoir_players WHERE player_id=$1 FOR UPDATE`, int64(p)))
	return r, err
}

// TuningTx reads the singleton operator overlay; found=false keeps the source catalog.
func (Store) TuningTx(c context.Context, q tx.Queryer) (d.Tuning, bool, error) {
	var raw string
	var version int16
	err := q.QueryRow(c, `SELECT payload::text,payload_version FROM memoir_tuning`).Scan(&raw, &version)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return d.Tuning{}, false, nil
	}
	if err != nil {
		return d.Tuning{}, false, err
	}
	var tuning d.Tuning
	err = payload.Decode("memoir_tuning", version, []byte(raw), &tuning)
	return tuning, true, err
}

func (Store) SaveTx(c context.Context, t tx.Tx, p identity.PlayerID, r d.State, at time.Time) error {
	if err := r.Validate(); err != nil {
		return err
	}
	raw, version, err := payload.Encode(r)
	if err != nil {
		return err
	}
	tag, err := t.Exec(c, `UPDATE memoir_players SET payload=$2::jsonb,updated_at=$3,payload_version=$4 WHERE player_id=$1`, int64(p), string(raw), at, version)
	if err == nil && tag.RowsAffected() != 1 {
		return d.ErrUnavailable
	}
	return err
}
