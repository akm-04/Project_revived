package i5

import (
	"context"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

// EmoticonEntitlementReader is an additive non-consuming I5 same-transaction
// qualification. All Economy700/Stack722 locks precede any FriendDM mutation.
// Free content requires no inventory lock. No grants/receipts/debits are emitted.
type EmoticonEntitlementReader struct {
	Store   MaterialCostStore
	Content ContentRuntime
}

func (d EmoticonEntitlementReader) PrepareEmoticonEntitlementTx(c context.Context, t tx.Tx, pid identity.PlayerID, revision string, item int64, at time.Time) (int64, error) {
	if t == nil || !pid.Valid() || item < 0 || at.IsZero() || validateContentRevision(revision) != nil {
		return 0, ErrContentRevisionConflict
	}
	if item == 0 {
		return 0, nil
	}
	if d.Store == nil || d.Content == nil {
		return 0, ErrContentRevisionConflict
	}
	resource, e := d.Content.ResolveResourceTx(c, t, revision, grant.Line{Kind: grant.StackItem, ItemID: item, Amount: 1})
	if e != nil {
		return 0, e
	}
	if resource.Kind != grant.StackItem || resource.Stack == nil || resource.Stack.ItemID != item || resource.Stack.StackCap != 1 {
		return 0, ErrContentRevisionConflict
	}
	if e = d.Store.LockEconomyOwnerTx(c, t, pid); e != nil {
		return 0, e
	}
	state, exists, e := d.Store.LockStackTx(c, t, pid, item, at)
	if e != nil {
		return 0, e
	}
	if !exists || state.Validate() != nil || state.Quantity < 1 {
		return 0, economy.ErrInsufficientBalance
	}
	return state.StateVersion, nil
}
