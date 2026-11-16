//go:build postgres

package playerdisplay_test

import (
	"testing"

	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/worldboss"
)

// DL-0e411008: every 276 boss_rank infos row carries the player's current
// guild name (the client opens world_boss_rank_info with it) and "" when the
// player has no guild.
func TestClosureB2WorldBossRankCarriesGuildNameNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	clock := worldBossTime(t)
	member, _ := worldBossActor(t, p, server)
	guildless, _ := worldBossActor(t, p, server)
	guildID := guildFixture(t, p, member)
	var guildName string
	if err := p.QueryRow(ctx, `SELECT name FROM guilds WHERE guild_id=$1`, int64(guildID)).Scan(&guildName); err != nil {
		t.Fatal(err)
	}

	for player, hurt := range map[identity.PlayerID]int64{member.PlayerID: 700, guildless.PlayerID: 500} {
		exec(t, p, `INSERT INTO worldboss_player_totals(logical_server_id,generation,boss_id,player_id,hurt,first_hurt_at,updated_at)VALUES($1,1,$2,$3,$4,0,clock_timestamp())`,
			int64(server), d.FirstBossID, int64(player), hurt)
	}

	s := worldBossService(t, p, clock)
	boards, err := s.BossRank(ctx, member, op())
	if err != nil || len(boards) != 5 {
		t.Fatalf("boards %d %v", len(boards), err)
	}
	infos, ok := boards[0]["infos"].([]map[string]any)
	if !ok || len(infos) != 2 {
		t.Fatalf("infos %#v", boards[0]["infos"])
	}
	rows := make(map[int64]map[string]any, len(infos))
	for _, row := range infos {
		rows[row["player_id"].(int64)] = row
	}
	if got := rows[int64(member.PlayerID)]["guild_name"]; got != guildName {
		t.Fatalf("member guild_name %#v want %q", got, guildName)
	}
	if got, present := rows[int64(guildless.PlayerID)]["guild_name"]; !present || got != "" {
		t.Fatalf("guildless guild_name %#v present=%v want \"\"", got, present)
	}
}
