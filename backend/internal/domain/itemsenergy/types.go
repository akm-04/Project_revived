// Package itemsenergy owns the pure rules of the stock item-use, sell, energy,
// golden-hand and box commands. Catalogue truth comes from content; player
// stacks, currencies and temporal state belong to their canonical owners.
package itemsenergy

import (
	"errors"
	"fmt"
)

// LockRankDailyConsume is LEAD_SEAMS_I9-11 V2 section 2 rank 450, the
// daily_consumption_players row. It is acquired after the player root and the
// hero roster and before any I5 economy lock.
const LockRankDailyConsume int64 = 450

// PolicyID is the outer semantic receipt policy version of this leaf.
const PolicyID = "I9_11B_ITEMS_ENERGY_V2"

var (
	ErrInvalid     = errors.New("items-energy: invalid request")
	ErrStaleState  = errors.New("items-energy: stale stack state")
	ErrRefused     = errors.New("items-energy: refused")
	ErrUnavailable = errors.New("items-energy: content unavailable")
)

// Item is one compiled item.lua row.
type Item struct {
	ID          int64
	Type        int64
	SubType     int64
	Stack       int64
	Energy      int64
	SkillPoint  int64
	Mana        int64
	Crystal     int64
	MagicEnergy int64
	MagicDust   int64
	MagicLiquid int64
	Level       int64
	Gifts       []int64
	OneInMore   []int64
}

// Gift is one compiled gift.lua row. Equip and SummonID stay as source text and
// id; both belong to owners outside this leaf.
type Gift struct {
	ID             int64
	Items          []int64
	ItemNums       []int64
	Drops          []int64
	Equip          string
	SummonID       int64
	Crystal        int64
	Mana           int64
	Energy         int64
	VipExp         int64
	ArenaCoin      int64
	MarchCoin      int64
	LuckyCoin      int64
	FriendshipCoin int64
	SkinFragment   int64
	Exp            int64
	Badge          int64
	Soul           int64
	Vip            int64
	ExBadge        int64
	TutorCoin      int64
	SkinCoin       int64
	SpiritEnergy   int64
}

// DropRoll is one dropbox.lua row.
type DropRoll struct {
	ID       int64
	ItemID   int64
	ItemNum  int64
	Rate     int64
	RollType int64
}

// Dropbox is one dropbox.lua group in source row order.
type Dropbox struct {
	ID    int64
	Rolls []DropRoll
}

type VIPRow struct {
	Level     int64
	NumEnergy int64
	NumMidas  int64
	SkillBuy  int64
	SkillMax  int64
}

type MonthlyPrivilege struct {
	NumEnergy int64
	NumMidas  int64
}

type RefreshCost struct {
	ID                     int64
	BuyEnergyCost          int64
	BuyManaCost            int64
	BuySkillCost           int64
	BuyManaRatioMillionths int64
}

type Misc struct {
	BuyEnergyNum              int64
	EnergyMaxLimit            int64
	MidasBase                 int64
	MidasLevelIncrease        int64
	MidasFloatUpBasisPoints   int64
	MidasFloatDownBasisPoints int64
	MidasCritTypes            []int64
	MidasCritRates            []int64
}

type DailyConsume struct {
	ID    int64
	Cost  int64
	Num   int64
	Value int64
}

// Catalog is the immutable items-energy view of one content revision.
type Catalog struct {
	Revision     string
	Items        map[int64]Item
	Gifts        map[int64]Gift
	Dropboxes    map[int64]Dropbox
	VIP          map[int64]VIPRow
	Monthly      MonthlyPrivilege
	RefreshCost  map[int64]RefreshCost
	Misc         Misc
	DailyConsume map[int64]DailyConsume
}

func (c Catalog) Validate() error {
	if len(c.Revision) != 64 || len(c.Items) == 0 || len(c.Gifts) == 0 || len(c.Dropboxes) == 0 {
		return fmt.Errorf("%w: incomplete catalog", ErrUnavailable)
	}
	if len(c.VIP) != 16 || len(c.RefreshCost) == 0 || len(c.DailyConsume) != 10 {
		return fmt.Errorf("%w: tunable tables incomplete", ErrUnavailable)
	}
	if c.Misc.BuyEnergyNum <= 0 || c.Misc.EnergyMaxLimit <= 0 || c.Misc.MidasBase <= 0 ||
		c.Misc.MidasLevelIncrease <= 0 || c.Misc.MidasFloatUpBasisPoints < 0 ||
		c.Misc.MidasFloatDownBasisPoints < 0 || len(c.Misc.MidasCritTypes) != len(c.Misc.MidasCritRates) || len(c.Misc.MidasCritTypes) == 0 {
		return fmt.Errorf("%w: golden-hand tunables invalid", ErrUnavailable)
	}
	for level := int64(0); level < 16; level++ {
		if _, ok := c.VIP[level]; !ok {
			return fmt.Errorf("%w: VIP level %d missing", ErrUnavailable, level)
		}
	}
	return nil
}

func (c Catalog) Item(id int64) (Item, error) {
	item, ok := c.Items[id]
	if !ok || item.ID != id {
		return Item{}, fmt.Errorf("%w: unknown item %d", ErrRefused, id)
	}
	return item, nil
}

func (c Catalog) Gift(id int64) (Gift, bool) {
	gift, ok := c.Gifts[id]
	return gift, ok && gift.ID == id
}

func (c Catalog) Refresh(id int64) (RefreshCost, bool) {
	cost, ok := c.RefreshCost[id]
	return cost, ok && cost.ID == id
}

func (c Catalog) Dropbox(id int64) (Dropbox, bool) {
	box, ok := c.Dropboxes[id]
	return box, ok && box.ID == id
}
