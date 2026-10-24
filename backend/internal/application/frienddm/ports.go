package frienddm

import (
	"context"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

// Store accesses only FriendDM-owned facts using caller transactions. Snapshot
// locks only an existing recipient root; the caller's I4 root fences absence.
type Store interface {
	ReferencePending(context.Context, tx.Queryer, Reference) (bool, error)
	Snapshot(context.Context, tx.Queryer, identity.PlayerID, bool) (Manifest, error)
	FindOccurrence(context.Context, tx.Queryer, string) (Occurrence, bool, error)
	FindProjection(context.Context, tx.Queryer, string) (ProjectionReceipt, bool, error)
	InsertTx(context.Context, tx.Tx, Manifest, Occurrence) error
	ApplyTx(context.Context, tx.Tx, Manifest, []Change, time.Time) error
	InsertProjectionTx(context.Context, tx.Tx, ProjectionReceipt) error
	PendingRecipients(context.Context, tx.Queryer, identity.PlayerID, identity.PlayerID, int) ([]identity.PlayerID, error)
	PendingHighWater(context.Context, tx.Queryer) (identity.PlayerID, error)
}
type EmoticonDefinition struct {
	ID, ItemID int64
	Revision   string
}
type OwnerFenceReader interface {
	AssertOwnerFenceTx(context.Context, tx.Tx, int64) error
	ReadOwnerFenceTx(context.Context, tx.Queryer) (int64, error)
}
type EmoticonContentReader interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	ResolveEmoticonTx(context.Context, tx.Tx, string, int64) (EmoticonDefinition, error)
}
type EmoticonEntitlementReader interface {
	PrepareEmoticonEntitlementTx(context.Context, tx.Tx, identity.PlayerID, string, int64, time.Time) (int64, error)
}
