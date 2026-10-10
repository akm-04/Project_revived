package publicprofile

import (
	"context"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/profile"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type Root struct {
	PlayerID             identity.PlayerID
	Preferences          profile.Preferences
	StateVersion         int64
	CreatedAt, UpdatedAt time.Time
}

func (r Root) Validate() error {
	if !r.PlayerID.Valid() || r.StateVersion <= 0 || r.CreatedAt.IsZero() || r.UpdatedAt.IsZero() || r.UpdatedAt.Before(r.CreatedAt) || r.Preferences.Validate() != nil {
		return ErrInvalidState
	}
	return nil
}
func (r Root) Clone() Root { r.Preferences = r.Preferences.Clone(); return r }

type Store interface {
	ReadRootTx(context.Context, tx.Queryer, identity.PlayerID) (Root, bool, error)
	LockRootTx(context.Context, tx.Tx, identity.PlayerID) (Root, bool, error)
	InsertRootTx(context.Context, tx.Tx, Root) error
	UpdateRootTx(context.Context, tx.Tx, Root, Root) error
}
