package events

import (
	"context"
	"strconv"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/events"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// grantChoice settles the chosen tier and returns the stock award entries in
// definition order. A hero line grants its character entity; a hero the player
// already owns becomes its stone instead (the item-box rule, 1071 tiers 2-5).
func (s ClaimService) grantChoice(ctx context.Context, transaction tx.Tx, actor identity.ActorContext, op operation.Context, occurrence *events.Occurrence, tier events.Tier, choiceIndex int, revision string) ([]map[string]any, error) {
	choice := tier.Choices[choiceIndex-1]
	if len(choice.Lines) == 0 {
		return nil, ErrUnavailable
	}
	if hasHeroLine(choice.Lines) {
		if err := s.Heroes.LockStoryRosterTx(ctx, transaction, actor.PlayerID); err != nil {
			return nil, err
		}
	}
	awards := make([]map[string]any, len(choice.Lines))
	fungible := make([]grant.Line, 0, len(choice.Lines))
	type pendingHero struct {
		index  int
		itemID int64
	}
	var pending []pendingHero
	for index, line := range choice.Lines {
		switch line.Kind {
		case events.RewardKindItem:
			awards[index] = itemAward(line.ItemID, line.Amount)
			fungible = append(fungible, grant.Line{Kind: grant.StackItem, ItemID: line.ItemID, Amount: line.Amount})
		case events.RewardKindCurrency:
			awards[index] = currencyAward(line.ResourceKey, line.Amount)
			fungible = append(fungible, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: line.ResourceKey, Amount: line.Amount})
		case events.RewardKindHero:
			policy, err := s.HeroContent.HeroNormalSummonTx(ctx, transaction, revision, line.ItemID)
			if err != nil {
				return nil, err
			}
			owned, err := s.Heroes.OwnsOriginTx(ctx, transaction, actor.PlayerID, policy.Template.OriginTableID)
			if err != nil {
				return nil, err
			}
			if !owned {
				pending = append(pending, pendingHero{index: index, itemID: line.ItemID})
				continue
			}
			stone, err := s.Fragments.HeroFragmentsTx(ctx, transaction, revision, policy.Template.OriginTableID)
			if err != nil {
				return nil, err
			}
			awards[index] = stoneAward(stone[0], stone[1])
			fungible = append(fungible, grant.Line{Kind: grant.StackItem, ItemID: stone[0], Amount: stone[1]})
		default:
			return nil, ErrUnavailable
		}
	}
	for _, hero := range pending {
		granted, admission, err := s.Heroes.AwardStoryPartnerTx(ctx, transaction, actor.PlayerID, hero.itemID, revision, op)
		if err != nil {
			return nil, err
		}
		if admission == nil {
			return nil, ErrUnavailable
		}
		wire, err := s.HeroWire(granted)
		if err != nil {
			return nil, err
		}
		wire["is_partner"] = true
		wire["to_stone"] = false
		// The client assigns one to a partner award itself; item_num keeps the
		// shared awards[] conformance path happy.
		wire["item_num"] = int64(1)
		awards[hero.index] = wire
	}
	if len(fungible) == 0 {
		return awards, nil
	}
	plan := grant.Plan{
		PlayerID: actor.PlayerID,
		Source: grant.SourceIdentity{
			Domain: "events", Operation: "claim",
			BusinessKey: claimBusinessKey(occurrence.ID, int64(actor.PlayerID), tier.ID),
			Occurrence:  strconv.FormatInt(occurrence.ID, 10), PolicyVersion: ClaimPolicyVersion,
		},
		Lines: fungible,
	}
	if _, err := s.Grants.SettleGrantTx(ctx, transaction, actor, plan, op, appi5.GrantTxOptions{}); err != nil {
		return nil, err
	}
	return awards, nil
}

func hasHeroLine(lines []events.RewardLine) bool {
	for _, line := range lines {
		if line.Kind == events.RewardKindHero {
			return true
		}
	}
	return false
}

func itemAward(itemID, amount int64) map[string]any {
	return map[string]any{"table_id": itemID, "item_num": amount, "is_partner": false, "to_stone": false}
}

func stoneAward(itemID, amount int64) map[string]any {
	return map[string]any{"table_id": itemID, "item_num": amount, "is_partner": false, "to_stone": true}
}

// currencyAward names the resource with the extra key the stock award window
// reads to pick its icon (AlertAwardWindow.lua:373-384, :193-194).
func currencyAward(resourceKey string, amount int64) map[string]any {
	return map[string]any{"table_id": int64(-1), "item_num": amount, resourceKey: amount}
}
