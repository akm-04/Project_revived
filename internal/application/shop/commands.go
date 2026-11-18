package shop

import (
	"context"
	"sort"

	gen "gxb.local/backend/v2/internal/application/generation"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/shop"
	"gxb.local/backend/v2/internal/foundation/operation"
)

const maxMultiBuySlots = 200

type BuyRequest struct {
	ShopType    int64
	Index       int64
	ClientPrice *int64
}

type MultiBuyRequest struct {
	ShopType     int64
	List         []int64
	ClientPrices []int64
}

type RefreshRequest struct {
	ShopType int64
}

// LoadShop answers MID 32. It generates this player's missing or scheduled
// generation, which is player state, and never advances shared time state.
func (s Service) LoadShop(c context.Context, actor identity.ActorContext, shopType int64, op operation.Context) (map[string]any, error) {
	return s.run(c, actor, op, false, func(c context.Context, sc gen.TimedScope, catalog d.Catalog) (map[string]any, error) {
		shop, err := s.requireShop(c, sc, catalog, actor.PlayerID, shopType)
		if err != nil {
			return nil, err
		}
		row, insert, changed, err := s.state(c, sc, catalog, shop, actor.PlayerID)
		if err != nil {
			return nil, err
		}
		if insert || changed {
			if err = s.save(c, sc, row, insert); err != nil {
				return nil, err
			}
		}
		return s.info(c, sc, catalog, shop, row, actor.PlayerID)
	})
}

// List answers MID 37 with exactly the served shops this player may open.
func (s Service) List(c context.Context, actor identity.ActorContext, op operation.Context) (map[string]any, error) {
	return s.run(c, actor, op, true, func(c context.Context, sc gen.TimedScope, catalog d.Catalog) (map[string]any, error) {
		list := make([]int64, 0, len(catalog.Shops))
		for _, shop := range catalog.Shops {
			eligible, err := s.available(c, sc, actor.PlayerID, shop)
			if err != nil {
				return nil, err
			}
			if eligible {
				list = append(list, shop.Type)
			}
		}
		sort.Slice(list, func(i, j int) bool { return list[i] < list[j] })
		return map[string]any{"list": list}, nil
	})
}

// CloseShop answers MID 38. No temporary merchant spawn exists in 11C, so an
// open temporary shop can never be closed here (C11).
func (s Service) CloseShop(c context.Context, actor identity.ActorContext, shopType int64, op operation.Context) (map[string]any, error) {
	return s.run(c, actor, op, true, func(c context.Context, sc gen.TimedScope, catalog d.Catalog) (map[string]any, error) {
		if _, ok := catalog.Shop(shopType); !ok {
			return nil, d.ErrRefused
		}
		return map[string]any{}, nil
	})
}

// Buy answers MID 33.
func (s Service) Buy(c context.Context, actor identity.ActorContext, request BuyRequest, op operation.Context) (map[string]any, error) {
	raw := map[string]any{"shop_type": request.ShopType, "index": request.Index}
	if request.ClientPrice != nil {
		raw["client_price"] = *request.ClientPrice
	}
	return s.execute(c, actor, op, "buy", raw, func(c context.Context, sc gen.TimedScope, catalog d.Catalog) (map[string]any, error) {
		shop, err := s.requireShop(c, sc, catalog, actor.PlayerID, request.ShopType)
		if err != nil {
			return nil, err
		}
		row, insert, _, err := s.state(c, sc, catalog, shop, actor.PlayerID)
		if err != nil {
			return nil, err
		}
		stored, found := row.FindSlot(request.Index)
		if !found {
			return nil, d.ErrRefused
		}
		slot, disabled := catalog.TunedSlot(shop.Type, stored)
		if disabled || stored.IsBuy != 0 {
			return nil, d.ErrRefused
		}
		price, err := s.priceFor(c, sc, catalog, shop, slot, actor.PlayerID)
		if err != nil {
			return nil, err
		}
		if err = s.checkClientPrice(shop.Type, price, request.ClientPrice); err != nil {
			return nil, err
		}
		cost, err := s.buyCost(c, sc, catalog, slot, price, actor.PlayerID)
		if err != nil {
			return nil, err
		}
		plan := s.rewardPlan(actor.PlayerID, "buy", sc.Operation.Operation(), []grant.Line{{Kind: grant.StackItem, ItemID: slot.ItemID, Amount: slot.ItemNum}})
		prepared, err := s.Exchange.PrepareItemsEnergyExchangeTx(c, sc.Tx, actor, appi5.ItemsEnergyExchangeRequest{Cost: cost, Restoration: plan}, sc.Operation.Operation())
		if err != nil {
			return nil, err
		}
		setBought(&row, request.Index)
		applied, err := s.Exchange.ApplyItemsEnergyExchangeTx(c, sc.Tx, prepared)
		if err != nil {
			return nil, err
		}
		if err = s.record(c, sc, actor.PlayerID, applied); err != nil {
			return nil, err
		}
		if err = s.save(c, sc, row, insert); err != nil {
			return nil, err
		}
		return map[string]any{"shop_type": shop.Type, "index": request.Index, "isbuy": int64(1), "isBuy": int64(1), "buy_times": int64(1)}, nil
	})
}

