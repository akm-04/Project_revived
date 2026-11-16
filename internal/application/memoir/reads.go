package memoir

import (
	"context"
	"sort"

	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/memoir"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// TenthFloor is the floor at least ten girls reached: the 10th-highest maximum
// floor, or 0 with fewer than ten girls.
func TenthFloor(maxFloors map[int64]int) int {
	if len(maxFloors) < 10 {
		return 0
	}
	floors := make([]int, 0, len(maxFloors))
	for _, floor := range maxFloors {
		floors = append(floors, floor)
	}
	sort.Sort(sort.Reverse(sort.IntSlice(floors)))
	return floors[9]
}

// TenthFloorTx is 100024's owner fact over the stored per-girl maxima.
func (mode Mode) TenthFloorTx(c context.Context, q tx.Queryer, p identity.PlayerID) (int64, error) {
	if mode.Store == nil {
		return 0, d.ErrUnavailable
	}
	state, found, e := mode.Store.ReadTx(c, q, p)
	if e != nil {
		return 0, e
	}
	if !found {
		return 0, nil
	}
	return int64(TenthFloor(state.MaxFloor)), nil
}
