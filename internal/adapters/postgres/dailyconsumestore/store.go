// Package dailyconsumestore persists DailyConsumption's sole durable counters.
package dailyconsumestore

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	app "gxb.local/backend/v2/internal/application/dailyconsume"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type Store struct{}

func read(c context.Context, q tx.Queryer, p identity.PlayerID, locked bool) (app.Counts, error) {
	sql := `SELECT counts::text,payload_version FROM daily_consumption_players WHERE player_id=$1`
	if locked {
		sql += ` FOR UPDATE`
	}
	var raw string
	var version int16
	err := q.QueryRow(c, sql, int64(p)).Scan(&raw, &version)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return app.Counts{}, nil
	}
	if err != nil {
		return nil, err
	}
	var counts app.Counts
	err = payload.Decode("daily_consumption_players", version, []byte(raw), &counts)
	return counts, err
}
func (Store) ReadTx(c context.Context, q tx.Queryer, p identity.PlayerID) (app.Counts, error) {
	return read(c, q, p, false)
}
func (Store) LockTx(c context.Context, t tx.Tx, p identity.PlayerID, at time.Time) (app.Counts, error) {
	if _, err := t.Exec(c, `INSERT INTO daily_consumption_players(player_id,counts,updated_at)VALUES($1,'{}'::jsonb,$2)ON CONFLICT(player_id)DO NOTHING`, int64(p), at); err != nil {
		return nil, err
	}
	return read(c, t, p, true)
}
func (Store) SaveTx(c context.Context, t tx.Tx, p identity.PlayerID, counts app.Counts, at time.Time) error {
	raw, version, err := payload.Encode(counts)
	if err != nil {
		return err
	}
	tag, err := t.Exec(c, `UPDATE daily_consumption_players SET counts=$2::jsonb,updated_at=$3,payload_version=$4 WHERE player_id=$1`, int64(p), string(raw), at, version)
	if err == nil && tag.RowsAffected() != 1 {
		return errors.New("daily consumption: missing locked row")
	}
	return err
}
