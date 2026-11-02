// Package summonstore persists the Vending row (summon_players).
package summonstore

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/summon"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{}

const columns = `mana_free_time,mana_free_num,mana_free_day,crystal_free_time,counters::text,featured_target,featured_pity,sx_target,sx_pity,magic_target`

func read(c context.Context, q tx.Queryer, p identity.PlayerID, locked bool) (d.State, bool, error) {
	sql := `SELECT ` + columns + ` FROM summon_players WHERE player_id=$1`
	if locked {
		sql += ` FOR UPDATE`
	}
	var s d.State
	var raw string
	err := q.QueryRow(c, sql, int64(p)).Scan(&s.ManaFreeTime, &s.ManaFreeNum, &s.ManaFreeDay, &s.CrystalFreeTime, &raw, &s.FeaturedTarget, &s.FeaturedPity, &s.SXTarget, &s.SXPity, &s.MagicTarget)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return d.State{}, false, nil
	}
	if err != nil {
		return d.State{}, false, err
	}
	err = json.Unmarshal([]byte(raw), &s.Counters)
	return s, true, err
}

// ReadTx reports found=false for a player who never opened Vending.
func (Store) ReadTx(c context.Context, q tx.Queryer, p identity.PlayerID) (d.State, bool, error) {
	return read(c, q, p, false)
}

// LockTx inserts fresh when the row is absent, then locks it.
func (s Store) LockTx(c context.Context, t tx.Tx, p identity.PlayerID, fresh d.State, at time.Time) (d.State, error) {
	if err := s.write(c, t, p, fresh, at, `INSERT INTO summon_players(player_id,mana_free_time,mana_free_num,mana_free_day,crystal_free_time,counters,featured_target,featured_pity,sx_target,sx_pity,magic_target,state_version,updated_at)VALUES($1,$2,$3,$4,$5,$6::jsonb,$7,$8,$9,$10,$11,1,$12)ON CONFLICT(player_id)DO NOTHING`, false); err != nil {
		return d.State{}, err
	}
	state, _, err := read(c, t, p, true)
	return state, err
}

func (s Store) SaveTx(c context.Context, t tx.Tx, p identity.PlayerID, state d.State, at time.Time) error {
	return s.write(c, t, p, state, at, `UPDATE summon_players SET mana_free_time=$2,mana_free_num=$3,mana_free_day=$4,crystal_free_time=$5,counters=$6::jsonb,featured_target=$7,featured_pity=$8,sx_target=$9,sx_pity=$10,magic_target=$11,state_version=state_version+1,updated_at=$12 WHERE player_id=$1`, true)
}

func (Store) write(c context.Context, t tx.Tx, p identity.PlayerID, s d.State, at time.Time, sql string, exact bool) error {
	counters := s.Counters
	if counters == nil {
		counters = map[string]int64{}
	}
	raw, err := json.Marshal(counters)
	if err != nil {
		return err
	}
	tag, err := t.Exec(c, sql, int64(p), s.ManaFreeTime, s.ManaFreeNum, s.ManaFreeDay, s.CrystalFreeTime, string(raw), s.FeaturedTarget, s.FeaturedPity, s.SXTarget, s.SXPity, s.MagicTarget, at)
	if err == nil && exact && tag.RowsAffected() != 1 {
		return errors.New("summon: missing locked row")
	}
	return err
}

// TuningTx reads the operator overlay; found=false keeps the source policy.
func (Store) TuningTx(c context.Context, q tx.Queryer) (d.Tuning, bool, error) {
	var raw string
	err := q.QueryRow(c, `SELECT payload::text FROM summon_tuning`).Scan(&raw)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return d.Tuning{}, false, nil
	}
	if err != nil {
		return d.Tuning{}, false, err
	}
	var t d.Tuning
	err = json.Unmarshal([]byte(raw), &t)
	return t, true, err
}
