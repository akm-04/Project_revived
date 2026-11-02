//go:build postgres

package playerdisplay_test

import (
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/arenastore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrelationstore"
	app "gxb.local/backend/v2/internal/application/arena"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/socialrelation"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sync"
	"testing"
	"time"
)

func TestI97CFriendFightLifecycleNative(t *testing.T) {
	database := pool(t)
	defer database.Close()
	service := arenaService(t, database)
	facts := countPVPFights(service.Facts.(i5.ObjectiveFacts))
	service.Facts = facts
	server := rankingServer(t, database)
	first, firstHeroes := oneOnOnePlayer(t, database, server)
	second, _ := oneOnOnePlayer(t, database, server)
	clock := &workplaceTime{at: time.Now().UTC().Add(time.Hour)}
	service.Timed.Binder.Time = clock
	for _, actor := range []identity.ActorContext{first, second} {
		exec(t, database, `UPDATE account_sessions SET absolute_expires_at=$2,idle_timeout_seconds=NULL WHERE session_id=$1`, actor.SessionID.UUID().String(), clock.at.Add(24*time.Hour))
		exec(t, database, `UPDATE player_directory_profiles SET lev=55 WHERE player_id=$1`, int64(actor.PlayerID))
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
	}
	command := app.FriendFightCommand{Player: second.PlayerID, Mode: 1, GameType: 1}
	if _, err := service.InviteFriendFight(ctx, first, command, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("nonfriend admitted", err)
	}
	dodgeballFriends(t, database, first.PlayerID, second.PlayerID, clock.at.Add(-time.Minute))
	setBlock := func(blocker, blocked identity.PlayerID, active bool) {
		transaction, err := database.Begin(ctx, tx.Options{})
		if err != nil {
			t.Fatal(err)
		}
		defer transaction.Rollback(ctx)
		store := socialrelationstore.Store{}
		previous, found, err := store.LockBlockTx(ctx, transaction, blocker, blocked)
		if err != nil {
			t.Fatal(err)
		}
		block := socialrelation.Block{BlockerPlayerID: blocker, BlockedPlayerID: blocked, Generation: 1, Active: active, ActivatedAt: clock.at.Add(-time.Second), UpdatedAt: clock.at, StateVersion: 1}
		var old *socialrelation.Block
		if found {
			old = &previous
			block = previous
			block.StateVersion++
			block.Active = active
			block.UpdatedAt = clock.at
		}
		if active {
			block.RemovedAt = nil
			if found {
				block.Generation++
				block.ActivatedAt = clock.at
			}
		}
		if !active {
			removed := clock.at
			block.RemovedAt = &removed
		}
		if err := store.PutBlockTx(ctx, transaction, old, block); err != nil {
			t.Fatal(err)
		}
		if err := transaction.Commit(ctx); err != nil {
			t.Fatal(err)
		}
	}
	for _, pair := range [][2]identity.PlayerID{{first.PlayerID, second.PlayerID}, {second.PlayerID, first.PlayerID}} {
		setBlock(pair[0], pair[1], true)
		if _, err := service.InviteFriendFight(ctx, first, command, op()); !errors.Is(err, d.ErrRefused) {
			t.Fatal("blocked invitation admitted", err)
		}
		setBlock(pair[0], pair[1], false)
	}
	exec(t, database, `UPDATE player_directory_profiles SET lev=54 WHERE player_id=$1`, int64(second.PlayerID))
	if _, err := service.InviteFriendFight(ctx, first, command, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("underlevel peer admitted", err)
	}
	exec(t, database, `UPDATE player_directory_profiles SET lev=55 WHERE player_id=$1`, int64(second.PlayerID))
	invitationBeforeBlock, err := service.InviteFriendFight(ctx, first, command, op())
	if err != nil {
		t.Fatal(err)
	}
	setBlock(second.PlayerID, first.PlayerID, true)
	if _, err := service.AcceptFriendFight(ctx, second, app.FriendFightCommand{Player: first.PlayerID, Mode: 1, GameType: 1}, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("block after invite ignored", err)
	}
	if err := service.RejectFriendFight(ctx, second, first.PlayerID, op()); err != nil {
		t.Fatal("blocked recipient cannot decline", err)
	}
	rejected, found, err := (arenastore.Store{}).ReadFriendInvitationTx(ctx, database, invitationBeforeBlock.Identifier, false)
	if err != nil || !found || rejected.Status != d.FriendInvitationRejected {
		t.Fatal("decline after block", err)
	}
	setBlock(second.PlayerID, first.PlayerID, false)
	reader := app.FriendFightNoticeReader{Store: arenastore.Store{}, Directory: service.Directory, Queryer: database, Time: clock}
	for _, mode := range []int{1, 2} {
		t.Run(map[int]string{1: "single-unbalanced", 2: "three-awakened"}[mode], func(t *testing.T) {
			command.Mode, command.GameType = mode, mode
			lost := service
			lost.Timed.Runner.DB = &faultDB{Beginner: database, n: 2, commit: true}
			invitation, err := lost.InviteFriendFight(ctx, first, command, op())
			if err != nil {
				t.Fatal("invite lost ACK", err)
			}
			repeat, err := service.InviteFriendFight(ctx, first, command, op())
			if err != nil || repeat.Identifier != invitation.Identifier {
				t.Fatal("duplicate invitation", err)
			}
			notice, found, err := reader.ReadFriendNotice(ctx, invitation.Identifier.String())
			if err != nil || !found || notice.Recipient != second.PlayerID || notice.Type != 14 || notice.Mode != mode {
				t.Fatal("canonical notice14", notice, err)
			}
			wrong := command
			wrong.Player = first.PlayerID
			wrong.Mode = 3 - mode
			if _, err := service.AcceptFriendFight(ctx, second, wrong, op()); !errors.Is(err, d.ErrRefused) {
				t.Fatal("choice substitution admitted", err)
			}
			accept := command
			accept.Player = first.PlayerID
			lost.Timed.Runner.DB = &faultDB{Beginner: database, n: 2, commit: true}
			room, err := lost.AcceptFriendFight(ctx, second, accept, op())
			if err != nil {
				t.Fatal("accept", err)
			}
			duplicate, err := service.AcceptFriendFight(ctx, second, accept, op())
			if err != nil || duplicate.Identifier != room.Identifier || room.Selection.TeamCount() != map[int]int{1: 1, 2: 3}[mode] {
				t.Fatal("duplicate room", err)
			}
			if _, found, err := reader.ReadFriendNotice(ctx, invitation.Identifier.String()); err != nil || found {
				t.Fatal("accepted invitation still notified", err)
			}
			if err := service.RejectFriendFight(ctx, second, first.PlayerID, op()); !errors.Is(err, d.ErrRefused) {
				t.Fatal("reject consumed acceptance", err)
			}
			if _, err := service.ReadyTournament(ctx, first, room.Identifier, op()); err != nil {
				t.Fatal("55-level ready", err)
			}
			clock.at = room.StartsAt
			if _, err := service.ReconcileTournamentSelection(ctx, room.Identifier, op()); err != nil {
				t.Fatal(err)
			}
			selected, err := service.SelectTournament(ctx, first, app.TournamentSelectionCommand{Room: room.Identifier, Team: 1, Turn: 0, Formation: d.SelectedFormation{Heroes: firstHeroes[:1]}}, op())
			if err != nil || selected.Selection.Turn != 1 {
				t.Fatal("55-level selector", err)
			}
			clock.at = room.StartsAt.Add(20 * time.Minute)
			room, err = service.ReconcileTournamentSelection(ctx, room.Identifier, op())
			if err != nil || !room.Selection.Complete() {
				t.Fatal("offline selector", err)
			}
			beforeMail := scalar(t, database, `SELECT count(*) FROM mail_records WHERE recipient_player_id IN($1,$2)`, int64(first.PlayerID), int64(second.PlayerID))
			beforeScores := scalar(t, database, `SELECT count(*) FROM arena_casual_scores WHERE player_id IN($1,$2)`, int64(first.PlayerID), int64(second.PlayerID))
			lost.Timed.Runner.DB = &faultDB{Beginner: database, n: 2, commit: true}
			started, err := lost.StartTournamentCombat(ctx, room.Identifier, op())
			if err != nil {
				t.Fatal("freeze engine31", err)
			}
			snapshot, err := service.Combat.SnapshotTx(ctx, database, started.Attempts[0])
			if err != nil || snapshot.Battle.CampaignType != 31 {
				t.Fatal("campaign source type", err)
			}
			if (mode == 1 && snapshot.Battle.Context != nil) || (mode == 2 && (snapshot.Battle.Context == nil || snapshot.Battle.Context.Transform != "REGION_ARENA_PLAYOFFS_AWAKE_V1")) {
				t.Fatal("mode transform", snapshot.Battle.Context)
			}
			lost.Timed.Runner.DB = &faultDB{Beginner: database, n: 2, commit: true}
			settled, err := lost.ResolveTournamentCombat(ctx, room.Identifier, op())
			if err != nil || settled.Status != d.RoomSettled || settled.GenuineBattles < 1 || settled.Winner == 0 {
				t.Fatal("real terminal", settled, err)
			}
			duplicate, err = service.ResolveTournamentCombat(ctx, room.Identifier, op())
			if err != nil || duplicate.StateVersion != settled.StateVersion {
				t.Fatal("duplicate terminal", err)
			}
			report, err := service.TournamentReport(ctx, first, room.Identifier, 1, 0, op())
			if err != nil || len(report.Report) == 0 || len(report.Heroes[0]) < 5 {
				t.Fatal("frozen replay", err)
			}
			stranger := bornActor(t, database)
			exec(t, database, `UPDATE account_sessions SET absolute_expires_at=$2,idle_timeout_seconds=NULL WHERE session_id=$1`, stranger.SessionID.UUID().String(), clock.at.Add(24*time.Hour))
			if _, err := service.TournamentReport(ctx, stranger, room.Identifier, 1, 0, op()); !errors.Is(err, d.ErrRefused) {
				t.Fatal("private replay exposed", err)
			}
			retainedAt := clock.at
			clock.at = settled.SettledAt.Add(8 * 24 * time.Hour)
			exec(t, database, `UPDATE account_sessions SET absolute_expires_at=$2 WHERE session_id=$1`, first.SessionID.UUID().String(), clock.at.Add(24*time.Hour))
			if _, err := service.TournamentReport(ctx, first, room.Identifier, 1, 0, op()); !errors.Is(err, d.ErrRefused) {
				t.Fatal("expired report exposed", err)
			}
			durable, found, err := (arenastore.Store{}).ReadTournamentRoomTx(ctx, database, room.Identifier, false)
			if err != nil || !found || durable.Status != d.RoomSettled {
				t.Fatal("expiry removed durable result", err)
			}
			clock.at = retainedAt
			if facts.of(first.PlayerID) != 0 || facts.of(second.PlayerID) != 0 {
				t.Fatal("practice emitted PK objective")
			}
			if scalar(t, database, `SELECT count(*) FROM mail_records WHERE recipient_player_id IN($1,$2)`, int64(first.PlayerID), int64(second.PlayerID)) != beforeMail || scalar(t, database, `SELECT count(*) FROM arena_casual_scores WHERE player_id IN($1,$2)`, int64(first.PlayerID), int64(second.PlayerID)) != beforeScores {
				t.Fatal("friendly fight granted ladder or Mail value")
			}
		})
	}
	t.Run("expiry-reject-and-race", func(t *testing.T) {
		command.Mode, command.GameType = 1, 1
		invitation, err := service.InviteFriendFight(ctx, first, command, op())
		if err != nil {
			t.Fatal(err)
		}
		clock.at = invitation.ExpiresAt
		if _, err := service.ExpireFriendInvitations(ctx, op(), 10); err != nil {
			t.Fatal(err)
		}
		if _, err := service.AcceptFriendFight(ctx, second, app.FriendFightCommand{Player: first.PlayerID, Mode: 1, GameType: 1}, op()); !errors.Is(err, d.ErrRefused) {
			t.Fatal("expired accepted", err)
		}
		if notice, found, err := reader.ReadFriendNotice(ctx, invitation.Identifier.String()); err != nil || !found || notice.Type != 15 || notice.Recipient != first.PlayerID {
			t.Fatal("expiry notice", err)
		}
		current, err := service.InviteFriendFight(ctx, first, command, op())
		if err != nil {
			t.Fatal(err)
		}
		if _, found, err := reader.ReadFriendNotice(ctx, invitation.Identifier.String()); err != nil || found {
			t.Fatal("stale notice generation", err)
		}
		var workers sync.WaitGroup
		outcomes := make(chan error, 2)
		workers.Add(2)
		go func() {
			defer workers.Done()
			_, err := service.AcceptFriendFight(ctx, second, app.FriendFightCommand{Player: first.PlayerID, Mode: 1, GameType: 1}, op())
			outcomes <- err
		}()
		go func() { defer workers.Done(); outcomes <- service.RejectFriendFight(ctx, second, first.PlayerID, op()) }()
		workers.Wait()
		close(outcomes)
		successes := 0
		for err := range outcomes {
			if err == nil {
				successes++
			} else if !errors.Is(err, d.ErrRefused) {
				t.Fatal(err)
			}
		}
		if successes != 1 {
			t.Fatal("accept/reject did not serialize", successes)
		}
		stored, found, err := (arenastore.Store{}).ReadFriendInvitationTx(ctx, database, current.Identifier, false)
		if err != nil || !found || (stored.Status != d.FriendInvitationAccepted && stored.Status != d.FriendInvitationRejected) {
			t.Fatal("invalid race state", err)
		}
	})
}
