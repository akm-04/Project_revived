package librarylocal

import (
	"context"
	"testing"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/identity"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type missionSettlementLibrary struct {
	LibraryPort
	rows  []lib.MissionFact
	saved []lib.MissionFact
}

func (l *missionSettlementLibrary) ListMissionsTx(context.Context, tx.Queryer, identity.PlayerID) ([]lib.MissionFact, error) {
	return l.rows, nil
}

func (l *missionSettlementLibrary) SaveMissionTx(_ context.Context, _ tx.Tx, f lib.MissionFact) error {
	l.saved = append(l.saved, f)
	for i := range l.rows {
		if l.rows[i].PartnerID == f.PartnerID && l.rows[i].MissionID == f.MissionID {
			l.rows[i] = f
		}
	}
	return nil
}

func giftMissionCatalog() lib.Catalog {
	return lib.Catalog{Missions: map[int64]lib.MissionRule{
		lib.GiftMissionID: {ID: lib.GiftMissionID, Difficulty: 1, Type: 1, Required: 1, Amour: 5},
	}}
}

// A-193 S26: the gift that completes 1001 awards its amour once; replaying the
// settlement against the stored AWARDED row grants nothing again.
func TestGiftMissionSettlementAwardsAmourOnce(t *testing.T) {
	at := time.Date(2026, 11, 19, 12, 0, 0, 0, time.UTC)
	store := &missionSettlementLibrary{rows: []lib.MissionFact{{
		PlayerID: 1, PartnerID: 1, MissionID: lib.GiftMissionID, MissionState: lib.MissionProceed, UpdatedAt: at.Add(-time.Second),
	}}}
	service := Service{Library: store}

	amour, changed, err := service.settlePartnerMissionsTx(context.Background(), nil, giftMissionCatalog(), 1, 1, true, at)
	if err != nil || !changed || amour != 5 {
		t.Fatalf("first settlement amour=%d changed=%v err=%v", amour, changed, err)
	}
	if len(store.saved) != 1 || store.saved[0].MissionState != lib.MissionAwarded || store.saved[0].Process != 1 {
		t.Fatalf("saved rows %+v", store.saved)
	}

	amour, changed, err = service.settlePartnerMissionsTx(context.Background(), nil, giftMissionCatalog(), 1, 1, true, at.Add(time.Second))
	if err != nil || changed || amour != 0 {
		t.Fatalf("replay amour=%d changed=%v err=%v", amour, changed, err)
	}
	if len(store.saved) != 1 {
		t.Fatalf("replay saved again %+v", store.saved)
	}
}

// A-193 S26: a stored SUCCESS row is settled by the next library write that
// reads it, even when that write is not the gift that reached success.
func TestStoredSuccessMissionSettlesOnNextWrite(t *testing.T) {
	at := time.Date(2026, 11, 19, 12, 0, 0, 0, time.UTC)
	store := &missionSettlementLibrary{rows: []lib.MissionFact{
		{PlayerID: 1, PartnerID: 1, MissionID: lib.GiftMissionID, Process: 1, MissionState: lib.MissionSuccess, UpdatedAt: at.Add(-time.Minute)},
		{PlayerID: 1, PartnerID: 2, MissionID: lib.GiftMissionID, Process: 1, MissionState: lib.MissionSuccess, UpdatedAt: at.Add(-time.Minute)},
	}}
	service := Service{Library: store}

	amour, changed, err := service.settlePartnerMissionsTx(context.Background(), nil, giftMissionCatalog(), 1, 1, false, at)
	if err != nil || !changed || amour != 5 {
		t.Fatalf("stored success amour=%d changed=%v err=%v", amour, changed, err)
	}
	if len(store.saved) != 1 || store.saved[0].PartnerID != 1 || store.saved[0].MissionState != lib.MissionAwarded {
		t.Fatalf("saved rows %+v", store.saved)
	}
}

type recordingFacts struct{ facts []objective.Fact }

func (*recordingFacts) PrepareTx(context.Context, tx.Tx, identity.PlayerID, gen.TimedOperation) (context.Context, error) {
	return context.Background(), nil
}

func (r *recordingFacts) RecordTx(_ context.Context, _ tx.Tx, _ operation.Context, facts ...objective.Fact) error {
	r.facts = append(r.facts, facts...)
	return nil
}

// C4: the favor fact carries the favored partner id so Adventure 10002 can
// name the hero instead of sending special_data 0.
func TestRecordIntimacyCarriesFavorPartner(t *testing.T) {
	recorder := &recordingFacts{}
	service := Service{Facts: recorder}
	id, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	op := operation.Context{ID: id, StartedAt: time.Unix(1700000000, 0).UTC()}
	if err := service.recordIntimacy(context.Background(), nil, op, identity.PlayerID(170001), 10001001); err != nil {
		t.Fatal(err)
	}
	if len(recorder.facts) != 1 {
		t.Fatalf("facts %d", len(recorder.facts))
	}
	fact := recorder.facts[0]
	if fact.Kind != objective.IntimacyImprovedKind || fact.Delta != 1 || fact.Value != 10001001 {
		t.Fatalf("favor fact %+v", fact)
	}
	if fact.PlayerID != identity.PlayerID(170001) || fact.SourceDomain != "library" {
		t.Fatalf("favor fact identity %+v", fact)
	}
}
