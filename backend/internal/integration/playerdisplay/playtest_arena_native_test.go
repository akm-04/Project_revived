//go:build postgres

package playerdisplay_test

import (
	"reflect"
	"testing"

	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// D507: a refresh keeps the previous issued lists fightable, an empty formation
// and a never-offered opponent refuse as stock 409s, and a repeated FIGHT replays.
func TestPlaytestArenaRecentOffersNative(t *testing.T) {
	p := pool(t)
	defer p.Close()
	s := arenaService(t, p)
	a, _ := oneOnOnePlayer(t, p, rankingServer(t, p))
	b, _ := oneOnOnePlayer(t, p, rankingServer(t, p))
	c, _ := oneOnOnePlayer(t, p, rankingServer(t, p))
	// Later tests in this package delete other players' arena rows, which these matches would block.
	defer func() {
		exec(t, p, `DELETE FROM arena_records WHERE owner_player_id=$1 OR match_id IN (SELECT match_id FROM arena_matches WHERE attacker_id=$1)`, int64(a.PlayerID))
		exec(t, p, `DELETE FROM arena_partner_usage WHERE player_id=$1`, int64(a.PlayerID))
		exec(t, p, `DELETE FROM arena_matches WHERE attacker_id=$1`, int64(a.PlayerID))
	}()
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
	matches := func() int64 {
		return scalar(t, p, `SELECT count(*) FROM arena_matches WHERE attacker_id=$1`, int64(a.PlayerID))
	}
	fightSettledThroughDispatcher := func(enemy int64, formation []any) httpedge.Response {
		for range 10 {
			response := dispatcher.Dispatch(ctx, playtestRequest(a, 773, fight(enemy, formation)))
			if response.HTTPStatus != 200 {
				return response
			}
			switch reports := response.Body["battle_report"].(type) {
			case []map[string]any:
				if len(reports) > 0 {
					return response
				}
			case []any:
				if len(reports) > 0 {
					return response
				}
			}
		}
		t.Fatalf("MID773 against %d never resolved", enemy)
		return httpedge.Response{}
	}

	before := matches()
	older := fightSettledThroughDispatcher(firstEnemy, fullFormation)
	if older.HTTPStatus != 200 {
		t.Fatalf("MID773 against older card %d after refreshing to %d: %+v", firstEnemy, secondEnemy, older)
	}
	if matches() != before+1 || scalar(t, p, `SELECT count(*) FROM arena_matches WHERE attacker_id=$1 AND defender_id=$2 AND status='SETTLED' AND COALESCE((outcome->>'forfeit')::boolean,false)=false`, int64(a.PlayerID), firstEnemy) != 1 {
		t.Fatal("the older offered card did not start and settle one fight")
	}

	replay := dispatcher.Dispatch(ctx, playtestRequest(a, 773, fight(firstEnemy, fullFormation)))
	if replay.HTTPStatus != 200 || !reflect.DeepEqual(replay.Body, older.Body) || matches() != before+1 {
		t.Fatalf("duplicated MID773 did not replay its result: %+v", replay)
	}

	d, _ := oneOnOnePlayer(t, p, rankingServer(t, p))
	if _, err = s.Info(ctx, d, op()); err != nil {
		t.Fatal(err)
	}
	if _, err = s.ModifyDefence(ctx, d, arenaGirls(5), 0, op()); err != nil {
		t.Fatal(err)
	}
	beforeRefusals := matches()
	notOffered := dispatcher.Dispatch(ctx, playtestRequest(a, 773, fight(int64(d.PlayerID), fullFormation)))
	if notOffered.HTTPStatus != 409 || notOffered.Body["error_code"] != int64(30023) {
		t.Fatalf("never-offered opponent: HTTP %d body %#v", notOffered.HTTPStatus, notOffered.Body)
	}
	empty := dispatcher.Dispatch(ctx, playtestRequest(a, 773, fight(secondEnemy, []any{})))
	if empty.HTTPStatus != 409 || empty.Body["error_code"] != int64(35006) {
		t.Fatalf("empty formation: HTTP %d body %#v", empty.HTTPStatus, empty.Body)
	}
	if matches() != beforeRefusals {
		t.Fatal("a refused MID773 changed the match ledger")
	}
}
