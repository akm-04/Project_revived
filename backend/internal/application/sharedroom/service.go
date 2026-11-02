package sharedroom

import (
	"context"
	"errors"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var (
	ErrUnavailable   = errors.New("shared room: service unavailable")
	ErrNotFound      = errors.New("shared room: room not found")
	ErrNotInRoom     = errors.New("shared room: no active room for the player")
	ErrAlreadyInRoom = errors.New("shared room: player already has an active room")
	ErrConflict      = errors.New("shared room: room changed during the command")
	ErrInvalidFamily = errors.New("shared room: invalid family")
)

// Family identifies one family slot and the realtime wakeup route its read MID
// owns. The room core never branches on the family name.
type Family struct {
	Name  string
	Slot  int64
	Route string
}

func (f Family) validate() error {
	if f.Name == "" || len(f.Name) > d.MaxFamilyLength || f.Slot < 0 || f.Route == "" {
		return ErrInvalidFamily
	}
	return nil
}

type Service struct {
	Timed   gen.TimedRunner
	Fresh   tx.Queryer
	Store   Store
	Fence   Fence
	Players Players
}

func (s Service) ready() bool {
	return s.Fresh != nil && s.Store != nil && s.Fence != nil && s.Players != nil
}

func profile() tx.Profile {
	return tx.Profile{Name: "shared-room", AcquireTimeout: 2 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 10 * time.Second, TransactionTimeout: 30 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 10 * time.Second, OperationTimeout: 60 * time.Second}
}

// retry is the shared-row abort budget of I9-SHARED-ROOM (8 attempts, 20-80 ms).
func retry() tx.RetryPolicy {
	return tx.RetryPolicy{MaxAttempts: 8, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 80 * time.Millisecond}
}

func (s Service) run(c context.Context, op operation.Context, body func(context.Context, gen.TimedScope) error) error {
	if !s.ready() {
		return ErrUnavailable
	}
	_, _, err := s.Timed.Run(c, op, profile(), tx.Options{Isolation: tx.Serializable}, retry(), nil, body)
	return err
}

// lockRoots locks every touched player's I4 root in ascending order before the
// room row, so a room command can never invert the declared lock order.
func (s Service) lockRoots(c context.Context, t tx.Tx, server identity.LogicalServerID, players []identity.PlayerID) error {
	canonical, err := playerroot.CanonicalPlayerIDs(players)
	if err != nil {
		return err
	}
	_, err = s.Players.LockPlayerRootsTx(c, t, server, canonical)
	return err
}

func roomDiffers(observed, locked d.Room) bool {
	return observed.ID != locked.ID || observed.StateVersion != locked.StateVersion
}
