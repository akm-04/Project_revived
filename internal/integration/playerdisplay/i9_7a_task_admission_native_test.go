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
)

func TestI97ATaskModeAdmissionReadsNative(t *testing.T) {
	database := pool(t)
	service := topFloorService(t, database)
	server := rankingServer(t, database)
	actor, _, hero := topFloorPlayer(t, database, server)
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
	eligibility, err := service.TaskModeEligibilityTx(ctx, database, catalog, actor, now)
	if err != nil || eligibility.WeeklyChallenges != 1 || eligibility.ServerMaximumLevel != 60 || eligibility.Eligible {
		t.Fatalf("source gate read %+v %v", eligibility, err)
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
