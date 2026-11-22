package mentor

import (
	"context"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	domain "gxb.local/backend/v2/internal/domain/mentor"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// AddDailyBondTx is the gift-owner seam that raises the pair's bond by the
// source daily amount at most once per day. The caller already fenced both I4
// player roots and its own player lock; this method only locks the relation row.
func (service Service) AddDailyBondTx(ctx context.Context, t tx.Tx, first, second identity.PlayerID, at time.Time) error {
	if t == nil || !first.Valid() || !second.Valid() || first == second || at.IsZero() {
		return domain.ErrInvalid
	}
	if logicalserver.PlayerRegion(first) != logicalserver.PlayerRegion(second) {
		return nil
	}
	catalog, err := service.catalog()
	if err != nil {
		return err
	}
	rules := rulesFromCatalog(catalog)
	relations, err := service.Store.LockRelationshipsTx(ctx, t, first, logicalserver.PlayerRegion(first))
	if err != nil {
		return fmt.Errorf("bond relation lock: %w", err)
	}
	for _, relation := range relations {
		if relation.Mentor != second && relation.Student != second {
			continue
		}
		today := gameDate(at)
		next, changed := domain.ApplyIntimacy(relation.Intimacy, rules.IntimacyDaily, rules.IntimacyCap, relation.LastIntimacyDay, today)
		if !changed {
			return nil
		}
		if err := service.Store.AddIntimacyTx(ctx, t, relation, next, today, at.UTC()); err != nil {
			return fmt.Errorf("bond update: %w", err)
		}
		mentor := relation.Mentor
		return advanceMissionCategoryTx(ctx, t, service.Store, mentor, missionsFromCatalog(catalog), domain.MissionTypeMentor, domain.CategoryBond, next, at)
	}
	return nil
}
