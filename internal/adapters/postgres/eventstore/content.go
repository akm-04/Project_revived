package eventstore

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/events"
	"gxb.local/backend/v2/internal/domain/grant"
	itemsenergy "gxb.local/backend/v2/internal/domain/itemsenergy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ContentGifts expands gift ids through the content owner's daily-buy read.
// That catalogue carries every stock item row and the gift rows the offline
// generator exports for shipped event definitions (EA-4, EA-11). A gift row
// with random, summon, equip or non-currency scalar contents is reported as
// not expandable rather than silently losing part of the award.
type ContentGifts struct{}

// GiftTx reads one gift row and turns it into item, hero and currency lines.
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
	if !found {
		return nil, false, nil
	}
	return expandGift(gift, catalog.Items)
}

// expandGift turns one deterministic gift row into reward lines. Hero items
// (client item type -1) become hero lines; every other item is a stack item,
// and mana/crystal are the only gift scalars the claim path grants today.
func expandGift(gift itemsenergy.Gift, items map[int64]itemsenergy.Item) ([]events.RewardLine, bool, error) {
	if len(gift.Drops) != 0 || gift.SummonID != 0 || (gift.Equip != "" && gift.Equip != "0") || len(gift.Items) != len(gift.ItemNums) {
		return nil, false, nil
	}
	if !currencyOnlyGift(gift) {
		return nil, false, nil
	}
	lines := make([]events.RewardLine, 0, len(gift.Items)+2)
	for index, itemID := range gift.Items {
		amount := gift.ItemNums[index]
		if amount <= 0 {
			return nil, false, nil
		}
		item, known := items[itemID]
		if !known {
			return nil, false, nil
		}
		if item.Type == -1 {
			if amount != 1 {
				return nil, false, nil
			}
			lines = append(lines, events.RewardLine{Kind: events.RewardKindHero, ItemID: itemID, Amount: 1})
			continue
		}
		lines = append(lines, events.RewardLine{Kind: events.RewardKindItem, ItemID: itemID, Amount: amount})
	}
	if gift.Mana > 0 {
		lines = append(lines, events.RewardLine{Kind: events.RewardKindCurrency, ResourceKey: "mana", Amount: gift.Mana})
	}
	if gift.Crystal > 0 {
		lines = append(lines, events.RewardLine{Kind: events.RewardKindCurrency, ResourceKey: "crystal", Amount: gift.Crystal})
	}
	return lines, len(lines) > 0, nil
}

// currencyOnlyGift reports that the row carries no gift scalar the claim path
// cannot grant. Mana and crystal become currency lines above.
func currencyOnlyGift(gift itemsenergy.Gift) bool {
	return gift.Energy == 0 && gift.VipExp == 0 && gift.ArenaCoin == 0 &&
		gift.MarchCoin == 0 && gift.LuckyCoin == 0 && gift.FriendshipCoin == 0 &&
		gift.SkinFragment == 0 && gift.Exp == 0 && gift.Badge == 0 && gift.Soul == 0 &&
		gift.Vip == 0 && gift.ExBadge == 0 && gift.TutorCoin == 0 && gift.SkinCoin == 0 &&
		gift.SpiritEnergy == 0
}

// ContentCatalogue checks a reward line against the active content: stack items
// and currencies resolve as resources, hero lines must be acquisition items the
// character owner can grant (I11A_OPERATOR_COMMANDS_V1 ruling 9).
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
		if line.Kind == events.RewardKindHero {
			if _, err := store.HeroNormalSummonTx(ctx, query, revision, line.ItemID); err != nil {
				if errors.Is(err, kernelstore.ErrNoRows) {
					return economy.ErrUnknownResource
				}
				return err
			}
			continue
		}
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
	case events.RewardKindItem:
		return grant.Line{Kind: grant.StackItem, ItemID: line.ItemID, Amount: line.Amount}, nil
	case events.RewardKindCurrency:
		return grant.Line{Kind: grant.ScalarCurrency, ResourceKey: line.ResourceKey, Amount: line.Amount}, nil
	default:
		return grant.Line{}, errInvalid
	}
}
