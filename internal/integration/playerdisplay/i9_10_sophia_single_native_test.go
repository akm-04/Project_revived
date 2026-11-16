//go:build postgres

package playerdisplay_test

import (
	"testing"
	"time"

	appadventure "gxb.local/backend/v2/internal/application/adventure"
	da "gxb.local/backend/v2/internal/domain/adventure"
)

// TestI9_10SophiaSingleSettleReplyShape checks 2422's awards key: a loss must
// omit it so the client fires the close callback, a win carries the gift rows,
// and the reported damage is clamped to the Adventure pool, not Fantasy's cap.
func TestI9_10SophiaSingleSettleReplyShape(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	loser, loserPicks := adventureOwner(t, p, server, 100, 10001001)
	winner, winnerPicks := adventureOwner(t, p, server, 100, 10001002)
	clock := &leagueClock{at: time.Now().UTC().Add(2 * time.Minute)}
	mode := adventureTestMode(t, p, clock, adventureOpponents{})
	opContext := opPinned(installed(t, p))
	opContext.StartedAt = clock.at

	putAdventureOccurrence(t, p, loser.PlayerID, da.EventIllusion, da.IllusionHiddenBoss, clock.at, clock.at.Add(2*time.Hour), "sophia-loss")
	if _, err := mode.StartSingle(ctx, loser, appadventure.FightRequest{Formation: []int64{loserPicks[0]}}, opContext); err != nil {
		t.Fatal("start loss", err)
	}
	loss, err := mode.SettleSingle(ctx, loser, appadventure.ResultRequest{Star: 0, Damage: 1000, Formation: []int64{loserPicks[0]}}, opContext)
	if err != nil {
		t.Fatal("settle loss", err)
	}
	if _, hasAwards := loss.Body["awards"]; hasAwards {
		t.Fatalf("a loss must omit awards, got %#v", loss.Body)
	}

	putAdventureOccurrence(t, p, winner.PlayerID, da.EventIllusion, da.IllusionHiddenBoss, clock.at, clock.at.Add(2*time.Hour), "sophia-win")
	if _, err = mode.StartSingle(ctx, winner, appadventure.FightRequest{Formation: []int64{winnerPicks[0]}}, opContext); err != nil {
		t.Fatal("start win", err)
	}
	win, err := mode.SettleSingle(ctx, winner, appadventure.ResultRequest{Star: 1, Damage: 9000000, Formation: []int64{winnerPicks[0]}}, opContext)
	if err != nil {
		t.Fatal("settle win", err)
	}
	awards, ok := win.Body["awards"].([]any)
	if !ok || len(awards) == 0 {
		t.Fatalf("a win must carry its gift rows: %#v", win.Body)
	}
	if damage := scalar(t, p, `SELECT damage FROM adventure_attempt_settlements WHERE player_id=$1`, int64(winner.PlayerID)); damage != da.IllusionTotalDamage {
		t.Fatalf("the win was clamped to %d, want the Adventure pool %d", damage, da.IllusionTotalDamage)
	}
	if rows := scalar(t, p, `SELECT count(*) FROM adventure_single_attempts_retired_r5d WHERE player_id=$1`, int64(winner.PlayerID)); rows != 0 {
		t.Fatal("mode-local attempt row", rows)
	}
}
