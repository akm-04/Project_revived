package compat

import (
	"context"
	"time"

	"gxb.local/backend/v2/internal/application/playerroot"
	d "gxb.local/backend/v2/internal/domain/compat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Store owns player_compat_preferences. LockTx creates the row for a new
// player with first_main_touch = 0; the migration backfilled existing players
// with 1, so a player without a row is new.
type Store interface {
	ReadTx(context.Context, tx.Queryer, identity.PlayerID) (d.Preferences, bool, error)
	LockTx(context.Context, tx.Tx, identity.PlayerID, time.Time) (d.Preferences, error)
	SaveTx(context.Context, tx.Tx, identity.PlayerID, d.Preferences, int64, time.Time) error
}

// Content reads the compiled message-push id set for the active revision.
type Content interface {
	ActiveRevision(context.Context, tx.Queryer) (string, error)
	MessagePushCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error)
}

// Players takes the I4 player root lock (FOR NO KEY UPDATE).
type Players interface {
	LockPlayerRootsTx(context.Context, tx.Tx, identity.LogicalServerID, []identity.PlayerID) ([]playerroot.Root, error)
}

// Fence is the rank-315 actor fence.
type Fence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}
