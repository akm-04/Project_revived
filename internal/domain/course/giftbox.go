package course

import (
	"encoding/binary"
	"fmt"
	"strconv"

	"gxb.local/backend/v2/internal/foundation/operation"
)

const (
	// DailyGiftBoxItemID is the once-per-day free box (misc object_box_book1).
	DailyGiftBoxItemID int64 = 50001418
	// PurchasedGiftBoxItemID is the box consumed from the backpack.
	PurchasedGiftBoxItemID int64 = 50001419
)

const probabilityScale = 10000

// GiftBoxDrop is one row of a gift box dropbox; Rate is in ten-thousandths.
type GiftBoxDrop struct {
	ID      int64
	ItemID  int64
	ItemNum int64
	Rate    int64
}

type GiftBoxRule struct {
	ItemID    int64
	DropboxID int64
	Rolls     []GiftBoxDrop
}

func (r GiftBoxRule) Validate() error {
	if r.ItemID <= 0 || r.DropboxID <= 0 || len(r.Rolls) == 0 {
		return ErrUnqualified
	}
	total, seen := int64(0), map[int64]bool{}
	for _, roll := range r.Rolls {
		if roll.ID <= 0 || roll.ItemID <= 0 || roll.ItemNum <= 0 || roll.Rate < 0 || roll.Rate > probabilityScale || seen[roll.ItemID] {
			return ErrUnqualified
		}
		seen[roll.ItemID] = true
		total += roll.Rate
	}
	if total != probabilityScale {
		return ErrUnqualified
	}
	return nil
}

// Roll selects one weighted row. Entropy derives from the semantic operation,
// so a retried transaction draws the same award.
func (r GiftBoxRule) Roll(op operation.Context) (GiftBoxDrop, error) {
	if r.Validate() != nil || op.ID.IsZero() || op.StartedAt.IsZero() {
		return GiftBoxDrop{}, ErrUnqualified
	}
	pick := giftBoxDraw(op, "course.giftbox.v1/dropbox="+strconv.FormatInt(r.DropboxID, 10), probabilityScale)
	cumulative := uint64(0)
	for _, roll := range r.Rolls {
		cumulative += uint64(roll.Rate)
		if pick < cumulative {
			return roll, nil
		}
	}
	return GiftBoxDrop{}, ErrUnqualified
}

func giftBoxDraw(op operation.Context, label string, bound uint64) uint64 {
	const space = uint64(1) << 32
	if bound == 0 || bound > space {
		panic("course: invalid sampling support")
	}
	limit := space - space%bound
	for round := uint64(0); ; round++ {
		block := op.Derive(fmt.Sprintf("%s/round=%d", label, round), 0)
		for i := 0; i+4 <= len(block); i += 4 {
			value := uint64(binary.BigEndian.Uint32(block[i : i+4]))
			if value < limit {
				return value % bound
			}
		}
	}
}
