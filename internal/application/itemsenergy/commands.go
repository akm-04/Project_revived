package itemsenergy

import (
	"context"
	"errors"
	"sort"

	appconsume "gxb.local/backend/v2/internal/application/dailyconsume"
	gen "gxb.local/backend/v2/internal/application/generation"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/itemsenergy"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/operation"
)

const goldenHandEntropyLabel = "items-energy.golden-hand/v1"

// maxBatchItems bounds every item-id list a stock backpack window can send.
const maxBatchItems = 200

type ItemAmount struct {
	ItemID int64
	Num    int64
}

func (s Service) UseEnergyItem(c context.Context, actor identity.ActorContext, itemID, num int64, op operation.Context) (map[string]any, error) {
	if itemID <= 0 || num <= 0 {
		return nil, d.ErrInvalid
	}
	return s.execute(c, actor, op, "item_use", map[string]any{"item_id": itemID, "item_num": num}, func(c context.Context, sc gen.TimedScope, catalog d.Catalog) (map[string]any, error) {
		item, err := catalog.Item(itemID)
		if err != nil {
			return nil, err
		}
		gain, err := d.EnergyItemGain(item, num)
		if err != nil {
			return nil, err
		}
		counters, err := s.Counters.ReadBuyTx(c, sc.Tx, actor.PlayerID, s.day(sc))
		if err != nil {
			return nil, err
		}
		plan := exchangePlan{
			cost:        appi5.MaterialCost{Stacks: []appi5.StackMaterialCost{{ItemID: itemID, Amount: num}}},
			restoration: rewardPlan(actor.PlayerID, "item_use", sc.Operation.Operation(), []grant.Line{{Kind: grant.Temporal, ResourceKey: "energy", Amount: gain}}),
		}
		if _, err = s.settle(c, sc, actor, plan, false); err != nil {
			return nil, err
		}
		energy, err := s.temporal(c, sc, actor.PlayerID, "energy")
		if err != nil {
			return nil, err
		}
		return map[string]any{"energy": energy, "buy_energy_times": counters.Energy}, nil
	})
}

func (s Service) SellItem(c context.Context, actor identity.ActorContext, itemID, num int64, op operation.Context) (map[string]any, error) {
	return s.sell(c, actor, op, "sell", []ItemAmount{{ItemID: itemID, Num: num}})
}

func (s Service) SellItems(c context.Context, actor identity.ActorContext, items []ItemAmount, op operation.Context) (map[string]any, error) {
	return s.sell(c, actor, op, "sell", items)
}

func (s Service) sell(c context.Context, actor identity.ActorContext, op operation.Context, name string, items []ItemAmount) (map[string]any, error) {
	amounts, err := aggregateItems(items)
	if err != nil {
		return nil, err
	}
	return s.execute(c, actor, op, name, map[string]any{"items": items}, func(c context.Context, sc gen.TimedScope, catalog d.Catalog) (map[string]any, error) {
		cost := appi5.MaterialCost{}
		scalars := map[string]int64{}
		order := []string{}
		for _, aggregate := range amounts {
			item, err := catalog.Item(aggregate.ItemID)
			if err != nil {
				return nil, err
			}
			key, unit, ok := d.SellUnitPrice(item)
			if !ok {
				return nil, d.ErrRefused
			}
			cost.Stacks = append(cost.Stacks, appi5.StackMaterialCost{ItemID: aggregate.ItemID, Amount: aggregate.Num})
			if _, exists := scalars[key]; !exists {
				order = append(order, key)
			}
			scalars[key] += unit * aggregate.Num
		}
		lines := make([]grant.Line, 0, len(order))
		for _, key := range order {
			lines = append(lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: key, Amount: scalars[key]})
		}
		plan := exchangePlan{cost: cost, restoration: rewardPlan(actor.PlayerID, name, sc.Operation.Operation(), lines)}
		if _, err := s.settle(c, sc, actor, plan, false); err != nil {
			return nil, err
		}
		return map[string]any{}, nil
	})
}

func (s Service) UseMagicItems(c context.Context, actor identity.ActorContext, items []ItemAmount, op operation.Context) (map[string]any, error) {
	amounts, err := aggregateItems(items)
	if err != nil {
		return nil, err
	}
	return s.execute(c, actor, op, "item_use", map[string]any{"items": items}, func(c context.Context, sc gen.TimedScope, catalog d.Catalog) (map[string]any, error) {
		cost := appi5.MaterialCost{}
		lines := []grant.Line{}
		for _, aggregate := range amounts {
			item, err := catalog.Item(aggregate.ItemID)
			if err != nil {
				return nil, err
			}
			grants, err := d.MagicItemGrants(item, aggregate.Num)
			if err != nil {
				return nil, err
			}
			cost.Stacks = append(cost.Stacks, appi5.StackMaterialCost{ItemID: aggregate.ItemID, Amount: aggregate.Num})
			lines = append(lines, grants...)
		}
		plan := exchangePlan{cost: cost, restoration: rewardPlan(actor.PlayerID, "item_use", sc.Operation.Operation(), mergeScalarLines(lines))}
		if _, err := s.settle(c, sc, actor, plan, false); err != nil {
			return nil, err
		}
		return map[string]any{}, nil
	})
}

