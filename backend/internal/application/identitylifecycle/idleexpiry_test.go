package identitylifecycle

import (
	"context"
	"sync"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type idleExpiryFake struct {
	mu      sync.Mutex
	order   []identity.SessionID
	revoked map[string]bool
	batches int
}

func (f *idleExpiryFake) ListIdleExpiredSessionIDsTx(_ context.Context, _ tx.Queryer, _ time.Time, _ identity.SessionID, limit int) ([]identity.SessionID, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	out := make([]identity.SessionID, 0, limit)
	for _, id := range f.order {
		if f.revoked[id.UUID().String()] {
			continue
		}
		out = append(out, id)
		if len(out) == limit {
			break
		}
	}
	return out, nil
}

func (f *idleExpiryFake) RevokeIdleExpiredSessionsTx(_ context.Context, _ tx.Tx, sessions []identity.SessionID, _ time.Time) (int64, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.batches++
	var revoked int64
	for _, id := range sessions {
		if f.revoked[id.UUID().String()] {
			continue
		}
		f.revoked[id.UUID().String()] = true
		revoked++
	}
	return revoked, nil
}

func TestIdleExpirySweepBatchesAndIsIdempotent(t *testing.T) {
	sessions := make([]identity.SessionID, IdleExpiryBatchSize+1)
	for index := range sessions {
		value, err := ids.NewUUID()
		if err != nil {
			t.Fatal(err)
		}
		sessions[index], err = identity.SessionIDFrom(value)
		if err != nil {
			t.Fatal(err)
		}
	}
	store := &idleExpiryFake{order: sessions, revoked: map[string]bool{}}
	sweep := IdleExpirySweep{
		Runner:     tx.Runner{DB: &testBeginner{}},
		Store:      store,
		Operations: operation.Factory{Clock: clock.System{}},
	}
	revoked, err := sweep.Run(context.Background())
	if err != nil || revoked != int64(len(sessions)) {
		t.Fatalf("first run revoked=%d err=%v", revoked, err)
	}
	if store.batches != 2 {
		t.Fatalf("batches=%d, want 2", store.batches)
	}
	revoked, err = sweep.Run(context.Background())
	if err != nil || revoked != 0 {
		t.Fatalf("second run revoked=%d err=%v", revoked, err)
	}
}
