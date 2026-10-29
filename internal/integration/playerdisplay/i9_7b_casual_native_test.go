//go:build postgres

package playerdisplay_test

import (
	"errors"
	"sync"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/arenastore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	app "gxb.local/backend/v2/internal/application/arena"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestI97BCasualQueueConcurrencyNative(t *testing.T) {
	database := pool(t)
	service := arenaService(t, database)
	first, firstHeroes := oneOnOnePlayer(t, database, rankingServer(t, database))
	second, _ := oneOnOnePlayer(t, database, rankingServer(t, database))
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
	}
	period := d.CasualPeriodAt(time.Now().UTC())
	if !period.OpensAt.After(time.Now().UTC()) {
		period = d.CasualPeriodAt(period.OpensAt.Add(7 * 24 * time.Hour))
	}
	clock := &workplaceTime{at: period.OpensAt.Add(time.Minute)}
	service.Timed.Binder.Time = clock
	for _, actor := range []identity.ActorContext{first, second} {
		exec(t, database, `UPDATE account_sessions SET absolute_expires_at=$2,idle_timeout_seconds=NULL WHERE session_id=$1`, actor.SessionID.UUID().String(), clock.at.Add(24*time.Hour))
	}
	t.Run("duplicate-admission-and-expiry", func(t *testing.T) {
		lostAcknowledgement := service
		lostAcknowledgement.Timed.Runner.DB = &faultDB{Beginner: database, n: 2, commit: true}
		request := op()
		entry, err := lostAcknowledgement.QueueCasual(ctx, first, request)
		if err != nil {
			t.Fatal(err)
		}
		replayed, err := service.QueueCasual(ctx, first, op())
		if err != nil || replayed.Identifier != entry.Identifier {
			t.Fatalf("duplicate admission %v %v", replayed.Identifier, err)
		}
		clock.at = entry.ExpiresAt
		replacement, err := service.QueueCasual(ctx, first, op())
		if err != nil || replacement.Identifier == entry.Identifier {
			t.Fatalf("expired entry reused: %v", err)
		}
		if err := service.CancelCasual(ctx, first, op()); err != nil {
			t.Fatal(err)
		}
	})
	t.Run("two-match-workers", func(t *testing.T) {
		for _, actor := range []identity.ActorContext{first, second} {
			clock.at = clock.at.Add(time.Millisecond)
			if _, err := service.QueueCasual(ctx, actor, op()); err != nil {
				t.Fatal(err)
			}
		}
		type result struct {
			room    d.TournamentRoom
			matched bool
			err     error
		}
		results := make(chan result, 2)
		var workers sync.WaitGroup
		for range 2 {
			workers.Add(1)
			go func() {
				defer workers.Done()
				room, matched, err := service.MatchCasual(ctx, op())
				results <- result{room: room, matched: matched, err: err}
			}()
		}
		workers.Wait()
		close(results)
		matches := 0
		var matchedRoom d.TournamentRoom
		for result := range results {
			if result.err != nil {
				t.Fatal(result.err)
			}
			if result.matched {
				matches++
				matchedRoom = result.room
			}
		}
		if matches != 1 {
			t.Fatalf("matched %d times", matches)
		}
		if err := service.CancelCasual(ctx, first, op()); !errors.Is(err, d.ErrRefused) {
			t.Fatalf("cancel consumed match: %v", err)
		}
		reloaded, found, err := (arenastore.Store{}).ReadTournamentRoomTx(ctx, database, matchedRoom.Identifier, false)
		if err != nil || !found || reloaded.Actors[0].ContextID.IsZero() {
			t.Fatalf("room provenance lost on JSON reload: %v", err)
		}
		command := app.TournamentSelectionCommand{Room: reloaded.Identifier, Team: 1, Turn: 0, Formation: d.SelectedFormation{Heroes: firstHeroes[:1]}}
		selected, err := service.SelectTournament(ctx, first, command, op())
		if err != nil || selected.Selection.Turn != 1 {
			t.Fatalf("owned selection: %+v %v", selected.Selection, err)
		}
		if err := service.AcknowledgeTournament(ctx, first, selected.Identifier, selected.NoticeVersion, op()); err != nil {
			t.Fatal(err)
		}
		acknowledged, _, err := (arenastore.Store{}).ReadTournamentRoomTx(ctx, database, selected.Identifier, false)
		if err != nil || acknowledged.NoticeVersion != selected.NoticeVersion || acknowledged.StateVersion != selected.StateVersion+1 || acknowledged.Acknowledged[0] != selected.NoticeVersion {
			t.Fatalf("ack altered notice version: %+v %v", acknowledged, err)
		}
		replayed, err := service.SelectTournament(ctx, first, command, op())
		if err != nil || replayed.StateVersion != selected.StateVersion {
			t.Fatalf("semantic selection replay advanced: %v", err)
		}
		unchanged, err := service.ReconcileTournamentSelection(ctx, selected.Identifier, op())
		if err != nil || unchanged.NoticeVersion != acknowledged.NoticeVersion || unchanged.StateVersion != acknowledged.StateVersion {
			t.Fatalf("idle poll changed acknowledged selector: %+v %v", unchanged, err)
		}
		clock.at = reloaded.StartsAt.Add(20 * time.Minute)
		restarted := arenaService(t, database)
		restarted.Timed.Binder.Time = clock
		expired, err := restarted.ReconcileTournamentSelection(ctx, reloaded.Identifier, op())
		if err != nil || !expired.Selection.Complete() || expired.Status != d.RoomFighting {
			t.Fatalf("offline deadline recovery: %+v %v", expired.Selection, err)
		}
		duplicate, err := restarted.ReconcileTournamentSelection(ctx, reloaded.Identifier, op())
		if err != nil || duplicate.StateVersion != expired.StateVersion {
			t.Fatalf("restart repeated deadline transition: %v", err)
		}
		replayed, err = service.SelectTournament(ctx, first, command, op())
		if err != nil || replayed.StateVersion != selected.StateVersion {
			t.Fatalf("old accepted command was lost after deadline: %v", err)
		}
		command.Formation.Heroes = firstHeroes[1:2]
		if _, err := service.SelectTournament(ctx, first, command, op()); err == nil {
			t.Fatal("conflicting old-turn overwrite accepted")
		}

		lostStart := restarted
		lostStart.Timed.Runner.DB = &faultDB{Beginner: database, n: 2, commit: true}
		started, err := lostStart.StartTournamentCombat(ctx, reloaded.Identifier, op())
		if err != nil || len(started.Attempts) != 3 {
			t.Fatalf("freeze real owned teams: %+v %v", started.Attempts, err)
		}
		lostTerminal := restarted
		lostTerminal.Timed.Runner.DB = &faultDB{Beginner: database, n: 2, commit: true}
		finished, err := lostTerminal.ResolveTournamentCombat(ctx, reloaded.Identifier, op())
		if err != nil || finished.Status != d.RoomSettled || finished.GenuineBattles < 2 || finished.Winner == 0 {
			t.Fatalf("genuine terminal: %+v %v", finished, err)
		}
		restartedAgain := arenaService(t, database)
		restartedAgain.Timed.Binder.Time = clock
		duplicateFinish, err := restartedAgain.ResolveTournamentCombat(ctx, reloaded.Identifier, op())
		if err != nil || duplicateFinish.StateVersion != finished.StateVersion {
			t.Fatalf("terminal restart changed outcome: %v", err)
		}

		replayView, err := restartedAgain.TournamentReport(ctx, first, reloaded.Identifier, 1, 0, op())
		if err != nil || len(replayView.Report) == 0 || len(replayView.Heroes[0]) != 5*finished.GenuineBattles || replayView.Room.Faces[0].Player == 0 {
			t.Fatalf("frozen replay view: %v", err)
		}
		stranger := rankingActor(t, database, rankingServer(t, database), true)
		exec(t, database, `UPDATE account_sessions SET absolute_expires_at=$2,idle_timeout_seconds=NULL WHERE session_id=$1`, stranger.SessionID.UUID().String(), clock.at.Add(24*time.Hour))
		if _, err := restartedAgain.TournamentReport(ctx, stranger, reloaded.Identifier, 1, 0, op()); err == nil {
			t.Fatal("Casual replay leaked to spectator")
		}
		beforeExpiry := clock.at
		clock.at = finished.SettledAt.Add(8 * 24 * time.Hour)
		exec(t, database, `UPDATE account_sessions SET absolute_expires_at=$2 WHERE session_id=$1`, first.SessionID.UUID().String(), clock.at.Add(24*time.Hour))
		if _, err := restartedAgain.TournamentReport(ctx, first, reloaded.Identifier, 1, 0, op()); !errors.Is(err, d.ErrRefused) {
			t.Fatalf("expired replay retained: %v", err)
		}
		retained, found, err := (arenastore.Store{}).ReadTournamentRoomTx(ctx, database, reloaded.Identifier, false)
		if err != nil || !found || retained.Status != d.RoomSettled {
			t.Fatalf("report expiry deleted durable log: %v", err)
		}
		clock.at = beforeExpiry
		if count := scalar(t, database, `SELECT sum(points) FROM arena_casual_scores WHERE week_day=$1 AND player_id IN ($2,$3)`, period.WeekDay, int64(first.PlayerID), int64(second.PlayerID)); count != 1 {
			t.Fatalf("duplicate points: %d", count)
		}
		for _, player := range []identity.PlayerID{first.PlayerID, second.PlayerID} {
			if _, found, err := (arenastore.Store{}).ActiveCasualEntryTx(ctx, database, player); err != nil || found {
				t.Fatalf("settled room retained queue: %v", err)
			}
		}

	})
	t.Run("cancel-versus-match", func(t *testing.T) {
		for _, actor := range []identity.ActorContext{first, second} {
			clock.at = clock.at.Add(time.Millisecond)
			if _, err := service.QueueCasual(ctx, actor, op()); err != nil {
				t.Fatal(err)
			}
		}
		cancelled := make(chan error, 1)
		go func() { cancelled <- service.CancelCasual(ctx, first, op()) }()
		room, matched, err := service.MatchCasual(ctx, op())
		cancelError := <-cancelled
		if err != nil {
			t.Fatal(err)
		}
		if matched && !errors.Is(cancelError, d.ErrRefused) || !matched && cancelError != nil {
			t.Fatalf("cancel and match did not linearize: matched=%v cancel=%v", matched, cancelError)
		}
		entry, found, err := (arenastore.Store{}).ActiveCasualEntryTx(ctx, database, first.PlayerID)
		if err != nil || found != matched || matched && entry.Room != room.Identifier || !matched && entry.Room != (ids.UUID{}) {
			t.Fatalf("queue disagrees with winner: %+v %v", entry, err)
		}
	})
	t.Run("session-settlement-once", func(t *testing.T) {
		rooms, err := (arenastore.Store{}).TournamentRoomsTx(ctx, database, period.WeekDay, 0, true)
		if err != nil {
			t.Fatal(err)
		}
		clock.at = period.ClosesAt
		for _, room := range rooms {
			if room.Status == d.RoomSettled {
				continue
			}
			if _, err := service.ReconcileTournamentSelection(ctx, room.Identifier, op()); err != nil {
				t.Fatal(err)
			}
			if _, err := service.StartTournamentCombat(ctx, room.Identifier, op()); err != nil {
				t.Fatal(err)
			}
			if _, err := service.ResolveTournamentCombat(ctx, room.Identifier, op()); err != nil {
				t.Fatal(err)
			}
		}
		beforeClose := period.OpensAt.Add(time.Minute)
		clock.at = period.ClosesAt
		lost := service
		lost.Timed.Runner.DB = &faultDB{Beginner: database, n: 2, commit: true}
		if err := lost.SettleCasualSession(ctx, period.WeekDay, op()); err != nil {
			t.Fatal(err)
		}
		if err := service.SettleCasualSession(ctx, period.WeekDay, op()); err != nil {
			t.Fatal(err)
		}
		for _, actor := range []identity.ActorContext{first, second} {
			if count := scalar(t, database, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='ARENA_CASUAL_REWARD'`, int64(actor.PlayerID)); count != 1 {
				t.Fatalf("reward count %d", count)
			}
		}
		clock.at = beforeClose
		if _, err := service.QueueCasual(ctx, first, op()); err == nil {
			t.Fatal("settled session reopened")
		}
	})

}
