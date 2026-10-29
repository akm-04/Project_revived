package i4store

import (
	"context"
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
