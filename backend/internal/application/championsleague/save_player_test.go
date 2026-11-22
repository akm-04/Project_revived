package championsleague

import (
	"context"
	"strings"
	"testing"
	"time"

	d "gxb.local/backend/v2/internal/domain/championsleague"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type savePlayerStore struct {
	Store
	saved d.Player
	old   int64
}

func (f *savePlayerStore) PutPlayerTx(_ context.Context, _ tx.Tx, p d.Player, old int64) error {
	f.saved, f.old = p, old
	return p.Validate()
}

// I9_11_CLOCK_ROLLBACK_V1 K3/K7: a decision time one hour before the stored
// UpdatedAt is accepted and the write keeps the later stored value.
func TestSavePlayerKeepsStoredForwardUpdatedAt(t *testing.T) {
	created := time.Date(2026, 11, 18, 2, 0, 0, 0, time.UTC)
	stored := created.Add(time.Hour)
	store := &savePlayerStore{}
	service := Service{Store: store}
	player := d.Player{ID: identity.PlayerID(100001), Server: 1, Season: 1, Group: 1, Points: 2000, ScoreAt: created, Tie: strings.Repeat("a", 64), Intent: 1, Version: 1, CreatedAt: created, UpdatedAt: stored}
	if err := service.savePlayer(context.Background(), nil, &player, created); err != nil {
		t.Fatal(err)
	}
	if !store.saved.UpdatedAt.Equal(stored) || store.saved.Version != 2 || store.old != 1 {
		t.Fatalf("saved %+v old=%d", store.saved, store.old)
	}
}
