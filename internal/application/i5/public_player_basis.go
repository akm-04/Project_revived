package i5

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type PublicPlayerBasis struct {
	Profile     player.Profile
	Progression player.Progression
	Functions   []player.FunctionUnlock
}

func (b PublicPlayerBasis) Validate() error {
	if b.Profile.Validate() != nil || b.Progression.Validate() != nil || b.Profile.PlayerID != b.Progression.PlayerID {
		return errors.New("invalid public Player basis")
	}
	var previous int64
	for _, f := range b.Functions {
		if f.Validate() != nil || f.PlayerID != b.Profile.PlayerID || f.FunctionID <= previous {
			return errors.New("invalid public Player function basis")
		}
		previous = f.FunctionID
	}
	return nil
}

// Consumer supplies a single witnessed RR/Serializable transaction. No clock, content or pool fallback.
type PublicPlayerBasisReader interface {
	ReadPublicPlayerBasisTx(context.Context, tx.Queryer, identity.PlayerID) (PublicPlayerBasis, error)
}
