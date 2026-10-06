package socialrelationstore

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const readRootSQL = `SELECT player_id,state_version,created_at,updated_at FROM player_social_roots WHERE player_id=$1`
const readRequestSQL = `SELECT requester_player_id,target_player_id,generation,status,request_msg,requested_at,terminal_at,state_version,updated_at FROM social_friend_requests WHERE requester_player_id=$1 AND target_player_id=$2`

func (Store) ReadRootTx(ctx context.Context, t tx.Tx, pid identity.PlayerID) (socialrelation.Root, bool, error) {
	if t == nil || !pid.Valid() {
		return socialrelation.Root{}, false, errors.New("social relation store: invalid root lock")
	}
	var out socialrelation.Root
	var rawPID int64
	if err := t.QueryRow(ctx, readRootSQL, int64(pid)).Scan(&rawPID, &out.StateVersion, &out.CreatedAt, &out.UpdatedAt); err != nil {
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

func (Store) ReadRequestTx(ctx context.Context, t tx.Tx, requester, target identity.PlayerID) (socialrelation.FriendRequest, bool, error) {
	if t == nil || !requester.Valid() || !target.Valid() || requester == target {
		return socialrelation.FriendRequest{}, false, errors.New("social relation store: invalid request lock")
	}
	var out socialrelation.FriendRequest
	var rawRequester, rawTarget int64
	var status string
	if err := t.QueryRow(ctx, readRequestSQL, int64(requester), int64(target)).Scan(&rawRequester, &rawTarget, &out.Generation, &status, &out.Message, &out.RequestedAt, &out.TerminalAt, &out.StateVersion, &out.UpdatedAt); err != nil {
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

var _ socialrelation.ReloadReader = Store{}
