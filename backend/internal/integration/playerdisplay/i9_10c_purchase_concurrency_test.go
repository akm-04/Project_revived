//go:build postgres

package playerdisplay_test

import (
	"errors"
	"sync"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	dorm "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/operation"
)

func TestI910CGluePurchaseDailyCapConcurrency(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	store := contentstore.Store{Queryer: p}
	owner := dormstore.Store{Queryer: p}
	activation, ok, err := store.ReadActivation(ctx, p)
	if err != nil || !ok || activation.RevisionID != revision {
		t.Fatalf("active revision=%+v ok=%v err=%v", activation, ok, err)
	}
	catalog, err := store.DormCatalogTx(ctx, p, activation.RevisionID)
	if err != nil || catalog.Glue == nil {
		t.Fatalf("glue rules=%v err=%v", catalog.Glue, err)
	}
	glue := catalog.Glue
	cap, known := glue.VIPDailyCap(0)
	if !known || cap != 1 {
		t.Fatalf("source VIP0 cap=%d known=%v", cap, known)
	}

	player := bornActor(t, p)
	service := dailyFloorService(p)
	at, err := (pg.AuthoritativeTime{Queryer: p}).Now(ctx)
	if err != nil {
		t.Fatal(err)
	}
	first := floorOperation(activation.RevisionID, at)
	second := floorOperation(activation.RevisionID, at)
	if first.ID == second.ID {
		t.Fatal("operations must be distinct")
	}

	type outcome struct {
		err error
	}
	results := make(chan outcome, 2)
	var wait sync.WaitGroup
	for _, current := range []operation.Context{first, second} {
		current := current
		wait.Add(1)
		go func() {
			defer wait.Done()
			results <- outcome{err: gluePurchaseCounterTransaction(service, owner, player, *glue, current)}
		}()
	}
	wait.Wait()
	close(results)
	successes, limitRefusals := 0, 0
	for result := range results {
		switch {
		case result.err == nil:
			successes++
		case errors.Is(result.err, dorm.ErrGlueDailyLimit):
			limitRefusals++
		default:
			t.Fatalf("unexpected concurrent purchase error: %v", result.err)
		}
	}
	if successes != 1 || limitRefusals != 1 {
		t.Fatalf("successes=%d limitRefusals=%d", successes, limitRefusals)
	}

	crystal, exists, err := (i5store.Store{Queryer: p}).ReadScalarTx(ctx, p, player.PlayerID, "crystal")
	if err != nil || !exists || crystal.Amount != 950 {
		t.Fatalf("crystal after contention=%+v exists=%v err=%v", crystal, exists, err)
	}
	glueBalance, exists, err := (i5store.Store{Queryer: p}).ReadScalarTx(ctx, p, player.PlayerID, "glue")
	if err != nil || !exists || glueBalance.Amount != 150 {
		t.Fatalf("glue after contention=%+v exists=%v err=%v", glueBalance, exists, err)
	}
	counter, exists, err := owner.ReadGluePurchasesTx(ctx, p, player.PlayerID)
	if err != nil || !exists || counter.Count != 1 || counter.StateVersion != 1 || counter.GameDay != modes.Day(at) {
		t.Fatalf("counter after contention=%+v exists=%v err=%v", counter, exists, err)
	}
	var anchorVersion int64
	var anchorDay int64
	if err := p.QueryRow(ctx, `SELECT state_version,game_day FROM player_scalar_daily_floors WHERE player_id=$1 AND resource_key='glue'`, int64(player.PlayerID)).Scan(&anchorVersion, &anchorDay); err != nil || anchorVersion != 1 || anchorDay != modes.Day(at) {
		t.Fatalf("floor anchor version=%d day=%d err=%v", anchorVersion, anchorDay, err)
	}
	if receipts := i910cGrantReceiptCount(t, p, player.PlayerID); receipts != 1 {
		t.Fatalf("accepted purchase grant receipts=%d want 1", receipts)
	}

	nextDay := modes.Day(at.Add(24 * time.Hour))
	projected, err := dorm.EffectiveGluePurchaseCount(&counter, player.PlayerID, nextDay, at.Add(24*time.Hour))
	if err != nil || projected != 0 {
		t.Fatalf("lazy next-day count=%d err=%v", projected, err)
	}
	if unchanged, exists, err := owner.ReadGluePurchasesTx(ctx, p, player.PlayerID); err != nil || !exists || unchanged != counter {
		t.Fatalf("projection wrote counter=%+v exists=%v err=%v", unchanged, exists, err)
	}
	next := floorOperation(activation.RevisionID, at.Add(24*time.Hour))
	if err = gluePurchaseCounterTransaction(service, owner, player, *glue, next); err != nil {
		t.Fatal(err)
	}
	crystal, _, err = (i5store.Store{Queryer: p}).ReadScalarTx(ctx, p, player.PlayerID, "crystal")
	if err != nil || crystal.Amount != 900 {
		t.Fatalf("next-day crystal=%+v err=%v", crystal, err)
	}
	glueBalance, _, err = (i5store.Store{Queryer: p}).ReadScalarTx(ctx, p, player.PlayerID, "glue")
	if err != nil || glueBalance.Amount != 200 {
		t.Fatalf("next-day glue=%+v err=%v", glueBalance, err)
	}
	updated, exists, err := owner.ReadGluePurchasesTx(ctx, p, player.PlayerID)
	if err != nil || !exists || updated.Count != 1 || updated.StateVersion != 2 || updated.GameDay != nextDay {
		t.Fatalf("next-day counter=%+v exists=%v err=%v", updated, exists, err)
	}
	t.Logf("REAL_PG concurrency: one accepted/one limit refusal crystal=950 glue=150 counter=1/v1; next-day (no clock move) count=%d then counter=1/v2 crystal=900 glue=200 day=%d", projected, updated.GameDay)
}
