// Package adventure converts objective facts into Adventure event occurrences.
// It owns no rooms and no awards; later modes consume the occurrence rows.
package adventure

import (
	"context"
	"errors"
	"time"

	d "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type TriggerStore interface {
	ActiveTypesTx(context.Context, tx.Queryer, identity.PlayerID, time.Time) (map[int64]struct{}, error)
	InsertOccurrenceTx(context.Context, tx.Tx, d.Occurrence) (bool, error)
}

// Observer is the one C2 trigger observer. It runs inside the transaction that
// recorded the fact; its occurrence rows take the late rank 750 and it never
// locks another family's row (D369).
type Observer struct {
	Store TriggerStore
	Wake  Wake
}

func (o Observer) ObserveTx(ctx context.Context, transaction tx.Tx, op operation.Context, facts ...objective.Fact) error {
	if o.Store == nil {
		return errors.New("adventure trigger store unavailable")
	}
	if op.StartedAt.IsZero() {
		return errors.New("adventure trigger: authoritative time required")
	}
	at := op.StartedAt.UTC()
	active := make(map[identity.PlayerID]map[int64]struct{})
	for _, fact := range facts {
		event, ok := d.EventForFactKind(fact.Kind)
		if !ok {
			continue
		}
		factKey, err := fact.Key()
		if err != nil {
			return err
		}
		triggered, err := d.Roll(event, factKey, op)
		if err != nil {
			return err
		}
		if !triggered {
			continue
		}
		types, loaded := active[fact.PlayerID]
		if !loaded {
			types, err = o.Store.ActiveTypesTx(ctx, transaction, fact.PlayerID, at)
			if err != nil {
				return err
			}
			active[fact.PlayerID] = types
		}
		if _, busy := types[event.ID]; busy {
			continue
		}
		occurrence, err := d.NewOccurrence(factKey, fact.PlayerID, event, at)
		if err != nil {
			return err
		}
		inserted, err := o.Store.InsertOccurrenceTx(ctx, transaction, occurrence)
		if err != nil {
			return err
		}
		if inserted {
			types[event.ID] = struct{}{}
			if o.Wake != nil {
				if err = o.Wake.WakeAdventureNotice(ctx, transaction, fact.PlayerID); err != nil {
					return err
				}
			}
		}
	}
	return nil
}
