package directorysync

import (
	"context"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

// VIP facts are Commerce-owned; the I4 projection owner alone writes its derived
// directory field. Existing I5 reconciliation deliberately preserves this field.
type PreparedVIPProjection interface {
	Apply(context.Context, tx.Tx) error
}
type VIPProjectionPort interface {
	PrepareVIPProjectionTx(context.Context, tx.Tx, identity.PlayerID, int64, time.Time) (PreparedVIPProjection, error)
}
