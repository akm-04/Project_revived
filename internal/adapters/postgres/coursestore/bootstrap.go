package coursestore

import (
	"context"
	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type BootstrapContributor struct{ Revision string }

func (BootstrapContributor) Name() string   { return "i7c2e.course-progression" }
func (BootstrapContributor) Required() bool { return true }
func (s BootstrapContributor) PersistCharacterBootstrap(ctx context.Context, t tx.Tx, b logicalserver.BootstrapContext) error {
	return (Store{}).EnsureRootTx(ctx, t, b.PlayerID, s.Revision, b.Operation.StartedAt)
}

var _ appboot.CharacterBootstrapPersistenceContributor = BootstrapContributor{}
