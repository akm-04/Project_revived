//go:build postgres

package playerdisplay_test

import (
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/adventurestore"
	d "gxb.local/backend/v2/internal/domain/adventure"
)

func TestI9_10BActiveTypesTxLifecycle(t *testing.T) {
	p := pool(t)
	a := bornActor(t, p)
	other := bornActor(t, p)
	empty := bornActor(t, p)
	// One explicit instant: active rows end after it, the expired row ends exactly on it.
	at := time.Date(2026, 11, 15, 12, 0, 0, 0, time.UTC)
	insert := func(playerID int64, eventType int64, occurredAt, endTime time.Time, finished any, sourceKey string) {
		t.Helper()
		exec(t, p, `INSERT INTO adventure_occurrences(player_id,logical_server_id,event_type,occurred_at,end_time,special_data,source_key,finished_at)VALUES($1,$2,$3,$4,$5,0,$6,$7)`,
			playerID, int32(a.LogicalServerID), eventType, occurredAt, endTime, sourceKey, finished)
	}
	insert(int64(a.PlayerID), d.EventFavor, at.Add(-time.Hour), at.Add(time.Hour), nil, "qual-active-favor")
	insert(int64(a.PlayerID), d.EventDefense, at.Add(-time.Hour), at, nil, "qual-expired-at-instant")
	insert(int64(a.PlayerID), d.EventShop, at.Add(-2*time.Hour), at.Add(time.Hour), at.Add(-time.Minute), "qual-finished")
	insert(int64(other.PlayerID), d.EventBattle, at.Add(-time.Hour), at.Add(time.Hour), nil, "qual-other-player")

	active, err := (adventurestore.Store{}).ActiveTypesTx(ctx, p, a.PlayerID, at)
	if err != nil {
		t.Fatal(err)
	}
	if len(active) != 1 {
		t.Fatalf("active types %v want only %d", active, d.EventFavor)
	}
	if _, ok := active[d.EventFavor]; !ok {
		t.Fatalf("active types %v missing favor %d", active, d.EventFavor)
	}
	for _, eventType := range []int64{d.EventDefense, d.EventShop, d.EventBattle} {
		if _, ok := active[eventType]; ok {
			t.Fatalf("active types %v included %d (expired-at-instant, finished or other player)", active, eventType)
		}
	}

	otherActive, err := (adventurestore.Store{}).ActiveTypesTx(ctx, p, other.PlayerID, at)
	if err != nil {
		t.Fatal(err)
	}
	if _, ok := otherActive[d.EventBattle]; !ok || len(otherActive) != 1 {
		t.Fatalf("other player active types %v want only its own %d", otherActive, d.EventBattle)
	}

	emptyActive, err := (adventurestore.Store{}).ActiveTypesTx(ctx, p, empty.PlayerID, at)
	if err != nil {
		t.Fatal(err)
	}
	if emptyActive == nil || len(emptyActive) != 0 {
		t.Fatalf("empty active types %v", emptyActive)
	}
}
