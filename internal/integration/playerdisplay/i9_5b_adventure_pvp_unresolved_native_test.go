//go:build postgres

package playerdisplay_test

import (
	"errors"
	"fmt"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	appadventure "gxb.local/backend/v2/internal/application/adventure"
	cb "gxb.local/backend/v2/internal/application/combat"
	d "gxb.local/backend/v2/internal/domain/adventure"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
)

func adventurePvpOpponent(t *testing.T, p *pg.Pool, server identity.LogicalServerID) appadventure.Opponent {
	t.Helper()
	defender, _, defenderHero := combatOwner(t, p, server)
	return appadventure.Opponent{PlayerID: defender.PlayerID, Heroes: []cb.Participant{{Origin: cd.OwnedForeign, Kind: cd.HeroActor, Player: defender.PlayerID, Identity: defenderHero.PartnerID}}}
}

func adventureBattleLocator(player identity.PlayerID, occurred time.Time) string {
	return fmt.Sprintf("player:%d/%d/%d", int64(player), d.EventBattle, occurred.Unix())
}

// A saturated worker leaves the PvP attempt unresolved. A same-stage START with
// another formation replays and resolves the frozen attempt instead of
// conflicting, and an identical START resumes it without settling twice
// (I8_PARENT_CONTRACT_V1 generation_supersede).
func TestI9_5BAdventurePvpUnresolvedNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, picks := adventureOwner(t, p, server, 11, 10001001, 10001002)
	enemy := adventurePvpOpponent(t, p, server)
	clock := &leagueClock{at: time.Now().UTC().Add(2 * time.Minute)}
	mode := adventureTestMode(t, p, clock, adventureOpponents{arena: enemy, arenaFound: true})
	mode.Combat = saturatedFirst(mode.Combat.(cb.Service))
	revision := installed(t, p)
	now := clock.at
	putAdventureOccurrence(t, p, a.PlayerID, d.EventBattle, 0, now, now.Add(2*time.Hour), "pvp-unresolved")
	first := opPinned(revision)
	first.StartedAt = clock.at

	if _, err := mode.Fight(ctx, a, appadventure.FightRequest{Formation: []int64{picks[0]}}, first); !errors.Is(err, cb.ErrWorkerSaturated) {
		t.Fatalf("saturated worker %v", err)
	}
	locator := adventureBattleLocator(a.PlayerID, now)
	if staged := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='ADVENTURE_PVP' AND domain_locator=$1 AND state='STAGED'`, locator); staged != 1 {
		t.Fatalf("staged attempts after saturation %d", staged)
	}

	// The unresolved attempt must not block the player: the same stage with
	// another formation replays the frozen START and resolves it, even after the
	// attempt's nominal deadline. It never closes the attempt or freezes a second
	// one (I8_PARENT_CONTRACT_V1 generation_supersede).
	clock.Set(now.Add(6 * time.Minute))
	second := opPinned(revision)
	second.StartedAt = clock.at
	response, err := mode.Fight(ctx, a, appadventure.FightRequest{Formation: []int64{picks[1]}}, second)
	if err != nil {
		t.Fatalf("same-stage START after the unresolved attempt: %v", err)
	}
	if report, _ := response.Body["battle_report"].(string); report == "" {
		t.Fatal("the replay replied no report")
	}
	if attempts := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='ADVENTURE_PVP' AND domain_locator=$1`, locator); attempts != 1 {
		t.Fatalf("the replay froze %d attempts", attempts)
	}
	if closed := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='ADVENTURE_PVP' AND domain_locator=$1 AND state='TERMINAL' AND terminal_kind='ADVENTURE_START_CLOSED'`, locator); closed != 0 {
		t.Fatalf("the replay closed %d attempts", closed)
	}
	if resolved := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='ADVENTURE_PVP' AND domain_locator=$1 AND state='TERMINAL' AND terminal_kind='ADVENTURE_PVP_RESULT'`, locator); resolved != 1 {
		t.Fatalf("settled attempts after the retry %d", resolved)
	}
	if finished := scalar(t, p, `SELECT count(*) FROM adventure_occurrences WHERE player_id=$1 AND event_type=$2 AND occurred_at=$3 AND finished_at IS NOT NULL`, int64(a.PlayerID), d.EventBattle, now.UTC()); finished != 1 {
		t.Fatalf("finished occurrences after the retry %d", finished)
	}

	// The same formation under a new operation id resumes the frozen attempt.
	b, bPicks := adventureOwner(t, p, server, 11, 10001003)
	resume := adventureTestMode(t, p, clock, adventureOpponents{arena: enemy, arenaFound: true})
	resume.Combat = saturatedFirst(resume.Combat.(cb.Service))
	now = clock.at
	putAdventureOccurrence(t, p, b.PlayerID, d.EventBattle, 0, now, now.Add(2*time.Hour), "pvp-resume")
	third := opPinned(revision)
	third.StartedAt = clock.at
	if _, err = resume.Fight(ctx, b, appadventure.FightRequest{Formation: []int64{bPicks[0]}}, third); !errors.Is(err, cb.ErrWorkerSaturated) {
		t.Fatalf("saturated worker %v", err)
	}
	fourth := opPinned(revision)
	fourth.StartedAt = clock.at
	response, err = resume.Fight(ctx, b, appadventure.FightRequest{Formation: []int64{bPicks[0]}}, fourth)
	if err != nil {
		t.Fatal("identical retry", err)
	}
	if report, _ := response.Body["battle_report"].(string); report == "" {
		t.Fatal("identical retry replied no report")
	}
	resumed := adventureBattleLocator(b.PlayerID, now)
	if attempts := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='ADVENTURE_PVP' AND domain_locator=$1`, resumed); attempts != 1 {
		t.Fatalf("the identical retry froze a second attempt: %d", attempts)
	}
	if resolved := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='ADVENTURE_PVP' AND domain_locator=$1 AND terminal_kind='ADVENTURE_PVP_RESULT'`, resumed); resolved != 1 {
		t.Fatalf("the identical retry settled %d times", resolved)
	}
}

