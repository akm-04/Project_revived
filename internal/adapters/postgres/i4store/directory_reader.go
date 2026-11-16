package i4store

import (
	"context"
	"encoding/json"
	"errors"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type PlayerDirectoryReader struct{ Queryer tx.Queryer }

func (r PlayerDirectoryReader) Profile(ctx context.Context, pid identity.PlayerID) (playerdirectory.Profile, bool, error) {
	return r.ProfileTx(ctx, r.Queryer, pid)
}

// PlayerLevelTx projects the same directory level a provider needs inside a
// caller snapshot.
func (r PlayerDirectoryReader) PlayerLevelTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID) (int64, bool, error) {
	profile, found, err := r.ProfileTx(ctx, q, pid)
	return profile.Level, found, err
}

func (PlayerDirectoryReader) ProfileTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID) (playerdirectory.Profile, bool, error) {
	if q == nil || !pid.Valid() {
		return playerdirectory.Profile{}, false, errors.New("invalid player directory read")
	}
	var p playerdirectory.Profile
	var rawPID int64
	err := q.QueryRow(ctx, `SELECT player_id,name,lev,avatar_id,avatar_frame_id,conquer_lev,conquer_loop_id FROM player_directory_profiles WHERE player_id=$1`, int64(pid)).Scan(&rawPID, &p.Name, &p.Level, &p.AvatarID, &p.AvatarFrameID, &p.ConquerLevel, &p.ConquerLoopID)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return playerdirectory.Profile{}, false, nil
	}
	if err != nil {
		return playerdirectory.Profile{}, false, err
	}
	p.PlayerID = identity.PlayerID(rawPID)
	if err := p.Validate(); err != nil {
		return playerdirectory.Profile{}, false, err
	}
	return p, true, nil
}

// ProfilesTx is the batched directory read for a board page: one statement,
// missing players simply absent from the map.
func (PlayerDirectoryReader) ProfilesTx(c context.Context, q tx.Queryer, ids []identity.PlayerID) (map[identity.PlayerID]playerdirectory.Profile, error) {
	out := map[identity.PlayerID]playerdirectory.Profile{}
	if q == nil {
		return out, errors.New("invalid player directory read")
	}
	if len(ids) == 0 {
		return out, nil
	}
	rawIDs := make([]int64, 0, len(ids))
	for _, pid := range ids {
		if !pid.Valid() {
			return out, errors.New("invalid player directory read")
		}
		rawIDs = append(rawIDs, int64(pid))
	}
	var raw string
	err := q.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_object('player_id',player_id,'name',name,'lev',lev,'avatar_id',avatar_id,'avatar_frame_id',avatar_frame_id,'conquer_lev',conquer_lev,'conquer_loop_id',conquer_loop_id)),'[]'::jsonb)::text FROM player_directory_profiles WHERE player_id=ANY($1)`, rawIDs).Scan(&raw)
	if err != nil {
		return out, err
	}
	var wire []struct {
		PlayerID      int64  `json:"player_id"`
		Name          string `json:"name"`
		Level         int64  `json:"lev"`
		AvatarID      int64  `json:"avatar_id"`
		AvatarFrameID int64  `json:"avatar_frame_id"`
		ConquerLevel  int64  `json:"conquer_lev"`
		ConquerLoopID int64  `json:"conquer_loop_id"`
	}
	if err = json.Unmarshal([]byte(raw), &wire); err != nil {
		return out, err
	}
	for _, w := range wire {
		p := playerdirectory.Profile{PlayerID: identity.PlayerID(w.PlayerID), Name: w.Name, Level: w.Level, AvatarID: w.AvatarID, AvatarFrameID: w.AvatarFrameID, ConquerLevel: w.ConquerLevel, ConquerLoopID: w.ConquerLoopID}
		if err = p.Validate(); err != nil {
			return out, err
		}
		out[p.PlayerID] = p
	}
	return out, nil
}

// ServerTx resolves one player's canonical logical server. It is a single-row
// lookup, never an enumeration.
func (PlayerDirectoryReader) ServerTx(c context.Context, q tx.Queryer, pid identity.PlayerID) (identity.LogicalServerID, bool, error) {
	if q == nil || !pid.Valid() {
		return 0, false, errors.New("invalid player server read")
	}
	var server int64
	err := q.QueryRow(c, `SELECT logical_server_id FROM players WHERE player_id=$1`, int64(pid)).Scan(&server)
	if errors.Is(err, kernelstore.ErrNoRows) {
		return 0, false, nil
	}
	if err != nil {
		return 0, false, err
	}
	out := identity.LogicalServerID(server)
	if !out.Valid() {
		return 0, false, errors.New("invalid player server")
	}
	return out, true, nil
}

var _ playerdirectory.Reader = PlayerDirectoryReader{}

func (PlayerDirectoryReader) ServerMaximumLevelTx(requestContext context.Context, query tx.Queryer, server identity.LogicalServerID) (int64, error) {
	if query == nil || !server.Valid() {
		return 0, errors.New("invalid server directory read")
	}
	const playerIDsPerServer = 100000
	firstPlayer, lastPlayer := int64(server)*playerIDsPerServer, (int64(server)+1)*playerIDsPerServer
	var level int64
	err := query.QueryRow(requestContext, `SELECT COALESCE(max(lev),0) FROM player_directory_profiles WHERE player_id >= $1 AND player_id < $2`, firstPlayer, lastPlayer).Scan(&level)
	return level, err
}
