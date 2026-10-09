package playerroot

import (
	"context"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// RecipientRoot retains typed absence only after the I4 allocator proves the
// already-bound ID is below its monotonic cursor. It is not a generic no-row.
type RecipientRoot struct {
	Root            Root
	NonReusedAbsent bool
}
type RecipientLocker interface {
	LockBoundRecipientTx(context.Context, tx.Tx, identity.LogicalServerID, identity.PlayerID) (RecipientRoot, error)
}