// EnergyBuy answers MID 97: one crystal-funded stamina purchase.
func (s Service) EnergyBuy(c context.Context, actor identity.ActorContext, op operation.Context) (map[string]any, error) {
	return s.execute(c, actor, op, "energy_buy", map[string]any{}, func(c context.Context, sc gen.TimedScope, catalog d.Catalog) (map[string]any, error) {
		privilege, err := s.snapshot(c, sc, actor.PlayerID, sc.Operation.DecisionAt())
		if err != nil {
			return nil, err
		}
		allowance, err := catalog.EnergyBuyAllowance(privilege.VIPLevel, privilege.MonthlyPrivilegeActive)
		if err != nil {
			return nil, err
		}
		counters, err := s.Counters.IncrementBuyTx(c, sc.Tx, actor.PlayerID, s.day(sc), appconsume.CounterBuyEnergy, allowance, sc.Operation.DecisionAt())
		if errors.Is(err, appconsume.ErrRefused) {
			return nil, d.ErrRefused
		}
		if err != nil {
			return nil, err
		}
		ordinal := counters.Energy
		cost, err := catalog.EnergyBuyCost(ordinal)
		if err != nil {
			return nil, err
		}
		gain, err := catalog.EnergyBuyGrant()
		if err != nil {
			return nil, err
		}
		plan := exchangePlan{
			cost:        appi5.MaterialCost{Scalars: []appi5.ScalarMaterialCost{{ResourceKey: "crystal", Amount: cost}}},
			restoration: rewardPlan(actor.PlayerID, "energy_buy", sc.Operation.Operation(), []grant.Line{{Kind: grant.Temporal, ResourceKey: "energy", Amount: gain}}),
		}
		prepared, err := s.Exchange.PrepareItemsEnergyExchangeTx(c, sc.Tx, actor, appi5.ItemsEnergyExchangeRequest{Cost: plan.cost, Restoration: plan.restoration}, sc.Operation.Operation())
		if err != nil {
			return nil, err
		}
		if err = s.refuseAtEnergyCap(c, sc, catalog, actor.PlayerID); err != nil {
			return nil, err
		}
		applied, err := s.Exchange.ApplyItemsEnergyExchangeTx(c, sc.Tx, prepared)
		if err != nil {
			return nil, err
		}
		recordDebit(c, applied.Debit)
		if err = s.recordRestoration(c, sc, actor.PlayerID, applied.Restoration); err != nil {
			return nil, err
		}
		energy, err := s.temporal(c, sc, actor.PlayerID, "energy")
		if err != nil {
			return nil, err
		}
		return map[string]any{"energy": energy, "buy_energy_times": ordinal}, nil
	})
}

func (s Service) refuseAtEnergyCap(c context.Context, sc gen.TimedScope, catalog d.Catalog, pid identity.PlayerID) error {
	cap, err := catalog.EnergyCap()
	if err != nil {
		return err
	}
	energy, err := s.temporal(c, sc, pid, "energy")
	if err != nil {
		return err
	}
	if energy >= cap {
		return ErrEnergyCap
	}
	return nil
}

// GoldenHand answers MID 96.
func (s Service) GoldenHand(c context.Context, actor identity.ActorContext, op operation.Context) (map[string]any, error) {
	return s.goldenHand(c, actor, op, "golden_hand", 1, appconsume.CounterBuyMana, false)
}

// TenfoldGoldenHand answers MID 29 consume_id 1.
func (s Service) TenfoldGoldenHand(c context.Context, actor identity.ActorContext, op operation.Context) (map[string]any, error) {
	return s.goldenHand(c, actor, op, "golden_hand", 10, 0, true)
}

