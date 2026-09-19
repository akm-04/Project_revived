package directorysync

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// CanonicalSnapshot contains only I5-owned facts that R6 is qualified to
// maintain in the I4 MID18 directory projection. VIP/conquest remain outside
// this snapshot and must be preserved by the I4 sink.
type CanonicalSnapshot struct {
	PlayerID      identity.PlayerID
	Name          string
	Level         int64
	AvatarID      int64
	AvatarFrameID int64
}

func (s CanonicalSnapshot) Validate() error {
	if !s.PlayerID.Valid() || s.Level < 1 || s.AvatarID <= 0 {
		return errors.New("invalid canonical directory snapshot")
	}
	return nil
}

type ProjectionSnapshot struct {
	Name          string
	Level         int64
	AvatarID      int64
	AvatarFrameID int64
	StateVersion  int64
}

func (s ProjectionSnapshot) Validate() error {
	if s.Level < 1 || s.AvatarID <= 0 || s.StateVersion <= 0 {
		return errors.New("invalid directory projection snapshot")
	}
	return nil
}

type CanonicalSource interface {
	ReadCanonicalDirectoryTx(context.Context, tx.Queryer, identity.PlayerID) (CanonicalSnapshot, error)
}

type ProjectionSink interface {
	LockOwnedDirectoryTx(context.Context, tx.Tx, identity.PlayerID) (ProjectionSnapshot, error)
	ApplyOwnedDirectoryTx(context.Context, tx.Tx, CanonicalSnapshot, int64, operation.Context) error
}

type Reconciler struct {
	Source CanonicalSource
	Sink   ProjectionSink
}

// ReconcileDirectoryTx must run inside the caller's SERIALIZABLE transaction.
// This prevents an out-of-transaction stale canonical snapshot from overwriting
// a newer D01 directory-level projection. PostgreSQL SSI overlap is an R7 live
// proof obligation; this function preserves the required transaction shape.
func (r Reconciler) ReconcileDirectoryTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, op operation.Context) error {
	if r.Source == nil || r.Sink == nil || t == nil || !pid.Valid() || op.StartedAt.IsZero() {
		return errors.New("invalid directory reconciliation input")
	}
	canonical, err := r.Source.ReadCanonicalDirectoryTx(ctx, t, pid)
	if err != nil {
		return err
	}
	if err := canonical.Validate(); err != nil {
		return err
	}
	current, err := r.Sink.LockOwnedDirectoryTx(ctx, t, pid)
	if err != nil {
		return err
	}
	if err := current.Validate(); err != nil {
		return err
	}
	if canonical.Name == current.Name && canonical.Level == current.Level && canonical.AvatarID == current.AvatarID && canonical.AvatarFrameID == current.AvatarFrameID {
		return nil
	}
	return r.Sink.ApplyOwnedDirectoryTx(ctx, t, canonical, current.StateVersion, op)
}
