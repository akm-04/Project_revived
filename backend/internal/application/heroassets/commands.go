package heroassets

import (
	"context"
	"math"

	appconsume "gxb.local/backend/v2/internal/application/dailyconsume"
	gen "gxb.local/backend/v2/internal/application/generation"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	d "gxb.local/backend/v2/internal/domain/heroassets"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/itemsenergy"
	"gxb.local/backend/v2/internal/foundation/operation"
)

// SkillPointBuy answers MID 99: one crystal-funded purchase of ten skill
// points, allowed above the natural cap. The ordinal is today's buy_skill_times
// plus one and the price comes from refresh_cost.buy_skill_cost.
func (s Service) SkillPointBuy(c context.Context, actor identity.ActorContext, op operation.Context) (map[string]any, error) {
	return s.execute(c, actor, op, "skill_point_buy", map[string]any{}, func(c context.Context, sc gen.TimedScope, catalog itemsenergy.Catalog) (map[string]any, error) {
		privilege, err := s.Privileges.SnapshotTx(c, sc.Tx, actor.PlayerID, sc.Operation.DecisionAt())
		if err != nil {
			return nil, err
		}
		allowed, err := d.SkillBuyAllowed(catalog, privilege.VIPLevel)
		if err != nil {
			return nil, err
		}
		if !allowed {
			return nil, d.ErrVipRequired
		}
		locked, before, err := s.Counters.LockBuyTx(c, sc.Tx, actor.PlayerID, s.day(sc), sc.Operation.DecisionAt())
		if err != nil {
			return nil, err
		}
		ordinal := d.BuyOrdinal(before.Skill)
		cost, err := d.SkillPointBuyCost(catalog, ordinal)
		if err != nil {
			return nil, err
		}
		exchange := appi5.ItemsEnergyExchangeRequest{
			Cost:        appi5.MaterialCost{Scalars: []appi5.ScalarMaterialCost{{ResourceKey: "crystal", Amount: cost}}},
			Restoration: rewardPlan(actor.PlayerID, "skill_point_buy", sc.Operation.Operation(), d.BuySkillPointGrant),
		}
		prepared, err := s.Exchange.PrepareItemsEnergyExchangeTx(c, sc.Tx, actor, exchange, sc.Operation.Operation())
		if err != nil {
			return nil, err
		}
		counters, err := s.Counters.AdvanceBuyTx(c, sc.Tx, actor.PlayerID, locked, appconsume.CounterBuySkill, math.MaxInt64)
		if err != nil {
			return nil, err
		}
		if _, err = s.Exchange.ApplyItemsEnergyExchangeTx(c, sc.Tx, prepared); err != nil {
			return nil, err
		}
		points, skillTime, err := s.skillPoint(c, sc.Tx, actor.PlayerID)
		if err != nil {
			return nil, err
		}
		crystal, err := s.scalar(c, sc.Tx, actor.PlayerID, "crystal")
		if err != nil {
			return nil, err
		}
		recordBalances(c, crystal, points)
		return map[string]any{"buy_skill_times": counters.Skill, "skill_point": points, "skill_time": skillTime}, nil
	})
}

// UseSkillPointItem answers MID 90: consume the pinned skill-point item stack
// and grant its skill points in one exchange, allowed above the natural cap.
func (s Service) UseSkillPointItem(c context.Context, actor identity.ActorContext, itemID, num int64, op operation.Context) (map[string]any, error) {
	return s.execute(c, actor, op, "skill_point_item", map[string]any{"item_id": itemID, "item_num": num}, func(c context.Context, sc gen.TimedScope, catalog itemsenergy.Catalog) (map[string]any, error) {
		amount, err := d.SkillPointItemGain(catalog, itemID, num)
		if err != nil {
			return nil, err
		}
		if err = s.requireStack(c, sc, actor.PlayerID, itemID, num); err != nil {
			return nil, err
		}
		exchange := appi5.ItemsEnergyExchangeRequest{
			Cost:        appi5.MaterialCost{Stacks: []appi5.StackMaterialCost{{ItemID: itemID, Amount: num}}},
			Restoration: rewardPlan(actor.PlayerID, "skill_point_item", sc.Operation.Operation(), amount),
		}
		prepared, err := s.Exchange.PrepareItemsEnergyExchangeTx(c, sc.Tx, actor, exchange, sc.Operation.Operation())
		if err != nil {
			return nil, err
		}
		if _, err = s.Exchange.ApplyItemsEnergyExchangeTx(c, sc.Tx, prepared); err != nil {
			return nil, err
		}
		points, skillTime, err := s.skillPoint(c, sc.Tx, actor.PlayerID)
		if err != nil {
			return nil, err
		}
		crystal, err := s.scalar(c, sc.Tx, actor.PlayerID, "crystal")
		if err != nil {
			return nil, err
		}
		recordBalances(c, crystal, points)
		return map[string]any{"skill_point": points, "skill_time": skillTime}, nil
	})
}
