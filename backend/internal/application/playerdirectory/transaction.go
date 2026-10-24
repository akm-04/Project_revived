package playerdirectory

import (
	"context"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// TxDiscoveryReader is I4-owned discovery using exactly the caller transaction.
type TxDiscoveryReader interface {
	ProfileTx(context.Context, tx.Tx, identity.PlayerID) (Profile, bool, error)
	ProfilesByExactNameTx(context.Context, tx.Tx, string, int) ([]Profile, error)
	PlayerIDBoundsTx(context.Context, tx.Tx) (identity.PlayerID, identity.PlayerID, bool, error)
	ProfilesAfterTx(context.Context, tx.Tx, identity.PlayerID, int) ([]Profile, error)
}
