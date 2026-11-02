// Package petcampaignstore owns only petcampaign_players (family lock605).
package petcampaignstore

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/petcampaign"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type Store struct{}

func read(row tx.Row) (d.State, bool, error) {
	var raw string
	var s d.State
	if e := row.Scan(&raw); errors.Is(e, kernelstore.ErrNoRows) {
		return s, false, nil
	} else if e != nil {
		return s, false, e
	}
	e := json.Unmarshal([]byte(raw), &s)
	return s, true, e
}
func (Store) ReadTx(c context.Context, q tx.Queryer, p identity.PlayerID) (d.State, bool, error) {
	return read(q.QueryRow(c, `SELECT payload::text FROM petcampaign_players WHERE player_id=$1`, int64(p)))
}
func (Store) LockTx(c context.Context, t tx.Tx, p identity.PlayerID, at time.Time) (d.State, error) {
	if _, e := t.Exec(c, `INSERT INTO petcampaign_players(player_id,payload,updated_at)VALUES($1,'{}',$2) ON CONFLICT(player_id)DO NOTHING`, int64(p), at); e != nil {
		return d.State{}, e
	}
	s, _, e := read(t.QueryRow(c, `SELECT payload::text FROM petcampaign_players WHERE player_id=$1 FOR UPDATE`, int64(p)))
	return s, e
}
func (Store) SaveTx(c context.Context, t tx.Tx, p identity.PlayerID, s d.State, at time.Time) error {
	raw, e := json.Marshal(s)
	if e != nil {
		return e
	}
	tag, e := t.Exec(c, `UPDATE petcampaign_players SET payload=$2::jsonb,updated_at=$3 WHERE player_id=$1`, int64(p), string(raw), at)
	if e == nil && tag.RowsAffected() != 1 {
		return d.ErrUnavailable
	}
	return e
}
