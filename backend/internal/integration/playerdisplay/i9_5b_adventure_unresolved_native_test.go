//go:build postgres

package playerdisplay_test

import (
	"errors"
	"fmt"
	"testing"
	"time"

	appadventure "gxb.local/backend/v2/internal/application/adventure"
	cb "gxb.local/backend/v2/internal/application/combat"
	d "gxb.local/backend/v2/internal/domain/adventure"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
)

// A permanent resolver failure must close the co-op attempt, so the next 2411
// in the same room freezes a new one instead of replaying the dead attempt.
func TestI9_5BAdventureCoopUnresolvedNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, aPicks := adventureOwner(t, p, server, 100, 10001001, 10001002)
	b, bPicks := adventureOwner(t, p, server, 100, 10001003, 10001004)
	c, cPicks := adventureOwner(t, p, server, 100, 10001005, 10001006)
	clock := &leagueClock{at: time.Now().UTC().Add(2 * time.Minute)}
	mode := adventureTestMode(t, p, clock, adventureOpponents{})
	mode.Combat = permanentFirst(mode.Combat.(cb.Service))
	revision := installed(t, p)
	now := clock.at
	putAdventureOccurrence(t, p, a.PlayerID, d.EventIllusion, d.IllusionHiddenBoss, now, now.Add(2*time.Hour), "unresolved-coop")
	first := opPinned(revision)
	first.StartedAt = clock.at

	created, err := mode.CreateCoop(ctx, a, first)
	if err != nil {
		t.Fatal("create coop", err)
	}
	coopID := adventureRoomIDFrom(created)
	if _, err = mode.InviteCoop(ctx, a, b.PlayerID, first); err != nil {
		t.Fatal("coop invite", err)
	}
	for _, member := range []identity.ActorContext{b, c} {
		putAdventureOccurrence(t, p, member.PlayerID, d.EventIllusion, d.IllusionHiddenBoss, now, now.Add(2*time.Hour), fmt.Sprintf("unresolved-coop-%d", member.PlayerID))
		if _, err = mode.EnterCoop(ctx, member, coopID, first); err != nil {
			t.Fatal("coop join", err)
		}
	}
	if _, err = mode.EnterTeamFight(ctx, a, first); err != nil {
		t.Fatal("enter team fight", err)
	}
	for _, member := range []struct {
		actor identity.ActorContext
		picks []int64
	}{{a, aPicks}, {b, bPicks}, {c, cPicks}} {
		for position, hero := range member.picks {
			if _, err = mode.SelectCoop(ctx, member.actor, appadventure.PickRequest{PartnerID: hero, Position: int64(position + 1)}, first); err != nil {
				t.Fatal("select", err)
			}
		}
	}
	for _, member := range []identity.ActorContext{a, b, c} {
		if _, err = mode.PrepareCoop(ctx, member, first); err != nil {
			t.Fatal("prepare coop", err)
		}
	}

	if _, err = mode.StartCoop(ctx, a, first); !errors.Is(err, cd.ErrResolverPermanent) {
		t.Fatalf("permanent resolver failure %v", err)
	}
	locator := fmt.Sprintf("room:%d", coopID)
	if closed := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='ADVENTURE_ILLUSION' AND domain_locator=$1 AND state='TERMINAL' AND terminal_kind='ADVENTURE_ILLUSION_TEAM_CLOSED'`, locator); closed != 1 {
		t.Fatalf("closed attempts %d", closed)
	}

	second := opPinned(revision)
	second.StartedAt = clock.at
	report, err := mode.StartCoop(ctx, a, second)
	if err != nil {
		t.Fatal("start after a closed attempt", err)
	}
	if text, _ := report["battle_report"].(string); text == "" {
		t.Fatal("second start did not resolve a report")
	}
	if attempts := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='ADVENTURE_ILLUSION' AND domain_locator=$1`, locator); attempts != 2 {
		t.Fatalf("attempts after the retry %d", attempts)
	}
	if resolved := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='ADVENTURE_ILLUSION' AND domain_locator=$1 AND state='TERMINAL' AND terminal_kind='ADVENTURE_ILLUSION_TEAM_RESULT'`, locator); resolved != 1 {
		t.Fatalf("resolved attempts %d", resolved)
	}
}
