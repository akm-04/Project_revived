//go:build postgres

package playerdisplay_test

import (
	"fmt"
	"reflect"
	"testing"

	"gxb.local/backend/v2/internal/adapters/postgres/petcampaignstore"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/petcampaign"
	rankingdomain "gxb.local/backend/v2/internal/domain/ranking"
	projection "gxb.local/backend/v2/internal/projection/ranking"
)

func TestI9_10DStarAndAwakenBoardsAreServerScoped(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	server := rankingServer(t, p)
	other := rankingServer(t, p)
	a := rankingActor(t, p, server, true)
	b := rankingActor(t, p, server, true)
	c := rankingActor(t, p, other, true)
	rankingSummon(t, p, a, rev, 10001001)
	rankingSummon(t, p, b, rev, 10001001)
	exec(t, p, `UPDATE player_heroes SET star=6,table_id=11001001 WHERE player_id=$1 AND partner_id=1`, int64(a.PlayerID))
	exec(t, p, `UPDATE player_heroes SET star=4 WHERE player_id=$1 AND partner_id=1`, int64(b.PlayerID))
	s := rankingService(p, p)

	stars, e := s.ReadBoard(ctx, rankingdomain.StarCountBoard, a, op())
	if e != nil {
		t.Fatal(e)
	}
	if len(stars.Entries) != 2 || !reflect.DeepEqual([]identity.PlayerID{stars.Entries[0].Metric.Player, stars.Entries[1].Metric.Player}, []identity.PlayerID{a.PlayerID, b.PlayerID}) || stars.Entries[0].Metric.Value != 6 || stars.Entries[1].Metric.Value != 4 {
		t.Fatal(stars.Entries)
	}
	starWire, e := projection.BoardList(stars, a.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	starInfo := starWire["rank_list"].([]map[string]any)[0]["rank_info"].(map[string]any)
	starMine := starInfo["my_rank"].(map[string]any)
	if starMine["rank"] != int64(1) || starMine["score"] != int64(6) {
		t.Fatal(starMine)
	}

	awakened, e := s.ReadBoard(ctx, rankingdomain.AwakenCountBoard, a, op())
	if e != nil {
		t.Fatal(e)
	}
	if len(awakened.Entries) != 2 || awakened.Entries[0].Metric.Player != a.PlayerID || awakened.Entries[0].Metric.Value != 1 || awakened.Entries[1].Metric.Player != b.PlayerID || awakened.Entries[1].Metric.Value != 0 {
		t.Fatal(awakened.Entries)
	}

	otherStars, e := s.ReadBoard(ctx, rankingdomain.StarCountBoard, c, op())
	if e != nil {
		t.Fatal(e)
	}
	if len(otherStars.Entries) != 1 || otherStars.Entries[0].Metric.Player != c.PlayerID || otherStars.Entries[0].Metric.Value != 0 || otherStars.Server != other {
		t.Fatal(otherStars)
	}
}

func TestI9_10DEliteRankOwnerOrdersAndIsolatesServers(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	other := rankingServer(t, p)
	a := rankingActor(t, p, server, true)
	b := rankingActor(t, p, server, true)
	c := rankingActor(t, p, other, true)
	seedElite := func(actor identity.ActorContext, eliteMax, attained int64) {
		payload := fmt.Sprintf(`{"Server":%d,"Player":%d,"EliteMax":%d,"Max":100,"Attained":%d}`, int64(actor.LogicalServerID), int64(actor.PlayerID), eliteMax, attained)
		exec(t, p, `INSERT INTO petcampaign_players(player_id,payload,updated_at)VALUES($1,$2::jsonb,clock_timestamp())`, int64(actor.PlayerID), payload)
	}
	seedElite(a, 7, 10)
	seedElite(b, 4, 20)
	seedElite(c, 9, 1)
	store := petcampaignstore.Store{}
	rows, my, e := store.EliteRanksTx(ctx, p, server, d.State{Player: int64(a.PlayerID), EliteMax: 7, Attained: 10})
	if e != nil {
		t.Fatal(e)
	}
	if len(rows) != 2 || rows[0].Player != a.PlayerID || rows[0].Floor != 7 || rows[1].Player != b.PlayerID || rows[1].Floor != 4 || my != 1 {
		t.Fatal(rows, my)
	}
}
