package bootstrap

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// CharacterBootstrapOperationBinder binds new-character policy before any
// player-root mutation. Callers retain the returned context across retries.
type CharacterBootstrapOperationBinder interface {
	BindCharacterBootstrapOperation(context.Context, tx.Queryer, operation.Context) (operation.Context, error)
}

// CharacterBootstrapPersistenceContributor owns required canonical state that
// must be created in the same caller-owned MID1 transaction as the player root.
// It receives no generic database/service handle: the concrete adapter remains
// responsible for writing only its owner's tables through the supplied tx.Tx.
type CharacterBootstrapPersistenceContributor interface {
	Name() string
	Required() bool
	PersistCharacterBootstrap(context.Context, tx.Tx, logicalserver.BootstrapContext) error
}

func ValidatePersistenceContributors(cs []CharacterBootstrapPersistenceContributor) error {
	seen := map[string]struct{}{}
	for _, c := range cs {
		if c == nil {
			return errors.New("nil character bootstrap persistence contributor")
		}
		name := strings.TrimSpace(c.Name())
		if name == "" {
			return errors.New("character bootstrap persistence contributor name required")
		}
		if _, ok := seen[name]; ok {
			return fmt.Errorf("duplicate character bootstrap persistence contributor %q", name)
		}
		seen[name] = struct{}{}
		// No optional non-fatal bootstrap persistence policy has been frozen.
		// Reject such registrations rather than silently swallowing owner
		// failures and exposing a half-character.
		if !c.Required() {
			return fmt.Errorf("optional bootstrap persistence contributor %q has no frozen non-fatal policy", name)
		}
	}
	return nil
}

func ApplyPersistenceContributors(ctx context.Context, t tx.Tx, b logicalserver.BootstrapContext, cs []CharacterBootstrapPersistenceContributor) error {
	if t == nil {
		return errors.New("character bootstrap persistence requires caller transaction")
	}
	if err := ValidatePersistenceContributors(cs); err != nil {
		return err
	}
	for _, c := range cs {
		if err := c.PersistCharacterBootstrap(ctx, t, b); err != nil {
			return fmt.Errorf("required bootstrap contributor %s: %w", c.Name(), err)
		}
	}
	return nil
}
