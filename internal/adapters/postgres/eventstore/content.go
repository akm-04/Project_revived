package eventstore

import (
	"context"

	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/domain/events"
	"gxb.local/backend/v2/internal/domain/grant"
	itemsenergy "gxb.local/backend/v2/internal/domain/itemsenergy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ContentGifts expands gift ids through the content owner's daily-buy read,
// the only backend content that carries gift.lua rows (EA-4). A gift row with
// random, summon, equip or scalar contents is reported as not expandable
// rather than silently losing part of the award.
type ContentGifts struct{}

// GiftTx reads one gift row and turns it into item lines.
func (ContentGifts) GiftTx(ctx context.Context, query tx.Queryer, giftID int64) ([]events.RewardLine, bool, error) {
	if query == nil || giftID <= 0 {
		return nil, false, errInvalid
	}
	store := contentstore.Store{}
	revision, err := store.ActiveRevision(ctx, query)
	if err != nil {
		return nil, false, err
	}
	catalog, err := store.DailyBuyInputsTx(ctx, query, revision)
	if err != nil {
		return nil, false, err
	}
	gift, found := catalog.Gifts[giftID]
	if !found || !deterministicGift(gift) {
		return nil, false, nil
	}
	lines := make([]events.RewardLine, 0, len(gift.Items))
	for index, itemID := range gift.Items {
		lines = append(lines, events.RewardLine{Kind: "item", ItemID: itemID, Amount: gift.ItemNums[index]})
	}
	return lines, len(lines) > 0, nil
}

func deterministicGift(gift itemsenergy.Gift) bool {
	if len(gift.Drops) != 0 || gift.SummonID != 0 || (gift.Equip != "" && gift.Equip != "0") || len(gift.Items) != len(gift.ItemNums) {
		return false
	}
	return gift.Crystal == 0 && gift.Mana == 0 && gift.Energy == 0 && gift.VipExp == 0 && gift.ArenaCoin == 0 &&
		gift.MarchCoin == 0 && gift.LuckyCoin == 0 && gift.FriendshipCoin == 0 && gift.SkinFragment == 0 &&
		gift.Exp == 0 && gift.Badge == 0 && gift.Soul == 0 && gift.Vip == 0 && gift.ExBadge == 0 &&
		gift.TutorCoin == 0 && gift.SkinCoin == 0 && gift.SpiritEnergy == 0
}

// ContentCatalogue checks a reward line against the content resource catalogue,
// which is the operator item catalogue (I11A_OPERATOR_COMMANDS_V1 ruling 9).
type ContentCatalogue struct{}

// CheckRewardsTx refuses a line set the content revision does not carry.
func (ContentCatalogue) CheckRewardsTx(ctx context.Context, query tx.Queryer, lines []events.RewardLine) error {
	if query == nil {
		return errInvalid
	}
	store := contentstore.Store{}
	revision, err := store.ActiveRevision(ctx, query)
	if err != nil {
		return err
	}
	for _, line := range lines {
		contentLine, err := grantLine(line)
		if err != nil {
			return err
		}
		if _, err := store.ResolveResourceTx(ctx, query, revision, contentLine); err != nil {
			return err
		}
	}
	return nil
}

func grantLine(line events.RewardLine) (grant.Line, error) {
	switch line.Kind {
	case "item":
		return grant.Line{Kind: grant.StackItem, ItemID: line.ItemID, Amount: line.Amount}, nil
	case "currency":
		return grant.Line{Kind: grant.ScalarCurrency, ResourceKey: line.ResourceKey, Amount: line.Amount}, nil
	default:
		return grant.Line{}, errInvalid
	}
}
