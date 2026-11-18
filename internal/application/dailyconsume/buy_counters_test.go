package dailyconsume

import (
	"context"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type memoryStore struct {
	counts Counts
	saves  int
}

func cloneCounts(counts Counts) Counts {
	out := Counts{}
	for id, counter := range counts {
		out[id] = counter
	}
	return out
}

func (m *memoryStore) ReadTx(context.Context, tx.Queryer, identity.PlayerID) (Counts, error) {
	return cloneCounts(m.counts), nil
}

func (m *memoryStore) LockTx(context.Context, tx.Tx, identity.PlayerID, time.Time) (Counts, error) {
	return cloneCounts(m.counts), nil
}

func (m *memoryStore) SaveTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, counts Counts, _ time.Time) error {
	m.counts = cloneCounts(counts)
	m.saves++
	return nil
}

func TestBuyCounterLazyResetAndAllowance(t *testing.T) {
	store := &memoryStore{counts: Counts{CounterBuyMana: {Period: 99, Used: 5}}}
	service := Service{Store: store}
	at := time.Unix(100*86400, 0)

	read, err := service.ReadBuyTx(context.Background(), nil, identity.PlayerID(1), 100)
	if err != nil || read.Mana != 0 || store.saves != 0 {
		t.Fatalf("read = %+v saves=%d err=%v", read, store.saves, err)
	}
	first, err := service.IncrementBuyTx(context.Background(), nil, identity.PlayerID(1), 100, CounterBuyMana, 2, at)
	if err != nil || first.Mana != 1 {
		t.Fatalf("first = %+v %v", first, err)
	}
	second, err := service.IncrementBuyTx(context.Background(), nil, identity.PlayerID(1), 100, CounterBuyMana, 2, at)
	if err != nil || second.Mana != 2 {
		t.Fatalf("second = %+v %v", second, err)
	}
	if _, err := service.IncrementBuyTx(context.Background(), nil, identity.PlayerID(1), 100, CounterBuyMana, 2, at); !errors.Is(err, ErrRefused) {
		t.Fatalf("allowance not enforced: %v", err)
	}
	if store.counts[CounterBuyMana].Period != 100 || store.counts[CounterBuyMana].Used != 2 {
		t.Fatalf("stored counter = %+v", store.counts[CounterBuyMana])
	}
}

func TestDailyConsumeTenfoldCounter(t *testing.T) {
	store := &memoryStore{}
	service := Service{Store: store}
	at := time.Unix(100*86400, 0)
	used, err := service.IncrementDailyTx(context.Background(), nil, identity.PlayerID(1), 100, 1, 1, at)
	if err != nil || used != 1 {
		t.Fatalf("tenfold = %d %v", used, err)
	}
	if _, err := service.IncrementDailyTx(context.Background(), nil, identity.PlayerID(1), 100, 1, 1, at); !errors.Is(err, ErrRefused) {
		t.Fatalf("second tenfold was accepted: %v", err)
	}
	next, err := service.IncrementDailyTx(context.Background(), nil, identity.PlayerID(1), 101, 1, 1, at.Add(24*time.Hour))
	if err != nil || next != 1 {
		t.Fatalf("next-day tenfold = %d %v", next, err)
	}
}
