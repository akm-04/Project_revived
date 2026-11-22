//go:build postgres

package playerdisplay_test

import (
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	app "gxb.local/backend/v2/internal/application/arena"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	arenawire "gxb.local/backend/v2/internal/projection/arena"
)

// arenaRosterRegionArenaTimes reads girl tableID from the production MID49
// roster projection (librarySvc.Roster carries this same HeroBootstrapProjection).
func arenaRosterRegionArenaTimes(t *testing.T, p *pg.Pool, s app.Service, actor identity.ActorContext, tableID int64) int64 {
	t.Helper()
	projection := characterstore.HeroBootstrapProjection{Content: contentstore.Store{Queryer: p}, SeasonPicks: s}
	transaction, err := p.Begin(ctx, tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	detail := map[string]any{}
	if err := projection.OverlayMID1(ctx, transaction, actor, false, time.Now().UTC(), detail); err != nil {
		t.Fatal(err)
	}
	body, _ := detail["49"].(map[string]any)
	rows, _ := body["heros"].(map[string]any)
	for _, raw := range rows {
		row, ok := raw.(map[string]any)
		if !ok || row["table_id"] != tableID {
			continue
		}
		times, ok := row["region_arena_times"].(int64)
		if !ok {
			t.Fatalf("roster row %d has no region_arena_times: %#v", tableID, row["region_arena_times"])
		}
		return times
	}
	t.Fatalf("roster row for %d missing", tableID)
	return 0
}

func TestI9_11ArenaHeroPicksNative(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	s := arenaService(t, pool)
	server := rankingServer(t, pool)
	a, _ := oneOnOnePlayer(t, pool, server)
	b, _ := oneOnOnePlayer(t, pool, server)
	catalog := arenaCatalog(t, pool)
	season := catalog.SeasonAt(time.Now())
	if _, err := s.Info(ctx, a, op()); err != nil {
		t.Fatal(err)
	}
	if _, err := s.Info(ctx, b, op()); err != nil {
		t.Fatal(err)
	}
	if _, err := s.ModifyDefence(ctx, b, arenaGirls(5), 0, op()); err != nil {
		t.Fatal(err)
	}
	exec(t, pool, `UPDATE arena_players SET defense=jsonb_build_object('heroes','[]'::jsonb,'pet',0) WHERE player_id<>$1`, int64(b.PlayerID))

	// Give owned girl X=10001001 an award row through one star exchange.
	exec(t, pool, `INSERT INTO player_currency_balances(player_id,resource_key,amount,updated_at)VALUES($1,'king_coin',5000,now()) ON CONFLICT(player_id,resource_key) DO UPDATE SET amount=5000`, int64(a.PlayerID))
	if _, err := s.Exchange(ctx, a, d.ExchangeStar, 10001001, op()); err != nil {
		t.Fatal(err)
	}

	ranked := func(formation []int64) {
		if _, err := s.Match(ctx, a, false, op()); err != nil {
			t.Fatal(err)
		}
		if err := s.Start(ctx, a, op()); err != nil {
			t.Fatal(err)
		}
		if _, err := fightSettled(s, a, app.FightCommand{Enemy: b.PlayerID, Formation: formation}); err != nil {
			t.Fatal(err)
		}
	}
	// Two non-forfeit ranked attacks; the second formation differs so the FIGHT
	// fingerprint does not replay the first settlement.
	ranked([]int64{10001001, 10001002, 10001003, 10001004, 10001005})
	ranked([]int64{10001005, 10001004, 10001003, 10001002, 10001001})

	// A forfeit (STOP without a battle) and a practice fight are not ranked fights.
	if _, err := s.Match(ctx, a, false, op()); err != nil {
		t.Fatal(err)
	}
	if err := s.Start(ctx, a, op()); err != nil {
		t.Fatal(err)
	}
	if _, err := s.Stop(ctx, a, b.PlayerID, op()); err != nil {
		t.Fatal(err)
	}
	if _, err := s.Match(ctx, a, true, op()); err != nil {
		t.Fatal(err)
	}
	if err := s.Start(ctx, a, op()); err != nil {
		t.Fatal(err)
	}
	if _, err := fightSettled(s, a, app.FightCommand{Enemy: b.PlayerID, Practice: true, Formation: arenaGirls(5)}); err != nil {
		t.Fatal(err)
	}

	if got := scalar(t, pool, `SELECT fights FROM arena_partner_usage WHERE player_id=$1 AND table_id=10001001`, int64(a.PlayerID)); got != 2 {
		t.Fatalf("usage fights = %d, want 2", got)
	}
	if got := arenaRosterRegionArenaTimes(t, pool, s, a, 10001001); got != 2 {
		t.Fatalf("roster region_arena_times = %d, want 2", got)
	}
	info, err := s.Info(ctx, a, op())
	if err != nil {
		t.Fatal(err)
	}
	awardFound := false
	for _, row := range arenawire.Info(info)["awards"].([]map[string]any) {
		if row["table_id"] != int64(10001001) {
			continue
		}
		awardFound = true
		if row["region_arena_times"] != int64(0) {
			t.Fatalf("award region_arena_times = %#v, want 0", row["region_arena_times"])
		}
	}
	if !awardFound {
		t.Fatal("girl award row missing")
	}
	partners, err := s.Partners(ctx, a, a.PlayerID, op())
	if err != nil {
		t.Fatal(err)
	}
	partnerFound := false
	for _, usage := range partners.Usage {
		if usage.TableID != 10001001 {
			continue
		}
		partnerFound = true
		if usage.Fights != 2 {
			t.Fatalf("partner total_fight = %d, want 2", usage.Fights)
		}
	}
	if !partnerFound {
		t.Fatal("partner_info row missing")
	}

	// After the season rolls the previous season's usage no longer counts.
	exec(t, pool, `UPDATE arena_partner_usage SET season=$1 WHERE player_id=$2`, season.Number-1, int64(a.PlayerID))
	exec(t, pool, `UPDATE arena_players SET season=$1 WHERE player_id=$2`, season.Number-1, int64(a.PlayerID))
	if got := arenaRosterRegionArenaTimes(t, pool, s, a, 10001001); got != 0 {
		t.Fatalf("roster region_arena_times after roll = %d, want 0", got)
	}
}
