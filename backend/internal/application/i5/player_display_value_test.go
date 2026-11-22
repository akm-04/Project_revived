package i5

import (
	"context"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/player"
)

func TestApplyDisplayValueKeepsAForwardStoredTimestamp(t *testing.T) {
	actor := testActor(t)
	at := time.Unix(1700000000, 0).UTC()
	stored := at.Add(8 * time.Hour)
	store := &testStore{
		scalar:       economy.ScalarBalance{PlayerID: actor.PlayerID, ResourceKey: "crystal", Amount: 100, StateVersion: 1, UpdatedAt: stored},
		scalarExists: true,
	}
	owner := DisplayValueOwner{Store: store}
	tx := &testTx{}
	prepared, err := owner.PrepareDisplayValueTx(context.Background(), tx, actor, DisplayValueRequest{RenameAmount: 5}, player.DisplayCatalog{}, strings.Repeat("a", 64), at, testOperation(9))
	if err != nil {
		t.Fatal(err)
	}
	if _, err = prepared.ApplyDisplayValueTx(context.Background(), tx); err != nil {
		t.Fatal(err)
	}
	if store.scalar.Amount != 95 {
		t.Fatalf("crystal amount = %d, want 95", store.scalar.Amount)
	}
	if store.scalar.UpdatedAt.Before(stored) {
		t.Fatalf("updated_at = %v before the stored forward fact %v", store.scalar.UpdatedAt, stored)
	}
}
