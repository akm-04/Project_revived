package playerdirectory

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/domain/identity"
)

var ErrProfileNotFound = errors.New("canonical player directory profile not found")

type Profile struct {
	PlayerID      identity.PlayerID
	Name          string
	Level         int64
	AvatarID      int64
	AvatarFrameID int64
	ConquerLevel  int64
	ConquerLoopID int64
}

func (p Profile) Validate() error {
	if !p.PlayerID.Valid() || p.Level < 1 || p.AvatarID < 0 || p.AvatarFrameID < 0 || p.ConquerLevel < 0 || p.ConquerLoopID < 0 {
		return errors.New("invalid player directory profile")
	}
	return nil
}

type Reader interface {
	Profile(context.Context, identity.PlayerID) (Profile, bool, error)
}

// DiscoveryReader is the additive I4-owned directory selection seam introduced
// by I7A-4A. It contains no Social policy: callers decide search semantics,
// exclusions, paging strategy, and presentation composition themselves.
type DiscoveryReader interface {
	ProfilesByExactName(context.Context, string, int) ([]Profile, error)
	PlayerIDBounds(context.Context) (min identity.PlayerID, max identity.PlayerID, ok bool, err error)
	ProfilesAfter(context.Context, identity.PlayerID, int) ([]Profile, error)
}
