package worldboss

import (
	"context"
	"fmt"

	gen "gxb.local/backend/v2/internal/application/generation"
	d "gxb.local/backend/v2/internal/domain/worldboss"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Reconciler struct{ Service Mode }

func (Reconciler) Name() string { return "world-boss" }

// Reconcile applies the daily 22:00 GMT+8 courage increment once per mode day
// and settles any boss it defeats.
func (r Reconciler) Reconcile(c context.Context, timed gen.TimedOperation, limit int) (gen.ReconcileResult, error) {
	out := gen.ReconcileResult{Provider: r.Name()}
	s := r.Service
	if !s.ready() || limit < 1 || limit > gen.MaxReconcileBatch {
		return out, d.ErrUnavailable
	}
	parent, err := s.pin(c, timed.Operation())
	if err != nil {
		return out, err
	}
	occurrences, err := s.Store.ListOccurrencesTx(c, s.Fresh, int64(limit))
	if err != nil {
		return out, err
	}
	for _, occurrence := range occurrences {
		child, err := reconcileOperation(parent, occurrence)
		if err != nil {
			return out, err
		}
		out.Scanned++
		applied := false
		_, _, err = s.Timed.Run(c, child, profile(), tx.Options{Isolation: tx.Serializable}, retry(), nil, func(c context.Context, sc gen.TimedScope) error {
			at := sc.Operation.DecisionAt()
			current, err := s.Store.LockOccurrenceTx(c, sc.Tx, occurrence.LogicalServerID, at)
			if err != nil {
				return err
			}
			updateDay := d.CourageDayFor(at)
			if updateDay <= current.CourageDay {
				return nil
			}
			level90, err := s.Population.LevelAtLeastCountTx(c, sc.Tx, current.LogicalServerID, 90)
			if err != nil {
				return err
			}
			challengers, err := s.Store.CountChallengersTx(c, sc.Tx, current.LogicalServerID, updateDay)
			if err != nil {
				return err
			}
			revision, _ := sc.Operation.Operation().Policies.Get("content")
			catalog, err := s.Content.WorldBossCatalogTx(c, sc.Tx, revision)
			if err != nil {
				return err
			}
			current.Courage += d.DailyCourage(level90, challengers)
			generation := current.Generation
			defeated, _ := current.Defeat(catalog)
			if err = s.deliverDefeats(c, sc, current.LogicalServerID, catalog, generation, defeated, at); err != nil {
				return err
			}
			current.CourageDay = updateDay
			if err = s.Store.SaveOccurrenceTx(c, sc.Tx, current, at); err != nil {
				return err
			}
			applied = true
			return nil
		})
		if err != nil {
			return out, err
		}
		if applied {
			out.Settled++
		} else {
			out.Noops++
		}
	}
	return out, nil
}

func reconcileOperation(parent operation.Context, occurrence d.Occurrence) (operation.Context, error) {
	id, err := ids.NewUUID()
	if err != nil {
		return operation.Context{}, err
	}
	return operation.Context{ID: id, StartedAt: parent.StartedAt, EntropySeed: parent.Derive(fmt.Sprintf("worldboss:reconcile:%d", occurrence.LogicalServerID), 0), Policies: parent.Policies}, nil
}
