package bootstrap

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// AccountCredentials is the stock account-scope SID+login_token pair used by
// MID18/MID1 before any gameplay bearer exists. These raw values are perimeter
// inputs only and must never be persisted or logged.

var ErrAccountAuth = errors.New("account bootstrap authentication failed")

type AccountCredentials struct {
	SID        string
	LoginToken string
}

// MID1DirectoryReconciler is the R6 typed composition seam. Implementations
// read canonical Player Core ownership and update only I4-owned directory
// projection columns inside the caller's MID1 SERIALIZABLE transaction.
type MID1DirectoryReconciler interface {
	ReconcileDirectoryTx(context.Context, tx.Tx, identity.PlayerID, operation.Context) error
}

type RuntimeMID1Request struct {
	Credentials AccountCredentials
	Region      identity.LogicalServerID
	Operation   operation.Context
}

// RuntimePort is the narrow I4 stock-bootstrap application seam. The concrete
// PostgreSQL adapter owns persistence mechanics; protocol adapters see only the
// source-shaped application operations.
type RuntimePort interface {
	MID18(context.Context, AccountCredentials, operation.Context) (MID18Result, error)
	MID1(context.Context, RuntimeMID1Request) (MID1Result, error)
}
