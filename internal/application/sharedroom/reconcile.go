package sharedroom

import (
	"context"
	"fmt"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Reconciler closes expired rooms of one logical server in bounded batches.
// Routes supplies each family's wakeup route; a family without one still has
// its authoritative read MID, so the close proceeds without a push.
type Reconciler struct {
	Service Service
	Server  identity.LogicalServerID
	Routes  map[string]string
}

func (r Reconciler) Name() string { return "shared-room" }

func (r Reconciler) Reconcile(c context.Context, timed gen.TimedOperation, limit int) (gen.ReconcileResult, error) {
	out := gen.ReconcileResult{Provider: r.Name()}
	s := r.Service
	if !s.ready() || limit < 1 || limit > gen.MaxReconcileBatch {
		return out, ErrUnavailable
	}
	roomIDs, err := s.Store.ExpiredRoomIDsTx(c, s.Fresh, r.Server, timed.DecisionAt(), limit)
	if err != nil {
		return out, err
	}
	for _, roomID := range roomIDs {
		child, err := reconcileOperation(timed.Operation(), roomID)
		if err != nil {
			return out, err
		}
		settled, woke := false, false
		_, _, err = s.Timed.Run(c, child, profile(), tx.Options{Isolation: tx.Serializable}, retry(), nil, func(c context.Context, sc gen.TimedScope) error {
			now := sc.Operation.DecisionAt()
			observed, found, err := s.Store.ReadRoomTx(c, sc.Tx, roomID)
			if err != nil {
				return err
			}
			if !found || observed.Status != d.StatusOpen {
				return nil
			}
			if err := s.lockRoots(c, sc.Tx, observed.LogicalServerID, observed.Members()); err != nil {
				return err
			}
			locked, found, err := s.Store.LockRoomTx(c, sc.Tx, roomID)
			if err != nil {
				return err
			}
			if !found {
				return nil
			}
			if roomDiffers(observed, locked) {
				return tx.MarkDefiniteAbort(ErrConflict)
			}
			if !locked.Expire(now) {
				return nil
			}
			if err := s.Store.SaveRoomTx(c, sc.Tx, locked); err != nil {
				return err
			}
			if route := r.Routes[locked.Family]; route != "" {
				if err := s.Store.WakeRoomTx(c, sc.Tx, locked.ID, route); err != nil {
					return err
				}
				woke = true
			}
			settled = true
			return nil
		})
		out.Scanned++
		if err != nil {
			return out, err
		}
		switch {
		case settled:
			out.Settled++
		default:
			out.Noops++
		}
		if woke {
			out.Wakeups++
		}
	}
	return out, nil
}

func reconcileOperation(parent operation.Context, roomID int64) (operation.Context, error) {
	id, err := ids.NewUUID()
	if err != nil {
		return operation.Context{}, err
	}
	return operation.Context{ID: id, StartedAt: parent.StartedAt, EntropySeed: parent.Derive(fmt.Sprintf("sharedroom:reconcile:%d", roomID), 0), Policies: parent.Policies}, nil
}
