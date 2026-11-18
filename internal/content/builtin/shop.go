package builtin

import (
	"errors"
	"strconv"
)

// ShopCatalog is the I9-11C compiled core-shop bundle: every served shop type,
// its stock table, the dropbox groups those tables reference and the refresh
// ladders.
type ShopCatalog struct {
	SchemaVersion   int                       `json:"schema_version"`
	PolicyID        string                    `json:"policy_id"`
	SourceRowCounts ShopSourceRowCounts       `json:"source_row_counts"`
	Shops           []ShopConfig              `json:"shops"`
	StockTables     map[string]ShopStockTable `json:"stock_tables"`
	Groups          map[string][]ShopDropRoll `json:"groups"`
	RefreshCost     map[string][]int64        `json:"refresh_cost"`
	Tunables        ShopTunables              `json:"tunables"`
}

type ShopSourceRowCounts struct {
	ShopConfig              int `json:"shop_config"`
	Shops                   int `json:"shops"`
	StockTables             int `json:"stock_tables"`
	StockRows               int `json:"stock_rows"`
	DropboxGroupsReferenced int `json:"dropbox_groups_referenced"`
	DropboxRowsReferenced   int `json:"dropbox_rows_referenced"`
	RefreshCostRows         int `json:"refresh_cost_rows"`
}

type ShopConfig struct {
	Type                    int64   `json:"type"`
	FunctionID              int64   `json:"function_id"`
	IsTeamShop              int64   `json:"is_team_shop"`
	SlotNum                 int64   `json:"slot_num"`
	RefreshType             int64   `json:"refresh_type"`
	RefreshKey              string  `json:"refresh_key"`
	RefreshTimes            []int64 `json:"refresh_times"`
	ShopTable               string  `json:"shop_table"`
	IsAlone                 int64   `json:"is_alone"`
	IsUnlimit               int64   `json:"is_unlimit"`
	AutoRefresh             int64   `json:"auto_refresh"`
	TeamDungeonHomologousID int64   `json:"team_dungeon_homologous_id"`
}

type ShopStockTable struct {
	Rows []ShopStockRow `json:"rows"`
}

type ShopStockRow struct {
	ID    int64           `json:"id"`
	Slots []ShopStockSlot `json:"slots"`
}

type ShopStockSlot struct {
	Groups []ShopStockGroup `json:"groups"`
}

type ShopStockGroup struct {
	DropboxID int64 `json:"dropbox_id"`
	Weight    int64 `json:"weight"`
}

type ShopDropRoll struct {
	ItemID    int64 `json:"item_id"`
	ItemNum   int64 `json:"item_num"`
	SellType  int64 `json:"sell_type"`
	SellPrice int64 `json:"sell_price"`
	Discount  int64 `json:"discount"`
	Rate      int64 `json:"rate"`
	StoneID   int64 `json:"stone_id"`
}

type ShopTunables struct {
	StoneSubstituteItem int64 `json:"stone_substitute_item"`
	CubeCurrencyItem    int64 `json:"cube_currency_item"`
	DiscountMillionths  int64 `json:"discount_millionths"`
	MonthCardMillionths int64 `json:"month_card_millionths"`
	LevelPoolRows       int64 `json:"level_pool_rows"`
}

// QualifyShopCatalog validates the compiled bundle against the pinned source
// counts and the shapes the shop domain depends on.
func QualifyShopCatalog(c ShopCatalog) error {
	if c.SchemaVersion != 1 || c.PolicyID != "I9_11C_CORE_SHOPS_V2" {
		return errors.New("shop catalog: unqualified policy")
	}
	counts := c.SourceRowCounts
	if counts.ShopConfig != 38 || len(c.Shops) != counts.Shops || counts.Shops != 30 ||
		len(c.StockTables) != counts.StockTables || counts.StockTables != 30 ||
		counts.StockRows != 1317 || len(c.Groups) != counts.DropboxGroupsReferenced ||
		counts.DropboxGroupsReferenced != 342 || counts.DropboxRowsReferenced != 2690 ||
		counts.RefreshCostRows != 330 {
		return errors.New("shop catalog: source row count drift")
	}
	if c.Tunables.StoneSubstituteItem != 50001427 || c.Tunables.CubeCurrencyItem != 50002072 ||
		c.Tunables.DiscountMillionths != 600000 || c.Tunables.MonthCardMillionths != 550000 ||
		c.Tunables.LevelPoolRows != 100 {
		return errors.New("shop catalog: tunable drift")
	}
	shops := make(map[int64]struct{}, len(c.Shops))
	for _, shop := range c.Shops {
		if shop.Type <= 0 || shop.SlotNum <= 0 || shop.ShopTable == "" {
			return errors.New("shop catalog: invalid shop row")
		}
		if _, exists := shops[shop.Type]; exists {
			return errors.New("shop catalog: duplicate shop type")
		}
		shops[shop.Type] = struct{}{}
		table, exists := c.StockTables[shop.ShopTable]
		if !exists || len(table.Rows) == 0 {
			return errors.New("shop catalog: shop names a missing stock table")
		}
		for _, row := range table.Rows {
			// team_shop21 carries 12 source slots while shop_config says 10; the
			// catalog serves shop_config's slot count and never invents slots.
			if row.ID <= 0 || int64(len(row.Slots)) < shop.SlotNum {
				return errors.New("shop catalog: stock row slot drift")
			}
			for _, slot := range row.Slots {
				var weight int64
				for _, group := range slot.Groups {
					if group.DropboxID <= 0 || group.Weight <= 0 {
						return errors.New("shop catalog: unreachable stock group")
					}
					if _, exists := c.Groups[strconv.FormatInt(group.DropboxID, 10)]; !exists {
						return errors.New("shop catalog: stock group missing")
					}
					weight += group.Weight
				}
				if weight <= 0 {
					return errors.New("shop catalog: empty stock slot")
				}
			}
		}
	}
	for _, rolls := range c.Groups {
		var rate int64
		for _, roll := range rolls {
			if roll.ItemID <= 0 || roll.ItemNum <= 0 || roll.SellPrice <= 0 || roll.Rate < 0 ||
				(roll.Discount != 0 && roll.Discount != 1) {
				return errors.New("shop catalog: unqualified drop roll")
			}
			stonePriced := roll.SellType == 7 || roll.SellType == 15
			if stonePriced != (roll.StoneID > 0) {
				return errors.New("shop catalog: stone_id does not match the sell type")
			}
			rate += roll.Rate
		}
		if rate <= 0 {
			return errors.New("shop catalog: empty drop group")
		}
	}
	for _, ladder := range c.RefreshCost {
		if len(ladder) == 0 {
			return errors.New("shop catalog: empty refresh ladder")
		}
	}
	return nil
}
