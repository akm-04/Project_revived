package dormstore

import (
	"context"
	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Revision is the installed immutable definition revision selected in owning
// composition, never an active-version lookup under bootstrap locks.
type BootstrapContributor struct{ Revision string }

func (BootstrapContributor) Name() string   { return "i7c2c.dorm-house" }
func (BootstrapContributor) Required() bool { return true }
func (s BootstrapContributor) PersistCharacterBootstrap(ctx context.Context, t tx.Tx, b logicalserver.BootstrapContext) error {
	return (Store{}).EnsureRootTx(ctx, t, b.PlayerID, s.Revision, b.Operation.StartedAt)
}

var _ appboot.CharacterBootstrapPersistenceContributor = BootstrapContributor{}
