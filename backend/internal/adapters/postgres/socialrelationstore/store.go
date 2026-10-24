package socialrelationstore

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{}

const ensureRootSQL = `
INSERT INTO player_social_roots(player_id,state_version,created_at,updated_at)
VALUES($1,1,$2,$2)
ON CONFLICT(player_id) DO NOTHING`

const lockRootSQL = `SELECT player_id,state_version,created_at,updated_at FROM player_social_roots WHERE player_id=$1 FOR UPDATE`

const lockFriendshipSQL = `
SELECT player_low_id,player_high_id,generation,active,activated_at,ended_at,state_version,updated_at
FROM social_friendships
WHERE player_low_id=$1 AND player_high_id=$2
FOR UPDATE`

const lockRequestSQL = `
SELECT requester_player_id,target_player_id,generation,status,request_msg,requested_at,terminal_at,state_version,updated_at
FROM social_friend_requests
WHERE requester_player_id=$1 AND target_player_id=$2
FOR UPDATE`

const lockBlockSQL = `
SELECT blocker_player_id,blocked_player_id,generation,active,activated_at,removed_at,state_version,updated_at
FROM social_blocks
WHERE blocker_player_id=$1 AND blocked_player_id=$2
FOR UPDATE`

const lockRequestEpochSQL = `
SELECT player_id,policy_id,epoch_generation,epoch_started_at,successful_new_requests,state_version,updated_at
FROM social_request_epochs
WHERE player_id=$1 AND policy_id=$2
FOR UPDATE`

func (Store) EnsureRootTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, now time.Time) (socialrelation.Root, error) {
	if t == nil || !pid.Valid() || now.IsZero() {
		return socialrelation.Root{}, errors.New("social relation store: invalid root ensure")
	}
	if _, err := t.Exec(ctx, ensureRootSQL, int64(pid), now.UTC()); err != nil {
		return socialrelation.Root{}, err
	}
	root, ok, err := (Store{}).LockRootTx(ctx, t, pid)
	if err != nil {
		return socialrelation.Root{}, err
	}
	if !ok {
		return socialrelation.Root{}, errors.New("social relation store: ensured root missing")
	}
	return root, nil
}

func (Store) LockRootTx(ctx context.Context, t tx.Tx, pid identity.PlayerID) (socialrelation.Root, bool, error) {
	if t == nil || !pid.Valid() {
		return socialrelation.Root{}, false, errors.New("social relation store: invalid root lock")
	}
	var out socialrelation.Root
	var rawPID int64
	if err := t.QueryRow(ctx, lockRootSQL, int64(pid)).Scan(&rawPID, &out.StateVersion, &out.CreatedAt, &out.UpdatedAt); err != nil {
		if noRows(err) {
			return socialrelation.Root{}, false, nil
		}
		return socialrelation.Root{}, false, err
	}
	out.PlayerID = identity.PlayerID(rawPID)
	out.CreatedAt = out.CreatedAt.UTC()
	out.UpdatedAt = out.UpdatedAt.UTC()
	if err := out.Validate(); err != nil {
		return socialrelation.Root{}, false, err
	}
	return out, true, nil
}

func (Store) LockFriendshipTx(ctx context.Context, t tx.Tx, a, b identity.PlayerID) (socialrelation.Friendship, bool, error) {
	if t == nil {
		return socialrelation.Friendship{}, false, errors.New("social relation store: nil transaction")
	}
	low, high, err := socialrelation.CanonicalPair(a, b)
	if err != nil {
		return socialrelation.Friendship{}, false, err
	}
	var out socialrelation.Friendship
	var rawLow, rawHigh int64
	if err := t.QueryRow(ctx, lockFriendshipSQL, int64(low), int64(high)).Scan(&rawLow, &rawHigh, &out.Generation, &out.Active, &out.ActivatedAt, &out.EndedAt, &out.StateVersion, &out.UpdatedAt); err != nil {
		if noRows(err) {
			return socialrelation.Friendship{}, false, nil
		}
		return socialrelation.Friendship{}, false, err
	}
	out.PlayerLowID, out.PlayerHighID = identity.PlayerID(rawLow), identity.PlayerID(rawHigh)
	out.ActivatedAt, out.UpdatedAt = out.ActivatedAt.UTC(), out.UpdatedAt.UTC()
	out.EndedAt = utcPtr(out.EndedAt)
	if err := out.Validate(); err != nil {
		return socialrelation.Friendship{}, false, err
	}
	return out, true, nil
}

