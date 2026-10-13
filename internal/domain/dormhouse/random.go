package dormhouse

import (
	"encoding/binary"
	"fmt"
	"gxb.local/backend/v2/internal/foundation/operation"
)

// SelectRoom is retry-stable, unbiased uniform selection within the particular
// key's source list. Application admissions retain op and receipt; this helper
// alone cannot prove payment or process recovery.
func (c Catalog) SelectRoom(itemID int64, op operation.Context) (int64, error) {
	k, ok := c.Keys[itemID]
	if !ok || len(k.Templates) == 0 || op.ID.IsZero() || op.StartedAt.IsZero() {
		return 0, ErrUnqualified
	}
	for _, id := range k.Templates {
		r, ok := c.Rooms[id]
		if !ok || r.MainType != k.MainType {
			return 0, ErrUnqualified
		}
	}
	n := uint64(len(k.Templates))
	threshold := -n % n
	for round := uint64(0); ; round++ {
		b := op.Derive(fmt.Sprintf("dorm/random-key/v1/item=%d/round=%d", itemID, round), 0)
		for i := 0; i < len(b); i += 8 {
			v := binary.BigEndian.Uint64(b[i : i+8])
			if v >= threshold {
				return k.Templates[v%n], nil
			}
		}
	}
}
