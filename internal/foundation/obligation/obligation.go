package obligation

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

// Obligation is immutable routing/evidence required to reload canonical state.
// It must never contain a serialized mutable gameplay aggregate.
type Obligation struct {
	Kind        string
	SemanticKey string
	DueAt       time.Time
	Args        json.RawMessage
	Queue       string
	Profile     string
}

func (o Obligation) Validate() error {
	if o.Kind == "" || o.SemanticKey == "" || o.Queue == "" {
		return errors.New("invalid durable obligation")
	}
	if len(o.Args) == 0 || !json.Valid(o.Args) {
		return errors.New("obligation args must be valid JSON")
	}
	return nil
}

// Queue couples owed asynchronous work to the same transaction as its source
// effect. River job IDs/leases are intentionally absent from this contract.
type Queue interface {
	InsertTx(context.Context, tx.Tx, Obligation) error
}
