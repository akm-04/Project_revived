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

// FavorOccurrence is the Library owner's typed favor read (C4): a 10002
// occurrence exists only for an owned partner below the Library favor limit.
type FavorOccurrence interface {
	FavorOccurrenceTx(context.Context, tx.Queryer, identity.PlayerID, int64) (bool, error)
}

// Observer is the one C2 trigger observer. It runs inside the transaction that
// recorded the fact; its occurrence rows take the late rank 750 and it never
// locks another family's row (D369).
type Observer struct {
	Store TriggerStore
	Wake  Wake
	Favor FavorOccurrence
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
		if event.ID == d.EventFavor {
			// C4: the fact's source value is the favored partner id, and the
			// occurrence exists only for an owned hero below the Library limit.
			if fact.Value <= 0 || o.Favor == nil {
				continue
			}
			allowed, err := o.Favor.FavorOccurrenceTx(ctx, transaction, fact.PlayerID, fact.Value)
			if err != nil {
				return err
			}
			if !allowed {
				continue
			}
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
		occurrence, err := d.NewOccurrence(factKey, fact.PlayerID, event, at, fact.Value)
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
