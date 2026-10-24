package charactersavedpreset

import (
	"context"
	"errors"
	"reflect"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type heroMap map[int64]int64

func (m heroMap) MapLegacyHero(_ context.Context, pid identity.PlayerID, old int64) (character.HeroRef, bool, error) {
	v, ok := m[old]
	return character.HeroRef{PlayerID: pid, PartnerID: v}, ok, nil
}

type petMap map[int64]int64

func (m petMap) MapLegacyPet(_ context.Context, pid identity.PlayerID, old int64) (character.PetRef, bool, error) {
	v, ok := m[old]
	return character.PetRef{PlayerID: pid, PetID: v}, ok, nil
}

func TestLegacyMappingUsesExplicitNonIdentityOwnerMapsAndPadsMissingPetName(t *testing.T) {
	lanes, q, err := MapLegacy(context.Background(), 7,
		LegacyRaw{SaveTeam: "10001|10002:10003", SaveTeamName: "One", SavePet: "500"},
		LegacyIdentityMappers{Heroes: heroMap{10001: 7, 10002: 8, 10003: 9}, Pets: petMap{500: 4}})
	if err != nil || q != nil {
		t.Fatalf("err=%v quarantine=%v", err, q)
	}
	if len(lanes) != 2 || lanes[0].Heroes[0].PartnerID != 7 || lanes[1].Heroes[0].PartnerID != 9 {
		t.Fatalf("mapped lanes=%+v", lanes)
	}
	if lanes[0].Pet == nil || lanes[0].Pet.PetID != 4 || lanes[1].Pet != nil || lanes[1].Name != "" {
		t.Fatalf("alignment transform=%+v", lanes)
	}
}

func TestLegacyMalformedOrUnresolvedStateQuarantinesWholeAggregate(t *testing.T) {
	cases := []LegacyRaw{
		{SaveTeam: "1", SaveTeamName: "a|||extra"},
		{SaveTeam: "1", SavePet: "0|0"},
		{SaveTeam: "1::2"},
		{SaveTeam: "0"},
	}
	for _, raw := range cases {
		if _, q := ParseLegacy(raw); q == nil {
			t.Fatalf("expected quarantine for %+v", raw)
		}
	}
	_, q, err := MapLegacy(context.Background(), 7, LegacyRaw{SaveTeam: "10001"}, LegacyIdentityMappers{Heroes: heroMap{}, Pets: petMap{}})
	if err != nil || q == nil || q.Code != "UNRESOLVED_HERO" {
		t.Fatalf("unresolved mapping err=%v q=%+v", err, q)
	}
}

type noopTag int64

func (t noopTag) RowsAffected() int64 { return int64(t) }

type noopTx struct{}

func (noopTx) QueryRow(context.Context, string, ...any) tx.Row             { return nil }
func (noopTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) { return noopTag(1), nil }
func (noopTx) Commit(context.Context) error                                { return nil }
func (noopTx) Rollback(context.Context) error                              { return nil }

type importStore struct {
	events   *[]string
	current  character.SavedPresetAggregate
	replaced *character.SavedPresetAggregate
}

func (s *importStore) ReadSavedPresetAggregateTx(context.Context, tx.Queryer, identity.PlayerID) (character.SavedPresetAggregate, error) {
	return s.current, nil
}
func (s *importStore) LockSavedPresetRootTx(_ context.Context, _ tx.Tx, _ identity.PlayerID) (character.SavedPresetRoot, error) {
	*s.events = append(*s.events, "root-lock")
	return s.current.Root, nil
}
func (s *importStore) ReplaceSavedPresetAggregateTx(_ context.Context, _ tx.Tx, a character.SavedPresetAggregate, _ int64) error {
	*s.events = append(*s.events, "replace")
	s.replaced = &a
	return nil
}
func (s *importStore) EnsureSavedPresetRootTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, _ time.Time) (bool, error) {
	*s.events = append(*s.events, "ensure-root")
	return false, nil
}

type importHeroOwner struct{ events *[]string }

func (o importHeroOwner) HeroReferenceLockKey(r character.HeroRef) (lockkey.Key, error) {
	return characterasset.HeroReferenceLockKey(r)
}
func (o importHeroOwner) LockHeroReferenceKeyTx(_ context.Context, _ tx.Tx, _ lockkey.Key, _ character.HeroRef) error {
	*o.events = append(*o.events, "hero-lock")
	return nil
}

type importPetOwner struct{ events *[]string }

func (o importPetOwner) PetReferenceLockKey(r character.PetRef) (lockkey.Key, error) {
	return characterasset.PetReferenceLockKey(r)
}
func (o importPetOwner) LockPetReferenceKeyTx(_ context.Context, _ tx.Tx, _ lockkey.Key, _ character.PetRef) error {
	*o.events = append(*o.events, "pet-lock")
	return nil
}

func TestImportLegacyValidatesMappedRefsBeforeRootAndDoesNotOverwriteConflict(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	events := []string{}
	store := &importStore{events: &events, current: character.SavedPresetAggregate{Root: character.SavedPresetRoot{PlayerID: 7, StateVersion: 1, CreatedAt: now, UpdatedAt: now}}}
	q, err := ImportLegacyTx(context.Background(), noopTx{}, store, ReferenceOwners{Heroes: importHeroOwner{&events}, Pets: importPetOwner{&events}}, LegacyIdentityMappers{Heroes: heroMap{10001: 7}, Pets: petMap{500: 4}}, 7, LegacyRaw{SaveTeam: "10001", SavePet: "500"}, now.Add(time.Second))
	if err != nil || q != nil {
		t.Fatalf("err=%v q=%v", err, q)
	}
	want := []string{"ensure-root", "hero-lock", "pet-lock", "root-lock", "replace"}
	if !reflect.DeepEqual(events, want) {
		t.Fatalf("events=%v want=%v", events, want)
	}
	if store.replaced == nil || store.replaced.Lanes[0].Heroes[0].PartnerID != 7 || store.replaced.Lanes[0].Pet == nil || store.replaced.Lanes[0].Pet.PetID != 4 {
		t.Fatalf("replace=%+v", store.replaced)
	}

	events = nil
	conflict := character.SavedPresetLane{Name: "existing", Heroes: []character.HeroRef{{PlayerID: 7, PartnerID: 99}}}
	store = &importStore{events: &events, current: character.SavedPresetAggregate{Root: character.SavedPresetRoot{PlayerID: 7, StateVersion: 2, CreatedAt: now, UpdatedAt: now}, Lanes: []character.SavedPresetLane{conflict}}}
	_, err = ImportLegacyTx(context.Background(), noopTx{}, store, ReferenceOwners{Heroes: importHeroOwner{&events}, Pets: importPetOwner{&events}}, LegacyIdentityMappers{Heroes: heroMap{10001: 7}, Pets: petMap{}}, 7, LegacyRaw{SaveTeam: "10001"}, now.Add(time.Second))
	if !errors.Is(err, ErrImportConflict) {
		t.Fatalf("conflict err=%v", err)
	}
	if store.replaced != nil {
		t.Fatal("conflicting non-empty target overwritten")
	}
}