// MultiBuy answers MID 2982: every selected slot or none, one purchase per slot.
func (s Service) MultiBuy(c context.Context, actor identity.ActorContext, request MultiBuyRequest, op operation.Context) (map[string]any, error) {
	if len(request.List) == 0 || len(request.List) > maxMultiBuySlots {
		return nil, d.ErrInvalid
	}
	seen := map[int64]struct{}{}
	for _, index := range request.List {
		if index <= 0 {
			return nil, d.ErrInvalid
		}
		if _, duplicate := seen[index]; duplicate {
			return nil, d.ErrInvalid
		}
		seen[index] = struct{}{}
	}
	raw := map[string]any{"shop_type": request.ShopType, "list": request.List, "client_prices": request.ClientPrices}
	return s.execute(c, actor, op, "multi_buy", raw, func(c context.Context, sc gen.TimedScope, catalog d.Catalog) (map[string]any, error) {
		shop, err := s.requireShop(c, sc, catalog, actor.PlayerID, request.ShopType)
		if err != nil {
			return nil, err
		}
		row, insert, _, err := s.state(c, sc, catalog, shop, actor.PlayerID)
		if err != nil {
			return nil, err
		}
		var cost appi5.MaterialCost
		var lines []grant.Line
		scalars := map[string]int64{}
		stacks := map[int64]int64{}
		for position, index := range request.List {
			stored, found := row.FindSlot(index)
			if !found {
				return nil, d.ErrRefused
			}
			slot, disabled := catalog.TunedSlot(shop.Type, stored)
			if disabled || stored.IsBuy != 0 {
				return nil, d.ErrRefused
			}
			price, err := s.priceFor(c, sc, catalog, shop, slot, actor.PlayerID)
			if err != nil {
				return nil, err
			}
			var clientPrice *int64
			if position < len(request.ClientPrices) {
				value := request.ClientPrices[position]
				clientPrice = &value
			}
			if err = s.checkClientPrice(shop.Type, price, clientPrice); err != nil {
				return nil, err
			}
			if err = s.addCost(c, sc, catalog, slot, price, actor.PlayerID, scalars, stacks); err != nil {
				return nil, err
			}
			lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: slot.ItemID, Amount: slot.ItemNum})
		}
		cost.Scalars = scalarCosts(scalars)
		cost.Stacks = stackCosts(stacks)
		plan := s.rewardPlan(actor.PlayerID, "multi_buy", sc.Operation.Operation(), lines)
		prepared, err := s.Exchange.PrepareItemsEnergyExchangeTx(c, sc.Tx, actor, appi5.ItemsEnergyExchangeRequest{Cost: cost, Restoration: plan}, sc.Operation.Operation())
		if err != nil {
			return nil, err
		}
		for _, index := range request.List {
			setBought(&row, index)
		}
		applied, err := s.Exchange.ApplyItemsEnergyExchangeTx(c, sc.Tx, prepared)
		if err != nil {
			return nil, err
		}
		if err = s.record(c, sc, actor.PlayerID, applied); err != nil {
			return nil, err
		}
		if err = s.save(c, sc, row, insert); err != nil {
			return nil, err
		}
		isBuy := make([]int64, len(request.List))
		buyTimes := make([]int64, len(request.List))
		for position := range request.List {
			isBuy[position] = 1
			buyTimes[position] = 1
		}
		return map[string]any{"shop_type": shop.Type, "list": request.List, "isbuy": isBuy, "buy_times": buyTimes}, nil
	})
}

