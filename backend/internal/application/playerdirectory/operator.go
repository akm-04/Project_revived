package playerdirectory

import (
	"context"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// OperatorPlayer is the read-only player row the operator tool shows.
type OperatorPlayer struct {
	PlayerID        identity.PlayerID
	AccountUID      string
	Name            string
	Level           int64
	LogicalServerID identity.LogicalServerID
	CreatedAt       time.Time
	LastLoginAt     *time.Time
}

// OperatorFind is the bounded player.find query. At least one of UID and
// NamePrefix is required so the read never enumerates the directory.
type OperatorFind struct {
	UID        string
	NamePrefix string
	ServerID   *int64
	Limit      int
}

// OperatorReader is I4's operator read port; it owns the SQL.
type OperatorReader interface {
	FindPlayersTx(context.Context, tx.Queryer, OperatorFind) ([]OperatorPlayer, error)
	OperatorPlayerTx(context.Context, tx.Queryer, identity.PlayerID) (OperatorPlayer, bool, error)
}

// OperatorRecipients is I4's bounded recipient enumeration for a bulk target.
type OperatorRecipients interface {
	ServerPlayerIDsTx(context.Context, tx.Queryer, identity.LogicalServerID, int) ([]identity.PlayerID, error)
	AllPlayerIDsTx(context.Context, tx.Queryer, int) ([]identity.PlayerID, error)
}
