package librarylocal

import (
	"context"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type partnerMissionContent struct {
	ContentPort
	active   bool
	revision string
	catalog  lib.Catalog
}

func (c partnerMissionContent) LibraryInputsActive(context.Context) (string, bool, error) {
	return c.revision, c.active, nil
}

func (c partnerMissionContent) LibraryCatalogTx(context.Context, tx.Queryer, string) (lib.Catalog, error) {
	return c.catalog, nil
}

type partnerMissionHeroes struct {
	HeroPort
	hero  character.Hero
	found bool
	err   error
}

func (h partnerMissionHeroes) FindHeroByPartnerIDTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Hero, bool, error) {
	return h.hero, h.found, h.err
}

type partnerMissionLibrary struct {
	LibraryPort
	rows  []lib.MissionFact
	facts lib.HeroFacts
	saved []lib.MissionFact
	err   error
}

func (l *partnerMissionLibrary) ReadHeroTx(context.Context, tx.Queryer, character.HeroRef) (lib.HeroFacts, error) {
	return l.facts, nil
}

func (l *partnerMissionLibrary) ListMissionsTx(context.Context, tx.Queryer, identity.PlayerID) ([]lib.MissionFact, error) {
	return l.rows, nil
}

func (l *partnerMissionLibrary) EnsureMissionTx(_ context.Context, _ tx.Tx, f lib.MissionFact) (bool, error) {
	return true, nil
}

func (l *partnerMissionLibrary) SaveMissionTx(_ context.Context, _ tx.Tx, f lib.MissionFact) error {
	if l.err != nil {
		return l.err
	}
	l.saved = append(l.saved, f)
	for index := range l.rows {
		if l.rows[index].PartnerID == f.PartnerID && l.rows[index].MissionID == f.MissionID {
			l.rows[index] = f
		}
	}
	return nil
}

func partnerMissionCatalog() lib.Catalog {
	return lib.Catalog{
		Templates: map[int64]lib.TemplateRule{10001001: {TableID: 10001001, RelationshipSourceID: 1, CollectionSourceID: 1}},
		Missions: map[int64]lib.MissionRule{
			lib.GiftMissionID:        {ID: lib.GiftMissionID, Difficulty: 1, Type: 1, Required: 1},
			lib.FriendFightMissionID: {ID: lib.FriendFightMissionID, Difficulty: 1, Type: 1, Required: 1},
			lib.RentalMissionID:      {ID: lib.RentalMissionID, Difficulty: 2, Type: 2, Required: 1},
			lib.ChampionMissionID:    {ID: lib.ChampionMissionID, Difficulty: 2, Type: 2, Required: 5},
			lib.TeaPartyMissionID:    {ID: lib.TeaPartyMissionID, Difficulty: 3, Type: 3, Required: 1},
			lib.PvPKillMissionID:     {ID: lib.PvPKillMissionID, Difficulty: 3, Type: 3, Required: 1},
		},
		Stages: []lib.StageRule{
			{ID: 1, Favor: 100, ActIDs: []int64{1}, MissionIDs: []int64{lib.GiftMissionID, lib.FriendFightMissionID, lib.RentalMissionID}},
			{ID: 2, Favor: 2000, ActIDs: []int64{1, 2, 3, 4}, MissionIDs: []int64{lib.GiftMissionID, lib.FriendFightMissionID, lib.RentalMissionID, lib.ChampionMissionID, lib.TeaPartyMissionID, lib.PvPKillMissionID}},
		},
	}
}

func partnerMissionService(catalog lib.Catalog, favor int64, rows []lib.MissionFact) (Service, *partnerMissionLibrary) {
	library := &partnerMissionLibrary{rows: rows, facts: lib.HeroFacts{Ref: character.HeroRef{PlayerID: 1, PartnerID: 1}, StateVersion: 1, Favor: favor}}
	service := Service{
		Content: partnerMissionContent{active: true, revision: "rev", catalog: catalog},
		Heroes:  partnerMissionHeroes{hero: character.Hero{PlayerID: 1, PartnerID: 1, TableID: 10001001}, found: true},
		Library: library,
	}
	return service, library
}

type partnerMissionTransaction struct{}

