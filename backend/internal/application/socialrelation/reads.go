package socialrelation

import (
	"context"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// CandidateState exposes only SocialRelation facts, never presentation or quota.
type CandidateState struct {
	PlayerID                                  identity.PlayerID
	Friend, Blocked, Pending, OutgoingPending bool
}
type ProjectionReader interface {
	LockRootTx(context.Context, tx.Tx, identity.PlayerID) (Root, bool, error)
	ActiveFriendsTx(context.Context, tx.Tx, identity.PlayerID) ([]identity.PlayerID, error)
	InboundPendingTx(context.Context, tx.Tx, identity.PlayerID) ([]FriendRequest, error)
	ActiveBlocksForTx(context.Context, tx.Tx, identity.PlayerID) ([]identity.PlayerID, error)
	CandidateStatesTx(context.Context, tx.Tx, identity.PlayerID, []identity.PlayerID) ([]CandidateState, error)
}
