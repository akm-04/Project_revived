package characterhero

import (
	"context"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type equipmentStateQueryer struct{}
type equipmentStateRow struct{}

func (equipmentStateQueryer) QueryRow(context.Context, string, ...any) tx.Row {
	return equipmentStateRow{}
}
func (equipmentStateQueryer) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return nil, errors.New("unexpected exec")
}
func (equipmentStateRow) Scan(...any) error { return errors.New("unexpected scan") }

type equipmentStateStore struct{ hero character.Hero }

func (s equipmentStateStore) ReadHeroByPartnerIDTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Hero, error) {
	return s.hero, nil
}

type equipmentStateContent struct {
	good           bool
	superGood      bool
	kind           character.HeroKind
	positions      map[int64]character.HeroEquipmentPosition
	superPositions map[int64]character.SuperEquipmentPosition
}

func (c equipmentStateContent) HeroEquipmentRevisionTx(context.Context, tx.Queryer, string) (bool, error) {
	return c.good, nil
}
func (c equipmentStateContent) SuperEquipmentRevisionTx(context.Context, tx.Queryer, string) (bool, error) {
	return c.superGood, nil
}
func (c equipmentStateContent) HeroTemplateProgressionTx(context.Context, tx.Queryer, string, int64) (character.HeroTemplateProgression, error) {
	return character.HeroTemplateProgression{Kind: c.kind, OriginTableID: 11001, InitialStar: 1}, nil
}
func (c equipmentStateContent) HeroEquipmentPositionTx(_ context.Context, _ tx.Queryer, _ string, tableID, color, slot int64) (character.HeroEquipmentPosition, error) {
	p, ok := c.positions[slot]
	if !ok {
		return character.HeroEquipmentPosition{}, errors.New("missing position")
	}
	p.HeroTableID, p.Color, p.Slot = tableID, color, slot
	return p, nil
}
func (c equipmentStateContent) SuperEquipmentPositionTx(_ context.Context, _ tx.Queryer, _ string, tableID, slot int64) (character.SuperEquipmentPosition, error) {
	p, ok := c.superPositions[slot]
	if !ok {
		return character.SuperEquipmentPosition{}, errors.New("missing Super position")
	}
	p.HeroTableID, p.Slot = tableID, slot
	return p, nil
}