func (s Service) goldenHand(c context.Context, actor identity.ActorContext, op operation.Context, name string, multiplier int64, counterID int64, tenfold bool) (map[string]any, error) {
	if !s.factsReady() {
		return nil, d.ErrUnavailable
	}
	request := map[string]any{}
	if tenfold {
		request["consume_id"] = int64(1)
	}
	return s.execute(c, actor, op, name, request, func(c context.Context, sc gen.TimedScope, catalog d.Catalog) (map[string]any, error) {
		level, err := s.level(c, sc, actor.PlayerID)
		if err != nil {
			return nil, err
		}
		var ordinal int64
		var counters appconsume.BuyCounters
		if tenfold {
			used, err := s.Counters.IncrementDailyTx(c, sc.Tx, actor.PlayerID, s.day(sc), 1, 1, sc.Operation.DecisionAt())
			if errors.Is(err, appconsume.ErrRefused) {
				return nil, d.ErrRefused
			}
			if err != nil {
				return nil, err
			}
			_ = used
			counters, err = s.Counters.ReadBuyTx(c, sc.Tx, actor.PlayerID, s.day(sc))
			if err != nil {
				return nil, err
			}
			ordinal = d.BuyOrdinal(counters.Mana)
		} else {
			privilege, err := s.snapshot(c, sc, actor.PlayerID, sc.Operation.DecisionAt())
			if err != nil {
				return nil, err
			}
			allowance, err := catalog.MidasAllowance(privilege.VIPLevel, privilege.MonthlyPrivilegeActive)
			if err != nil {
				return nil, err
			}
			counters, err = s.Counters.IncrementBuyTx(c, sc.Tx, actor.PlayerID, s.day(sc), counterID, allowance, sc.Operation.DecisionAt())
			if errors.Is(err, appconsume.ErrRefused) {
				return nil, d.ErrRefused
			}
			if err != nil {
				return nil, err
			}
			ordinal = counters.Mana
		}
		stream := combat.NewStream(sc.Operation.Operation().Derive(goldenHandEntropyLabel, 0))
		mana, crit, cost, err := catalog.MidasMana(level, ordinal, multiplier, stream)
		if err != nil {
			return nil, err
		}
		if tenfold {
			cost, err = catalog.TenfoldCost(ordinal)
			if err != nil {
				return nil, err
			}
		}
		plan := exchangePlan{
			cost:        appi5.MaterialCost{Scalars: []appi5.ScalarMaterialCost{{ResourceKey: "crystal", Amount: cost}}},
			restoration: rewardPlan(actor.PlayerID, name, sc.Operation.Operation(), []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "mana", Amount: mana}}),
		}
		if _, err = s.settle(c, sc, actor, plan, false); err != nil {
			return nil, err
		}
		if err = s.Facts.RecordTx(c, sc.Tx, sc.Operation.Operation(), objective.Fact{PlayerID: actor.PlayerID, SourceDomain: "items-energy", SourceBusinessKey: sc.Operation.Operation().ID.String(), Kind: "GOLDEN_HAND_USED", Delta: 1}); err != nil {
			return nil, err
		}
		balance, err := s.scalar(c, sc, actor.PlayerID, "mana")
		if err != nil {
			return nil, err
		}
		if tenfold {
			return map[string]any{"cost": cost, "crit": crit, "mana": balance, "fumo": map[string]any{}, "trial_info": map[string]any{"left_times": int64(0)}}, nil
		}
		return map[string]any{"cost": cost, "crit": crit, "mana": balance, "buy_mana_times": counters.Mana}, nil
	})
}

func (s Service) factsReady() bool {
	return s.Facts.Open != nil && s.Facts.Owner.Store != nil && s.Facts.Owner.Receipts != nil
}

func aggregateItems(items []ItemAmount) ([]ItemAmount, error) {
	if len(items) == 0 {
		return nil, d.ErrInvalid
	}
	byID := map[int64]int64{}
	order := make([]int64, 0, len(items))
	for _, item := range items {
		if item.ItemID <= 0 || item.Num <= 0 {
			return nil, d.ErrInvalid
		}
		if _, exists := byID[item.ItemID]; !exists {
			order = append(order, item.ItemID)
		}
		byID[item.ItemID] += item.Num
	}
	if len(byID) > maxBatchItems {
		return nil, d.ErrInvalid
	}
	out := make([]ItemAmount, 0, len(order))
	for _, itemID := range order {
		out = append(out, ItemAmount{ItemID: itemID, Num: byID[itemID]})
	}
	return out, nil
}

func mergeScalarLines(lines []grant.Line) []grant.Line {
	amounts := map[string]int64{}
	keys := make([]string, 0, len(lines))
	for _, line := range lines {
		if _, exists := amounts[line.ResourceKey]; !exists {
			keys = append(keys, line.ResourceKey)
		}
		amounts[line.ResourceKey] += line.Amount
	}
	sort.Strings(keys)
	out := make([]grant.Line, 0, len(keys))
	for _, key := range keys {
		out = append(out, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: key, Amount: amounts[key]})
	}
	return out
}
