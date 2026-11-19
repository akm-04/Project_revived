//go:build postgres

package playerdisplay_test

import (
	"testing"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/domain/identity"
)

// girlsLogCount is one hero's durable G2 battle count, zero when uncounted.
func girlsLogCount(t *testing.T, p *pg.Pool, player identity.PlayerID, partner int64) int64 {
	t.Helper()
	return scalar(t, p, `SELECT COALESCE((SELECT count FROM library_hero_battle_counts WHERE player_id=$1 AND partner_id=$2),0)`, int64(player), partner)
}

// girlsLogRows is every counted partner of one player with its count.
func girlsLogRows(t *testing.T, p *pg.Pool, player identity.PlayerID) map[int64]int64 {
	t.Helper()
	rows, err := p.Raw().Query(ctx, `SELECT partner_id,count FROM library_hero_battle_counts WHERE player_id=$1`, int64(player))
	if err != nil {
		t.Fatal(err)
	}
	defer rows.Close()
	out := map[int64]int64{}
	for rows.Next() {
		var partner, count int64
		if err = rows.Scan(&partner, &count); err != nil {
			t.Fatal(err)
		}
		out[partner] = count
	}
	if err = rows.Err(); err != nil {
		t.Fatal(err)
	}
	return out
}

// girlsLogExactlyOnce fails unless the player holds exactly want partner rows,
// each counted once.
func girlsLogExactlyOnce(t *testing.T, p *pg.Pool, player identity.PlayerID, want int) {
	t.Helper()
	rows := girlsLogRows(t, p, player)
	if len(rows) != want {
		t.Fatalf("player %d counted partners %v, want %d", player, rows, want)
	}
	for partner, count := range rows {
		if count != 1 {
			t.Fatalf("player %d partner %d count %d, want 1", player, partner, count)
		}
	}
}
