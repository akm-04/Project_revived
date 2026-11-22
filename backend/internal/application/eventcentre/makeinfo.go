package eventcentre

import (
	"context"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// MakeInfoTx projects the desk and pet-room make state for the building list
// (MID 1056). It is a read: the settled clone is never saved, so a caller's
// transaction cannot advance make state through this method.
func (s Service) MakeInfoTx(ctx context.Context, q tx.Queryer, player identity.PlayerID, at time.Time) (map[string]any, map[string]any, error) {
	desk := map[string]any{"is_making": int64(0), "make_need_time": int64(0), "make_start_time": int64(0), "make_item": int64(0)}
	pet := map[string]any{"is_making": int64(0), "make_need_time": int64(0), "make_start_time": int64(0), "make_item": int64(0), "pet_id": int64(0)}
	if s.Owner == nil || !player.Valid() || at.IsZero() {
		return nil, nil, ErrUnqualified
	}
	root, exists, err := s.Owner.ReadRootTx(ctx, q, player)
	if err != nil {
		return nil, nil, err
	}
	if !exists {
		return desk, pet, nil
	}
	state := root.Facts.Clone()
	if err = state.SettleMakes(at); err != nil {
		return nil, nil, err
	}
	if desk, err = MakeWire(DeskBuilding, state.Desk, at); err != nil {
		return nil, nil, err
	}
	if pet, err = MakeWire(PetRoomBuilding, state.Pet, at); err != nil {
		return nil, nil, err
	}
	return desk, pet, nil
}
