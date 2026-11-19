package itemsenergy

import (
	"errors"
	"strconv"
)

// Tuning is the D476 operator overlay (items_energy_tuning, one row). Zero or
// empty fields keep the source value; an invalid overlay is rejected whole.
type Tuning struct {
	Version                   int64   `json:"version"`
	BuyEnergyNum              int64   `json:"buy_energy_num"`
	EnergyMaxLimit            int64   `json:"energy_max_limit"`
	MidasBase                 int64   `json:"midas_base"`
	MidasLevelIncrease        int64   `json:"midas_lv_increase"`
	MidasFloatUpBasisPoints   int64   `json:"midas_float_up"`
	MidasFloatDownBasisPoints int64   `json:"midas_float_down"`
	MidasCritTypes            []int64 `json:"midas_crit_type"`
	MidasCritRates            []int64 `json:"midas_crit_rate"`
	// BuyManaCost, BuyEnergyCost and BuySkillCost replace ordinals 1..N; a
	// shorter ladder leaves the remaining source ordinals unchanged.
	BuyManaCost   []int64 `json:"buy_mana_cost"`
	BuyEnergyCost []int64 `json:"buy_energy_cost"`
	BuySkillCost  []int64 `json:"buy_skill_cost"`
	// VipSkillBuy is keyed by VIP level; an absent level keeps the source row.
	VipSkillBuy map[string]int64 `json:"vip_skill_buy"`
	// SkillPointItemAmount replaces the skill points of the one stock
	// skill-point item; 0 keeps the source amount.
	SkillPointItemAmount int64 `json:"skill_point_item_amount"`
}

// SkillPointItemID is the stock skill-point item (C6).
const SkillPointItemID int64 = 50001538

var errTuning = errors.New("items-energy: operator tuning")

// Tune returns the catalog with t applied. Any validation failure leaves the
// source catalog in force.
func (c Catalog) Tune(t Tuning) (Catalog, error) {
	if t.BuyEnergyNum < 0 || t.EnergyMaxLimit < 0 || t.MidasBase < 0 || t.MidasLevelIncrease < 0 ||
		t.MidasFloatUpBasisPoints < 0 || t.MidasFloatDownBasisPoints < 0 {
		return c, errTuning
	}
	applied := c
	applied.Misc = c.Misc
	if t.BuyEnergyNum > 0 {
		applied.Misc.BuyEnergyNum = t.BuyEnergyNum
	}
	if t.EnergyMaxLimit > 0 {
		applied.Misc.EnergyMaxLimit = t.EnergyMaxLimit
	}
	if t.MidasBase > 0 {
		applied.Misc.MidasBase = t.MidasBase
	}
	if t.MidasLevelIncrease > 0 {
		applied.Misc.MidasLevelIncrease = t.MidasLevelIncrease
	}
	if t.MidasFloatUpBasisPoints > 0 {
		applied.Misc.MidasFloatUpBasisPoints = t.MidasFloatUpBasisPoints
	}
	if t.MidasFloatDownBasisPoints > 0 {
		applied.Misc.MidasFloatDownBasisPoints = t.MidasFloatDownBasisPoints
	}
	if t.MidasFloatDownBasisPoints > t.MidasFloatUpBasisPoints {
		return c, errTuning
	}
	if err := tuneCrit(&applied, t); err != nil {
		return c, err
	}
	applied.RefreshCost = refreshCopy(applied.RefreshCost)
	if err := tuneCosts(&applied, t); err != nil {
		return c, err
	}
	if err := tuneSkill(&applied, t); err != nil {
		return c, err
	}
	if err := applied.Validate(); err != nil {
		return c, errTuning
	}
	return applied, nil
}

func tuneSkill(catalog *Catalog, t Tuning) error {
	catalog.VIP = vipCopy(catalog.VIP)
	if err := tuneVipSkill(catalog, t); err != nil {
		return err
	}
	if t.SkillPointItemAmount < 0 {
		return errTuning
	}
	if t.SkillPointItemAmount == 0 {
		return nil
	}
	item, ok := catalog.Items[SkillPointItemID]
	if !ok {
		return errTuning
	}
	catalog.Items = itemCopy(catalog.Items)
	item.SkillPoint = t.SkillPointItemAmount
	catalog.Items[SkillPointItemID] = item
	return nil
}

func tuneVipSkill(catalog *Catalog, t Tuning) error {
	for rawLevel, value := range t.VipSkillBuy {
		level, err := strconv.ParseInt(rawLevel, 10, 64)
		if err != nil || (value != 0 && value != 1) {
			return errTuning
		}
		row, ok := catalog.VIP[level]
		if !ok {
			return errTuning
		}
		row.SkillBuy = value
		catalog.VIP[level] = row
	}
	return nil
}

func vipCopy(source map[int64]VIPRow) map[int64]VIPRow {
	out := make(map[int64]VIPRow, len(source))
	for level, row := range source {
		out[level] = row
	}
	return out
}

func itemCopy(source map[int64]Item) map[int64]Item {
	out := make(map[int64]Item, len(source))
	for id, item := range source {
		out[id] = item
	}
	return out
}

func tuneCrit(catalog *Catalog, t Tuning) error {
	if len(t.MidasCritTypes) == 0 && len(t.MidasCritRates) == 0 {
		return nil
	}
	if len(t.MidasCritTypes) != len(t.MidasCritRates) || len(t.MidasCritTypes) == 0 {
		return errTuning
	}
	total := int64(0)
	for index, rate := range t.MidasCritRates {
		if t.MidasCritTypes[index] <= 0 || rate < 0 {
			return errTuning
		}
		total += rate
	}
	if total <= 0 {
		return errTuning
	}
	catalog.Misc.MidasCritTypes = append([]int64(nil), t.MidasCritTypes...)
	catalog.Misc.MidasCritRates = append([]int64(nil), t.MidasCritRates...)
	return nil
}

func tuneCosts(catalog *Catalog, t Tuning) error {
	if len(t.BuyManaCost) > len(catalog.RefreshCost) || len(t.BuyEnergyCost) > len(catalog.RefreshCost) || len(t.BuySkillCost) > len(catalog.RefreshCost) {
		return errTuning
	}
	for ordinal, cost := range t.BuyManaCost {
		if cost <= 0 {
			return errTuning
		}
		row, ok := catalog.RefreshCost[int64(ordinal+1)]
		if !ok {
			return errTuning
		}
		row.BuyManaCost = cost
		catalog.RefreshCost[row.ID] = row
	}
	for ordinal, cost := range t.BuyEnergyCost {
		if cost <= 0 {
			return errTuning
		}
		row, ok := catalog.RefreshCost[int64(ordinal+1)]
		if !ok {
			return errTuning
		}
		row.BuyEnergyCost = cost
		catalog.RefreshCost[row.ID] = row
	}
	for ordinal, cost := range t.BuySkillCost {
		if cost <= 0 {
			return errTuning
		}
		row, ok := catalog.RefreshCost[int64(ordinal+1)]
		if !ok {
			return errTuning
		}
		row.BuySkillCost = cost
		catalog.RefreshCost[row.ID] = row
	}
	return nil
}

func refreshCopy(source map[int64]RefreshCost) map[int64]RefreshCost {
	out := make(map[int64]RefreshCost, len(source))
	for id, row := range source {
		out[id] = row
	}
	return out
}
