//go:build postgres

package playerdisplay_test

import (
	"testing"
	"time"

	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
)

// S17 A-174: 769 partner_info carries the subject's current star; a girl the
// subject no longer owns carries none.
func TestI9_11T34ArenaPartnerStarNative(t *testing.T) {
	database := pool(t)
	defer database.Close()
	service := arenaService(t, database)
	server := rankingServer(t, database)
	self, _ := oneOnOnePlayer(t, database, server)
	other, _ := oneOnOnePlayer(t, database, server)
	for _, actor := range []identity.ActorContext{self, other} {
		if _, err := service.Info(ctx, actor, op()); err != nil {
			t.Fatal("arena entry", err)
		}
	}
	season := arenaCatalog(t, database).SeasonAt(time.Now()).Number
	const ownedGirl, unownedGirl = int64(10001001), int64(19999999)
	for _, player := range []identity.PlayerID{self.PlayerID, other.PlayerID} {
		exec(t, database, `INSERT INTO arena_partner_usage(player_id,season,table_id,fights,wins,kill_count,harms)VALUES($1,$2,$3,1,1,0,0),($1,$2,$4,1,1,0,0)`,
			int64(player), season, ownedGirl, unownedGirl)
	}
	exec(t, database, `UPDATE player_heroes SET star=4 WHERE player_id=$1 AND table_id=$2`, int64(other.PlayerID), ownedGirl)

	selfView, err := service.Partners(ctx, self, self.PlayerID, op())
	if err != nil {
		t.Fatal("769 self read", err)
	}
	if got := partnerStar(t, selfView, ownedGirl); got != 1 {
		t.Fatalf("self star = %d, want the self hero star 1", got)
	}
	otherView, err := service.Partners(ctx, self, other.PlayerID, op())
	if err != nil {
		t.Fatal("769 subject read", err)
	}
	if got := partnerStar(t, otherView, ownedGirl); got != 4 {
		t.Fatalf("subject star = %d, want the subject hero star 4", got)
	}
	for _, view := range []d.PartnersView{selfView, otherView} {
		if star := partnerStarOrNil(view, unownedGirl); star != nil {
			t.Fatalf("unowned girl star = %d, want omitted", *star)
		}
	}
}

func partnerStar(t *testing.T, view d.PartnersView, tableID int64) int64 {
	t.Helper()
	star := partnerStarOrNil(view, tableID)
	if star == nil {
		t.Fatalf("partner row %d has no star", tableID)
	}
	return *star
}

func partnerStarOrNil(view d.PartnersView, tableID int64) *int64 {
	for _, usage := range view.Usage {
		if usage.TableID == tableID {
			return usage.Star
		}
	}
	return nil
}
