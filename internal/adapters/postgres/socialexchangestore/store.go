package socialexchangestore

import (
	"context"
	"encoding/json"
	"errors"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{}

func (Store) TuningTx(ctx context.Context, query tx.Queryer) (json.RawMessage, error) {
	var payload string
	err := query.QueryRow(ctx, `SELECT payload::text FROM social_exchange_tuning WHERE singleton=true`).Scan(&payload)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return json.RawMessage(payload), nil
}
