package librarylocal

import (
	"context"

	i5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/identity"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// unlockBackgroundTx inserts paid-background ownership before debiting the one
// stock unlock item, so a failed debit removes the ownership in the same rollback.
func (s Service) unlockBackgroundTx(ctx context.Context, t tx.Tx, a identity.ActorContext, d Admission, catalog lib.Catalog, costOp operation.Context) error {
	rule, ok := catalog.Backgrounds[d.Command.Value]
	if !ok || rule.Limit != 1 {
		return lib.ErrUnqualified
	}
	inserted, e := s.Library.UnlockBackgroundTx(ctx, t, lib.BackgroundFact{PlayerID: a.PlayerID, BgID: rule.ID, UnlockedAt: d.DecisionAt})
	if e != nil {
		return e
	}
	if !inserted {
		return lib.ErrBgOwned
	}
	_, e = s.Costs.DebitMaterialCostTx(ctx, t, a.PlayerID, i5.MaterialCost{Stacks: []i5.StackMaterialCost{{ItemID: lib.BackgroundUnlockItemID, Amount: 1}}}, costOp)
	return e
}

// setBackgroundTx validates free or owned ownership, stores the main/room
// selection, and restores the stock default when the same background is chosen.
func (s Service) setBackgroundTx(ctx context.Context, t tx.Tx, a identity.ActorContext, d Admission, catalog lib.Catalog, root lib.PlayerFacts) (lib.PlayerFacts, error) {
	rule, ok := catalog.Backgrounds[d.Command.Value]
	if !ok {
		return root, lib.ErrUnqualified
	}
	if rule.Limit == 1 {
		owned, e := s.ownedBackgroundTx(ctx, t, a.PlayerID, rule.ID)
		if e != nil {
			return root, e
		}
		if !owned {
			return root, lib.ErrUnqualified
		}
	}
	next, changed, e := root.SetBackground(d.Command.SelectID, rule.ID, d.DecisionAt)
	if e != nil {
		return root, e
	}
	if !changed {
		return next, nil
	}
	if e = s.Library.SavePlayerTx(ctx, t, next, root.StateVersion); e != nil {
		return root, e
	}
	return next, nil
}

func (s Service) ownedBackgroundTx(ctx context.Context, q tx.Queryer, player identity.PlayerID, bgID int64) (bool, error) {
	facts, e := s.Library.ListBackgroundsTx(ctx, q, player)
	if e != nil {
		return false, e
	}
	for _, fact := range facts {
		if fact.BgID == bgID {
			return true, nil
		}
	}
	return false, nil
}
