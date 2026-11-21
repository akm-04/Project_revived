// Package shop owns the I9-11C core-shop policy: the compiled catalog, the
// deterministic stock generation, the price rules and the stock snapshot the
// application owner freezes per player and shop type.
package shop

import (
	"errors"
	"time"

	"gxb.local/backend/v2/internal/domain/modes"
)

const (
	// PolicyID is the receipt policy version of every 11C command.
	PolicyID = "I9_11C_CORE_SHOPS_V2"
	// ReceiptClass is the LEAD_SEAMS_I9-11 V2 section 5 receipt class.
	ReceiptClass = "I9_11C_SHOP"
	// EntropyLabel is the LEAD_SEAMS_I9-11 V2 section 8 stock stream.
	EntropyLabel = "shop.stock/v1"
	// CourseBooksShopType is the Electives bookshop (shop_config row 29),
	// reached from the Course window and never listed by MID 37.
	CourseBooksShopType int64 = 29
)

var (
	ErrInvalid        = errors.New("shop: invalid request")
	ErrRefused        = errors.New("shop: refused")
	ErrStaleState     = errors.New("shop: stale generation")
	ErrUnavailable    = errors.New("shop: unavailable")
	ErrPriceExpired   = errors.New("shop: client shows an ended discount")
	ErrPriceDiscount  = errors.New("shop: client misses an active discount")
	ErrOverlayInvalid = errors.New("shop: invalid operator overlay")
)

// SellType is the client currencyType of a dropbox row.
type SellType int64

const (
	SellMana         SellType = 1
	SellCrystal      SellType = 2
	SellArenaCoin    SellType = 3
	SellMarchCoin    SellType = 4
	SellTopCoin      SellType = 5
	SellGuildCoin    SellType = 6
	SellStone        SellType = 7
	SellRegionCoin   SellType = 10
	SellPetStone     SellType = 15
	SellHonorCoin    SellType = 16
	SellIllusionCoin SellType = 17
	SellTeaTalk      SellType = 22
	SellAcademyCoin  SellType = 23
	SellTeamDungeon  SellType = 24
	SellSummonCoin   SellType = 25
	SellCube         SellType = 32
)

// ScalarKey is the canonical I5 scalar resource key of a currency sell type.
func (s SellType) ScalarKey() (string, bool) {
	switch s {
	case SellMana:
		return "mana", true
	case SellCrystal:
		return "crystal", true
	case SellArenaCoin:
		return "arena_coin", true
	case SellMarchCoin:
		return "march_coin", true
	case SellTopCoin:
		return "top_coin", true
	case SellGuildCoin:
		return "guild_coin", true
	case SellRegionCoin:
		return "region_coin", true
	case SellHonorCoin:
		return "honor_coin", true
	case SellIllusionCoin:
		return "paradise_coin", true
	case SellTeaTalk:
		return "friend_medal", true
	case SellAcademyCoin:
		return "god_war_coin", true
	case SellTeamDungeon:
		return "team_dungeon_coin", true
	case SellSummonCoin:
		return "summon_coin", true
	}
	return "", false
}

// Shop is one shop_config row.
type Shop struct {
	Type         int64
	FunctionID   int64
	Team         bool
	SlotNum      int64
	RefreshType  int64
	RefreshKey   string
	RefreshTimes []int64
	Table        string
	Alone        bool
	Unlimit      bool
	AutoRefresh  int64
	HomologousID int64
}

// HasSchedule reports whether this type rerolls on the source clock.
func (s Shop) HasSchedule() bool { return len(s.RefreshTimes) > 0 }

// AllowsManualRefresh reports whether a refresh button exists for the type.
// Type 35 (Champions League) hides it (ChampionsLeagueShopWindow.lua:79-85);
// a type with refresh_type 0 has no ladder.
func (s Shop) AllowsManualRefresh() bool {
	return s.RefreshType != 0 && s.RefreshKey != "" && s.Type != 35
}

// Group is one weighted dropbox group of a stock slot.
type Group struct {
	DropboxID int64
	Weight    int64
}

// SourceSlot is one slotN_drop/slotN_rate pair.
type SourceSlot struct{ Groups []Group }

// SourceRow is one stock table row (a level pool row, or row 1 of a fixed table).
type SourceRow struct {
	ID    int64
	Slots []SourceSlot
}

// Roll is one dropbox row: the product, its price and, for a stone-priced row,
// the stone item the source names as its currency.
type Roll struct {
	ItemID    int64
	ItemNum   int64
	SellType  int64
	SellPrice int64
	Discount  int64
	Rate      int64
	StoneID   int64
}

// Tunables are the compiled private policy constants.
type Tunables struct {
	StoneSubstituteItem int64
	CubeCurrencyItem    int64
	DiscountMillionths  int64
	MonthCardMillionths int64
	LevelPoolRows       int64
}

// Catalog is the compiled immutable shop content for one revision.
type Catalog struct {
	Revision    string
	Shops       map[int64]Shop
	StockTables map[string][]SourceRow
	Groups      map[int64][]Roll
	RefreshCost map[string][]int64
	Tunables    Tunables
	Tuning      Tuning
}

// Shop returns one type's source row.
func (c Catalog) Shop(shopType int64) (Shop, bool) {
	shop, ok := c.Shops[shopType]
	return shop, ok
}

// RefreshCostAt returns the ladder price at refresh_times (0-based, the client
// indexes refreshTimes+1 into the 1-based table). exhausted is true when the
// ladder has no entry for that ordinal.
func (c Catalog) RefreshCostAt(shop Shop, refreshTimes int64) (int64, bool) {
	ladder, ok := c.RefreshCost[shop.RefreshKey]
	if !ok || refreshTimes < 0 || refreshTimes >= int64(len(ladder)) {
		return 0, false
	}
	return ladder[refreshTimes], true
}

