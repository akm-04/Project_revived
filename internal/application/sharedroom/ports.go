package sharedroom

import (
	"context"
	"time"

	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Store owns the shared_rooms and shared_room_seats tables. The room row is the
// rank-607 lock; seats are read and written under it. The wakeup is emitted on
// the caller's transaction so PostgreSQL delivers it only on commit.
type Store interface {
	ReadRoomTx(context.Context, tx.Queryer, int64) (d.Room, bool, error)
	ReadPlayerRoomTx(context.Context, tx.Queryer, identity.PlayerID, string, int64) (d.Room, bool, error)
	LockRoomTx(context.Context, tx.Tx, int64) (d.Room, bool, error)
	OpenRoomTx(context.Context, tx.Tx, d.Room) (d.Room, error)
	SaveRoomTx(context.Context, tx.Tx, d.Room) error
	ExpiredRoomIDsTx(context.Context, tx.Queryer, identity.LogicalServerID, time.Time, int) ([]int64, error)
	WakeRoomTx(context.Context, tx.Tx, int64, string) error
}

type Fence interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}

// Players is the I4 player root lock at rank 315. Roots are locked ascending
// for every member a command touches.
type Players interface {
	LockPlayerRootsTx(context.Context, tx.Tx, identity.LogicalServerID, []identity.PlayerID) ([]playerroot.Root, error)
}
