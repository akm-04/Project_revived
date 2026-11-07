//go:build postgres

package playerdisplay_test

import (
	"strconv"
	"testing"
	"time"
)

// TestI9_10RosterProjectsCumulativeEXPFloorNative proves MID49 does not print
// negative progress for a freshly granted Hero or a legacy row below its level
// floor. The stock window prints exp - partnerExp:totalExp(lev-1).
func TestI9_10RosterProjectsCumulativeEXPFloorNative(t *testing.T) {
	p := pool(t)
	defer p.Close()
	rev := installed(t, p)
	a := actor(t, p)
	hero := skillHero(t, p, a, rev, 10001001, 1)
	libraryHero(t, p, a, hero, false, true)
	s := libraryService(p, p)
	at := time.Now().UTC()

	row := func() map[string]any {
		t.Helper()
		detail := map[string]any{}
		if err := s.Roster.OverlayMID1(ctx, p, a, false, at, detail); err != nil {
			t.Fatal(err)
		}
		body, _ := detail["49"].(map[string]any)
		rows, _ := body["heros"].(map[string]any)
		wire, _ := rows[formatInt(hero.PartnerID)].(map[string]any)
		if wire == nil {
			t.Fatalf("roster row %d missing", hero.PartnerID)
		}
		return wire
	}

	if wire := row(); wire["lev"] != int64(1) || wire["exp"] != int64(0) {
		t.Fatalf("newly granted hero lev=%v exp=%v", wire["lev"], wire["exp"])
	}
	exec(t, p, `UPDATE player_heroes SET level=100, exp=0 WHERE player_id=$1 AND partner_id=$2`, int64(a.PlayerID), hero.PartnerID)
	floor := scalar(t, p, `SELECT total_exp FROM gxb_content_hero_exp WHERE revision_id=$1 AND level=99`, rev)
	wire := row()
	if wire["lev"] != int64(100) || wire["exp"] != floor {
		t.Fatalf("legacy levelled hero lev=%v exp=%v want floor %d", wire["lev"], wire["exp"], floor)
	}
	if wire["exp"].(int64)-floor < 0 {
		t.Fatal("stock progress would be negative")
	}
}

func formatInt(value int64) string {
	return strconv.FormatInt(value, 10)
}
