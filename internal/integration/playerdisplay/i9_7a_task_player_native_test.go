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

func TestI97ATaskPlayerStorageNative(t *testing.T) {
	database := pool(t)
	server := rankingServer(t, database)
	actor, revision, hero := topFloorPlayer(t, database, server)
	if _, err := topFloorService(t, database).Load(ctx, actor, op()); err != nil {
		t.Fatal(err)
	}
	at := time.Date(2026, 10, 23, 10, 0, 0, 0, time.UTC)
	catalog := domain.TaskModeCatalog{Schedule: []domain.TaskModeScheduleEntry{{Date: "20170811", Mode: domain.TaskModeLeader}}}
	period, err := catalog.NewPeriod(server, revision, at)
	if err != nil {
		t.Fatal(err)
	}
	store := topfloorstore.Store{}
	transaction, err := database.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	if err = store.CreateTaskPeriodTx(ctx, transaction, period); err != nil {
		t.Fatal(err)
	}
	if err = store.AppendTaskPlayerTx(ctx, transaction, server, period.Rotation.Number, domain.RobotTeams+1, actor.PlayerID); err != nil {
		t.Fatal(err)
	}
	period.Ladder.Size++
	period.Ladder.StateVersion++
	if err = store.SaveTaskPeriodTx(ctx, transaction, period, 1); err != nil {
		t.Fatal(err)
	}
	player := domain.TaskModePlayer{Player: (domain.Catalog{FreeTickets: 5}).NewPlayer(actor.PlayerID, server, revision, domain.RobotTeams+1, at), PeriodNumber: period.Rotation.Number}
	if err = store.InsertTaskPlayerTx(ctx, transaction, player, period); err != nil {
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
	loaded, found, err := store.ReadTaskPlayerTx(ctx, transaction, actor.PlayerID, period, true)
	if err != nil || !found || loaded.Player.TicketsLeft != 5 {
		t.Fatal("player round trip", found, err)
	}
	loaded.Player.Defense = []int64{hero.PartnerID}
	loaded.Leader = hero.PartnerID
	loaded.Player.TicketsLeft = 4
	loaded.Player.StateVersion++
	loaded.Player.UpdatedAt = at.Add(time.Minute)
	if err = store.SaveTaskPlayerTx(ctx, transaction, loaded, period, 1); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	actual, found, err := store.ReadTaskPlayerTx(ctx, database, actor.PlayerID, period, false)
	if err != nil || !found || actual.Leader != hero.PartnerID || actual.Player.TicketsLeft != 4 || actual.Player.StateVersion != 2 {
		t.Fatalf("saved player %+v %v", actual, err)
	}
	transaction, err = database.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	if err = store.SaveTaskPlayerTx(ctx, transaction, loaded, period, 1); !errors.Is(err, domain.ErrConflict) {
		t.Fatal("stale player write", err)
	}
	invalid := loaded
	const startingHeroTableID = 10001001
	invalid.Leader = startingHeroTableID
	invalid.Player.StateVersion++
	if err = store.SaveTaskPlayerTx(ctx, transaction, invalid, period, 2); !errors.Is(err, domain.ErrConflict) {
		t.Fatal("table ID accepted as owned leader", err)
	}
	invalid = loaded
	invalid.Player.ContentRevision = "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
	invalid.Player.StateVersion++
	if err = store.SaveTaskPlayerTx(ctx, transaction, invalid, period, 2); !errors.Is(err, domain.ErrConflict) {
		t.Fatal("unfrozen content accepted", err)
	}
}