// Refresh answers MID 34: charge the ladder, increment, reroll and reply with
// the MID 32 shape.
func (s Service) Refresh(c context.Context, actor identity.ActorContext, request RefreshRequest, op operation.Context) (map[string]any, error) {
	return s.execute(c, actor, op, "refresh", map[string]any{"shop_type": request.ShopType}, func(c context.Context, sc gen.TimedScope, catalog d.Catalog) (map[string]any, error) {
		shop, err := s.requireShop(c, sc, catalog, actor.PlayerID, request.ShopType)
		if err != nil {
			return nil, err
		}
		if !shop.AllowsManualRefresh() {
			return nil, d.ErrRefused
		}
		row, insert, _, err := s.state(c, sc, catalog, shop, actor.PlayerID)
		if err != nil {
			return nil, err
		}
		times := row.EffectiveRefreshTimes(s.day(sc))
		cost, ok := catalog.RefreshCostAt(shop, times)
		if !ok {
			return nil, d.ErrRefused
		}
		var prepared *appi5.PreparedMaterialDebit
		if cost > 0 {
			charge, err := s.refreshCharge(shop, cost)
			if err != nil {
				return nil, err
			}
			prepared, err = s.Debiter.PrepareMaterialDebitTx(c, sc.Tx, actor.PlayerID, charge, sc.Operation.Operation())
			if err != nil {
				return nil, err
			}
		}
		if err = s.regenerate(c, sc, catalog, shop, &row, row.Generation+1); err != nil {
			return nil, err
		}
		row.RefreshTimes = times + 1
		row.RefreshDay = s.day(sc)
		if prepared != nil {
			debit, err := s.Debiter.ApplyMaterialDebitTx(c, sc.Tx, prepared)
			if err != nil {
				return nil, err
			}
			recordDebit(c, debit)
		}
		if err = s.save(c, sc, row, insert); err != nil {
			return nil, err
		}
		return s.info(c, sc, catalog, shop, row, actor.PlayerID)
	})
}

func (s Service) requireShop(c context.Context, sc gen.TimedScope, catalog d.Catalog, pid identity.PlayerID, shopType int64) (d.Shop, error) {
	shop, ok := catalog.Shop(shopType)
	if !ok {
		return d.Shop{}, d.ErrRefused
	}
	eligible, err := s.available(c, sc, pid, shop)
	if err != nil {
		return d.Shop{}, err
	}
	if !eligible {
		return d.Shop{}, d.ErrRefused
	}
	return shop, nil
}

func (s Service) info(c context.Context, sc gen.TimedScope, catalog d.Catalog, shop d.Shop, row d.Row, pid identity.PlayerID) (map[string]any, error) {
	monthCard, err := s.monthCard(c, sc, pid, shop.Type)
	if err != nil {
		return nil, err
	}
	items := make([]any, 0, len(row.Stock.Slots))
	for _, stored := range row.Stock.Slots {
		slot, disabled := catalog.TunedSlot(shop.Type, stored)
		if disabled {
			slot.IsBuy = 1
		}
		price, err := catalog.Price(slot, shop.Type, monthCard)
		if err != nil {
			return nil, err
		}
		slot.SellPrice = price
		item := map[string]any{
			"index": slot.Index, "item_id": slot.ItemID, "item_num": slot.ItemNum,
			"sell_type": slot.SellType, "sell_price": slot.SellPrice, "discount": slot.Discount,
			"isbuy": slot.IsBuy, "buy_times": slot.BuyTimes,
		}
		if slot.StoneID > 0 {
			item["stone_id"] = slot.StoneID
		}
		items = append(items, item)
	}
	return map[string]any{
		"shop_type": shop.Type, "refresh_times": row.EffectiveRefreshTimes(s.day(sc)),
		"open_time": int64(0), "is_open": int64(1), "count_down": int64(0), "items": items,
		"hot_hero": int64(0), "cost_stone": []any{}, "is_awarded": []any{},
	}, nil
}

func (s Service) priceFor(c context.Context, sc gen.TimedScope, catalog d.Catalog, shop d.Shop, slot d.StockSlot, pid identity.PlayerID) (int64, error) {
	monthCard, err := s.monthCard(c, sc, pid, shop.Type)
	if err != nil {
		return 0, err
	}
	price, err := catalog.Price(slot, shop.Type, monthCard)
	if err != nil || price <= 0 {
		return 0, d.ErrRefused
	}
	return price, nil
}

func (s Service) checkClientPrice(shopType, price int64, clientPrice *int64) error {
	if clientPrice == nil || shopType != 13 {
		return nil
	}
	switch {
	case *clientPrice == price:
		return nil
	case *clientPrice < price:
		return d.ErrPriceExpired
	default:
		return d.ErrPriceDiscount
	}
}

