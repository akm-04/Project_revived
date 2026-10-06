package socialinbox

import (
	"context"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// RelationWindowReader projects only typed, active, non-null relation notices.
type RelationWindowReader interface {
	RelationWindowTx(context.Context, tx.Tx, identity.PlayerID) ([]Notice, error)
}
