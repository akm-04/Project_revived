package spirit

import (
	"context"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// LockTrialInventoryTx keeps Trial capacity observation inside the canonical owner.
func (s Service) LockTrialInventoryTx(c context.Context, t tx.Tx, p identity.PlayerID) (int64, error) {
	root, e := s.Owner.LockRootTx(c, t, p)
	if e != nil {
		return 0, e
	}
	return int64(len(root.Facts.Instances)), nil
}
