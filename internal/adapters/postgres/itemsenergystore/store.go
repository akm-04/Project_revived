// Package itemsenergystore persists the D476 items-energy operator overlay.
package itemsenergystore

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	d "gxb.local/backend/v2/internal/domain/itemsenergy"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{}

// TuningTx reads the singleton overlay; found=false keeps the source catalog.
func (Store) TuningTx(c context.Context, q tx.Queryer) (d.Tuning, bool, error) {
	var raw string
	var version int16
	err := q.QueryRow(c, `SELECT payload::text,payload_version FROM items_energy_tuning`).Scan(&raw, &version)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return d.Tuning{}, false, nil
	}
	if err != nil {
		return d.Tuning{}, false, err
	}
	var tuning d.Tuning
	err = payload.Decode("items_energy_tuning", version, []byte(raw), &tuning)
	return tuning, true, err
}
