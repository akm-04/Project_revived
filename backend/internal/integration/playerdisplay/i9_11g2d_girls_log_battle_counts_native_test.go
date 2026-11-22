//go:build postgres

package playerdisplay_test

import (
	"testing"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/domain/identity"
)

// battleCountRows is one player's durable Girls Log battle counts by partner id.
func battleCountRows(t *testing.T, p *pg.Pool, player identity.PlayerID) map[int64]int64 {
	t.Helper()
	rows, err := p.Raw().Query(ctx, `SELECT partner_id,count FROM library_hero_battle_counts WHERE player_id=$1`, int64(player))
	if err != nil {
		t.Fatal(err)
	}
	defer rows.Close()
	out := map[int64]int64{}
	for rows.Next() {
		var partnerID, count int64
		if err = rows.Scan(&partnerID, &count); err != nil {
			t.Fatal(err)
		}
		out[partnerID] = count
	}
	if err = rows.Err(); err != nil {
		t.Fatal(err)
	}
	return out
}

func battleCountSum(t *testing.T, p *pg.Pool, player identity.PlayerID) int64 {
	t.Helper()
	total := int64(0)
	for _, count := range battleCountRows(t, p, player) {
		total += count
	}
	return total
}
