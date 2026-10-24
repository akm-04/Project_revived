package socialrelationstore

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

func readJSON(c context.Context, t tx.Tx, q string, out any, args ...any) error {
	if t == nil {
		return errors.New("nil relation read transaction")
	}
	var raw string
	if e := t.QueryRow(c, q, args...).Scan(&raw); e != nil {
		return e
	}
	return json.Unmarshal([]byte(raw), out)
}

const activeFriendsSQL = `SELECT COALESCE(jsonb_agg(other ORDER BY other),'[]'::jsonb)::text FROM (SELECT CASE WHEN player_low_id=$1 THEN player_high_id ELSE player_low_id END other FROM social_friendships WHERE active AND (player_low_id=$1 OR player_high_id=$1)) t`
const activeBlocksForSQL = `SELECT COALESCE(jsonb_agg(blocked_player_id ORDER BY blocked_player_id),'[]'::jsonb)::text FROM social_blocks WHERE blocker_player_id=$1 AND active`

func readIDs(c context.Context, t tx.Tx, q string, p identity.PlayerID) ([]identity.PlayerID, error) {
	if !p.Valid() {
		return nil, socialrelation.ErrInvalidState
	}
	out := []identity.PlayerID{}
	if e := readJSON(c, t, q, &out, int64(p)); e != nil {
		return nil, e
	}
	var prev identity.PlayerID
	for _, id := range out {
		if !id.Valid() || id == p || id <= prev {
			return nil, socialrelation.ErrInvalidState
		}
		prev = id
	}
	return out, nil
}
func (Store) ActiveFriendsTx(c context.Context, t tx.Tx, p identity.PlayerID) ([]identity.PlayerID, error) {
	return readIDs(c, t, activeFriendsSQL, p)
}
func (Store) ActiveBlocksForTx(c context.Context, t tx.Tx, p identity.PlayerID) ([]identity.PlayerID, error) {
	return readIDs(c, t, activeBlocksForSQL, p)
}

const inboundPendingSQL = `SELECT COALESCE(jsonb_agg(to_jsonb(r) ORDER BY requested_at DESC,requester_player_id),'[]'::jsonb)::text FROM social_friend_requests r WHERE target_player_id=$1 AND status='PENDING'`

type requestRow struct {
	Requester  int64                        `json:"requester_player_id"`
	Target     int64                        `json:"target_player_id"`
	Generation int64                        `json:"generation"`
	Status     socialrelation.RequestStatus `json:"status"`
	Message    string                       `json:"request_msg"`
	Requested  time.Time                    `json:"requested_at"`
	Terminal   *time.Time                   `json:"terminal_at"`
	Version    int64                        `json:"state_version"`
	Updated    time.Time                    `json:"updated_at"`
}

func (Store) InboundPendingTx(c context.Context, t tx.Tx, p identity.PlayerID) ([]socialrelation.FriendRequest, error) {
	if !p.Valid() {
		return nil, socialrelation.ErrInvalidState
	}
	var rows []requestRow
	if e := readJSON(c, t, inboundPendingSQL, &rows, int64(p)); e != nil {
		return nil, e
	}
	out := make([]socialrelation.FriendRequest, 0, len(rows))
	for _, r := range rows {
		v := socialrelation.FriendRequest{RequesterPlayerID: identity.PlayerID(r.Requester), TargetPlayerID: identity.PlayerID(r.Target), Generation: r.Generation, Status: r.Status, Message: r.Message, RequestedAt: r.Requested.UTC(), TerminalAt: utcPtr(r.Terminal), StateVersion: r.Version, UpdatedAt: r.Updated.UTC()}
		if v.Validate() != nil || v.TargetPlayerID != p || v.Status != socialrelation.RequestPending {
			return nil, socialrelation.ErrInvalidState
		}
		out = append(out, v)
	}
	return out, nil
}

const candidateStatesSQL = `SELECT COALESCE(jsonb_agg(jsonb_build_object('PlayerID',p,'Friend',EXISTS(SELECT 1 FROM social_friendships WHERE active AND player_low_id=LEAST($1,p) AND player_high_id=GREATEST($1,p)),'Blocked',EXISTS(SELECT 1 FROM social_blocks WHERE active AND ((blocker_player_id=$1 AND blocked_player_id=p) OR (blocker_player_id=p AND blocked_player_id=$1))),'Pending',EXISTS(SELECT 1 FROM social_friend_requests WHERE status='PENDING' AND ((requester_player_id=$1 AND target_player_id=p) OR (requester_player_id=p AND target_player_id=$1))),'OutgoingPending',EXISTS(SELECT 1 FROM social_friend_requests WHERE status='PENDING' AND requester_player_id=$1 AND target_player_id=p)) ORDER BY p),'[]'::jsonb)::text FROM unnest($2::bigint[]) p`

func (Store) CandidateStatesTx(c context.Context, t tx.Tx, p identity.PlayerID, ids []identity.PlayerID) ([]socialrelation.CandidateState, error) {
	if t == nil || !p.Valid() {
		return nil, socialrelation.ErrInvalidState
	}
	out := []socialrelation.CandidateState{}
	if len(ids) == 0 {
		return out, nil
	}
	raw := make([]int64, len(ids))
	seen := map[identity.PlayerID]bool{}
	for i, id := range ids {
		if !id.Valid() || seen[id] {
			return nil, socialrelation.ErrInvalidState
		}
		seen[id] = true
		raw[i] = int64(id)
	}
	if e := readJSON(c, t, candidateStatesSQL, &out, int64(p), raw); e != nil {
		return nil, e
	}
	if len(out) != len(ids) {
		return nil, socialrelation.ErrInvalidState
	}
	for _, v := range out {
		if !seen[v.PlayerID] || v.OutgoingPending && !v.Pending {
			return nil, socialrelation.ErrInvalidState
		}
		delete(seen, v.PlayerID)
	}
	return out, nil
}

var _ socialrelation.ProjectionReader = Store{}
