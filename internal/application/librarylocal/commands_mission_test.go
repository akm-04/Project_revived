package librarylocal

import (
	"context"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
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
