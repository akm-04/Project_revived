package characterpet

import (
	"context"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type petEquipQ struct{}

func (petEquipQ) QueryRow(context.Context, string, ...any) tx.Row { return nil }

type petEquipStore struct{ p character.Pet }

func (s petEquipStore) ReadPetByIDTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Pet, error) {
	return s.p, nil
}

type petEquipContent struct {
	good      bool
	seenQ     tx.Queryer
	positions map[int64]character.PetEquipmentPosition
}

func (c *petEquipContent) PetEquipmentRevisionTx(_ context.Context, q tx.Queryer, _ string) (bool, error) {
	c.seenQ = q
	return c.good, nil
}
func (c *petEquipContent) PetEquipmentPositionTx(_ context.Context, q tx.Queryer, _ string, table, color, slot int64) (character.PetEquipmentPosition, error) {
	c.seenQ = q
	p, ok := c.positions[slot]
	if !ok {
		return character.PetEquipmentPosition{}, errors.New("missing")
	}
	p.PetTableID, p.Color, p.Slot = table, color, slot
	return p, nil
}

func petEquipFixture() character.Pet {
	now := time.Unix(1, 0).UTC()
	return character.Pet{PlayerID: 7, PetID: 3, TableID: 2001, OriginTableID: 2001, Star: 1, Level: 1, Color: 2, Equipment: character.PetEquipmentSlots{1, 0, 1}, Fumo: character.PetFumoSlots{10, 20, 30}, Skills: character.DefaultPetSkillLevels(), Birthday: 1, IsShow: true, CreationContentRevision: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", StateVersion: 8, CreatedAt: now, UpdatedAt: now}
}

func TestPetRawEquipmentStateUsesCallerQueryerAndPinnedMapping(t *testing.T) {
	p := petEquipFixture()
	q := petEquipQ{}
	c := &petEquipContent{good: true, positions: map[int64]character.PetEquipmentPosition{1: {ItemID: 101, Classification: character.PetEquipmentOrdinary}, 3: {ItemID: 303, Classification: character.PetEquipmentAwakening}}}
	got, err := (EquipmentStateReader{Store: petEquipStore{p: p}, Content: c}).RawEquipmentStateTx(context.Background(), q, 7, 3, "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
	if err != nil {
		t.Fatal(err)
	}
	if c.seenQ == nil || got.Family != "PET" || got.OwnerID != 3 || got.StateVersion != 8 || len(got.Slots) != 3 {
		t.Fatalf("got=%+v", got)
	}
	if got.Slots[0].TemplateID != 101 || got.Slots[0].RawFumo != 10 || got.Slots[1].TemplateID != 0 || got.Slots[1].RawFumo != 20 || got.Slots[2].TemplateID != 303 || got.Slots[2].RawFumo != 30 {
		t.Fatalf("slots=%+v", got.Slots)
	}
}

func TestPetRawEquipmentStateFailsClosedWhenCapabilityInactive(t *testing.T) {
	p := petEquipFixture()
	_, err := (EquipmentStateReader{Store: petEquipStore{p: p}, Content: &petEquipContent{good: false}}).RawEquipmentStateTx(context.Background(), petEquipQ{}, 7, 3, "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
	if !errors.Is(err, ErrPetEquipmentContentInactive) {
		t.Fatalf("err=%v", err)
	}
}
