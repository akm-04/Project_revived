//go:build postgres

package playerdisplay_test

import (
	"net/http"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

func gcvJoinMember(t *testing.T, p *pg.Pool, guildID int64, player identity.PlayerID, joinedAt time.Time) {
	t.Helper()
	exec(t, p, `INSERT INTO guild_memberships(player_id,guild_id,role,joined_at,membership_version,state_version,updated_at)VALUES($1,$2,0,$3,1,1,$3)`,
		int64(player), guildID, joinedAt)
}

func gcvListed(t *testing.T, response httpedge.Response, shopType int64) bool {
	t.Helper()
	if response.HTTPStatus != http.StatusOK {
		t.Fatalf("MID 37: %d %+v", response.HTTPStatus, response.Body)
	}
	served, _ := response.Body["list"].([]int64)
	for _, value := range served {
		if value == shopType {
			return true
		}
	}
	return false
}

// TestI911CTeamShopJoinGateNative proves 11C C3/C12 with the guild campaign at
// chapter_version 2: the chapter 7 team shop is served, and membership joined
// at or after the run start is refused on listing and on every direct request.
func TestI911CTeamShopJoinGateNative(t *testing.T) {
	f := newCampaignFixture(t)
	f.seedActivity(t, 40)
	if _, err := f.mode.Open(ctx, f.leader, 7, f.op()); err != nil {
		t.Fatal("open", err)
	}
	f.mode.Settings.ChapterVersions = map[int64]int64{7: 2}
	revision := installed(t, f.pool)
	i911cOpenFunctions(t, f.pool, f.leader, revision)
	i911cScalar(t, f.pool, f.leader, "team_dungeon_coin", 1_000_000)
	exec(t, f.pool, `UPDATE player_progression SET level=100 WHERE player_id=$1`, int64(f.leader.PlayerID))

	composition := i911cTeamComposition(f.pool, f.leader, pg.AuthoritativeTime{Queryer: f.pool}, f.mode)
	dispatcher := composition.Dispatcher
	if !gcvListed(t, i911cDispatch(t, dispatcher, f.leader, 37, map[string]any{}), 15) {
		t.Fatal("chapter 7 team shop 15 not listed for a member joined before the run")
	}
	load := i911cDispatch(t, dispatcher, f.leader, 32, map[string]any{"shop_type": int64(15)})
	if load.HTTPStatus != http.StatusOK {
		t.Fatalf("MID 32 team shop: %d %+v", load.HTTPStatus, load.Body)
	}
	items := i911cItems(t, load)
	target := items[0]
	index := target["index"].(int64)
	price := target["sell_price"].(int64)
	before := i911cScalarAmount(t, f.pool, f.leader, "team_dungeon_coin")
	buy := i911cDispatch(t, dispatcher, f.leader, 33, map[string]any{"shop_type": int64(15), "index": index})
	if buy.HTTPStatus != http.StatusOK || buy.Body["isbuy"] != int64(1) {
		t.Fatalf("MID 33 team shop: %d %+v", buy.HTTPStatus, buy.Body)
	}
	if after := i911cScalarAmount(t, f.pool, f.leader, "team_dungeon_coin"); after != before-price {
		t.Fatalf("team_dungeon_coin %d -> %d, price %d", before, after, price)
	}

	for _, joinedAt := range []time.Time{f.at.Add(time.Hour), f.at} {
		late, _ := genuinePlayer(t, f.pool, f.server)
		gcvJoinMember(t, f.pool, int64(f.guild), late.PlayerID, joinedAt)
		lateComposition := i911cTeamComposition(f.pool, late, pg.AuthoritativeTime{Queryer: f.pool}, f.mode)
		if gcvListed(t, i911cDispatch(t, lateComposition.Dispatcher, late, 37, map[string]any{}), 15) {
			t.Fatalf("team shop 15 listed for a member joined at %v", joinedAt)
		}
		direct := i911cDispatch(t, lateComposition.Dispatcher, late, 32, map[string]any{"shop_type": int64(15)})
		if direct.HTTPStatus != http.StatusConflict || direct.Body["error_code"] != int64(35028) {
			t.Fatalf("MID 32 for a member joined at %v: %d %+v", joinedAt, direct.HTTPStatus, direct.Body)
		}
		for mid, params := range map[uint16]map[string]any{
			33:   {"shop_type": int64(15), "index": int64(1)},
			34:   {"shop_type": int64(15)},
			2982: {"shop_type": int64(15), "list": []any{int64(1)}},
		} {
			refused := i911cDispatch(t, lateComposition.Dispatcher, late, mid, params)
			if refused.HTTPStatus != http.StatusConflict || refused.Body["error_code"] != int64(35028) {
				t.Fatalf("MID %d for a member joined at %v: %d %+v", mid, joinedAt, refused.HTTPStatus, refused.Body)
			}
		}
	}
}
