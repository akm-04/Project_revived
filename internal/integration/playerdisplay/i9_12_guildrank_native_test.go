//go:build postgres

package playerdisplay_test

import (
	"context"
	"testing"

	guildwire "gxb.local/backend/v2/internal/adapters/guildwire"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/application/guildview"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
)

// TestI9_12GuildRankMID2565 pins the 2565 guild_rank to the activity board:
// daily-capped three-day points, ties by lower guild_id, zero activity ranked
// last, and no rank for a guild the board does not carry.
func TestI9_12GuildRankMID2565(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	server := nativeServer(t, pool)
	a, b, c := rankingActor(t, pool, server, true), rankingActor(t, pool, server, true), rankingActor(t, pool, server, true)
	first := guildFixture(t, pool, a, b)
	second := guildFixture(t, pool, c)

	now, err := (pg.AuthoritativeTime{Queryer: pool}).Now(ctx)
	if err != nil {
		t.Fatal(err)
	}
	day := modes.Day(now)
	// first reaches 1500 raw, capped to 1000; second reaches exactly 1000, so
	// the two tie and the lower guild_id ranks first.
	appendActivity(t, pool, a, day, 1500)
	appendActivity(t, pool, c, day, 1000)

	store := guildstore.Store{Queryer: pool}
	view := guildview.Service{Store: store, Directory: i4store.PlayerDirectoryReader{Queryer: pool}, Day: func(context.Context) (int64, error) { return day, nil }}
	cases := []struct {
		name   string
		leader identity.ActorContext
		rank   int64
	}{
		{"capped and tied first by lower guild id", a, 1},
		{"tied second by higher guild id", c, 2},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			info, ok, err := view.GuildForPlayer(ctx, tc.leader, tc.leader.PlayerID)
			if err != nil || !ok {
				t.Fatalf("ok=%v err=%v", ok, err)
			}
			if info.GuildRank != tc.rank {
				t.Fatalf("guild_rank=%d want %d", info.GuildRank, tc.rank)
			}
			if info.ThreeHuoyue != 1000 {
				t.Fatalf("three_huoyue=%d want the daily-capped 1000", info.ThreeHuoyue)
			}
			wireInfo, ok := guildwire.Detail2565(info)["guild_info"].(map[string]any)
			if !ok || wireInfo["guild_rank"] != tc.rank {
				t.Fatalf("2565 wire guild_info=%+v", guildwire.Detail2565(info))
			}
		})
	}

	zeroLeader := rankingActor(t, pool, server, true)
	guildFixture(t, pool, zeroLeader)
	info, ok, err := view.GuildForPlayer(ctx, zeroLeader, zeroLeader.PlayerID)
	if err != nil || !ok {
		t.Fatalf("zero guild ok=%v err=%v", ok, err)
	}
	if info.GuildRank != 3 || info.ThreeHuoyue != 0 {
		t.Fatalf("zero-activity guild rank=%d three_huoyue=%d want 3 and 0", info.GuildRank, info.ThreeHuoyue)
	}

	foreignServer := nativeServer(t, pool)
	foreignLeader, _ := playerRoot(t, pool, foreignServer)
	foreign := guildFixture(t, pool, foreignLeader)
	if rank, err := store.ActivityRankOf(ctx, server, day, foreign); err != nil || rank != 0 {
		t.Fatalf("guild absent from the board rank=%d err=%v want 0", rank, err)
	}
	if first == second || first == foreign {
		t.Fatalf("fixture guild ids not distinct: first=%d second=%d foreign=%d", first, second, foreign)
	}
}
