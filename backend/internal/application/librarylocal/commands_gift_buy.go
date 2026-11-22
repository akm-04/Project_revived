package librarylocal

import (
	"context"
	"strconv"

	i5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// buyGiftTx debits the gift's crystal price, grants one gift stack, and answers
// the post-grant owned count from the I5 stack owner. No hero is in the request.
func (s Service) buyGiftTx(ctx context.Context, t tx.Tx, a identity.ActorContext, d Admission, catalog lib.Catalog, costOp operation.Context) (int64, int64, error) {
	gift, ok := catalog.Gifts[d.Command.Value]
	if !ok || gift.ItemID != d.Command.Value || gift.PriceCrystal <= 0 {
		return 0, 0, lib.ErrInvalidGift
	}
	if s.Grants == nil || s.Stacks == nil {
		return 0, 0, ErrUnavailable
	}
	if _, e := s.Costs.DebitMaterialCostTx(ctx, t, a.PlayerID, i5.MaterialCost{Scalars: []i5.ScalarMaterialCost{{ResourceKey: "crystal", Amount: gift.PriceCrystal}}}, costOp); e != nil {
		return 0, 0, e
	}
	plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "library", Operation: "buy-gift", BusinessKey: "library:buy-gift:" + strconv.FormatInt(gift.ItemID, 10), Occurrence: d.Operation.ID.String(), PolicyVersion: LifecyclePolicy}, Lines: []grant.Line{{Kind: grant.StackItem, ItemID: gift.ItemID, Amount: 1}}}
	if _, e := s.Grants.SettleGrantTx(ctx, t, a, plan, d.Operation, i5.GrantTxOptions{AllowOverflowMail: true}); e != nil {
		return 0, 0, e
	}
	stack, exists, e := s.Stacks.ReadStackTx(ctx, t, a.PlayerID, gift.ItemID)
	if e != nil {
		return 0, 0, e
	}
	if !exists {
		return 0, 0, ErrUnavailable
	}
	return gift.ItemID, stack.Quantity, nil
}
