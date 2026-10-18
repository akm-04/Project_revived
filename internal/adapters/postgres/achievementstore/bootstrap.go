package achievementstore

import (
	"context"
	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type BootstrapContributor struct{ Revision string }

func (BootstrapContributor) Name() string   { return "i7c4b.achievement-facts" }
func (BootstrapContributor) Required() bool { return true }
func (b BootstrapContributor) PersistCharacterBootstrap(c context.Context, t tx.Tx, s logicalserver.BootstrapContext) error {
	return (Store{}).InitFreshTx(c, t, s.PlayerID, b.Revision, s.Operation.StartedAt)
}

var _ appboot.CharacterBootstrapPersistenceContributor = BootstrapContributor{}
