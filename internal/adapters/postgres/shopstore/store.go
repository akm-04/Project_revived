// Package shopstore persists shop_players and the D476 shop_tuning singleton.
package shopstore

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"strconv"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/shop"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{}

const rowColumns = `generation,refresh_times,refresh_day,stock::text,payload_version,state_version,updated_at`

// LockShopTx reads and locks one player's shop row at rank 460; rows absent.
func (Store) LockShopTx(c context.Context, t tx.Tx, player identity.PlayerID, shopType int64) (d.Row, bool, error) {
	row := d.Row{PlayerID: player, ShopType: shopType}
	if t == nil || !player.Valid() || shopType <= 0 {
		return row, false, d.ErrInvalid
	}
	var raw string
	err := t.QueryRow(c, `SELECT `+rowColumns+` FROM shop_players WHERE player_id=$1 AND shop_type=$2 FOR UPDATE`, int64(player), shopType).
		Scan(&row.Generation, &row.RefreshTimes, &row.RefreshDay, &raw, &row.PayloadVersion, &row.StateVersion, &row.UpdatedAt)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return row, false, nil
	}
	if err != nil {
		return row, false, err
	}
	if err = payload.Decode("shop_players", row.PayloadVersion, []byte(raw), &row.Stock); err != nil {
		return d.Row{}, false, err
	}
	return row, true, nil
}

// InsertShopTx writes a new generation row.
func (Store) InsertShopTx(c context.Context, t tx.Tx, row d.Row) error {
	if t == nil || !row.PlayerID.Valid() || row.ShopType <= 0 {
		return d.ErrInvalid
	}
	raw, version, err := payload.Encode(row.Stock)
	if err != nil {
		return err
	}
	_, err = t.Exec(c, `INSERT INTO shop_players(player_id,shop_type,generation,refresh_times,refresh_day,stock,payload_version,state_version,updated_at)VALUES($1,$2,$3,$4,$5,$6::jsonb,$7,$8,$9)`,
		int64(row.PlayerID), row.ShopType, row.Generation, row.RefreshTimes, row.RefreshDay, string(raw), version, row.StateVersion, row.UpdatedAt)
	return err
}

// SaveShopTx saves an existing row by its state_version.
func (Store) SaveShopTx(c context.Context, t tx.Tx, row d.Row) error {
	if t == nil || !row.PlayerID.Valid() || row.ShopType <= 0 {
		return d.ErrInvalid
	}
	raw, version, err := payload.Encode(row.Stock)
	if err != nil {
		return err
	}
	tag, err := t.Exec(c, `UPDATE shop_players SET generation=$3,refresh_times=$4,refresh_day=$5,stock=$6::jsonb,payload_version=$7,state_version=state_version+1,updated_at=$8 WHERE player_id=$1 AND shop_type=$2 AND state_version=$9`,
		int64(row.PlayerID), row.ShopType, row.Generation, row.RefreshTimes, row.RefreshDay, string(raw), version, row.UpdatedAt, row.StateVersion)
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return d.ErrStaleState
	}
	return nil
}

// TuningTx reads the singleton overlay. An absent row keeps the source catalog.
func (Store) TuningTx(c context.Context, q tx.Queryer) (d.Tuning, bool, error) {
	var raw string
	var version int16
	var revision int64
	err := q.QueryRow(c, `SELECT payload::text,payload_version,revision FROM shop_tuning`).Scan(&raw, &version, &revision)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return d.Tuning{}, false, nil
	}
	if err != nil {
		return d.Tuning{}, false, err
	}
	var stored d.MarketTuning
	if err = payload.Decode("shop_tuning", version, []byte(raw), &stored); err != nil {
		return d.Tuning{}, false, err
	}
	digest := sha256.Sum256([]byte(raw))
	return d.Tuning{Revision: strconv.FormatInt(revision, 10), Digest: hex.EncodeToString(digest[:]), Rows: stored.Rows}, true, nil
}
