package shop

import (
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

// Row is one player's persisted state for one shop type.
type Row struct {
	PlayerID       identity.PlayerID
	ShopType       int64
	Generation     int64
	RefreshTimes   int64
	RefreshDay     int64
	Stock          Stock
	PayloadVersion int16
	StateVersion   int64
	UpdatedAt      time.Time
}

// EffectiveRefreshTimes normalises the manual counter to the current game day
// without writing (a read never advances shared time state).
func (r Row) EffectiveRefreshTimes(day int64) int64 {
	if r.RefreshDay != day {
		return 0
	}
	return r.RefreshTimes
}

// NormaliseDay resets the manual counter when the stored day moved.
func (r *Row) NormaliseDay(day int64) bool {
	if r.RefreshDay == day {
		return false
	}
	r.RefreshDay = day
	r.RefreshTimes = 0
	return true
}

// FindSlot indexes a frozen slot, refusing an out-of-range index.
func (r Row) FindSlot(index int64) (StockSlot, bool) {
	for _, slot := range r.Stock.Slots {
		if slot.Index == index {
			return slot, true
		}
	}
	return StockSlot{}, false
}