func (s Service) buyCost(c context.Context, sc gen.TimedScope, catalog d.Catalog, slot d.StockSlot, price int64, pid identity.PlayerID) (appi5.MaterialCost, error) {
	scalars := map[string]int64{}
	stacks := map[int64]int64{}
	if err := s.addCost(c, sc, catalog, slot, price, pid, scalars, stacks); err != nil {
		return appi5.MaterialCost{}, err
	}
	return appi5.MaterialCost{Scalars: scalarCosts(scalars), Stacks: stackCosts(stacks)}, nil
}

// addCost adds one slot's authoritative debit. A stone price debits the
// substitute voucher first, else the frozen stone (C5).
func (s Service) addCost(c context.Context, sc gen.TimedScope, catalog d.Catalog, slot d.StockSlot, price int64, pid identity.PlayerID, scalars map[string]int64, stacks map[int64]int64) error {
	sellType := d.SellType(slot.SellType)
	if key, ok := sellType.ScalarKey(); ok {
		if sellType == d.SellSummonCoin {
			// No summon_coin source or catalog row exists in this build (C13).
			return d.ErrRefused
		}
		if amount, err := s.scalarBalance(c, sc, pid, key); err != nil {
			return err
		} else if amount < price {
			return economy.InsufficientBalance(key)
		}
		scalars[key] += price
		return nil
	}
	switch sellType {
	case d.SellStone:
		voucher := catalog.Tunables.StoneCurrencyItem
		available, err := s.stack(c, sc, pid, voucher)
		if err != nil {
			return err
		}
		if available >= price {
			stacks[voucher] += price
			return nil
		}
		if slot.StoneID > 0 && slot.StoneID != voucher {
			if amount, err := s.stack(c, sc, pid, slot.StoneID); err == nil && amount >= price {
				stacks[slot.StoneID] += price
				return nil
			}
		}
		return d.ErrRefused
	case d.SellPetStone:
		// The pet-stone currency is not named by the client data (UNKNOWN).
		return d.ErrRefused
	case d.SellCube:
		cube := catalog.Tunables.CubeCurrencyItem
		available, err := s.stack(c, sc, pid, cube)
		if err != nil {
			return err
		}
		if available < price {
			return d.ErrRefused
		}
		stacks[cube] += price
		return nil
	}
	return d.ErrRefused
}

func scalarCosts(values map[string]int64) []appi5.ScalarMaterialCost {
	keys := make([]string, 0, len(values))
	for key := range values {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	out := make([]appi5.ScalarMaterialCost, 0, len(keys))
	for _, key := range keys {
		out = append(out, appi5.ScalarMaterialCost{ResourceKey: key, Amount: values[key]})
	}
	return out
}

func stackCosts(values map[int64]int64) []appi5.StackMaterialCost {
	ids := make([]int64, 0, len(values))
	for itemID := range values {
		ids = append(ids, itemID)
	}
	sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
	out := make([]appi5.StackMaterialCost, 0, len(ids))
	for _, itemID := range ids {
		out = append(out, appi5.StackMaterialCost{ItemID: itemID, Amount: values[itemID]})
	}
	return out
}

func (s Service) refreshCharge(shop d.Shop, cost int64) (appi5.MaterialCost, error) {
	key, ok := refreshCurrency(shop)
	if !ok {
		return appi5.MaterialCost{}, d.ErrRefused
	}
	return appi5.MaterialCost{Scalars: []appi5.ScalarMaterialCost{{ResourceKey: key, Amount: cost}}}, nil
}

func refreshCurrency(shop d.Shop) (string, bool) {
	if shop.Team {
		return "team_dungeon_coin", true
	}
	if shop.RefreshType == 2 {
		return "crystal", true
	}
	switch shop.Type {
	case 2:
		return "arena_coin", true
	case 3:
		return "march_coin", true
	case 6:
		return "top_coin", true
	case 7:
		return "guild_coin", true
	case 9:
		return "region_coin", true
	case 12:
		return "paradise_coin", true
	case 14:
		return "friend_medal", true
	}
	return "crystal", true
}

func setBought(row *d.Row, index int64) {
	for position := range row.Stock.Slots {
		if row.Stock.Slots[position].Index == index {
			row.Stock.Slots[position].IsBuy = 1
			row.Stock.Slots[position].BuyTimes = 1
			return
		}
	}
}

func (s Service) scalarBalance(c context.Context, sc gen.TimedScope, pid identity.PlayerID, key string) (int64, error) {
	state, exists, err := s.Balances.ReadScalarTx(c, sc.Tx, pid, key)
	if err != nil {
		return 0, err
	}
	if !exists {
		return 0, nil
	}
	return state.Amount, nil
}
