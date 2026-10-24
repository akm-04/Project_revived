package charactersavedpreset

import (
	"context"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type guardTx struct{}
type guardRow struct{}
type guardTag struct{}

func (guardTx) QueryRow(context.Context, string, ...any) tx.Row             { return guardRow{} }
func (guardTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) { return guardTag{}, nil }
func (guardTx) Commit(context.Context) error                                { return nil }
func (guardTx) Rollback(context.Context) error                              { return nil }
func (guardRow) Scan(...any) error                                          { return errors.New("unexpected scan") }
func (guardTag) RowsAffected() int64                                        { return 1 }

type guardStore struct {
	heroUsed bool
	petUsed  bool
	locked   []identity.PlayerID
}

func (s *guardStore) LockSavedPresetRootTx(_ context.Context, _ tx.Tx, pid identity.PlayerID) (character.SavedPresetRoot, error) {
	s.locked = append(s.locked, pid)
	now := time.Unix(10, 0).UTC()
	return character.SavedPresetRoot{PlayerID: pid, StateVersion: 3, CreatedAt: now, UpdatedAt: now}, nil
}
func (s *guardStore) SavedPresetReferencesHeroTx(context.Context, tx.Queryer, identity.PlayerID, int64) (bool, error) {
	return s.heroUsed, nil
}
func (s *guardStore) SavedPresetReferencesPetTx(context.Context, tx.Queryer, identity.PlayerID, int64) (bool, error) {
	return s.petUsed, nil
}

func testSavedPresetGuard(usedHero, usedPet bool) (SavedPresetReferenceGuard, *guardStore) {
	s := &guardStore{heroUsed: usedHero, petUsed: usedPet}
	return SavedPresetReferenceGuard{Store: s, PlayerID: identity.PlayerID(7)}, s
}

func TestReferenceGuardPreflightIsStableAndActorBound(t *testing.T) {
	g, _ := testSavedPresetGuard(false, false)
	hero := character.HeroRef{PlayerID: 7, PartnerID: 11}
	pet := character.PetRef{PlayerID: 7, PetID: 12}
	hp, err := g.PreflightHeroRemovalTx(context.Background(), nil, hero)
	if err != nil {
		t.Fatal(err)
	}
	pp, err := g.PreflightPetRemovalTx(context.Background(), nil, pet)
	if err != nil {
		t.Fatal(err)
	}
	if hp.ProviderID != SavedPresetReferenceGuardProviderID || pp.ProviderID != hp.ProviderID || len(hp.Locks) != 1 || len(pp.Locks) != 1 || lockkey.Compare(hp.Locks[0], pp.Locks[0]) != 0 {
		t.Fatalf("hero=%+v pet=%+v", hp, pp)
	}
	if hp.Locks[0].DomainRank != characterasset.SavedPresetRootLockRank || hp.Locks[0].OwnerKind != characterasset.SavedPresetRootOwnerKind {
		t.Fatalf("lock=%+v", hp.Locks[0])
	}
	if _, err := g.PreflightHeroRemovalTx(context.Background(), nil, character.HeroRef{PlayerID: 8, PartnerID: 11}); !errors.Is(err, characterasset.ErrInvalidReferenceGuard) {
		t.Fatalf("foreign Hero err=%v", err)
	}
	if _, err := g.PreflightPetRemovalTx(context.Background(), nil, character.PetRef{PlayerID: 7}); !errors.Is(err, characterasset.ErrInvalidReferenceGuard) {
		t.Fatalf("malformed Pet err=%v", err)
	}
}

func TestReferenceGuardLocksOnlyBoundPlayerRoot(t *testing.T) {
	g, s := testSavedPresetGuard(false, false)
	key, _ := characterasset.SavedPresetRootLockKey(7)
	if err := g.LockReferenceGuardKeyTx(context.Background(), guardTx{}, key); err != nil {
		t.Fatal(err)
	}
	if len(s.locked) != 1 || s.locked[0] != 7 {
		t.Fatalf("locked=%v", s.locked)
	}
	foreign, _ := characterasset.SavedPresetRootLockKey(8)
	if err := g.LockReferenceGuardKeyTx(context.Background(), guardTx{}, foreign); !errors.Is(err, characterasset.ErrInvalidReferenceGuard) {
		t.Fatalf("foreign root err=%v", err)
	}
	heroKey, _ := characterasset.HeroReferenceLockKey(character.HeroRef{PlayerID: 7, PartnerID: 1})
	if err := g.LockReferenceGuardKeyTx(context.Background(), guardTx{}, heroKey); !errors.Is(err, characterasset.ErrInvalidReferenceGuard) {
		t.Fatalf("wrong key err=%v", err)
	}
}

func TestReferenceGuardLockedValidation(t *testing.T) {
	g, s := testSavedPresetGuard(true, true)
	href := character.HeroRef{PlayerID: 7, PartnerID: 11}
	pref := character.PetRef{PlayerID: 7, PetID: 12}
	plan, _ := g.PreflightHeroRemovalTx(context.Background(), nil, href)
	if err := g.ValidateHeroRemovalLockedTx(context.Background(), guardTx{}, href, plan); !errors.Is(err, characterasset.ErrReferenceInUse) {
		t.Fatalf("Hero err=%v", err)
	}
	if err := g.ValidatePetRemovalLockedTx(context.Background(), guardTx{}, pref, plan); !errors.Is(err, characterasset.ErrReferenceInUse) {
		t.Fatalf("Pet err=%v", err)
	}
	s.heroUsed, s.petUsed = false, false
	if err := g.ValidateHeroRemovalLockedTx(context.Background(), guardTx{}, href, plan); err != nil {
		t.Fatalf("unreferenced Hero err=%v", err)
	}
	if err := g.ValidatePetRemovalLockedTx(context.Background(), guardTx{}, pref, plan); err != nil {
		t.Fatalf("unreferenced Pet err=%v", err)
	}
}

func TestReferenceGuardRejectsInvalidPlans(t *testing.T) {
	g, _ := testSavedPresetGuard(false, false)
	href := character.HeroRef{PlayerID: 7, PartnerID: 11}
	good, _ := g.PreflightHeroRemovalTx(context.Background(), nil, href)
	foreign, _ := characterasset.SavedPresetRootLockKey(8)
	extra, _ := characterasset.HeroReferenceLockKey(character.HeroRef{PlayerID: 7, PartnerID: 11})
	cases := []characterasset.ReferenceGuardPlan{
		{},
		{ProviderID: "other", Locks: good.Locks},
		{ProviderID: SavedPresetReferenceGuardProviderID, Locks: []lockkey.Key{foreign}},
		{ProviderID: SavedPresetReferenceGuardProviderID, Locks: append(append([]lockkey.Key(nil), good.Locks...), extra)},
	}
	for i, plan := range cases {
		if err := g.ValidateHeroRemovalLockedTx(context.Background(), guardTx{}, href, plan); !errors.Is(err, characterasset.ErrInvalidReferenceGuard) {
			t.Fatalf("case %d err=%v", i, err)
		}
	}
}
