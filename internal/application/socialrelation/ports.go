package socialrelation

import (
	"context"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Store is the SocialRelation owner-local persistence seam established by
// I7A-4A. Mutation methods are intentionally absent until I7A-4B.
type Store interface {
	EnsureRootTx(context.Context, tx.Tx, identity.PlayerID, time.Time) (Root, error)
	LockRootTx(context.Context, tx.Tx, identity.PlayerID) (Root, bool, error)
	LockFriendshipTx(context.Context, tx.Tx, identity.PlayerID, identity.PlayerID) (Friendship, bool, error)
	LockRequestTx(context.Context, tx.Tx, identity.PlayerID, identity.PlayerID) (FriendRequest, bool, error)
	LockBlockTx(context.Context, tx.Tx, identity.PlayerID, identity.PlayerID) (Block, bool, error)
	LockRequestEpochTx(context.Context, tx.Tx, identity.PlayerID, string) (RequestEpoch, bool, error)
}
