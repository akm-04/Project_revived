package characterhero

import (
	"context"
	"strings"
	"testing"
	"time"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type clockClampAwakeningStore struct {
	savedRaw  character.RawAwakeningBirth
	savedHero character.Hero
}

func (s *clockClampAwakeningStore) FindRawAwakeningTx(context.Context, tx.Queryer, character.HeroRef) (character.RawAwakeningBirth, bool, error) {
	return s.savedRaw, true, nil
}
func (s *clockClampAwakeningStore) SaveRawAwakeningTx(_ context.Context, _ tx.Tx, raw character.RawAwakeningBirth, _ int64) error {
	s.savedRaw = raw
	return nil
}
func (s *clockClampAwakeningStore) SaveHeroAwakeningTx(_ context.Context, _ tx.Tx, hero character.Hero, _ int64) error {
	s.savedHero = hero
	return nil
}

func TestApplyAwakeningHeroClampsBackwardDecisionToBirthFacts(t *testing.T) {
	forward := time.Now().UTC().Add(8 * time.Hour).Truncate(time.Microsecond)
	revision := strings.Repeat("ab", 32)
	raw := character.RawAwakeningBirth{Ref: character.HeroRef{PlayerID: 7, PartnerID: 1}, Version: 1,
		BirthPolicy: character.RawAwakeningBirthPolicy, CreationContentRevision: revision,
		BirthAt: forward, CreatedAt: forward, UpdatedAt: forward}
	hero := character.Hero{RawSkills: character.NewHeroRawSkillSeed(), PlayerID: 7, PartnerID: 1,
		TableID: 11001001, OriginTableID: 11001001, Kind: character.NormalHero, Star: 1, Level: 100,
		Color: 15, CreationContentRevision: revision, StateVersion: 1, CreatedAt: forward, UpdatedAt: forward}
	store := &clockClampAwakeningStore{}
	service := Service{Awakening: store}
	var id ids.UUID
	id[15] = 7
	decision := forward.Add(-time.Hour)
	op := operation.Context{ID: id, StartedAt: decision}
	def := objective.AwakeDefinition{ID: 2001001, Type: 2, Stage: 1, Before: 11001001}
	instance := objective.AwakeInstance{Mission: 2001001, Type: 2, OwnerID: 1, Generation: 1, Revision: revision}
	next, err := service.ApplyAwakeningHeroLockedTx(context.Background(), &fakeTx{}, appi5.AwakeningHero{Hero: hero, Raw: &raw}, def, instance, "open", op, decision)
	if err != nil {
		t.Fatal(err)
	}
	if next.Raw == nil || next.Raw.Version != 2 || next.Raw.RawStage != 1 || next.Raw.UpdatedAt.Before(forward) {
		t.Fatalf("raw after backward decision: %+v", next.Raw)
	}
	if next.Hero.UpdatedAt.Before(next.Hero.CreatedAt) || next.Hero.UpdatedAt.Before(forward) {
		t.Fatalf("hero after backward decision: %+v", next.Hero)
	}
	if store.savedRaw.UpdatedAt.Before(store.savedRaw.CreatedAt) || store.savedHero.UpdatedAt.Before(store.savedHero.CreatedAt) {
		t.Fatal("inverted timestamps reached the store")
	}
}
