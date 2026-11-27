package i5

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// OperatorWallet is the read-only economy part of the operator player summary.
// The resource keys are the client's own currency names: mana is the gold
// currency and crystal the premium one.
type OperatorWallet struct {
	Gold     int64
	Crystals int64
	VIPLevel int64
}

// OperatorWalletReader is I5's port for the operator player summary.
type OperatorWalletReader interface {
	OperatorWalletTx(context.Context, tx.Queryer, identity.PlayerID, time.Time) (OperatorWallet, error)
}

// OperatorWalletService reads the two currencies and VIP through their owning
// readers; it never touches another owner's tables.
type OperatorWalletService struct {
	Store      Store
	Privileges PrivilegeSnapshotProvider
}

func (s OperatorWalletService) OperatorWalletTx(ctx context.Context, q tx.Queryer, player identity.PlayerID, at time.Time) (OperatorWallet, error) {
	if q == nil || !player.Valid() || at.IsZero() {
		return OperatorWallet{}, errors.New("invalid operator wallet read")
	}
	gold, _, err := s.Store.ReadScalarTx(ctx, q, player, "mana")
	if err != nil {
		return OperatorWallet{}, err
	}
	crystals, _, err := s.Store.ReadScalarTx(ctx, q, player, "crystal")
	if err != nil {
		return OperatorWallet{}, err
	}
	if s.Privileges == nil {
		return OperatorWallet{}, errors.New("operator wallet privilege provider unavailable")
	}
	privilege, err := s.Privileges.SnapshotTx(ctx, q, player, at)
	if err != nil {
		return OperatorWallet{}, err
	}
	return OperatorWallet{Gold: gold.Amount, Crystals: crystals.Amount, VIPLevel: privilege.VIPLevel}, nil
}

var _ OperatorWalletReader = OperatorWalletService{}
