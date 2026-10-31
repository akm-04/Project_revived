//go:build postgres

package playerdisplay_test

import (
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/arenastore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/application/i5"
	display "gxb.local/backend/v2/internal/application/playerdisplay"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestI97BEnrollmentUsesImmutableSettlementNative(t *testing.T) {
	database := pool(t)
	service := arenaService(t, database)
	first, _ := oneOnOnePlayer(t, database, rankingServer(t, database))
	second, _ := oneOnOnePlayer(t, database, rankingServer(t, database))
	catalog := arenaCatalog(t, database)
	season := catalog.SeasonAt(time.Now()).Number
	// Matchmaking and settlement span the whole season, so earlier tests' players would be offered instead of this pair.
	exec(t, database, `UPDATE arena_players SET season=LEAST(season,$1-1),defense=jsonb_set(defense,'{heroes}','[]')`, season)
	exec(t, database, `DELETE FROM arena_settlement_ranks WHERE season=$1`, season)
	exec(t, database, `DELETE FROM arena_settlements WHERE season=$1`, season)
	for _, actor := range []identity.ActorContext{first, second} {
		transaction, err := database.Begin(ctx, tx.Options{})
		if err != nil {
			t.Fatal(err)
		}
		if err := (characterstore.PetBootstrapContributor{}).PersistCharacterBootstrap(ctx, transaction, logicalserver.BootstrapContext{PlayerID: actor.PlayerID, Operation: op()}); err != nil {
			transaction.Rollback(ctx)
			t.Fatal(err)
		}
		if err := transaction.Commit(ctx); err != nil {
			t.Fatal(err)
		}
		if _, err := service.Info(ctx, actor, op()); err != nil {
			t.Fatal(err)
		}
		if _, err := service.ModifyDefence(ctx, actor, arenaGirls(5), 0, op()); err != nil {
			t.Fatal(err)
		}
	}
	arenaFight(t, service, first, second.PlayerID, false)
	arenaFight(t, service, second, first.PlayerID, false)
	calendar, err := catalog.Tournament.Rules.Calendar(catalog.SeasonNumbered(season))
	if err != nil {
		t.Fatal(err)
	}
	clock := &workplaceTime{at: calendar.Stages[0].Add(time.Minute)}
	service.Timed.Binder.Time = clock
	for _, actor := range []identity.ActorContext{first, second} {
		exec(t, database, `UPDATE account_sessions SET absolute_expires_at=$2,idle_timeout_seconds=NULL WHERE session_id=$1`, actor.SessionID.UUID().String(), clock.at.Add(10*24*time.Hour))
	}
	if _, err := service.Due(ctx, op()); err != nil {
		t.Fatal("settle source Arena season", err)
	}
	previous, err := (arenastore.Store{}).PreviousSeasonRanksTx(ctx, database, season)
	if err != nil || len(previous) < 2 {
		t.Fatalf("missing immutable ranks: %v", err)
	}
	initial, err := service.EnrollTournament(ctx, first, op())
	if err != nil {
		t.Fatal(err)
	}
	replayed, err := service.EnrollTournament(ctx, first, op())
	if err != nil || len(replayed.Entrants) != len(initial.Entrants) {
		t.Fatalf("duplicate enrollment: %v", err)
	}
	if _, err := service.EnrollTournament(ctx, second, op()); err != nil {
		t.Fatal(err)
	}
	// Mutable next-season standings cannot replace the completed season's qualification facts.
	exec(t, database, `UPDATE arena_players SET star=95,point=999 WHERE player_id=$1`, int64(second.PlayerID))
	declarationRequest := op()
	if _, err := service.DeclareTournament(ctx, first, "Ready for Playoffs", declarationRequest); err != nil {
		t.Fatal(err)
	}
	if _, err := service.DeclareTournament(ctx, first, "Ready for Playoffs", declarationRequest); err != nil {
		t.Fatal(err)
	}
	if _, err := service.DeclareTournament(ctx, first, string(make([]byte, 100)), op()); err == nil {
		t.Fatal("oversized declaration accepted")
	}
	clock.at = calendar.Stages[1]
	locked, err := service.AdvanceTournament(ctx, season, op())
	if err != nil || !locked.RosterLocked || locked.Cancelled || len(locked.Contests) != 48 {
		t.Fatalf("freeze source group structure: %+v %v", locked, err)
	}
	for _, entrant := range locked.Entrants {
		found := false
		for _, row := range previous {
			if row.PlayerID == entrant.PlayerID && row.PreviousSeasonRank == entrant.PreviousSeasonRank {
				found = true
			}
		}
		if !found {
			t.Fatal("qualification reread mutable next-season standings")
		}
	}
	if _, err := service.EnrollTournament(ctx, first, op()); err == nil {
		t.Fatal("registration reopened at preparation")
	}
	if _, err := service.SupportTournament(ctx, first, second.PlayerID, op()); err != nil {
		t.Fatal(err)
	}
	clock.at = calendar.Stages[5]
	if _, err := service.SupportTournament(ctx, first, second.PlayerID, op()); err == nil {
		t.Fatal("support accepted at semifinal cutoff")
	}
	clock.at = calendar.Stages[7].Add(2 * time.Hour)
	readyChecked := false
	var finished d.TournamentPeriod
	for step := 0; step < 12; step++ {
		if _, err := service.AdvanceTournament(ctx, season, op()); err != nil {
			t.Fatal(err)
		}
		if !readyChecked {
			rooms, err := (arenastore.Store{}).TournamentRoomsTx(ctx, database, season, 0, false)
			if err != nil {
				t.Fatal(err)
			}
			for _, room := range rooms {
				if room.Status != d.RoomPreparing {
					continue
				}
				later := clock.at
				clock.at = room.StartsAt.Add(-10 * time.Second)
				actor := first
				if room.Selection.Players[0] == second.PlayerID {
					actor = second
				}
				request := op()
				ready, err := service.ReadyTournament(ctx, actor, room.Identifier, request)
				if err != nil || !ready.Ready[0] {
					t.Fatalf("ready: %+v %v", ready, err)
				}
				if _, err := service.ReadyTournament(ctx, actor, room.Identifier, request); err != nil {
					t.Fatal(err)
				}
				clock.at = room.StartsAt
				other := first
				if actor.PlayerID == first.PlayerID {
					other = second
				}
				if _, err := service.ReadyTournament(ctx, other, room.Identifier, op()); err == nil {
					t.Fatal("late ready accepted")
				}
				clock.at = later
				readyChecked = true
				break
			}
		}
		if _, err := service.ReconcileTournaments(ctx, op(), 100); err != nil {
			t.Fatal("reconcile recurring bracket", err)
		}
		var found bool
		finished, found, err = (arenastore.Store{}).ReadTournamentTx(ctx, database, season, false)
		if err != nil || !found {
			t.Fatal(err)
		}
		if finished.Settled {
			break
		}
	}
	if !readyChecked {
		t.Fatal("no genuine preparing room tested")
	}
	if !finished.Settled || finished.Cancelled || !finished.ChampionPrizeOwed {
		t.Fatalf("bracket did not finish: %+v", finished)
	}
	var champion identity.PlayerID
	for _, entrant := range finished.Entrants {
		if entrant.Placement < 1 || entrant.Placement > d.TournamentEntrantLimit {
			t.Fatalf("sparse placement: %+v", entrant)
		}
		if entrant.Placement == 1 {
			champion = entrant.PlayerID
		}
		if count := scalar(t, database, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='ARENA_PLAYOFFS_REWARD'`, int64(entrant.PlayerID)); count != 1 {
			t.Fatalf("tournament reward count %d", count)
		}
	}
	if _, err := service.AdvanceTournament(ctx, season, op()); err != nil {
		t.Fatal(err)
	}
	templates, err := service.Content.ArenaTemplatesTx(ctx, database, finished.ContentRevision)
	if err != nil {
		t.Fatal(err)
	}
	var chosen int64
	for identifier, template := range templates {
		if template.Super && !template.Awakened {
			chosen = identifier
			break
		}
	}
	if chosen == 0 {
		t.Fatal("missing SX catalog")
	}
	operator := i5.AdminOperator{ID: "native-operator", ReasonCode: "champion-selected-SX"}
	lostChoice := service
	lostChoice.Timed.Runner.DB = &faultDB{Beginner: database, n: 2, commit: true}
	if _, err := lostChoice.FulfillTournamentChampion(ctx, operator, season, chosen, op()); err != nil {
		t.Fatal(err)
	}
	if _, err := service.FulfillTournamentChampion(ctx, operator, season, chosen, op()); err != nil {
		t.Fatal(err)
	}
	if count := scalar(t, database, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='ARENA_PLAYOFFS_CHAMPION_CHOICE'`, int64(champion)); count != 1 {
		t.Fatalf("champion choice duplicated %d", count)
	}

	observation, err := service.ReadCatalogDisplayOriginsTx(ctx, database, display.CatalogOriginRequest{PlayerID: champion, Family: "frame", CatalogID: 120001078, Revision: finished.ContentRevision, ObservedAt: clock.at})
	if err != nil || !observation.Qualified || !observation.CompleteHistory || len(observation.Origins) != 1 {
		t.Fatalf("champion frame origin: %+v %v", observation, err)
	}

}
