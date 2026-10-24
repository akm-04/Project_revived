package bootstrap

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// CharacterLoginReconciler performs narrowly owned, idempotent reconciliation
// inside the caller-owned MID1 transaction before mutable detail projection.
// It is distinct from first-character persistence and may run on every login.
type CharacterLoginReconciler interface {
	Name() string
	ReconcileCharacterLogin(context.Context, tx.Tx, identity.ActorContext, operation.Context) error
}

func ValidateLoginReconcilers(rs []CharacterLoginReconciler) error {
	seen := map[string]struct{}{}
	for _, r := range rs {
		if r == nil {
			return errors.New("nil character login reconciler")
		}
		n := strings.TrimSpace(r.Name())
		if n == "" {
			return errors.New("character login reconciler name required")
		}
		if _, ok := seen[n]; ok {
			return fmt.Errorf("duplicate character login reconciler %q", n)
		}
		seen[n] = struct{}{}
	}
	return nil
}
func ApplyLoginReconcilers(ctx context.Context, t tx.Tx, actor identity.ActorContext, op operation.Context, rs []CharacterLoginReconciler) error {
	if t == nil {
		return errors.New("character login reconciliation requires caller transaction")
	}
	if err := ValidateLoginReconcilers(rs); err != nil {
		return err
	}
	for _, r := range rs {
		if err := r.ReconcileCharacterLogin(ctx, t, actor, op); err != nil {
			return fmt.Errorf("login reconciler %s: %w", r.Name(), err)
		}
	}
	return nil
}
