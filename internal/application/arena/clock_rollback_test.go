package arena

import (
	"context"
	"testing"
	"time"

	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type recordingPlayerStore struct {
	Store
	saved d.Player
	old   int64
}

func (f *recordingPlayerStore) SavePlayerTx(_ context.Context, _ tx.Tx, p d.Player, old int64) error {
	f.saved, f.old = p, old
	return p.Validate()
}

// I9_11_CLOCK_ROLLBACK_V1 K3: a decision time behind every stored player
// timestamp still commits, keeping the latest durable observations.
func TestI9_12SavePlayerKeepsForwardTimestamps(t *testing.T) {
	created := time.Date(2026, 11, 18, 2, 0, 0, 0, time.UTC)
	stored := created.Add(8 * time.Hour)
	before := d.Player{PlayerID: identity.PlayerID(100001), Season: 1, StarAt: stored, MissionTime: stored, StateVersion: 1, CreatedAt: created, UpdatedAt: stored}
	next := before
	next.StarAt, next.MissionTime = created, created
	store := &recordingPlayerStore{}
	service := Service{Store: store}
	if err := service.save(context.Background(), nil, before, next, created); err != nil {
		t.Fatal(err)
	}
	if !store.saved.UpdatedAt.Equal(stored) || !store.saved.StarAt.Equal(stored) || !store.saved.MissionTime.Equal(stored) || store.saved.StateVersion != 2 || store.old != 1 {
		t.Fatalf("saved %+v old=%d", store.saved, store.old)
	}
}