func (Store) LockRequestTx(ctx context.Context, t tx.Tx, requester, target identity.PlayerID) (socialrelation.FriendRequest, bool, error) {
	if t == nil || !requester.Valid() || !target.Valid() || requester == target {
		return socialrelation.FriendRequest{}, false, errors.New("social relation store: invalid request lock")
	}
	var out socialrelation.FriendRequest
	var rawRequester, rawTarget int64
	var status string
	if err := t.QueryRow(ctx, lockRequestSQL, int64(requester), int64(target)).Scan(&rawRequester, &rawTarget, &out.Generation, &status, &out.Message, &out.RequestedAt, &out.TerminalAt, &out.StateVersion, &out.UpdatedAt); err != nil {
		if noRows(err) {
			return socialrelation.FriendRequest{}, false, nil
		}
		return socialrelation.FriendRequest{}, false, err
	}
	out.RequesterPlayerID, out.TargetPlayerID = identity.PlayerID(rawRequester), identity.PlayerID(rawTarget)
	out.Status = socialrelation.RequestStatus(status)
	out.RequestedAt, out.UpdatedAt = out.RequestedAt.UTC(), out.UpdatedAt.UTC()
	out.TerminalAt = utcPtr(out.TerminalAt)
	if err := out.Validate(); err != nil {
		return socialrelation.FriendRequest{}, false, err
	}
	return out, true, nil
}

func (Store) LockBlockTx(ctx context.Context, t tx.Tx, blocker, blocked identity.PlayerID) (socialrelation.Block, bool, error) {
	if t == nil || !blocker.Valid() || !blocked.Valid() || blocker == blocked {
		return socialrelation.Block{}, false, errors.New("social relation store: invalid block lock")
	}
	var out socialrelation.Block
	var rawBlocker, rawBlocked int64
	if err := t.QueryRow(ctx, lockBlockSQL, int64(blocker), int64(blocked)).Scan(&rawBlocker, &rawBlocked, &out.Generation, &out.Active, &out.ActivatedAt, &out.RemovedAt, &out.StateVersion, &out.UpdatedAt); err != nil {
		if noRows(err) {
			return socialrelation.Block{}, false, nil
		}
		return socialrelation.Block{}, false, err
	}
	out.BlockerPlayerID, out.BlockedPlayerID = identity.PlayerID(rawBlocker), identity.PlayerID(rawBlocked)
	out.ActivatedAt, out.UpdatedAt = out.ActivatedAt.UTC(), out.UpdatedAt.UTC()
	out.RemovedAt = utcPtr(out.RemovedAt)
	if err := out.Validate(); err != nil {
		return socialrelation.Block{}, false, err
	}
	return out, true, nil
}

func (Store) LockRequestEpochTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, policyID string) (socialrelation.RequestEpoch, bool, error) {
	if t == nil || !pid.Valid() || policyID == "" {
		return socialrelation.RequestEpoch{}, false, errors.New("social relation store: invalid request epoch lock")
	}
	var out socialrelation.RequestEpoch
	var rawPID int64
	if err := t.QueryRow(ctx, lockRequestEpochSQL, int64(pid), policyID).Scan(&rawPID, &out.PolicyID, &out.EpochGeneration, &out.EpochStartedAt, &out.SuccessfulNewRequests, &out.StateVersion, &out.UpdatedAt); err != nil {
		if noRows(err) {
			return socialrelation.RequestEpoch{}, false, nil
		}
		return socialrelation.RequestEpoch{}, false, err
	}
	out.PlayerID = identity.PlayerID(rawPID)
	out.EpochStartedAt, out.UpdatedAt = out.EpochStartedAt.UTC(), out.UpdatedAt.UTC()
	if err := out.Validate(); err != nil {
		return socialrelation.RequestEpoch{}, false, err
	}
	return out, true, nil
}

func noRows(err error) bool { return errors.Is(err, kernelstore.ErrNoRows) }

func utcPtr(v *time.Time) *time.Time {
	if v == nil {
		return nil
	}
	x := v.UTC()
	return &x
}

var _ socialrelation.Store = Store{}