// Price returns the authoritative unit price of a frozen slot.
func (c Catalog) Price(slot StockSlot, shopType int64, monthCard bool) (int64, error) {
	switch slot.Discount {
	case 0:
		return slot.SellPrice, nil
	case 1:
		scale := c.Tunables.DiscountMillionths
		if (shopType == 4 || shopType == 5) && monthCard {
			scale = c.Tunables.MonthCardMillionths
		}
		return slot.SellPrice * scale / 1_000_000, nil
	}
	return 0, ErrInvalid
}

// StockSlot is one frozen stock item of a player's generation.
type StockSlot struct {
	Index     int64 `json:"index"`
	ItemID    int64 `json:"item_id"`
	ItemNum   int64 `json:"item_num"`
	SellType  int64 `json:"sell_type"`
	SellPrice int64 `json:"sell_price"`
	Discount  int64 `json:"discount"`
	StoneID   int64 `json:"stone_id,omitempty"`
	IsBuy     int64 `json:"isbuy"`
	BuyTimes  int64 `json:"buy_times"`
}

// Stock is the stored per-(player, shop type) state payload.
type Stock struct {
	ScheduleDay  int64       `json:"schedule_day"`
	ScheduleMark int64       `json:"schedule_mark"`
	Slots        []StockSlot `json:"slots"`
}

// Clone returns a deep copy so a caller never mutates a memoised catalog row.
func (s Stock) Clone() Stock {
	out := s
	out.Slots = append([]StockSlot(nil), s.Slots...)
	return out
}

// ScheduledMark returns the game day and the number of source schedule marks
// that have passed inside that day, in GMT+8 (the schedule-of-day timezone).
func ScheduledMark(shop Shop, now time.Time) (int64, int64) {
	day := modes.Day(now)
	gmt8 := now.In(time.FixedZone("GMT+8", 8*3600))
	seconds := int64(gmt8.Hour()*3600 + gmt8.Minute()*60 + gmt8.Second())
	var passed int64
	for _, mark := range shop.RefreshTimes {
		if mark <= seconds {
			passed++
		}
	}
	return day, passed
}

// NeedsScheduledReroll reports whether this player's generation predates the
// latest source mark (or belongs to an earlier game day).
func NeedsScheduledReroll(shop Shop, stock Stock, now time.Time) bool {
	if len(stock.Slots) == 0 {
		return true
	}
	if !shop.HasSchedule() {
		return false
	}
	day, mark := ScheduledMark(shop, now)
	if stock.ScheduleDay != day {
		return true
	}
	return mark > stock.ScheduleMark
}

// Tuning is the validated D476 operator overlay.
type Tuning struct {
	Revision string
	Digest   string
	Rows     []TuningRow
}

// TuningRow may only disable, reprice, requantity, re-stone or lower the one-buy
// cap of a known (shop type, index) row. StoneID only applies to a slot that is
// already stone-priced (sell_type 7/15); the source prices those in the
// product's own stone.
type TuningRow struct {
	ShopType  int64  `json:"shop_type"`
	Index     int64  `json:"index"`
	Disabled  bool   `json:"disabled,omitempty"`
	SellPrice *int64 `json:"sell_price,omitempty"`
	ItemNum   *int64 `json:"item_num,omitempty"`
	MaxBuys   *int64 `json:"max_buys,omitempty"`
	StoneID   *int64 `json:"stone_id,omitempty"`
}

// MarketTuning is the stored overlay document.
type MarketTuning struct {
	Revision int64       `json:"revision"`
	Rows     []TuningRow `json:"rows"`
}

// ValidateTuning rejects the whole overlay when any row names an unknown shop
// row or carries a non-positive value. max_buys may only lower the one-buy cap.
func ValidateTuning(catalog Catalog, tuning Tuning) error {
	seen := map[[2]int64]struct{}{}
	for _, row := range tuning.Rows {
		shop, ok := catalog.Shops[row.ShopType]
		if !ok || row.Index < 1 || row.Index > shop.SlotNum {
			return ErrOverlayInvalid
		}
		key := [2]int64{row.ShopType, row.Index}
		if _, duplicate := seen[key]; duplicate {
			return ErrOverlayInvalid
		}
		seen[key] = struct{}{}
		if row.SellPrice != nil && *row.SellPrice <= 0 {
			return ErrOverlayInvalid
		}
		if row.ItemNum != nil && *row.ItemNum <= 0 {
			return ErrOverlayInvalid
		}
		if row.MaxBuys != nil && (*row.MaxBuys < 0 || *row.MaxBuys > 1) {
			return ErrOverlayInvalid
		}
		if row.StoneID != nil && *row.StoneID <= 0 {
			return ErrOverlayInvalid
		}
	}
	return nil
}

// TunedSlot applies the overlay rows for (shopType, index).
func (c Catalog) TunedSlot(shopType int64, slot StockSlot) (StockSlot, bool) {
	disabled := false
	for _, row := range c.Tuning.Rows {
		if row.ShopType != shopType || row.Index != slot.Index {
			continue
		}
		disabled = disabled || row.Disabled
		if row.SellPrice != nil {
			slot.SellPrice = *row.SellPrice
		}
		if row.ItemNum != nil {
			slot.ItemNum = *row.ItemNum
		}
		if row.MaxBuys != nil && *row.MaxBuys < 1 {
			disabled = true
		}
		if row.StoneID != nil && slot.StoneID > 0 {
			slot.StoneID = *row.StoneID
		}
	}
	return slot, disabled
}
