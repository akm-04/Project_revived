package socialrelation

import (
	"context"
	"sort"
	"time"

	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// FriendshipEnsurer is the exported transaction-level auto-friend seam for
// owners (Mentor) that must create a friendship without writing the Social
// tables themselves. It fences both I4 player roots before the Social root and
// friendship rows, so callers must invoke it before any higher-rank lock.
type FriendshipEnsurer struct {
	Players playerroot.TxLocker
	Store   CommandStore
}

func (ensurer FriendshipEnsurer) EnsureFriendshipTx(ctx context.Context, t tx.Tx, first, second identity.PlayerID, at time.Time) (bool, error) {
	if ensurer.Players == nil || ensurer.Store == nil || t == nil || !first.Valid() || !second.Valid() || first == second || at.IsZero() {
		return false, ErrInvalidCommand
	}
	if logicalserver.PlayerRegion(first) != logicalserver.PlayerRegion(second) {
		return false, ErrNotEligible
	}
	ids := []identity.PlayerID{first, second}
	sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
	server := logicalserver.PlayerRegion(first)
	roots, err := ensurer.Players.LockPlayerRootsTx(ctx, t, server, ids)
	if err != nil {
		return false, err
	}
	if len(roots) != 2 || roots[0].PlayerID != ids[0] || roots[1].PlayerID != ids[1] {
		return false, ErrStateConflict
	}
	socialRoots := map[identity.PlayerID]Root{}
	for _, player := range ids {
		root, err := ensurer.Store.EnsureRootTx(ctx, t, player, at)
		if err != nil {
			return false, err
		}
		socialRoots[player] = root
	}
	low, high := ids[0], ids[1]
	existing, found, err := ensurer.Store.LockFriendshipTx(ctx, t, low, high)
	if err != nil {
		return false, err
	}
	if found && existing.Active {
		return false, nil
	}
	next := Friendship{PlayerLowID: low, PlayerHighID: high, Generation: 1, Active: true, ActivatedAt: at.UTC(), StateVersion: 1, UpdatedAt: at.UTC()}
	var previous *Friendship
	if found {
		previousCopy := existing
		previous = &previousCopy
		next.Generation = existing.Generation + 1
		next.StateVersion = existing.StateVersion + 1
	}
	if err := ensurer.Store.PutFriendshipTx(ctx, t, previous, next); err != nil {
		return false, err
	}
	for _, player := range ids {
		if err := ensurer.Store.TouchRootTx(ctx, t, socialRoots[player], at); err != nil {
			return false, err
		}
	}
	return true, nil
}
