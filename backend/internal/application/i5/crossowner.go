package i5

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// TxScalarDebiter is the I5-owned cross-domain seam for debiting canonical
// scalar currency inside a caller-owned transaction. Callers never access I5
// tables directly and must enter this port only after lower-ranked owner locks.
type TxScalarDebiter interface {
	DebitScalarTx(context.Context, tx.Tx, identity.PlayerID, string, int64, time.Time) (economy.ScalarBalance, error)
}

// TxPlayerLevelReader is the I5-owned same-transaction progression seam used by
// another owner to authorize a mutation from canonical player level.
type TxPlayerLevelReader interface {
	PlayerLevelTx(context.Context, tx.Tx, identity.PlayerID) (int64, error)
}

// CrossOwner composes narrow I5-owned ports without exposing the much wider I5
// Service/Store surface to shared domains.
type CrossOwner struct {
	Store CrossOwnerBackend
}

type CrossOwnerBackend interface {
	LockEconomyOwnerTx(context.Context, tx.Tx, identity.PlayerID) error
	LockScalarTx(context.Context, tx.Tx, identity.PlayerID, string, time.Time) (economy.ScalarBalance, bool, error)
	SaveScalarTx(context.Context, tx.Tx, economy.ScalarBalance, bool) error
	LockPlayerLevelTx(context.Context, tx.Tx, identity.PlayerID) (int64, error)
}

func (c CrossOwner) DebitScalarTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, key string, amount int64, now time.Time) (economy.ScalarBalance, error) {
	if c.Store == nil || t == nil || !pid.Valid() || key == "" || amount <= 0 || now.IsZero() {
		return economy.ScalarBalance{}, errors.New("i5 cross-owner scalar debit: invalid input")
	}
	if err := c.Store.LockEconomyOwnerTx(ctx, t, pid); err != nil {
		return economy.ScalarBalance{}, err
	}
	b, exists, err := c.Store.LockScalarTx(ctx, t, pid, key, now.UTC())
	if err != nil {
		return economy.ScalarBalance{}, err
	}
	if !exists {
		return economy.ScalarBalance{}, economy.ErrUnknownResource
	}
	next, err := b.Debit(amount, now.UTC())
	if err != nil {
		return economy.ScalarBalance{}, err
	}
	if err := c.Store.SaveScalarTx(ctx, t, next, true); err != nil {
		return economy.ScalarBalance{}, err
	}
	return next, nil
}

func (c CrossOwner) PlayerLevelTx(ctx context.Context, t tx.Tx, pid identity.PlayerID) (int64, error) {
	if c.Store == nil || t == nil || !pid.Valid() {
		return 0, errors.New("i5 cross-owner level read: invalid input")
	}
	level, err := c.Store.LockPlayerLevelTx(ctx, t, pid)
	if err != nil {
		return 0, err
	}
	if level <= 0 {
		return 0, errors.New("i5 cross-owner level read: invalid canonical level")
	}
	return level, nil
}

// TxLevelAndScalarDebiter is the combined I5-owned seam for operations such as
// Guild creation that require both a canonical level gate and scalar debit. It
// structurally acquires I5 locks in rank order: economy owner (700), progression
// (710), scalar (720). This prevents callers from composing the two narrower
// ports in an order that would invert I5's accepted lock plan.
type TxLevelAndScalarDebiter interface {
	AuthorizeLevelAndDebitScalarTx(context.Context, tx.Tx, identity.PlayerID, int64, string, int64, time.Time) (int64, economy.ScalarBalance, error)
}

var ErrLevelRequirement = errors.New("canonical player level below requirement")

func (c CrossOwner) AuthorizeLevelAndDebitScalarTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, minLevel int64, key string, amount int64, now time.Time) (int64, economy.ScalarBalance, error) {
	if c.Store == nil || t == nil || !pid.Valid() || minLevel <= 0 || key == "" || amount <= 0 || now.IsZero() {
		return 0, economy.ScalarBalance{}, errors.New("i5 cross-owner level+debit: invalid input")
	}
	if err := c.Store.LockEconomyOwnerTx(ctx, t, pid); err != nil {
		return 0, economy.ScalarBalance{}, err
	}
	level, err := c.Store.LockPlayerLevelTx(ctx, t, pid)
	if err != nil {
		return 0, economy.ScalarBalance{}, err
	}
	if level < minLevel {
		return level, economy.ScalarBalance{}, ErrLevelRequirement
	}
	b, exists, err := c.Store.LockScalarTx(ctx, t, pid, key, now.UTC())
	if err != nil {
		return level, economy.ScalarBalance{}, err
	}
	if !exists {
		return level, economy.ScalarBalance{}, economy.ErrUnknownResource
	}
	next, err := b.Debit(amount, now.UTC())
	if err != nil {
		return level, economy.ScalarBalance{}, err
	}
	if err := c.Store.SaveScalarTx(ctx, t, next, true); err != nil {
		return level, economy.ScalarBalance{}, err
	}
	return level, next, nil
}
