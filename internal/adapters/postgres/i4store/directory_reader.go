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
	if r.Queryer == nil || !pid.Valid() {
		return playerdirectory.Profile{}, false, errors.New("invalid player directory read")
	}
	var p playerdirectory.Profile
	var rawPID int64
	err := r.Queryer.QueryRow(ctx, `SELECT player_id,name,lev,avatar_id,avatar_frame_id,conquer_lev,conquer_loop_id FROM player_directory_profiles WHERE player_id=$1`, int64(pid)).Scan(&rawPID, &p.Name, &p.Level, &p.AvatarID, &p.AvatarFrameID, &p.ConquerLevel, &p.ConquerLoopID)
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