func equipmentStateHero() character.Hero {
	now := time.Unix(10, 0).UTC()
	return character.Hero{RawSkills: character.NewHeroRawSkillSeed(), PlayerID: 1, PartnerID: 7, TableID: 11001, OriginTableID: 11001, Star: 2, Level: 3, Exp: 4, Color: 5,
		Equipment: character.HeroEquipmentSlots{1, 0, 1, 0, 0, 1}, Fumo: character.HeroFumoSlots{10, 0, 30, 0, 0, 60}, CreationContentRevision: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", StateVersion: 9, CreatedAt: now, UpdatedAt: now}
}

func TestRawEquipmentStateNormalHeroUsesPinnedMapping(t *testing.T) {
	h := equipmentStateHero()
	content := equipmentStateContent{good: true, kind: character.NormalHero, positions: map[int64]character.HeroEquipmentPosition{
		1: {ItemID: 1001, OrdinaryEligible: true}, 3: {ItemID: 1003, OrdinaryEligible: true}, 6: {ItemID: 1006, OrdinaryEligible: true},
	}}
	r := EquipmentStateReader{Store: equipmentStateStore{hero: h}, Content: content}
	got, err := r.RawEquipmentStateTx(context.Background(), equipmentStateQueryer{}, h.PlayerID, h.PartnerID, "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
	if err != nil {
		t.Fatal(err)
	}
	if got.Family != "HERO" || got.OwnerID != 7 || got.StateVersion != 9 || len(got.Slots) != 6 {
		t.Fatalf("raw=%+v", got)
	}
	want := []character.EquipmentTemplateID{1001, 0, 1003, 0, 0, 1006}
	wantFumo := []int64{10, 0, 30, 0, 0, 60}
	for i, slot := range got.Slots {
		if slot.Slot != int64(i+1) || slot.TemplateID != want[i] || slot.RawFumo != wantFumo[i] || slot.Enhancement != 0 {
			t.Fatalf("slot %d=%+v", i+1, slot)
		}
	}
	if len(got.SpiritRefs) != 0 {
		t.Fatalf("borrowed spirit refs invented: %+v", got.SpiritRefs)
	}
}

func TestRawEquipmentStateRejectsInactiveAndMapsSuper(t *testing.T) {
	h := equipmentStateHero()
	rev := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
	r := EquipmentStateReader{Store: equipmentStateStore{hero: h}, Content: equipmentStateContent{good: false, kind: character.NormalHero}}
	if _, err := r.RawEquipmentStateTx(context.Background(), equipmentStateQueryer{}, h.PlayerID, h.PartnerID, rev); !errors.Is(err, ErrHeroEquipmentContentInactive) {
		t.Fatalf("inactive err=%v", err)
	}

	h.Equipment = character.HeroEquipmentSlots{0, 1, 2, 11, 21, 40}
	superPositions := map[int64]character.SuperEquipmentPosition{}
	for slot := int64(1); slot <= character.HeroEquipmentSlotCount; slot++ {
		superPositions[slot] = character.SuperEquipmentPosition{ItemID: character.EquipmentTemplateID(20001365 + slot)}
	}
	r = EquipmentStateReader{Store: equipmentStateStore{hero: h}, Content: equipmentStateContent{superGood: true, kind: character.SuperHero, superPositions: superPositions}}
	got, err := r.RawEquipmentStateTx(context.Background(), equipmentStateQueryer{}, h.PlayerID, h.PartnerID, rev)
	if err != nil {
		t.Fatal(err)
	}
	if got.Family != "SUPER" || got.OwnerID != h.PartnerID || got.StateVersion != h.StateVersion || len(got.Slots) != 6 {
		t.Fatalf("raw=%+v", got)
	}
	wantRaw := []int64{0, 1, 2, 11, 21, 40}
	for i, slot := range got.Slots {
		if slot.RawFumo != 0 {
			t.Fatalf("slot %d invented Fumo: %+v", i+1, slot)
		}
		if wantRaw[i] == 0 {
			if slot.TemplateID != 0 || slot.Enhancement != 0 {
				t.Fatalf("empty slot=%+v", slot)
			}
		} else if slot.TemplateID != character.EquipmentTemplateID(20001365+int64(i+1)) || slot.Enhancement != wantRaw[i]-1 {
			t.Fatalf("slot %d=%+v", i+1, slot)
		}
	}

	r = EquipmentStateReader{Store: equipmentStateStore{hero: h}, Content: equipmentStateContent{superGood: false, kind: character.SuperHero, superPositions: superPositions}}
	if _, err := r.RawEquipmentStateTx(context.Background(), equipmentStateQueryer{}, h.PlayerID, h.PartnerID, rev); !errors.Is(err, ErrSuperEquipmentContentInactive) {
		t.Fatalf("Super inactive err=%v", err)
	}
}

func TestRawEquipmentStateAcceptsCollectedSpecialMapping(t *testing.T) {
	h := equipmentStateHero()
	content := equipmentStateContent{good: true, kind: character.NormalHero, positions: map[int64]character.HeroEquipmentPosition{
		1: {ItemID: 20001466, OrdinaryEligible: false},
		3: {ItemID: 1003, OrdinaryEligible: true},
		6: {ItemID: 1006, OrdinaryEligible: true},
	}}
	r := EquipmentStateReader{Store: equipmentStateStore{hero: h}, Content: content}
	got, err := r.RawEquipmentStateTx(context.Background(), equipmentStateQueryer{}, h.PlayerID, h.PartnerID, "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
	if err != nil {
		t.Fatal(err)
	}
	if got.Slots[0].TemplateID != 20001466 || got.Slots[0].RawFumo != 10 {
		t.Fatalf("special slot=%+v", got.Slots[0])
	}
}

func TestRawEquipmentStateRejectsNormalSlotAboveOne(t *testing.T) {
	h := equipmentStateHero()
	h.Equipment[0] = 2
	r := EquipmentStateReader{Store: equipmentStateStore{hero: h}, Content: equipmentStateContent{good: true, kind: character.NormalHero}}
	_, err := r.RawEquipmentStateTx(context.Background(), equipmentStateQueryer{}, h.PlayerID, h.PartnerID, "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
	if err == nil {
		t.Fatal("future Super enhancement value accepted as Normal-Hero bit")
	}
}
