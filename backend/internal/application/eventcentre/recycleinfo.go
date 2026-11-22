package eventcentre

import (
	"context"
	"time"

	appbook "gxb.local/backend/v2/internal/application/bookskill"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// RecycleInfoTx projects the canonical recycle energy snapshot at the applied
// building level for a caller that changed that level in its own transaction
// (the Book type-3 speed-up). It is a read: the settled clone is never saved.
func (s Service) RecycleInfoTx(ctx context.Context, q tx.Queryer, player identity.PlayerID, revision string, at time.Time) (map[string]any, error) {
	if s.Owner == nil || s.Book == nil || s.Content == nil || !player.Valid() || len(revision) != 64 || at.IsZero() {
		return nil, ErrUnqualified
	}
	root, exists, err := s.Owner.ReadRootTx(ctx, q, player)
	if err != nil {
		return nil, err
	}
	var state State
	if exists {
		state = root.Facts.Clone()
	} else {
		state = Seed()
	}
	catalog, err := s.Content.WorkshopInputsTx(ctx, q, revision)
	if err != nil {
		return nil, err
	}
	inputs, err := s.Book.BookInputsTx(ctx, q, appbook.InputScope{Player: player, ContentRevision: revision, ObservedAt: at})
	if err != nil {
		return nil, err
	}
	if err = state.Validate(); err != nil {
		return nil, err
	}
	if err = state.SettleMakes(at); err != nil {
		return nil, err
	}
	limit, err := catalog.EnergyLimit(buildingLevel(inputs, RecycleBuilding))
	if err != nil {
		return nil, err
	}
	wire, err := RecycleWire(state, limit, catalog.Misc.SaturationSeconds, at)
	if err != nil {
		return nil, err
	}
	return map[string]any{"energy": wire["energy"], "energy_time": wire["energy_time"]}, nil
}
