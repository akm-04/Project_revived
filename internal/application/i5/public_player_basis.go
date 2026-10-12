package i5

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
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

// Canonical bounded name selection happens before derived row enrichment.
type PublicPlayerNameReader interface {
	ReadPlayerIDsByExactNameTx(context.Context, tx.Queryer, string, int) ([]identity.PlayerID, error)
}

// Effective display is a narrow typed Player owner observation; callers pin
// revision and instant in their existing coherent transaction.
type EffectivePlayerDisplay struct {
	AvatarID, AvatarFrameID            int64
	TitleInfo, BubbleInfo              map[string]any
	ProfileVersion, ProgressionVersion int64
	ObservedAt                         time.Time
	ContentRevision                    string
}
type TxEffectivePlayerDisplayReader interface {
	ReadEffectivePlayerDisplayTx(context.Context, tx.Queryer, identity.PlayerID, string, time.Time) (EffectivePlayerDisplay, error)
}
