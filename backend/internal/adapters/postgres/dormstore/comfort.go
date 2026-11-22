package dormstore

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	dorm "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ComfortFactTx supplies the Ranking owner one typed comfort fact per player.
// An absent Dorm root is not a zero score the board invents; the caller skips it.
func (s Store) ComfortFactTx(ctx context.Context, q tx.Queryer, player identity.PlayerID, revision string, at time.Time) (dorm.ComfortFact, bool, error) {
	root, e := s.ReadRootTx(ctx, q, player)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return dorm.ComfortFact{}, false, nil
	}
	if e != nil {
		return dorm.ComfortFact{}, false, e
	}
	rooms, e := s.ListRoomsTx(ctx, q, player)
	if e != nil {
		return dorm.ComfortFact{}, false, e
	}
	fact, e := dorm.BuildComfortFact(player, rooms, root.StateVersion, revision, at)
	return fact, true, e
}
