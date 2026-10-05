package socialinbox

import (
	"context"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Store is the I7A-4A SocialInbox owner-local foundation. Materialization and
// dismissal mutations are added only when their owning later substage is
// authorized.
type Store interface {
	NextNoticeIDTx(context.Context, tx.Queryer) (NoticeID, error)
	LockNoticeTx(context.Context, tx.Tx, identity.PlayerID, NoticeID) (Notice, bool, error)
}
