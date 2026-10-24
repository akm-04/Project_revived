package socialinbox

import (
	"context"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

// RelationWindowReader projects only typed, active, non-null relation notices.
type RelationWindowReader interface {
	RelationWindowTx(context.Context, tx.Tx, identity.PlayerID) ([]Notice, error)
}

// NoticePageReader reads owner rows in a strict keyset order, without selection
// or value mutations. The composer bounds work and validates recognized owners.
type NoticeCursor struct {
	At time.Time
	ID NoticeID
}
type NoticePageReader interface {
	NoticePageTx(context.Context, tx.Tx, identity.PlayerID, NoticeCursor, int) ([]Notice, error)
}
