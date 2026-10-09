package playerroot

import (
	"context"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
	"unicode/utf8"
)

// NameSnapshot is the I4 directory name projection retained from its canonical
// I5 feed. ChangedAt is the directory row's update timestamp, a conservative
// snapshot fence (also changes on level/avatar updates), not a rename timestamp.
type NameSnapshot struct {
	PlayerID  identity.PlayerID
	Server    identity.LogicalServerID
	Name      string
	ChangedAt time.Time
}

func (n NameSnapshot) Validate() error {
	if !n.PlayerID.Valid() || !n.Server.Valid() || !utf8.ValidString(n.Name) || n.ChangedAt.IsZero() {
		return ErrInvalidPlayerRootRequest
	}
	return nil
}

type NameReader interface {
	ReadNameSnapshotTx(context.Context, tx.Queryer, identity.PlayerID) (NameSnapshot, error)
}
