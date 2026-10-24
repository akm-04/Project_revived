package socialrelationstore

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"math"
	"time"
)

func (Store) CountActiveFriendsTx(ctx context.Context, t tx.Tx, pid identity.PlayerID) (int64, error) {
	if t == nil || !pid.Valid() {
		return 0, socialrelation.ErrInvalidCommand
	}
	var n int64
	err := t.QueryRow(ctx, `SELECT count(*) FROM social_friendships WHERE active AND (player_low_id=$1 OR player_high_id=$1)`, int64(pid)).Scan(&n)
	if err != nil {
		return 0, err
	}
	if n < 0 {
		return 0, socialrelation.ErrInvalidState
	}
	return n, nil
}
func (Store) ActiveBlockTargetsTx(ctx context.Context, t tx.Tx, pid identity.PlayerID) ([]identity.PlayerID, error) {
	if t == nil || !pid.Valid() {
		return nil, socialrelation.ErrInvalidCommand
	}
	var raw string
	err := t.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(blocked_player_id ORDER BY blocked_player_id),'[]'::jsonb)::text FROM social_blocks WHERE blocker_player_id=$1 AND active`, int64(pid)).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var ids []int64
	if err := json.Unmarshal([]byte(raw), &ids); err != nil {
		return nil, err
	}
	out := make([]identity.PlayerID, len(ids))
	for i, id := range ids {
		pid := identity.PlayerID(id)
		if _, err := socialrelation.CanonicalServer(pid); err != nil {
			return nil, err
		}
		out[i] = pid
	}
	return out, nil
}
func effect(t tx.Tx, ctx context.Context, q string, args ...any) error {
	if t == nil {
		return errors.New("nil social transaction")
	}
	tag, err := t.Exec(ctx, q, args...)
	if err != nil {
		return err
	}
	if tag == nil || tag.RowsAffected() != 1 {
		return socialrelation.ErrStateConflict
	}
	return nil
}
func (Store) TouchRootTx(ctx context.Context, t tx.Tx, old socialrelation.Root, at time.Time) error {
	if err := old.Validate(); err != nil {
		return err
	}
	if old.StateVersion == math.MaxInt64 {
		return socialrelation.ErrCounterOverflow
	}
	if at.IsZero() || at.Before(old.CreatedAt) || at.Before(old.UpdatedAt) {
		return socialrelation.ErrStaleDecisionTime
	}
	return effect(t, ctx, `UPDATE player_social_roots SET state_version=state_version+1,updated_at=$3 WHERE player_id=$1 AND state_version=$2`, int64(old.PlayerID), old.StateVersion, at.UTC())
}
func (Store) PutFriendshipTx(ctx context.Context, t tx.Tx, old *socialrelation.Friendship, n socialrelation.Friendship) error {
	if err := n.Validate(); err != nil {
		return err
	}
	if old == nil {
		if n.Generation != 1 || n.StateVersion != 1 || !n.Active {
			return socialrelation.ErrInvalidState
		}
		return effect(t, ctx, `INSERT INTO social_friendships(player_low_id,player_high_id,generation,active,activated_at,ended_at,state_version,updated_at) VALUES($1,$2,$3,$4,$5,$6,$7,$8)`, int64(n.PlayerLowID), int64(n.PlayerHighID), n.Generation, n.Active, n.ActivatedAt, n.EndedAt, n.StateVersion, n.UpdatedAt)
	}
	if err := old.Validate(); err != nil {
		return err
	}
	if old.StateVersion == math.MaxInt64 || old.Generation == math.MaxInt64 && n.Active && !old.Active {
		return socialrelation.ErrCounterOverflow
	}
	if n.PlayerLowID != old.PlayerLowID || n.PlayerHighID != old.PlayerHighID || n.StateVersion != old.StateVersion+1 {
		return socialrelation.ErrStateConflict
	}
	return effect(t, ctx, `UPDATE social_friendships SET generation=$3,active=$4,activated_at=$5,ended_at=$6,state_version=$7,updated_at=$8 WHERE player_low_id=$1 AND player_high_id=$2 AND generation=$9 AND state_version=$10 AND active=$11`, int64(n.PlayerLowID), int64(n.PlayerHighID), n.Generation, n.Active, n.ActivatedAt, n.EndedAt, n.StateVersion, n.UpdatedAt, old.Generation, old.StateVersion, old.Active)
}
func (Store) PutRequestTx(ctx context.Context, t tx.Tx, old *socialrelation.FriendRequest, n socialrelation.FriendRequest) error {
	if err := n.Validate(); err != nil {
		return err
	}
	if old == nil {
		if n.Generation != 1 || n.StateVersion != 1 || n.Status != socialrelation.RequestPending {
			return socialrelation.ErrInvalidState
		}
		return effect(t, ctx, `INSERT INTO social_friend_requests(requester_player_id,target_player_id,generation,status,request_msg,requested_at,terminal_at,state_version,updated_at) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9)`, int64(n.RequesterPlayerID), int64(n.TargetPlayerID), n.Generation, string(n.Status), n.Message, n.RequestedAt, n.TerminalAt, n.StateVersion, n.UpdatedAt)
	}
	if err := old.Validate(); err != nil {
		return err
	}
	if old.StateVersion == math.MaxInt64 || old.Generation == math.MaxInt64 && n.Status == socialrelation.RequestPending && old.Status != socialrelation.RequestPending {
		return socialrelation.ErrCounterOverflow
	}
	if n.RequesterPlayerID != old.RequesterPlayerID || n.TargetPlayerID != old.TargetPlayerID || n.StateVersion != old.StateVersion+1 {
		return socialrelation.ErrStateConflict
	}
	return effect(t, ctx, `UPDATE social_friend_requests SET generation=$3,status=$4,request_msg=$5,requested_at=$6,terminal_at=$7,state_version=$8,updated_at=$9 WHERE requester_player_id=$1 AND target_player_id=$2 AND generation=$10 AND state_version=$11 AND status=$12`, int64(n.RequesterPlayerID), int64(n.TargetPlayerID), n.Generation, string(n.Status), n.Message, n.RequestedAt, n.TerminalAt, n.StateVersion, n.UpdatedAt, old.Generation, old.StateVersion, string(old.Status))
}
func (Store) PutBlockTx(ctx context.Context, t tx.Tx, old *socialrelation.Block, n socialrelation.Block) error {
	if err := n.Validate(); err != nil {
		return err
	}
	if old == nil {
		if n.Generation != 1 || n.StateVersion != 1 || !n.Active {
			return socialrelation.ErrInvalidState
		}
		return effect(t, ctx, `INSERT INTO social_blocks(blocker_player_id,blocked_player_id,generation,active,activated_at,removed_at,state_version,updated_at) VALUES($1,$2,$3,$4,$5,$6,$7,$8)`, int64(n.BlockerPlayerID), int64(n.BlockedPlayerID), n.Generation, n.Active, n.ActivatedAt, n.RemovedAt, n.StateVersion, n.UpdatedAt)
	}
	if err := old.Validate(); err != nil {
		return err
	}
	if old.StateVersion == math.MaxInt64 || old.Generation == math.MaxInt64 && n.Active && !old.Active {
		return socialrelation.ErrCounterOverflow
	}
	if n.BlockerPlayerID != old.BlockerPlayerID || n.BlockedPlayerID != old.BlockedPlayerID || n.StateVersion != old.StateVersion+1 {
		return socialrelation.ErrStateConflict
	}
	return effect(t, ctx, `UPDATE social_blocks SET generation=$3,active=$4,activated_at=$5,removed_at=$6,state_version=$7,updated_at=$8 WHERE blocker_player_id=$1 AND blocked_player_id=$2 AND generation=$9 AND state_version=$10 AND active=$11`, int64(n.BlockerPlayerID), int64(n.BlockedPlayerID), n.Generation, n.Active, n.ActivatedAt, n.RemovedAt, n.StateVersion, n.UpdatedAt, old.Generation, old.StateVersion, old.Active)
}
func (Store) PutRequestEpochTx(ctx context.Context, t tx.Tx, old *socialrelation.RequestEpoch, n socialrelation.RequestEpoch) error {
	if err := n.Validate(); err != nil {
		return err
	}
	if old == nil {
		if n.StateVersion != 1 {
			return socialrelation.ErrInvalidState
		}
		return effect(t, ctx, `INSERT INTO social_request_epochs(player_id,policy_id,epoch_generation,epoch_started_at,successful_new_requests,state_version,updated_at) VALUES($1,$2,$3,$4,$5,$6,$7)`, int64(n.PlayerID), n.PolicyID, n.EpochGeneration, n.EpochStartedAt, n.SuccessfulNewRequests, n.StateVersion, n.UpdatedAt)
	}
	if err := old.Validate(); err != nil {
		return err
	}
	if old.StateVersion == math.MaxInt64 {
		return socialrelation.ErrCounterOverflow
	}
	if n.PlayerID != old.PlayerID || n.PolicyID != old.PolicyID || n.EpochGeneration < old.EpochGeneration || n.StateVersion != old.StateVersion+1 {
		return socialrelation.ErrStateConflict
	}
	return effect(t, ctx, `UPDATE social_request_epochs SET epoch_generation=$3,epoch_started_at=$4,successful_new_requests=$5,state_version=$6,updated_at=$7 WHERE player_id=$1 AND policy_id=$2 AND epoch_generation=$8 AND state_version=$9`, int64(n.PlayerID), n.PolicyID, n.EpochGeneration, n.EpochStartedAt, n.SuccessfulNewRequests, n.StateVersion, n.UpdatedAt, old.EpochGeneration, old.StateVersion)
}

var _ socialrelation.CommandStore = Store{}
