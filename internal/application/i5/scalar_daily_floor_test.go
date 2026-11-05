package i5

import (
	"context"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"testing"
	"time"
)

type floorStore struct {
	*testStore
	anchor      *economy.ScalarDailyFloor
	anchorSaves int
}

func (store *floorStore) ReadScalarDailyFloorTx(context.Context, tx.Queryer, identity.PlayerID, string) (economy.ScalarDailyFloor, bool, error) {
	if store.anchor == nil {
		return economy.ScalarDailyFloor{}, false, nil
	}
	return *store.anchor, true, nil
}
func (store *floorStore) SaveScalarDailyFloorTx(_ context.Context, _ tx.Tx, anchor economy.ScalarDailyFloor, _ int64) error {
	store.anchor = &anchor
	store.anchorSaves++
	return nil
}
func TestScalarFloorMaterializesOnceAndPureReadDoesNotConsumeDay(t *testing.T) {
	at := time.Unix(1700000000, 0).UTC()
	minimum := int64(100)
	store := &floorStore{testStore: &testStore{}}
	balance := economy.ScalarBalance{PlayerID: 7, ResourceKey: "glue", Amount: 20, StateVersion: 1, UpdatedAt: at}
	planned, err := effectiveDailyFloorTx(context.Background(), &testTx{}, store, balance, &minimum, at)
	if err != nil || planned.Amount != 100 || store.anchorSaves != 0 || store.saveScalarCalls != 0 {
		t.Fatal(planned, err)
	}
	settled, exists, err := settleDailyFloorTx(context.Background(), &testTx{}, store, balance, true, &minimum, at)
	if err != nil || !exists || settled.Amount != 100 || store.anchorSaves != 1 || store.saveScalarCalls != 1 {
		t.Fatal(settled, err)
	}
	spent, err := settled.Debit(90, at.Add(time.Second))
	if err != nil {
		t.Fatal(err)
	}
	again, _, err := settleDailyFloorTx(context.Background(), &testTx{}, store, spent, true, &minimum, at.Add(2*time.Second))
	if err != nil || again.Amount != 10 || store.anchorSaves != 1 {
		t.Fatal(again, err)
	}
	next, _, err := settleDailyFloorTx(context.Background(), &testTx{}, store, spent, true, &minimum, at.Add(24*time.Hour))
	if err != nil || next.Amount != 100 || store.anchorSaves != 2 {
		t.Fatal(next, err)
	}
}
func TestScalarFloorPreservesHighBalancesAndMissingStorageFailsClosed(t *testing.T) {
	at := time.Unix(1700000000, 0).UTC()
	minimum := int64(100)
	store := &floorStore{testStore: &testStore{}}
	balance := economy.ScalarBalance{PlayerID: 7, ResourceKey: "glue", Amount: 350, StateVersion: 1, UpdatedAt: at}
	settled, _, err := settleDailyFloorTx(context.Background(), &testTx{}, store, balance, true, &minimum, at)
	if err != nil || settled.Amount != 350 || store.saveScalarCalls != 0 || store.anchorSaves != 1 {
		t.Fatal(settled, err)
	}
	if _, _, err := settleDailyFloorTx(context.Background(), &testTx{}, store.testStore, balance, true, &minimum, at); err == nil {
		t.Fatal("missing floor owner silently accepted")
	}
	unchanged, _, err := settleDailyFloorTx(context.Background(), &testTx{}, store.testStore, balance, true, nil, at)
	if err != nil || unchanged.Amount != 350 {
		t.Fatal(unchanged, err)
	}
}
