package rankingstore

import (
	"context"
	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	d "gxb.local/backend/v2/internal/domain/ranking"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// BootstrapContributor is called only inside I4's fresh unpublished namespace
// transaction. It is never a login reconciler or a legacy backfill.
type BootstrapContributor struct{}

func (BootstrapContributor) Name() string   { return "i7c4c.girls-ranking-origin-history" }
func (BootstrapContributor) Required() bool { return true }
func (BootstrapContributor) PersistCharacterBootstrap(c context.Context, t tx.Tx, b logicalserver.BootstrapContext) error {
	for _, board := range d.Boards {
		if e := (Store{}).FreshBoardTrackingTx(c, t, board, b.PlayerID, b.LogicalServerID, b.Operation.StartedAt); e != nil {
			return e
		}
	}
	return nil
}

var _ appboot.CharacterBootstrapPersistenceContributor = BootstrapContributor{}
