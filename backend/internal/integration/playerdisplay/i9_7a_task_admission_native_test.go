//go:build postgres

package playerdisplay_test

import (
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/topfloorstore"
	application "gxb.local/backend/v2/internal/application/topfloor"
	"gxb.local/backend/v2/internal/domain/modes"
	domain "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestI97ATaskModeAdmissionReadsNative(t *testing.T) {
	database := pool(t)
	service := topFloorService(t, database)
	server := rankingServer(t, database)
	actor, revision, hero := topFloorPlayer(t, database, server)
	otherServer := rankingServer(t, database)
	other, _, _ := topFloorPlayer(t, database, otherServer)
	exec(t, database, `UPDATE player_directory_profiles SET lev=60 WHERE player_id=$1`, int64(actor.PlayerID))
	exec(t, database, `UPDATE player_directory_profiles SET lev=99 WHERE player_id=$1`, int64(other.PlayerID))
	maximum, err := (i4store.PlayerDirectoryReader{}).ServerMaximumLevelTx(ctx, database, server)
	if err != nil || maximum != 60 {
		t.Fatalf("cross-server maximum leaked: %d %v", maximum, err)
	}
	current, err := service.Load(ctx, actor, op())
	if err != nil {
		t.Fatal(err)
	}
	normal := domain.Catalog{CutoffSeconds: 75600, FreezeEndSeconds: 77400}
	if normal.Frozen(time.Now()) {
		t.Skip("normal Top Floor freeze: no host clock change permitted")
	}
	command := application.StartCommand{Formation: []int64{hero.PartnerID}, Enemy: current.Enemies[0].Occupant.TableID()}
	if err = service.SaveDefense(ctx, actor, []int64{hero.PartnerID}, 0, op()); err != nil {
		t.Fatal("saved defense", err)
	}
	result, err := service.Start(ctx, actor, command, op())
	if err != nil || len(result.Report) == 0 {
		t.Fatalf("genuine admission: %v", err)
	}
	if _, err = service.Start(ctx, actor, command, op()); err != nil {
		t.Fatal(err)
	}
	store := topfloorstore.Store{}
	now := time.Now()
	count, err := store.WeeklyChallengesTx(ctx, database, actor.PlayerID, now)
	if err != nil || count != 1 {
		t.Fatalf("retry counted again: %d %v", count, err)
	}
	exec(t, database, `DELETE FROM top_floor_records WHERE owner_player_id=$1`, int64(actor.PlayerID))
	count, err = store.WeeklyChallengesTx(ctx, database, actor.PlayerID, now)
	if err != nil || count != 1 {
		t.Fatalf("display trimming lost admission: %d %v", count, err)
	}
	catalog := domain.TaskModeCatalog{EntryRank: 200, EntryChallenges: 10, ServerLevel: 60}
	period := domain.TaskModePeriod{
		Rotation: domain.TaskModeRotation{Number: 1, Mode: domain.TaskModeSingle, StartsAt: now, EndsAt: now.Add(7 * 24 * time.Hour)},
		Ladder:   domain.Ladder{Server: server, ContentRevision: revision, SettledDay: 0, StateVersion: 1, CreatedAt: now, UpdatedAt: now},
	}
	eligibility, err := service.TaskModeEligibilityTx(ctx, database, catalog, period, actor, now)
	if err != nil || eligibility.WeeklyChallenges != 1 || eligibility.ServerMaximumLevel != 60 || eligibility.Eligible {
		t.Fatalf("unranked above 200 source gate read %+v %v", eligibility, err)
	}
	// D512: weekly challenges are no longer enforced; rank <=200 and server level
	// >=60 qualify even with a single challenge this week.
	robotAtEntryRank := domain.Occupant{Robot: domain.RobotTeams + 1 - 200}
	transaction, err := database.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	if err = store.SwapTx(ctx, transaction, server, domain.Ranked{Rank: current.Rank, Occupant: domain.Occupant{Player: actor.PlayerID}}, domain.Ranked{Rank: 200, Occupant: robotAtEntryRank}); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	eligibility, err = service.TaskModeEligibilityTx(ctx, database, catalog, period, actor, now)
	if err != nil || !eligibility.Eligible || eligibility.Rank != 200 {
		t.Fatalf("D512 challenge gate still enforced: %+v %v", eligibility, err)
	}
	// A player admitted to the period stays eligible after their normal rank drops.
	transaction, err = database.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	if err = store.CreateTaskPeriodTx(ctx, transaction, period); err != nil {
		t.Fatal(err)
	}
	admitted := domain.TaskModePlayer{PeriodNumber: period.Rotation.Number, Player: (domain.Catalog{FreeTickets: 5}).NewPlayer(actor.PlayerID, server, revision, 1, now)}
	if err = store.InsertTaskPlayerTx(ctx, transaction, admitted, period); err != nil {
		t.Fatal(err)
	}
	if err = store.SwapTx(ctx, transaction, server, domain.Ranked{Rank: 200, Occupant: domain.Occupant{Player: actor.PlayerID}}, domain.Ranked{Rank: current.Rank, Occupant: robotAtEntryRank}); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	eligibility, err = service.TaskModeEligibilityTx(ctx, database, catalog, period, actor, now)
	if err != nil || !eligibility.Eligible || eligibility.Rank <= 200 {
		t.Fatalf("admitted player lost eligibility after a rank drop: %+v %v", eligibility, err)
	}
	boundary := modes.DayBegins(modes.WeekStart(now))
	exec(t, database, `UPDATE top_floor_fights SET started_at=$2 WHERE challenger_id=$1`, int64(actor.PlayerID), boundary)
	for _, check := range []struct {
		at   time.Time
		want int64
	}{{boundary, 1}, {boundary.Add(-time.Nanosecond), 0}, {boundary.Add(7 * 24 * time.Hour), 0}} {
		count, err = store.WeeklyChallengesTx(ctx, database, actor.PlayerID, check.at)
		if err != nil || count != check.want {
			t.Fatalf("week half-open at %s: %d want %d %v", check.at, count, check.want, err)
		}
	}
}