func (partnerMissionTransaction) QueryRow(context.Context, string, ...any) tx.Row { return nil }
func (partnerMissionTransaction) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return nil, nil
}
func (partnerMissionTransaction) Commit(context.Context) error   { return nil }
func (partnerMissionTransaction) Rollback(context.Context) error { return nil } // A-206 R7: an unlocked, unfinished mission advances exactly once and stores
// its new process/state; the transaction is the producer's.
func TestObservePartnerMissionTxAdvancesUnlocked(t *testing.T) {
	at := time.Date(2026, 11, 21, 12, 0, 0, 0, time.UTC)
	rows := []lib.MissionFact{{PlayerID: 1, PartnerID: 1, MissionID: lib.FriendFightMissionID, MissionState: lib.MissionProceed, UpdatedAt: at.Add(-time.Minute)}}
	service, library := partnerMissionService(partnerMissionCatalog(), 100, rows)
	service.Library = library

	// Keep the transaction non-nil behind its interface so the port's own nil
	// guard does not short-circuit; the fake store ignores it.
	if err := service.ObservePartnerMissionTx(context.Background(), partnerMissionTransaction{}, 1, 1, lib.FriendFightMissionID, at); err != nil {
		t.Fatal(err)
	}
	if len(library.saved) != 1 || library.saved[0].Process != 1 || library.saved[0].MissionState != lib.MissionSuccess {
		t.Fatalf("saved %+v", library.saved)
	}
	if err := service.ObservePartnerMissionTx(context.Background(), partnerMissionTransaction{}, 1, 1, lib.FriendFightMissionID, at.Add(time.Second)); err != nil {
		t.Fatal(err)
	}
	if len(library.saved) != 1 {
		t.Fatalf("finished mission advanced again %+v", library.saved)
	}
}

// A-206 R7: a locked mission, a finished mission, and a Hero the player does
// not own are no-ops, never refusals.
func TestObservePartnerMissionTxIgnoresIneligible(t *testing.T) {
	at := time.Date(2026, 11, 21, 12, 0, 0, 0, time.UTC)
	catalog := partnerMissionCatalog()
	cases := []struct {
		name    string
		favor   int64
		rows    []lib.MissionFact
		mission int64
		missing bool
	}{
		{name: "locked-by-favor", favor: 100, mission: lib.PvPKillMissionID},
		{name: "finished", favor: 2000, mission: lib.FriendFightMissionID, rows: []lib.MissionFact{{PlayerID: 1, PartnerID: 1, MissionID: lib.FriendFightMissionID, Process: 1, MissionState: lib.MissionSuccess, UpdatedAt: at}}},
		{name: "awarded", favor: 2000, mission: lib.FriendFightMissionID, rows: []lib.MissionFact{{PlayerID: 1, PartnerID: 1, MissionID: lib.FriendFightMissionID, Process: 1, MissionState: lib.MissionAwarded, UpdatedAt: at}}},
		{name: "missing-hero", favor: 2000, mission: lib.FriendFightMissionID, missing: true},
	}
	for _, test := range cases {
		t.Run(test.name, func(t *testing.T) {
			service, library := partnerMissionService(catalog, test.favor, test.rows)
			if test.missing {
				service.Heroes = partnerMissionHeroes{found: false}
			}
			if err := service.ObservePartnerMissionTx(context.Background(), partnerMissionTransaction{}, 1, 1, test.mission, at); err != nil {
				t.Fatal(err)
			}
			if len(library.saved) != 0 {
				t.Fatalf("ineligible mission saved %+v", library.saved)
			}
		})
	}
}

// A-206 R7: database errors propagate so the producer's transaction rolls back.
func TestObservePartnerMissionTxPropagatesStoreError(t *testing.T) {
	at := time.Date(2026, 11, 21, 12, 0, 0, 0, time.UTC)
	rows := []lib.MissionFact{{PlayerID: 1, PartnerID: 1, MissionID: lib.FriendFightMissionID, MissionState: lib.MissionProceed, UpdatedAt: at}}
	service, library := partnerMissionService(partnerMissionCatalog(), 100, rows)
	storeError := errors.New("library store unavailable")
	library.err = storeError
	if err := service.ObservePartnerMissionTx(context.Background(), partnerMissionTransaction{}, 1, 1, lib.FriendFightMissionID, at); !errors.Is(err, storeError) {
		t.Fatalf("store error %v", err)
	}
}

// A-206 R7: the port refuses arguments outside its typed mission set.
func TestObservePartnerMissionTxRejectsInvalidInput(t *testing.T) {
	at := time.Date(2026, 11, 21, 12, 0, 0, 0, time.UTC)
	service, _ := partnerMissionService(partnerMissionCatalog(), 100, nil)
	for _, mission := range []int64{0, lib.GiftMissionID, 1007} {
		if err := service.ObservePartnerMissionTx(context.Background(), partnerMissionTransaction{}, 1, 1, mission, at); !errors.Is(err, lib.ErrUnqualified) {
			t.Fatalf("mission %d error %v", mission, err)
		}
	}
	if err := service.ObservePartnerMissionTx(context.Background(), nil, 1, 1, lib.FriendFightMissionID, at); !errors.Is(err, lib.ErrUnqualified) {
		t.Fatalf("nil transaction error %v", err)
	}
}
