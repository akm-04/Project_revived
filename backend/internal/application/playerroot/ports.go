package playerroot

import (
	"context"
	"errors"
	"sort"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// LockRank is the I4-owned canonical Player root rank used by shared-domain
// transactions. It intentionally sits after Guild root (310) and before
// GuildMembership (320), and far below I5 progression/economy ranks.
const LockRank uint16 = 315

var (
	ErrInvalidPlayerRootRequest = errors.New("invalid player root lock request")
	ErrPlayerRootNotFound       = errors.New("canonical player root not found")
	ErrPlayerServerMismatch     = errors.New("canonical player root logical server mismatch")
)

type Root struct {
	PlayerID        identity.PlayerID
	LogicalServerID identity.LogicalServerID
}

func (r Root) Validate() error {
	if !r.PlayerID.Valid() || !r.LogicalServerID.Valid() {
		return ErrInvalidPlayerRootRequest
	}
	return nil
}

// TxLocker is owned by I4/player-core. Shared domains may request canonical
// player-root locks but never query the players table directly.
type TxLocker interface {
	LockPlayerRootsTx(context.Context, tx.Tx, identity.LogicalServerID, []identity.PlayerID) ([]Root, error)
}

func CanonicalPlayerIDs(in []identity.PlayerID) ([]identity.PlayerID, error) {
	if len(in) == 0 {
		return nil, ErrInvalidPlayerRootRequest
	}
	out := append([]identity.PlayerID(nil), in...)
	for _, id := range out {
		if !id.Valid() {
			return nil, ErrInvalidPlayerRootRequest
		}
	}
	sort.Slice(out, func(i, j int) bool { return out[i] < out[j] })
	uniq := out[:0]
	for _, id := range out {
		if len(uniq) == 0 || uniq[len(uniq)-1] != id {
			uniq = append(uniq, id)
		}
	}
	return uniq, nil
}

func LockKey(id identity.PlayerID) (lockkey.Key, error) {
	if !id.Valid() {
		return lockkey.Key{}, ErrInvalidPlayerRootRequest
	}
	return lockkey.New(LockRank, "i4.player-root", lockkey.Int64(int64(id)))
}
