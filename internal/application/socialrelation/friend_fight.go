package socialrelation

import (
	"context"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/tx"
	"slices"
	"time"
)

type FriendFightPrivacy struct {
	ChangedAt            time.Time
	Eligible             bool
	FriendshipGeneration int64
	BlockVersions        [2]int64
}

type FriendFightPrivacyReader interface {
	PrepareFriendFightPrivacyTx(context.Context, tx.Tx, identity.PlayerID, identity.PlayerID) (FriendFightPrivacy, error)
}

type FriendFightPrivacyProvider struct{ Store Store }

// The caller holds both I4 roots315; Social locks360/361/363 follow in canonical order.
func (provider FriendFightPrivacyProvider) PrepareFriendFightPrivacyTx(requestContext context.Context, transaction tx.Tx, first, second identity.PlayerID) (FriendFightPrivacy, error) {
	result := FriendFightPrivacy{}
	if provider.Store == nil || transaction == nil || first == second {
		return result, ErrInvalidState
	}
	for _, player := range []identity.PlayerID{first, second} {
		if _, err := CanonicalServer(player); err != nil {
			return result, err
		}
	}
	if first > second {
		first, second = second, first
	}
	present := true
	for _, player := range []identity.PlayerID{first, second} {
		root, found, err := provider.Store.LockRootTx(requestContext, transaction, player)
		if err != nil {
			return result, err
		}
		if found && (root.Validate() != nil || root.PlayerID != player) {
			return result, ErrInvalidState
		}
		present = present && found
	}
	friendship, found, err := provider.Store.LockFriendshipTx(requestContext, transaction, first, second)
	if err != nil {
		return result, err
	}
	if found && friendship.Validate() != nil {
		return result, ErrInvalidState
	}
	result.Eligible = present && found && friendship.Active
	if found {
		result.FriendshipGeneration = friendship.Generation
		result.ChangedAt = friendship.UpdatedAt
	}
	pairs := [][2]identity.PlayerID{{first, second}, {second, first}}
	slices.SortFunc(pairs, func(left, right [2]identity.PlayerID) int {
		firstKey, _ := BlockLockKey(left[0], left[1])
		secondKey, _ := BlockLockKey(right[0], right[1])
		return lockkey.Compare(firstKey, secondKey)
	})
	for _, pair := range pairs {
		index := 0
		if pair[0] != first {
			index = 1
		}
		block, found, err := provider.Store.LockBlockTx(requestContext, transaction, pair[0], pair[1])
		if err != nil {
			return result, err
		}
		if !found {
			continue
		}
		if block.Validate() != nil {
			return result, ErrInvalidState
		}
		result.BlockVersions[index] = block.StateVersion
		if block.UpdatedAt.After(result.ChangedAt) {
			result.ChangedAt = block.UpdatedAt
		}
		result.Eligible = result.Eligible && !block.Active
	}
	return result, nil
}
