package itemsenergy

import (
	"context"

	gen "gxb.local/backend/v2/internal/application/generation"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/itemsenergy"
	"gxb.local/backend/v2/internal/foundation/operation"
)

const boxEntropyLabel = "items-energy.box/v1"

// ExchangeCode answers MID 241: open one chosen gift pack num times.
func (s Service) ExchangeCode(c context.Context, actor identity.ActorContext, itemID, giftID, num int64, op operation.Context) (map[string]any, error) {
	if itemID <= 0 || giftID <= 0 || num <= 0 {
		return nil, d.ErrInvalid
	}
	request := map[string]any{"item_id": itemID, "gift_id": giftID, "num": num}
	return s.execute(c, actor, op, "box_open", request, func(c context.Context, sc gen.TimedScope, catalog d.Catalog) (map[string]any, error) {
		plan, err := catalog.ResolveBox(itemID, giftID, num)
		if err != nil {
			return nil, err
		}
		rewards, err := catalog.GiftRewards(plan.Gift, plan.Num)
		if err != nil {
			return nil, err
		}
		stream := combat.NewStream(sc.Operation.Operation().Derive(boxEntropyLabel, 0))
		for _, groups := range plan.Units {
			for _, group := range groups {
				roll, err := catalog.DrawDrop(group, stream)
				if err != nil {
					return nil, err
				}
				drawn, err := catalog.DropReward(roll)
				if err != nil {
					return nil, err
				}
				rewards.Add(drawn)
			}
		}
		heroAwards, heroIDs, err := s.resolveHeroRewards(c, sc, actor.PlayerID, catalog, rewards.Heroes)
		if err != nil {
			return nil, err
		}
		lines := rewardLines(rewards)
		lines = append(lines, heroAwards.lines...)
		restoration := rewardPlan(actor.PlayerID, "box_open", sc.Operation.Operation(), lines)
		exchange := exchangePlan{
			cost:        appi5.MaterialCost{Stacks: []appi5.StackMaterialCost{{ItemID: itemID, Amount: num}}},
			restoration: restoration,
		}
		if _, err := s.settle(c, sc, actor, exchange, true); err != nil {
			return nil, err
		}
		awards := rewardAwards(rewards)
		awards = append(awards, heroAwards.awards...)
		if err = s.materializeHeroes(c, sc, actor.PlayerID, catalog, heroIDs, &awards); err != nil {
			return nil, err
		}
		if awards == nil {
			awards = []map[string]any{}
		}
		return map[string]any{"awards": awards, "spirit_awards": []any{}}, nil
	})
}

type heroRewards struct {
	lines  []grant.Line
	awards []map[string]any
}

// resolveHeroRewards converts a hero already owned (or repeated inside the same
// open) into its stone line and award. The roster lock is taken here, before the
// I5 exchange closes its lock union.
func (s Service) resolveHeroRewards(c context.Context, sc gen.TimedScope, pid identity.PlayerID, catalog d.Catalog, heroes []int64) (heroRewards, []int64, error) {
	var out heroRewards
	if len(heroes) == 0 {
		return out, nil, nil
	}
	if s.Heroes == nil || s.Fragments == nil || s.HeroWire == nil {
		return heroRewards{}, nil, d.ErrUnavailable
	}
	if err := s.Heroes.LockStoryRosterTx(c, sc.Tx, pid); err != nil {
		return heroRewards{}, nil, err
	}
	seen := map[int64]struct{}{}
	newHeroes := []int64{}
	for _, heroID := range heroes {
		owned, err := s.Heroes.OwnsOriginTx(c, sc.Tx, pid, heroID)
		if err != nil {
			return heroRewards{}, nil, err
		}
		_, repeated := seen[heroID]
		seen[heroID] = struct{}{}
		if owned || repeated {
			stone, err := s.Fragments.Fragments(heroID)
			if err != nil {
				return heroRewards{}, nil, d.ErrRefused
			}
			out.lines = append(out.lines, grant.Line{Kind: grant.StackItem, ItemID: stone[0], Amount: stone[1]})
			out.awards = append(out.awards, map[string]any{"table_id": stone[0], "item_num": stone[1], "to_stone": true})
			continue
		}
		newHeroes = append(newHeroes, heroID)
	}
	return out, newHeroes, nil
}

func (s Service) materializeHeroes(c context.Context, sc gen.TimedScope, pid identity.PlayerID, catalog d.Catalog, heroes []int64, awards *[]map[string]any) error {
	revision := catalog.Revision
	for _, heroID := range heroes {
		hero, admission, err := s.Heroes.AwardStoryPartnerTx(c, sc.Tx, pid, heroID, revision, sc.Operation.Operation())
		if err != nil {
			return err
		}
		if admission == nil {
			return d.ErrRefused
		}
		wire, err := s.HeroWire(hero)
		if err != nil {
			return err
		}
		wire["is_partner"] = true
		*awards = append(*awards, wire)
	}
	return nil
}

func rewardLines(rewards d.Rewards) []grant.Line {
	lines := make([]grant.Line, 0, len(rewards.Stacks)+len(rewards.Scalars)+2)
	seenStacks := map[int64]int64{}
	stackOrder := []int64{}
	for _, stack := range rewards.Stacks {
		if _, exists := seenStacks[stack.ItemID]; !exists {
			stackOrder = append(stackOrder, stack.ItemID)
		}
		seenStacks[stack.ItemID] += stack.Amount
	}
	for _, itemID := range stackOrder {
		lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: itemID, Amount: seenStacks[itemID]})
	}
	scalarOrder := []string{}
	scalars := map[string]int64{}
	for _, scalar := range rewards.Scalars {
		if _, exists := scalars[scalar.ResourceKey]; !exists {
			scalarOrder = append(scalarOrder, scalar.ResourceKey)
		}
		scalars[scalar.ResourceKey] += scalar.Amount
	}
	for _, key := range scalarOrder {
		lines = append(lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: key, Amount: scalars[key]})
	}
	temporalOrder := []string{}
	temporals := map[string]int64{}
	for _, temporal := range rewards.Temporals {
		if _, exists := temporals[temporal.ResourceKey]; !exists {
			temporalOrder = append(temporalOrder, temporal.ResourceKey)
		}
		temporals[temporal.ResourceKey] += temporal.Amount
	}
	for _, key := range temporalOrder {
		lines = append(lines, grant.Line{Kind: grant.Temporal, ResourceKey: key, Amount: temporals[key]})
	}
	if rewards.PlayerExp > 0 {
		lines = append(lines, grant.Line{Kind: grant.PlayerExp, Amount: rewards.PlayerExp})
	}
	return lines
}

func rewardAwards(rewards d.Rewards) []map[string]any {
	awards := make([]map[string]any, 0, len(rewards.Awards))
	for _, award := range rewards.Awards {
		awards = append(awards, map[string]any{"table_id": award.TableID, "item_num": award.ItemNum})
	}
	return awards
}
