//go:build postgres

package playerdisplay_test

import (
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/topfloorstore"
	domain "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestI97ATaskPeriodStorageIsolationNative(t *testing.T) {
	database := pool(t)
	server := rankingServer(t, database)
	actor, revision, _ := topFloorPlayer(t, database, server)
	normal, err := topFloorService(t, database).Load(ctx, actor, op())
	if err != nil {
		t.Fatal(err)
	}
	catalog := domain.TaskModeCatalog{Schedule: []domain.TaskModeScheduleEntry{{Date: "20170811", Mode: domain.TaskModeSingle}}}
	at := time.Date(2026, 10, 23, 10, 0, 0, 0, time.UTC)
	first, err := catalog.NewPeriod(server, revision, at)
	if err != nil {
		t.Fatal(err)
	}
	next, err := catalog.NewPeriod(server, revision, at.Add(7*24*time.Hour))
	if err != nil {
		t.Fatal(err)
	}
	store := topfloorstore.Store{}
	transaction, err := database.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	if _, err = transaction.Exec(ctx, `SET LOCAL TIME ZONE 'Europe/London'`); err != nil {
		t.Fatal(err)
	}
	if err = store.CreateTaskPeriodTx(ctx, transaction, first); err != nil {
		t.Fatal(err)
	}
	if err = store.CreateTaskPeriodTx(ctx, transaction, next); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	ranks, err := store.TaskRangeTx(ctx, database, server, first.Rotation.Number, 1, 2)
	if err != nil || len(ranks) != 2 || ranks[0].Occupant.Robot != domain.RobotTeams {
		t.Fatalf("source robot seed %+v %v", ranks, err)
	}
	transaction, err = database.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	locked, found, err := store.ReadTaskPeriodTx(ctx, transaction, server, first.Rotation.Number, true)
	if err != nil || !found {
		t.Fatal("period missing", err)
	}
	if err = store.AppendTaskPlayerTx(ctx, transaction, server, first.Rotation.Number, domain.RobotTeams+1, actor.PlayerID); err != nil {
		t.Fatal(err)
	}
	locked.Ladder.Size++
	locked.Ladder.StateVersion++
	locked.Ladder.UpdatedAt = at.Add(time.Minute)
	if err = store.SaveTaskPeriodTx(ctx, transaction, locked, first.Ladder.StateVersion); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	transaction, err = database.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	challenger := domain.Ranked{Rank: domain.RobotTeams + 1, Occupant: domain.Occupant{Player: actor.PlayerID}}
	if err = store.SwapTaskRanksTx(ctx, transaction, server, first.Rotation.Number, challenger, ranks[0]); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal("deferred uniqueness swap", err)
	}
	rank, found, err := store.TaskRankOfTx(ctx, database, server, first.Rotation.Number, challenger.Occupant)
	if err != nil || !found || rank != 1 {
		t.Fatalf("special player rank %d %v %v", rank, found, err)
	}
	rank, found, err = store.RankOfTx(ctx, database, server, challenger.Occupant)
	if err != nil || !found || rank != normal.Rank {
		t.Fatal("normal ladder changed", rank, normal.Rank, err)
	}
	rank, found, err = store.TaskRankOfTx(ctx, database, server, next.Rotation.Number, ranks[0].Occupant)
	if err != nil || !found || rank != 1 {
		t.Fatal("next period changed", rank, err)
	}
	transaction, err = database.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	stale := first
	stale.Ladder.StateVersion++
	stale.Ladder.UpdatedAt = at.Add(2 * time.Minute)
	if err = store.SaveTaskPeriodTx(ctx, transaction, stale, first.Ladder.StateVersion); !errors.Is(err, domain.ErrConflict) {
		t.Fatal("stale write accepted", err)
	}
	frozen := locked
	frozen.Rotation.Mode = domain.TaskModeTriple
	frozen.Ladder.StateVersion++
	frozen.Ladder.UpdatedAt = at.Add(3 * time.Minute)
	if err = store.SaveTaskPeriodTx(ctx, transaction, frozen, locked.Ladder.StateVersion); !errors.Is(err, domain.ErrConflict) {
		t.Fatal("frozen mode changed", err)
	}
	transaction.Rollback(ctx)
	ready, release := make(chan struct{}, 2), make(chan struct{})
	results := make(chan error, 2)
	for range 2 {
		go func() {
			concurrent, failure := database.Begin(ctx, tx.Options{})
			var candidate domain.TaskModePeriod
			if failure == nil {
				defer concurrent.Rollback(ctx)
				var exists bool
				candidate, exists, failure = store.ReadTaskPeriodTx(ctx, concurrent, server, first.Rotation.Number, false)
				if failure == nil && !exists {
					failure = domain.ErrConflict
				}
			}
			ready <- struct{}{}
			<-release
			if failure == nil {
				previousVersion := candidate.Ladder.StateVersion
				candidate.Ladder.StateVersion++
				candidate.Ladder.UpdatedAt = at.Add(5 * time.Minute)
				failure = store.SaveTaskPeriodTx(ctx, concurrent, candidate, previousVersion)
			}
			if failure == nil {
				failure = concurrent.Commit(ctx)
			}
			results <- failure
		}()
	}
	<-ready
	<-ready
	close(release)
	wins, conflicts := 0, 0
	for range 2 {
		failure := <-results
		if failure == nil {
			wins++
			continue
		}
		if errors.Is(failure, domain.ErrConflict) {
			conflicts++
			continue
		}
		t.Fatal("concurrent period update", failure)
	}
	if wins != 1 || conflicts != 1 {
		t.Fatalf("concurrent CAS wins%d conflicts%d", wins, conflicts)
	}
}
