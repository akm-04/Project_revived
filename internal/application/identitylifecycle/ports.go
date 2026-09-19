// Package identitylifecycle owns the transactional application boundary for
// durable account/provider/session lifecycle. Provider SDK/network ingress is
// deliberately outside this package; callers pass already-validated evidence.
package identitylifecycle

import (
	"context"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Store is owner-shaped: it exposes identity lifecycle operations only, and
// every write receives the caller-owned Wave-A transaction.
type Store interface {
	LockAccountTx(context.Context, tx.Tx, identity.AccountID) (identity.Account, error)

	FindProviderBindingTx(context.Context, tx.Tx, identity.ProviderPrincipal) (*identity.ProviderBinding, error)
	InsertProviderBindingTx(context.Context, tx.Tx, identity.ProviderBinding) error

	InsertSessionTx(context.Context, tx.Tx, identity.Session) error
	InsertSessionCredentialTx(context.Context, tx.Tx, identity.SessionCredential) error

	// Revocation lock order is session -> live context -> credential updates.
	LockSessionTx(context.Context, tx.Tx, identity.SessionID) (identity.Session, error)
	LockLiveContextTx(context.Context, tx.Tx, identity.SessionID) (*identity.GameplayContext, error)
	SaveRevokedSessionTx(context.Context, tx.Tx, identity.Session, int64) error
	SaveEndedContextTx(context.Context, tx.Tx, identity.GameplayContext, int64) error
	RevokeSessionCredentialsTx(context.Context, tx.Tx, identity.SessionID, time.Time) error
	RevokeGameplayCredentialsTx(context.Context, tx.Tx, identity.SessionID, time.Time) error

	// TouchSessionActivityTx must be a conditional/coalesced write. It may only
	// advance last_activity_at for a live, idle-expiry-enabled session whose
	// stored timestamp is older than cutoff.
	TouchSessionActivityTx(context.Context, tx.Tx, identity.SessionID, time.Time, time.Time) (bool, error)
}

// RevocationNotifier is a post-commit optimization only. PostgreSQL liveness
// remains canonical even when this hint is lost.
type RevocationNotifier interface {
	SessionRevoked(context.Context, identity.SessionID, string) error
}