// Every same-stage START of an unresolved attempt replays the frozen attempt: a
// later formation neither closes it nor freezes a second one
// (I8_PARENT_CONTRACT_V1 generation_supersede).
func TestI9_5BAdventurePvpRepeatedReplacementNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, picks := adventureOwner(t, p, server, 11, 10001001, 10001002)
	enemy := adventurePvpOpponent(t, p, server)
	clock := &leagueClock{at: time.Now().UTC().Add(2 * time.Minute)}
	mode := adventureTestMode(t, p, clock, adventureOpponents{arena: enemy, arenaFound: true})
	mode.Combat = saturatedTimes(mode.Combat.(cb.Service), 3)
	revision := installed(t, p)
	start := clock.at
	putAdventureOccurrence(t, p, a.PlayerID, d.EventBattle, 0, start, start.Add(2*time.Hour), "pvp-replaced-twice")

	formations := [][]int64{{picks[0]}, {picks[1]}, {picks[0]}, {picks[1]}}
	for i, formation := range formations {
		clock.Set(start.Add(time.Duration(i) * 6 * time.Minute))
		op := opPinned(revision)
		op.StartedAt = clock.at
		response, err := mode.Fight(ctx, a, appadventure.FightRequest{Formation: formation}, op)
		if i < len(formations)-1 {
			if !errors.Is(err, cb.ErrWorkerSaturated) {
				t.Fatalf("fight %d: saturated worker %v", i, err)
			}
			continue
		}
		if err != nil {
			t.Fatal("fight after three stuck attempts", err)
		}
		if report, _ := response.Body["battle_report"].(string); report == "" {
			t.Fatal("fight after three stuck attempts replied no report")
		}
	}
	locator := adventureBattleLocator(a.PlayerID, start)
	if attempts := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='ADVENTURE_PVP' AND domain_locator=$1`, locator); attempts != 1 {
		t.Fatalf("the replays froze %d attempts", attempts)
	}
	if closed := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='ADVENTURE_PVP' AND domain_locator=$1 AND terminal_kind='ADVENTURE_START_CLOSED'`, locator); closed != 0 {
		t.Fatalf("the replays closed %d attempts", closed)
	}
	if resolved := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='ADVENTURE_PVP' AND domain_locator=$1 AND terminal_kind='ADVENTURE_PVP_RESULT'`, locator); resolved != 1 {
		t.Fatalf("settled attempts %d", resolved)
	}
}

// A replayed earlier START operation resumes the same frozen attempt instead of
// conflicting, so no operation can close a later attempt under a stale receipt
// (I8_PARENT_CONTRACT_V1 generation_supersede; A-058 class).
func TestI9_5BAdventurePvpReplayedReplacementNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, picks := adventureOwner(t, p, server, 11, 10001001, 10001002)
	enemy := adventurePvpOpponent(t, p, server)
	clock := &leagueClock{at: time.Now().UTC().Add(2 * time.Minute)}
	mode := adventureTestMode(t, p, clock, adventureOpponents{arena: enemy, arenaFound: true})
	mode.Combat = saturatedTimes(mode.Combat.(cb.Service), 3)
	revision := installed(t, p)
	start := clock.at
	putAdventureOccurrence(t, p, a.PlayerID, d.EventBattle, 0, start, start.Add(2*time.Hour), "pvp-replayed-replacement")

	formations := [][]int64{{picks[0]}, {picks[1]}, {picks[0]}}
	var replaced = opPinned(revision)
	for i, formation := range formations {
		clock.Set(start.Add(time.Duration(i) * 6 * time.Minute))
		op := opPinned(revision)
		op.StartedAt = clock.at
		if i == 1 {
			replaced = op
		}
		if _, err := mode.Fight(ctx, a, appadventure.FightRequest{Formation: formation}, op); !errors.Is(err, cb.ErrWorkerSaturated) {
			t.Fatalf("fight %d: saturated worker %v", i, err)
		}
	}
	clock.Set(start.Add(18 * time.Minute))
	if _, err := mode.Fight(ctx, a, appadventure.FightRequest{Formation: formations[1]}, replaced); err != nil {
		t.Fatal("replayed START", err)
	}
	locator := adventureBattleLocator(a.PlayerID, start)
	if closed := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='ADVENTURE_PVP' AND domain_locator=$1 AND terminal_kind='ADVENTURE_START_CLOSED'`, locator); closed != 0 {
		t.Fatalf("the replay closed attempts %d", closed)
	}
	if attempts := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='ADVENTURE_PVP' AND domain_locator=$1`, locator); attempts != 1 {
		t.Fatalf("the replay froze %d attempts", attempts)
	}
	if resolved := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='ADVENTURE_PVP' AND domain_locator=$1 AND terminal_kind='ADVENTURE_PVP_RESULT'`, locator); resolved != 1 {
		t.Fatalf("settled attempts %d", resolved)
	}
}
