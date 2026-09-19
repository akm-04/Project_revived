package characterhero

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var ErrHeroEquipmentContentInactive = errors.New("CA4-2 Hero equipment content capability inactive")

type EquipmentStateStore interface {
	ReadHeroByPartnerIDTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Hero, error)
}

type EquipmentStateContent interface {
	HeroEquipmentRevision(context.Context, string) (bool, error)
	HeroTemplateProgressionTx(context.Context, tx.Queryer, string, int64) (character.HeroTemplateProgression, error)
	HeroEquipmentPositionTx(context.Context, tx.Queryer, string, int64, int64, int64) (character.HeroEquipmentPosition, error)
}

// EquipmentStateReader materializes the CA4-1 raw stat-consumer seam from
// Normal-Hero family-owned durable state. It neither owns final battle stats
// nor mutates gameplay state.
type EquipmentStateReader struct {
	Store   EquipmentStateStore
	Content EquipmentStateContent
}

func (r EquipmentStateReader) RawEquipmentStateTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, partnerID int64, revision string) (characterasset.RawEquipmentState, error) {
	if r.Store == nil || r.Content == nil || q == nil || !pid.Valid() || partnerID <= 0 || len(revision) != 64 {
		return characterasset.RawEquipmentState{}, errors.New("character hero: invalid equipment-state read")
	}
	good, err := r.Content.HeroEquipmentRevision(ctx, revision)
	if err != nil {
		return characterasset.RawEquipmentState{}, err
	}
	if !good {
		return characterasset.RawEquipmentState{}, ErrHeroEquipmentContentInactive
	}

	h, err := r.Store.ReadHeroByPartnerIDTx(ctx, q, pid, partnerID)
	if err != nil {
		return characterasset.RawEquipmentState{}, err
	}
	if err := h.Equipment.ValidateNormal(); err != nil {
		return characterasset.RawEquipmentState{}, err
	}
	tmpl, err := r.Content.HeroTemplateProgressionTx(ctx, q, revision, h.TableID)
	if err != nil {
		return characterasset.RawEquipmentState{}, err
	}
	if tmpl.Kind != character.NormalHero {
		return characterasset.RawEquipmentState{}, errors.New("character hero: raw Normal-Hero equipment requested for non-Normal Hero")
	}

	out := characterasset.RawEquipmentState{
		Family:       "HERO",
		OwnerID:      h.PartnerID,
		StateVersion: h.StateVersion,
		Slots:        make([]characterasset.RawEquipmentSlot, 0, character.HeroEquipmentSlotCount),
	}
	for slot := int64(1); slot <= character.HeroEquipmentSlotCount; slot++ {
		v, err := h.Equipment.Value(slot)
		if err != nil {
			return characterasset.RawEquipmentState{}, err
		}
		rawFumo, err := h.Fumo.Value(slot)
		if err != nil {
			return characterasset.RawEquipmentState{}, err
		}
		row := characterasset.RawEquipmentSlot{Slot: slot, RawFumo: rawFumo}
		if v != 0 {
			pos, err := r.Content.HeroEquipmentPositionTx(ctx, q, revision, h.TableID, h.Color, slot)
			if err != nil {
				return characterasset.RawEquipmentState{}, err
			}
			if !pos.ItemID.Valid() {
				return characterasset.RawEquipmentState{}, errors.New("character hero: collected slot contradicts current content mapping")
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
