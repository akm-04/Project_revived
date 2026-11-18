package shop

import (
	"gxb.local/backend/v2/internal/domain/combat"
)

// Generate produces one stock generation: slot order 1..N, group then row,
// from the operation-derived stream the caller supplies (LEAD_SEAMS_I9-11 V2
// section 8). Weights are relative to the actual sum; a zero-weight group is
// unreachable.
func (c Catalog) Generate(shop Shop, playerLevel int64, stream *combat.Stream) ([]StockSlot, error) {
	if stream == nil || shop.SlotNum <= 0 {
		return nil, ErrInvalid
	}
	row, err := c.poolRow(shop, playerLevel)
	if err != nil {
		return nil, err
	}
	if int64(len(row.Slots)) < shop.SlotNum {
		return nil, ErrRefused
	}
	slots := make([]StockSlot, 0, shop.SlotNum)
	for index := int64(1); index <= shop.SlotNum; index++ {
		source := row.Slots[index-1]
		groupID, err := pickWeighted(stream, len(source.Groups), func(position int) int64 { return source.Groups[position].Weight })
		if err != nil {
			return nil, err
		}
		rolls := c.Groups[source.Groups[groupID].DropboxID]
		rollIndex, err := pickWeighted(stream, len(rolls), func(position int) int64 { return rolls[position].Rate })
		if err != nil {
			return nil, err
		}
		roll := rolls[rollIndex]
		slot := StockSlot{
			Index:     index,
			ItemID:    roll.ItemID,
			ItemNum:   roll.ItemNum,
			SellType:  roll.SellType,
			SellPrice: roll.SellPrice,
			Discount:  roll.Discount,
		}
		switch SellType(roll.SellType) {
		case SellStone:
			slot.StoneID = c.Tunables.StoneCurrencyItem
		case SellCube:
			slot.StoneID = 0
		}
		slots = append(slots, slot)
	}
	return slots, nil
}

// poolRow selects the level pool row: min(level, 100) of a 100-row pool, row 1
// of a fixed table (C9). A missing row fails closed.
func (c Catalog) poolRow(shop Shop, playerLevel int64) (SourceRow, error) {
	rows, ok := c.StockTables[shop.Table]
	if !ok || len(rows) == 0 {
		return SourceRow{}, ErrUnavailable
	}
	wanted := int64(1)
	if int64(len(rows)) == c.Tunables.LevelPoolRows {
		wanted = playerLevel
		if wanted < 1 {
			wanted = 1
		}
		if wanted > c.Tunables.LevelPoolRows {
			wanted = c.Tunables.LevelPoolRows
		}
	}
	for _, row := range rows {
		if row.ID == wanted {
			return row, nil
		}
	}
	return SourceRow{}, ErrRefused
}

func pickWeighted(stream *combat.Stream, length int, weight func(position int) int64) (int, error) {
	if length <= 0 {
		return 0, ErrRefused
	}
	var total int64
	for position := 0; position < length; position++ {
		value := weight(position)
		if value < 0 {
			return 0, ErrRefused
		}
		total += value
	}
	if total <= 0 {
		return 0, ErrRefused
	}
	target := int64(stream.Uniform(uint64(total)))
	var running int64
	for position := 0; position < length; position++ {
		running += weight(position)
		if target < running {
			return position, nil
		}
	}
	return length - 1, nil
}
