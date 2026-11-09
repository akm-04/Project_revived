//go:build postgres

package playerdisplay_test

import (
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	app "gxb.local/backend/v2/internal/application/march"
	"gxb.local/backend/v2/internal/domain/identity"
)

func marchPopulatedActor(t *testing.T, p *pg.Pool, rev string, server identity.LogicalServerID, level, heroes int) identity.ActorContext {
	t.Helper()
	a := marchActorOnServer(t, p, server)
	for i := 1; i <= heroes; i++ {
		bornHero(t, p, a, rev, int64(10001000+i), int64(i))
		marchSetHeroLevel(t, p, a, int64(i), int64(level))
	}
	compositeLevel(t, p, a, rev, level)
	exec(t, p, `UPDATE player_directory_profiles SET lev=$2 WHERE player_id=$1`, int64(a.PlayerID), level)
	return a
}

// TestI9_10MarchNativeLatencyBudget profiles the four hot Champion requests on
// a populated server: 20 full six-girl rosters on the ladder plus the requester.
// The budget is server-side wall time through the production Mode.
func TestI9_10MarchNativeLatencyBudget(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	server := marchNewServer(t, p)
	ladder := topFloorService(t, p)
	requester := marchPopulatedActor(t, p, rev, server, 90, 10)
	for o := 0; o < 20; o++ {
		opponent := marchPopulatedActor(t, p, rev, server, 90, 6)
		if _, err := ladder.Load(ctx, opponent, op()); err != nil {
			t.Fatal("opponent ladder entry", err)
		}
		if err := ladder.SaveDefense(ctx, opponent, []int64{1, 2, 3, 4, 5}, 0, op()); err != nil {
			t.Fatal("opponent defense", err)
		}
	}
	s := marchMode(t, p)
	measure := func(name string, budget time.Duration, call func() error) {
		t.Helper()
		started := time.Now()
		if err := call(); err != nil {
			t.Fatalf("%s: %v", name, err)
		}
		elapsed := time.Since(started)
		t.Logf("%s %v (budget %v)", name, elapsed, budget)
		if elapsed > budget {
			t.Fatalf("%s %v exceeds budget %v", name, elapsed, budget)
		}
	}
	measure("LOAD 336", time.Second, func() error {
		body, err := s.Load(ctx, requester, op())
		if err == nil {
			if enemies, ok := body["enemies"].([]map[string]any); !ok || len(enemies) != 15 {
				t.Fatal("load did not project fifteen stages")
			}
		}
		return err
	})
	measure("RESET 337", time.Second, func() error {
		_, err := s.Reset(ctx, requester, op())
		return err
	})
	team := []int64{1, 2, 3, 4, 5}
	measure("START 340", 500*time.Millisecond, func() error {
		_, err := s.Start(ctx, requester, app.Fight{Formation: team}, op())
		return err
	})
	measure("RESULT 338", 500*time.Millisecond, func() error {
		_, err := s.Result(ctx, requester, marchReport(marchRecord(t, p, requester), int64(requester.PlayerID), team, true), op())
		return err
	})
}
