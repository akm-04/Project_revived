package contentstore

import (
	"context"
	application "gxb.local/backend/v2/internal/application/socialrecall"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/domain/grant"
	domain "gxb.local/backend/v2/internal/domain/socialrecall"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (store Store) SocialRecallAwardCatalogTx(ctx context.Context, query tx.Queryer, revision string) (application.AwardCatalog, error) {
	catalog, err := store.SocialInputCatalogTx(ctx, query, revision)
	if err != nil {
		return nil, err
	}
	return socialRecallAwardCatalog(catalog)
}
func socialRecallAwardCatalog(catalog builtin.SocialInputCatalog) (application.AwardCatalog, error) {
	if catalog.Validate() != nil {
		return nil, ErrSocialContentUnavailable
	}
	gifts := map[int64]builtin.SocialGift{}
	for _, gift := range catalog.Gifts {
		gifts[gift.ID] = gift
	}
	result := application.AwardCatalog{}
	for _, milestone := range catalog.RecallMilestones {
		gift, found := gifts[milestone.GiftID]
		if !found || len(gift.Drops) != 0 {
			return nil, ErrSocialContentUnavailable
		}
		lines := make([]grant.Line, 0, len(gift.Items)+1)
		if gift.Crystal > 0 {
			lines = append(lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: "crystal", Amount: gift.Crystal})
		}
		for _, item := range gift.Items {
			lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: item.ItemID, Amount: item.Quantity})
		}
		result[milestone.ID] = application.AwardSpec{ID: milestone.ID, GiftID: gift.ID, Threshold: milestone.Condition, Category: domain.Category(milestone.Type), Lines: lines}
	}
	if result.Validate() != nil {
		return nil, ErrSocialContentUnavailable
	}
	return result, nil
}
