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
var ErrSuperEquipmentContentInactive = errors.New("CA4-5 Super equipment content capability inactive")

type EquipmentStateStore interface {
	ReadHeroByPartnerIDTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Hero, error)
}

type EquipmentStateContent interface {
	HeroEquipmentRevisionTx(context.Context, tx.Queryer, string) (bool, error)
	SuperEquipmentRevisionTx(context.Context, tx.Queryer, string) (bool, error)
	HeroTemplateProgressionTx(context.Context, tx.Queryer, string, int64) (character.HeroTemplateProgression, error)
	HeroEquipmentPositionTx(context.Context, tx.Queryer, string, int64, int64, int64) (character.HeroEquipmentPosition, error)
	SuperEquipmentPositionTx(context.Context, tx.Queryer, string, int64, int64) (character.SuperEquipmentPosition, error)
}

// EquipmentStateReader materializes the CA4 raw stat-consumer seam from
// CharacterHero-owned durable slot state. Normal-Hero mapping remains
// color-qualified; Super-Hero mapping uses CA4-5's fixed six-slot topology and
// raw value N>0 => enhancement N-1. It neither owns final battle stats nor
// mutates gameplay state.
type EquipmentStateReader struct {
	Store   EquipmentStateStore
	Content EquipmentStateContent
}

func (r EquipmentStateReader) RawEquipmentStateTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, partnerID int64, revision string) (characterasset.RawEquipmentState, error) {
	if r.Store == nil || r.Content == nil || q == nil || !pid.Valid() || partnerID <= 0 || characterasset.ValidateExactRevisionID(revision) != nil {
		return characterasset.RawEquipmentState{}, errors.New("character hero: invalid equipment-state read")
	}
	h, err := r.Store.ReadHeroByPartnerIDTx(ctx, q, pid, partnerID)
	if err != nil {
		return characterasset.RawEquipmentState{}, err
	}
	if h.PlayerID != pid || h.PartnerID != partnerID || h.StateVersion <= 0 || h.TableID <= 0 {
		return characterasset.RawEquipmentState{}, errors.New("character hero: equipment-state owner mismatch")
	}
	if err := h.Equipment.Validate(); err != nil {
		return characterasset.RawEquipmentState{}, err
	}
	tmpl, err := r.Content.HeroTemplateProgressionTx(ctx, q, revision, h.TableID)
	if err != nil {
		return characterasset.RawEquipmentState{}, err
	}

	switch tmpl.Kind {
	case character.NormalHero:
		good, err := r.Content.HeroEquipmentRevisionTx(ctx, q, revision)
		if err != nil {
			return characterasset.RawEquipmentState{}, err
		}
		if !good {
			return characterasset.RawEquipmentState{}, ErrHeroEquipmentContentInactive
		}
		if err := h.Equipment.ValidateNormal(); err != nil {
			return characterasset.RawEquipmentState{}, err
		}
		out := characterasset.RawEquipmentState{
			Family: "HERO", OwnerID: h.PartnerID, StateVersion: h.StateVersion,
			Slots: make([]characterasset.RawEquipmentSlot, 0, character.HeroEquipmentSlotCount),
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

	case character.SuperHero:
		good, err := r.Content.SuperEquipmentRevisionTx(ctx, q, revision)
		if err != nil {
			return characterasset.RawEquipmentState{}, err
		}
		if !good {
			return characterasset.RawEquipmentState{}, ErrSuperEquipmentContentInactive
		}
		out := characterasset.RawEquipmentState{
			Family: "SUPER", OwnerID: h.PartnerID, StateVersion: h.StateVersion,
			Slots: make([]characterasset.RawEquipmentSlot, 0, character.HeroEquipmentSlotCount),
		}
		for slot := int64(1); slot <= character.HeroEquipmentSlotCount; slot++ {
			raw, err := h.Equipment.Value(slot)
			if err != nil {
				return characterasset.RawEquipmentState{}, err
			}
			row := characterasset.RawEquipmentSlot{Slot: slot}
			if raw > 0 {
				pos, err := r.Content.SuperEquipmentPositionTx(ctx, q, revision, h.TableID, slot)
				if err != nil {
					return characterasset.RawEquipmentState{}, err
				}
				if !pos.ItemID.Valid() {
					return characterasset.RawEquipmentState{}, errors.New("character hero: collected Super slot contradicts current content mapping")
				}
				row.TemplateID = pos.ItemID
				row.Enhancement = raw - 1
			}
			out.Slots = append(out.Slots, row)
		}
		if err := out.Validate(); err != nil {
			return characterasset.RawEquipmentState{}, err
		}
		return out, nil
	default:
		return characterasset.RawEquipmentState{}, errors.New("character hero: equipment-state Hero family unresolved")
	}
}
