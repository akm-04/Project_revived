package characterpet

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type EquipmentStateStore interface {
	ReadPetByIDTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Pet, error)
}

type EquipmentStateContent interface {
	PetEquipmentRevisionTx(context.Context, tx.Queryer, string) (bool, error)
	PetEquipmentPositionTx(context.Context, tx.Queryer, string, int64, int64, int64) (character.PetEquipmentPosition, error)
}

// EquipmentStateReader completes the CA4-deferred Pet stat-consumer export
// seam. It reads CA4-owned durable state only; it does not compute final stats.
type EquipmentStateReader struct {
	Store   EquipmentStateStore
	Content EquipmentStateContent
}

func (r EquipmentStateReader) RawEquipmentStateTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, petID int64, revision string) (characterasset.RawEquipmentState, error) {
	if r.Store == nil || r.Content == nil || q == nil || !pid.Valid() || petID <= 0 || characterasset.ValidateExactRevisionID(revision) != nil {
		return characterasset.RawEquipmentState{}, errors.New("character pet: invalid equipment-state read")
	}
	good, err := r.Content.PetEquipmentRevisionTx(ctx, q, revision)
	if err != nil {
		return characterasset.RawEquipmentState{}, err
	}
	if !good {
		return characterasset.RawEquipmentState{}, ErrPetEquipmentContentInactive
	}
	p, err := r.Store.ReadPetByIDTx(ctx, q, pid, petID)
	if err != nil {
		return characterasset.RawEquipmentState{}, err
	}
	if err := p.ValidatePersistent(); err != nil {
		return characterasset.RawEquipmentState{}, err
	}
	out := characterasset.RawEquipmentState{
		Family: "PET", OwnerID: p.PetID, StateVersion: p.StateVersion,
		Slots: make([]characterasset.RawEquipmentSlot, 0, character.PetEquipmentSlotCount),
	}
	for slot := int64(1); slot <= character.PetEquipmentSlotCount; slot++ {
		collected, err := p.Equipment.Value(slot)
		if err != nil {
			return characterasset.RawEquipmentState{}, err
		}
		rawFumo, err := p.Fumo.Value(slot)
		if err != nil {
			return characterasset.RawEquipmentState{}, err
		}
		row := characterasset.RawEquipmentSlot{Slot: slot, RawFumo: rawFumo}
		if collected != 0 {
			pos, err := r.Content.PetEquipmentPositionTx(ctx, q, revision, p.TableID, p.Color, slot)
			if err != nil {
				return characterasset.RawEquipmentState{}, err
			}
			if !pos.ItemID.Valid() {
				return characterasset.RawEquipmentState{}, errors.New("character pet: collected slot contradicts current content mapping")
			}
			row.TemplateID = pos.ItemID
		}
		out.Slots = append(out.Slots, row)
	}
	if err := out.Validate(); err != nil {
		return characterasset.RawEquipmentState{}, err
	}
	return out, nil
}
