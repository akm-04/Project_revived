package publication

import (
	"fmt"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	pub "gxb.local/backend/v2/internal/domain/publication"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/lockkey"
)

func MarkerLockKey(player identity.PlayerID, set ids.UUID) (lockkey.Key, error) {
	if !player.Valid() || set.IsZero() {
		return lockkey.Key{}, pub.ErrInvalid
	}
	return lockkey.New(pub.MarkerLockRank, "publication.picture-read", lockkey.String(fmt.Sprintf("%020d:%s", player, set.String())))
}
func MarkerCreationFence(player identity.PlayerID) (lockkey.CreationFence, error) {
	key, e := playerroot.LockKey(player)
	if e != nil {
		return lockkey.CreationFence{}, e
	}
	f := lockkey.CreationFence{Parent: key, UniqueConstraint: "publication_picture_reads_pkey"}
	return f, f.Validate()
}
