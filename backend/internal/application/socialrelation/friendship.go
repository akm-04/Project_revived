package socialrelation

import (
	"context"
	"errors"
	"sort"
	"time"

	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ErrPairBlocked refuses a new friendship while either direction is blocked.
var ErrPairBlocked = errors.New("social relation: pair is blocked")

// FriendCapacityError names the player whose active friend list is full.
type FriendCapacityError struct{ PlayerID identity.PlayerID }

func (err *FriendCapacityError) Error() string { return "social relation: friend list full" }

// FriendshipEnsurer is the exported transaction-level auto-friend seam for
// owners (Mentor) that must create a friendship without writing the Social
// tables themselves. It fences both I4 player roots before the Social root,
// friendship and block rows, and applies the owner's block and 80-friend
// capacity invariants, so callers must invoke it before any higher-rank lock.
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
	blockPairs, err := orderedBlockPairs(first, second)
	if err != nil {
		return false, err
	}
	for _, pair := range blockPairs {
		block, found, err := ensurer.Store.LockBlockTx(ctx, t, pair[0], pair[1])
		if err != nil {
			return false, err
		}
		if found && block.Active {
			return false, ErrPairBlocked
		}
	}
	for _, player := range []identity.PlayerID{first, second} {
		count, err := ensurer.Store.CountActiveFriendsTx(ctx, t, player)
		if err != nil {
			return false, err
		}
		if count >= FriendCapacity {
			return false, &FriendCapacityError{PlayerID: player}
		}
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

// PairBlockedTx reports whether either direction of the pair holds an active
// block. It is the typed observation an owner applies inside its own
// transaction; the caller must already have fenced both players' I4 roots.
func (ensurer FriendshipEnsurer) PairBlockedTx(ctx context.Context, t tx.Tx, first, second identity.PlayerID) (bool, error) {
	if ensurer.Store == nil || t == nil || !first.Valid() || !second.Valid() || first == second {
		return false, ErrInvalidCommand
	}
	blockPairs, err := orderedBlockPairs(first, second)
	if err != nil {
		return false, err
	}
	for _, pair := range blockPairs {
		block, found, err := ensurer.Store.LockBlockTx(ctx, t, pair[0], pair[1])
		if err != nil {
			return false, err
		}
		if found && block.Active {
			return true, nil
		}
	}
	return false, nil
}

func orderedBlockPairs(first, second identity.PlayerID) ([][2]identity.PlayerID, error) {
	firstKey, err := BlockLockKey(first, second)
	if err != nil {
		return nil, err
	}
	secondKey, err := BlockLockKey(second, first)
	if err != nil {
		return nil, err
	}
	pairs := [][2]identity.PlayerID{{first, second}, {second, first}}
	if lockkey.Compare(secondKey, firstKey) < 0 {
		pairs[0], pairs[1] = pairs[1], pairs[0]
	}
	return pairs, nil
}
