//go:build postgres

package playerdisplay_test

import (
	"testing"

	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/domain/identity"
)

func TestPlaytestArenaRefreshOlderCardAndFormationsNative(t *testing.T) {
	p := pool(t)
	defer p.Close()
	s := arenaService(t, p)
	a, _ := oneOnOnePlayer(t, p, rankingServer(t, p))
	b, _ := oneOnOnePlayer(t, p, rankingServer(t, p))
	c, _ := oneOnOnePlayer(t, p, rankingServer(t, p))
	catalog := arenaCatalog(t, p)
	for _, actor := range []identity.ActorContext{a, b, c} {
		if _, err := s.Info(ctx, actor, op()); err != nil {
			t.Fatal(err)
		}
	}
	for _, defender := range []identity.ActorContext{b, c} {
		if _, err := s.ModifyDefence(ctx, defender, arenaGirls(5), 0, op()); err != nil {
			t.Fatal(err)
		}
	}

	player, found, err := s.Store.ReadPlayerTx(ctx, p, a.PlayerID, false)
	if err != nil || !found {
		t.Fatalf("arena player: found=%v err=%v", found, err)
	}
	standings, err := s.Store.StandingsTx(ctx, p, player.Season)
	if err != nil {
		t.Fatal(err)
	}
	var initialCounter int64
	var distinctOffers bool
	for counter := player.MatchCounter + 1; counter < player.MatchCounter+10000; counter++ {
		firstPlayer := player
		firstPlayer.MatchCounter = counter
		firstOffer, firstFound := catalog.Pick(firstPlayer, standings, true)
		secondPlayer := player
		secondPlayer.MatchCounter = counter + 1
		secondOffer, secondFound := catalog.Pick(secondPlayer, standings, true)
		if firstFound && secondFound && firstOffer != secondOffer {
			initialCounter = counter - 1
			distinctOffers = true
			break
		}
	}
	if !distinctOffers {
		t.Fatal("could not seed consecutive distinct practice offers")
	}
	exec(t, p, `UPDATE arena_players SET match_counter=$2 WHERE player_id=$1`, int64(a.PlayerID), initialCounter)

	dispatcher := stockruntime.ArenaDispatcher{Authority: playtestAuthority{a}, Service: s}
	firstMatch := dispatcher.Dispatch(ctx, playtestRequest(a, 771, map[string]any{"is_practice": int64(1)}))
	if firstMatch.HTTPStatus != 200 {
		t.Fatalf("first MID771: %+v", firstMatch)
	}
	firstEnemy, ok := firstMatch.Body["player_id"].(int64)
	if !ok {
		t.Fatalf("first MID771 body: %#v", firstMatch.Body)
	}
	firstStart := dispatcher.Dispatch(ctx, playtestRequest(a, 772, map[string]any{}))
	if firstStart.HTTPStatus != 200 {
		t.Fatalf("first MID772: %+v", firstStart)
	}

	secondMatch := dispatcher.Dispatch(ctx, playtestRequest(a, 771, map[string]any{"is_practice": int64(1)}))
	if secondMatch.HTTPStatus != 200 {
		t.Fatalf("second MID771: %+v", secondMatch)
	}
	secondEnemy, ok := secondMatch.Body["player_id"].(int64)
	if !ok || secondEnemy == firstEnemy {
		t.Fatalf("refresh offers old=%d new=%#v", firstEnemy, secondMatch.Body["player_id"])
	}
	secondStart := dispatcher.Dispatch(ctx, playtestRequest(a, 772, map[string]any{}))
	if secondStart.HTTPStatus != 200 {
		t.Fatalf("second MID772: %+v", secondStart)
	}

	fullFormation := make([]any, 0, 5)
	for _, hero := range arenaGirls(5) {
		fullFormation = append(fullFormation, hero)
	}
	fight := func(enemy int64, formation []any) map[string]any {
		return map[string]any{"enemy_id": enemy, "is_test": int64(1), "pet_id": int64(0), "campaign_id": int64(0), "formation": formation}
	}
	stale := dispatcher.Dispatch(ctx, playtestRequest(a, 773, fight(firstEnemy, fullFormation)))
	t.Logf("MID773 against older card %d after refreshing to %d: HTTP %d body %#v", firstEnemy, secondEnemy, stale.HTTPStatus, stale.Body)
	if stale.HTTPStatus != 400 || stale.Body["error"] != "arena_request_refused" {
		t.Fatalf("stale-card response: %+v", stale)
	}

	empty := dispatcher.Dispatch(ctx, playtestRequest(a, 773, fight(secondEnemy, []any{})))
	t.Logf("MID773 with empty formation: HTTP %d body %#v", empty.HTTPStatus, empty.Body)
	if empty.HTTPStatus != 400 || empty.Body["error"] != "arena_request_refused" {
		t.Fatalf("empty-formation response: %+v", empty)
	}

	partial := dispatcher.Dispatch(ctx, playtestRequest(a, 773, fight(secondEnemy, []any{arenaGirls(1)[0]})))
	t.Logf("MID773 with one-hero formation: HTTP %d body %#v", partial.HTTPStatus, partial.Body)
	if partial.HTTPStatus != 200 {
		t.Fatalf("partial-formation response: %+v", partial)
	}
}
