// Package compatstore owns only player_compat_preferences, under the caller's
// rank-470 row lock and after the I4 player root.
package compatstore

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	d "gxb.local/backend/v2/internal/domain/compat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{}

const createRowSQL = `INSERT INTO player_compat_preferences(player_id,first_main_touch,message_push_ids,state_version,created_at,updated_at) VALUES($1,0,'{}',1,$2,$2) ON CONFLICT (player_id) DO NOTHING`
const selectRowSQL = `SELECT first_main_touch,message_push_ids,state_version FROM player_compat_preferences WHERE player_id=$1`
const lockRowSQL = selectRowSQL + ` FOR UPDATE`
const saveRowSQL = `UPDATE player_compat_preferences SET first_main_touch=$2,message_push_ids=$3,state_version=$4,updated_at=$5 WHERE player_id=$1 AND state_version=$6`

func scan(row tx.Row) (d.Preferences, error) {
	var firstMainTouch int16
	var messagePushIDs []int64
	var stateVersion int64
	if err := row.Scan(&firstMainTouch, &messagePushIDs, &stateVersion); err != nil {
		return d.Preferences{}, err
	}
	preferences := d.Preferences{FirstMainTouch: int64(firstMainTouch), MessagePushIDs: messagePushIDs, StateVersion: stateVersion}
	if preferences.MessagePushIDs == nil {
		preferences.MessagePushIDs = []int64{}
	}
	return preferences, preferences.Validate()
}

func (Store) ReadTx(ctx context.Context, q tx.Queryer, player identity.PlayerID) (d.Preferences, bool, error) {
	preferences, err := scan(q.QueryRow(ctx, selectRowSQL, int64(player)))
	if errors.Is(err, kernelstore.ErrNoRows) {
		return d.Preferences{MessagePushIDs: []int64{}, StateVersion: 1}, false, nil
	}
	if err != nil {
		return d.Preferences{}, false, err
	}
	return preferences, true, nil
}

func (Store) LockTx(ctx context.Context, t tx.Tx, player identity.PlayerID, at time.Time) (d.Preferences, error) {
	if _, err := t.Exec(ctx, createRowSQL, int64(player), at); err != nil {
		return d.Preferences{}, err
	}
	return scan(t.QueryRow(ctx, lockRowSQL, int64(player)))
}

func (Store) SaveTx(ctx context.Context, t tx.Tx, player identity.PlayerID, preferences d.Preferences, expectedVersion int64, at time.Time) error {
	messagePushIDs := preferences.MessagePushIDs
	if messagePushIDs == nil {
		messagePushIDs = []int64{}
	}
	tag, err := t.Exec(ctx, saveRowSQL, int64(player), preferences.FirstMainTouch, messagePushIDs, preferences.StateVersion, at, expectedVersion)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return d.ErrUnavailable
	}
	return nil
}
