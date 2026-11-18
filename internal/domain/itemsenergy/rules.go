package itemsenergy

import (
	"math"

	"gxb.local/backend/v2/internal/domain/grant"
)

// SellUnitPrice is the stock rule: mana when positive, else crystal when
// positive (SellDetailWindow.lua:65-85). An entity or zero-stack row and a
// zero-price row are not sellable.
func SellUnitPrice(item Item) (string, int64, bool) {
	if item.Type == -1 || item.Stack <= 0 {
		return "", 0, false
	}
	if item.Mana > 0 {
		return "mana", item.Mana, true
	}
	if item.Crystal > 0 {
		return "crystal", item.Crystal, true
	}
	return "", 0, false
}

// EnergyItemGain accepts only stock energy items: type 4, sub_type 5, energy > 0.
func EnergyItemGain(item Item, num int64) (int64, error) {
	if num <= 0 || item.Type != 4 || item.SubType != 5 || item.Energy <= 0 {
		return 0, ErrRefused
	}
	return item.Energy * num, nil
}

// MagicItemGrants converts a sub_type 12 item into the positive magic scalars
// of its row, multiplied by num.
func MagicItemGrants(item Item, num int64) ([]grant.Line, error) {
	if num <= 0 || item.SubType != 12 {
		return nil, ErrRefused
	}
	lines := make([]grant.Line, 0, 3)
	for _, field := range []struct {
		key    string
		amount int64
	}{{"magic_energy", item.MagicEnergy}, {"magic_dust", item.MagicDust}, {"magic_liquid", item.MagicLiquid}} {
		if field.amount > 0 {
			lines = append(lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: field.key, Amount: field.amount * num})
		}
	}
	if len(lines) == 0 {
		return nil, ErrRefused
	}
	return lines, nil
}

// BuyOrdinal is the stock one-based purchase ordinal.
func BuyOrdinal(used int64) int64 { return used + 1 }

// MidasAllowance is VIP num_midas plus the active monthly privilege.
func (c Catalog) MidasAllowance(vipLevel int64, monthlyActive bool) (int64, error) {
	vip, ok := c.VIP[vipLevel]
	if !ok {
		return 0, ErrRefused
	}
	allowance := vip.NumMidas
	if monthlyActive {
		allowance += c.Monthly.NumMidas
	}
	return allowance, nil
}

// EnergyBuyAllowance is VIP num_energy plus the active monthly privilege.
func (c Catalog) EnergyBuyAllowance(vipLevel int64, monthlyActive bool) (int64, error) {
	vip, ok := c.VIP[vipLevel]
	if !ok {
		return 0, ErrRefused
	}
	allowance := vip.NumEnergy
	if monthlyActive {
		allowance += c.Monthly.NumEnergy
	}
	return allowance, nil
}

// MidasSingleBase is (midas_base + level * midas_lv_increase) * buy_mana_ratio.
func (c Catalog) MidasSingleBase(level, ordinal int64) (float64, error) {
	cost, ok := c.Refresh(ordinal)
	if !ok {
		return 0, ErrRefused
	}
	base := c.Misc.MidasBase + level*c.Misc.MidasLevelIncrease
	return float64(base) * float64(cost.BuyManaRatioMillionths) / 1000000, nil
}

// MidasCost is buy_mana_cost(ordinal).
func (c Catalog) MidasCost(ordinal int64) (int64, error) {
	cost, ok := c.Refresh(ordinal)
	if !ok || cost.BuyManaCost <= 0 {
		return 0, ErrRefused
	}
	return cost.BuyManaCost, nil
}

// EnergyBuyCost is buy_energy_cost(ordinal).
func (c Catalog) EnergyBuyCost(ordinal int64) (int64, error) {
	cost, ok := c.Refresh(ordinal)
	if !ok || cost.BuyEnergyCost <= 0 {
		return 0, ErrRefused
	}
	return cost.BuyEnergyCost, nil
}

// EnergyBuyGrant is misc.buy_energy_num.
func (c Catalog) EnergyBuyGrant() (int64, error) {
	if c.Misc.BuyEnergyNum <= 0 {
		return 0, ErrRefused
	}
	return c.Misc.BuyEnergyNum, nil
}

// EnergyCap is the stock client's buy/use ceiling (misc.energy_max_limit).
func (c Catalog) EnergyCap() (int64, error) {
	if c.Misc.EnergyMaxLimit <= 0 {
		return 0, ErrRefused
	}
	return c.Misc.EnergyMaxLimit, nil
}

type UniformSource interface{ Uniform(uint64) uint64 }

// MidasCrit selects one weighted crit multiplier from midas_crit_type/rate.
func (c Catalog) MidasCrit(stream UniformSource) (int64, error) {
	total := int64(0)
	for _, rate := range c.Misc.MidasCritRates {
		total += rate
	}
	if total <= 0 {
		return 0, ErrRefused
	}
	roll := int64(stream.Uniform(uint64(total)))
	for index, rate := range c.Misc.MidasCritRates {
		if roll < rate {
			return c.Misc.MidasCritTypes[index], nil
		}
		roll -= rate
	}
	return 0, ErrRefused
}

// MidasMana is the contract's one-ceil pipeline: base * multiplier * (1+float) * crit.
func (c Catalog) MidasMana(level, ordinal, multiplier int64, stream UniformSource) (int64, int64, int64, error) {
	if multiplier <= 0 {
		return 0, 0, 0, ErrRefused
	}
	cost, err := c.MidasCost(ordinal)
	if err != nil {
		return 0, 0, 0, err
	}
	base, err := c.MidasSingleBase(level, ordinal)
	if err != nil {
		return 0, 0, 0, err
	}
	crit, err := c.MidasCrit(stream)
	if err != nil {
		return 0, 0, 0, err
	}
	floatUp := float64(c.Misc.MidasFloatUpBasisPoints) / 10000
	floatDown := float64(c.Misc.MidasFloatDownBasisPoints) / 10000
	fraction := float64(stream.Uniform(1<<53)) / float64(1<<53)
	floated := floatDown + fraction*(floatUp-floatDown)
	amount := int64(math.Ceil(base * float64(multiplier) * (1 + floated) * float64(crit)))
	if amount <= 0 {
		return 0, 0, 0, ErrRefused
	}
	return amount, crit, cost, nil
}

// TenfoldCost adds daily_consume[1].cost to the ordinary mana-buy cost. The
// tenfold never advances buy_mana_times.
func (c Catalog) TenfoldCost(ordinal int64) (int64, error) {
	cost, err := c.MidasCost(ordinal)
	if err != nil {
		return 0, err
	}
	rule, ok := c.DailyConsume[1]
	if !ok || rule.Cost < 0 || rule.Num != 1 {
		return 0, ErrRefused
	}
	return cost + rule.Cost, nil
}
