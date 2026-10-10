package publicprofile

import (
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/lockkey"
)

const LockRankRoot uint16 = 391
const RootUniqueConstraint = "player_public_profile_roots_pkey"

func RootLockKey(pid identity.PlayerID) (lockkey.Key, error) {
	if !pid.Valid() {
		return lockkey.Key{}, ErrInvalidState
	}
	return lockkey.New(LockRankRoot, "public-profile.root", lockkey.Int64(int64(pid)))
}
func RootCreationFence(pid identity.PlayerID) (lockkey.CreationFence, error) {
	p, e := playerroot.LockKey(pid)
	if e != nil {
		return lockkey.CreationFence{}, e
	}
	f := lockkey.CreationFence{Parent: p, UniqueConstraint: RootUniqueConstraint}
	return f, f.Validate()
}
