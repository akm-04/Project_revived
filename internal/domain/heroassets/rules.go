// Package heroassets owns the pure rules of the I9-11A skill-point purchase and
// skill-point item commands. Catalogue truth comes from the 11B daily-buy
// bundle; the skill-point balance and the daily buy counter belong to I5 and
// the daily-consume owner.
package heroassets

import (
	"errors"
	"math"

	"gxb.local/backend/v2/internal/domain/itemsenergy"
)

// PolicyID is the outer semantic receipt policy version of this leaf.
const PolicyID = "I9_11A_HERO_ASSETS_V2"

// The stock client sells skill points only through item 50001538
// (xyd.ConsumeItemType.SKILL_POINT = 19, enums.lua:539; item.lua row). MID 99
// buys the ten points the client prompt names (SKILL_POINT_BUY, translation2.lua:434).
const (
	SkillPointItemID      int64 = 50001538
	SkillPointItemSubType int64 = 19
	BuySkillPointGrant    int64 = 10
)

var (
	ErrInvalid         = errors.New("hero-assets: invalid request")
	ErrRefused         = errors.New("hero-assets: refused")
	ErrStaleState      = errors.New("hero-assets: stale stack state")
	ErrVipRequired     = errors.New("hero-assets: VIP skill purchase locked")
	ErrUnsupportedItem = errors.New("hero-assets: unsupported skill-point item")
	ErrUnavailable     = errors.New("hero-assets: content unavailable")
)

// BuyOrdinal is today's buy count plus one. A negative stored count is treated
// as the first purchase of the day.
func BuyOrdinal(used int64) int64 {
	if used < 0 {
		return 1
	}
	return used + 1
}

// CostOrdinal clamps a purchase ordinal to the refresh_cost table (the stock
// table repeats its last price through row 330).
func CostOrdinal(ordinal, rows int64) int64 {
	if rows < 1 {
		return 0
	}
	if ordinal < 1 {
		return 1
	}
	if ordinal > rows {
		return rows
	}
	return ordinal
}

// SkillBuyAllowed reports the VIP skill_buy gate (VIP 2 and above in the stock
// table).
func SkillBuyAllowed(catalog itemsenergy.Catalog, vipLevel int64) (bool, error) {
	row, ok := catalog.VIP[vipLevel]
	if !ok {
		return false, ErrUnavailable
	}
	return row.SkillBuy != 0, nil
}

// SkillPointBuyCost is the crystal cost of one skill-point purchase at ordinal.
func SkillPointBuyCost(catalog itemsenergy.Catalog, ordinal int64) (int64, error) {
	row, ok := catalog.Refresh(CostOrdinal(ordinal, int64(len(catalog.RefreshCost))))
	if !ok || row.BuySkillCost <= 0 {
		return 0, ErrUnavailable
	}
	return row.BuySkillCost, nil
}

// SkillPointItemGain validates one MID 90 request against the pinned item row
// and returns the skill points it grants.
func SkillPointItemGain(catalog itemsenergy.Catalog, itemID, num int64) (int64, error) {
	if itemID != SkillPointItemID {
		return 0, ErrUnsupportedItem
	}
	if num < 1 {
		return 0, ErrInvalid
	}
	item, ok := catalog.Items[itemID]
	if !ok || item.SubType != SkillPointItemSubType || item.SkillPoint <= 0 || item.Stack <= 0 {
		return 0, ErrUnsupportedItem
	}
	if num > item.Stack {
		return 0, ErrStaleState
	}
	if num > math.MaxInt64/item.SkillPoint {
		return 0, ErrInvalid
	}
	return num * item.SkillPoint, nil
}
