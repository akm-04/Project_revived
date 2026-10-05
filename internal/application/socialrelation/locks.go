package socialrelation

import (
	"errors"
	"fmt"

	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/lockkey"
)

const (
	LockRankSocialRoot   uint16 = 360
	LockRankFriendship   uint16 = 361
	LockRankRequest      uint16 = 362
	LockRankBlock        uint16 = 363
	LockRankRequestEpoch uint16 = 364
)

const (
	SocialRootUniqueConstraint   = "player_social_roots_pkey"
	FriendshipUniqueConstraint   = "social_friendships_pkey"
	RequestUniqueConstraint      = "social_friend_requests_pkey"
	BlockUniqueConstraint        = "social_blocks_pkey"
	RequestEpochUniqueConstraint = "social_request_epochs_pkey"
)

var ErrInvalidLockKey = errors.New("invalid social relation lock key")

func CanonicalPair(a, b identity.PlayerID) (identity.PlayerID, identity.PlayerID, error) {
	if !a.Valid() || !b.Valid() || a == b {
		return 0, 0, ErrInvalidLockKey
	}
	if a < b {
		return a, b, nil
	}
	return b, a, nil
}

func SocialRootLockKey(pid identity.PlayerID) (lockkey.Key, error) {
	if !pid.Valid() {
		return lockkey.Key{}, ErrInvalidLockKey
	}
	return lockkey.New(LockRankSocialRoot, "social-relation.root", lockkey.Int64(int64(pid)))
}

func SocialRootCreationFence(pid identity.PlayerID) (lockkey.CreationFence, error) {
	parent, err := playerroot.LockKey(pid)
	if err != nil {
		return lockkey.CreationFence{}, err
	}
	f := lockkey.CreationFence{Parent: parent, UniqueConstraint: SocialRootUniqueConstraint}
	return f, f.Validate()
}

func FriendshipLockKey(a, b identity.PlayerID) (lockkey.Key, error) {
	low, high, err := CanonicalPair(a, b)
	if err != nil {
		return lockkey.Key{}, err
	}
	return lockkey.New(LockRankFriendship, "social-relation.friendship", lockkey.String(fmt.Sprintf("%d:%d", low, high)))
}

func RequestLockKey(requester, target identity.PlayerID) (lockkey.Key, error) {
	if !requester.Valid() || !target.Valid() || requester == target {
		return lockkey.Key{}, ErrInvalidLockKey
	}
	return lockkey.New(LockRankRequest, "social-relation.request", lockkey.String(fmt.Sprintf("%d:%d", requester, target)))
}

func BlockLockKey(blocker, blocked identity.PlayerID) (lockkey.Key, error) {
	if !blocker.Valid() || !blocked.Valid() || blocker == blocked {
		return lockkey.Key{}, ErrInvalidLockKey
	}
	return lockkey.New(LockRankBlock, "social-relation.block", lockkey.String(fmt.Sprintf("%d:%d", blocker, blocked)))
}

func RequestEpochLockKey(pid identity.PlayerID, policyID string) (lockkey.Key, error) {
	if !pid.Valid() || policyID == "" {
		return lockkey.Key{}, ErrInvalidLockKey
	}
	return lockkey.New(LockRankRequestEpoch, "social-relation.request-epoch", lockkey.String(fmt.Sprintf("%d:%s", pid, policyID)))
}
