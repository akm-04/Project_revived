//go:build postgres

package playerdisplay_test

import (
	"errors"
	"fmt"
	"slices"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	appadventure "gxb.local/backend/v2/internal/application/adventure"
	cb "gxb.local/backend/v2/internal/application/combat"
	d "gxb.local/backend/v2/internal/domain/adventure"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
)

func frozenTeamIdentities(t *testing.T, p *pg.Pool, domainKind, locator string) []int64 {
	t.Helper()
	var hash string
	var raw []byte
	if err := p.QueryRow(ctx, `SELECT s.snapshot_hash, s.canonical FROM combat_attempts a JOIN combat_snapshots s USING(snapshot_hash) WHERE a.domain_kind=$1 AND a.domain_locator=$2`, domainKind, locator).Scan(&hash, &raw); err != nil {
		t.Fatal(err)
	}
	snapshot, err := cd.DecodeSnapshot(raw, hash)
	if err != nil {
		t.Fatal(err)
	}
	identities := make([]int64, 0, len(snapshot.Battle.TeamA))
	for _, actor := range snapshot.Battle.TeamA {
		identities = append(identities, actor.Identity)
	}
	return identities
}

// TestClosureE6AdventurePvpOpenStartReplaysFrozenFormationNative is
// I8_PARENT_CONTRACT_V1 generation_supersede: an open attempt for the same
// occurrence replays its frozen START when the second 2419 submits another
// owned formation, spending nothing.
func TestClosureE6AdventurePvpOpenStartReplaysFrozenFormationNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	owner, picks := adventureOwner(t, p, server, 11, 10001001, 10001002)
	enemy := adventurePvpOpponent(t, p, server)
	clock := &leagueClock{at: time.Now().UTC().Add(2 * time.Minute)}
	mode := adventureTestMode(t, p, clock, adventureOpponents{arena: enemy, arenaFound: true})
	mode.Combat = saturatedFirst(mode.Combat.(cb.Service))
	revision := installed(t, p)
	now := clock.at
	putAdventureOccurrence(t, p, owner.PlayerID, d.EventBattle, 0, now, now.Add(2*time.Hour), "closure-e6-pvp")
	first := opPinned(revision)
	first.StartedAt = clock.at
	if _, err := mode.Fight(ctx, owner, appadventure.FightRequest{Formation: []int64{picks[0]}}, first); !errors.Is(err, cb.ErrWorkerSaturated) {
		t.Fatalf("first START: %v", err)
	}
	locator := adventureBattleLocator(owner.PlayerID, now)
	if staged := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='ADVENTURE_PVP' AND domain_locator=$1 AND state='STAGED'`, locator); staged != 1 {
		t.Fatalf("staged attempts %d", staged)
	}

	second := opPinned(revision)
	second.StartedAt = clock.at
	response, err := mode.Fight(ctx, owner, appadventure.FightRequest{Formation: []int64{picks[1]}}, second)
	if err != nil {
		t.Fatalf("same-stage START with another formation: %v", err)
	}
	if report, _ := response.Body["battle_report"].(string); report == "" {
		t.Fatal("the replay replied no report")
	}
	if attempts := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='ADVENTURE_PVP' AND domain_locator=$1`, locator); attempts != 1 {
		t.Fatalf("the replay froze %d attempts", attempts)
	}
	if got := frozenTeamIdentities(t, p, "ADVENTURE_PVP", locator); !slices.Equal(got, []int64{picks[0]}) {
		t.Fatalf("frozen team %v != first formation %v", got, []int64{picks[0]})
	}
	if resolved := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='ADVENTURE_PVP' AND domain_locator=$1 AND state='TERMINAL' AND terminal_kind='ADVENTURE_PVP_RESULT'`, locator); resolved != 1 {
		t.Fatalf("settled attempts %d", resolved)
	}

	// The occurrence closes at settlement (I9_ADVENTURE_V1 C2/C3), so a later
	// START is refused, never a replay of the frozen attempt and never a fight.
	settled := opPinned(revision)
	settled.StartedAt = clock.at
	if _, err := mode.Fight(ctx, owner, appadventure.FightRequest{Formation: []int64{picks[1]}}, settled); !errors.Is(err, d.ErrExpired) {
		t.Fatalf("settled occurrence: %v", err)
	}
	if attempts := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='ADVENTURE_PVP' AND domain_locator=$1`, locator); attempts != 1 {
		t.Fatalf("a settled occurrence froze another attempt: %d", attempts)
	}
}

// TestClosureE6AdventureCoopOpenStartReplaysFrozenPicksNative is
// I8_PARENT_CONTRACT_V1 generation_supersede: an open attempt for the same room
// replays its frozen START when the master changes a pick before the second
// 2411, spending nothing.
func TestClosureE6AdventureCoopOpenStartReplaysFrozenPicksNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	owner, ownerPicks := adventureOwner(t, p, server, 100, 10001001, 10001002, 10001003)
	b, bPicks := adventureOwner(t, p, server, 100, 10001004, 10001005)
	c, cPicks := adventureOwner(t, p, server, 100, 10001006, 10001007)
	clock := &leagueClock{at: time.Now().UTC().Add(2 * time.Minute)}
	mode := adventureTestMode(t, p, clock, adventureOpponents{})
	revision := installed(t, p)
	now := clock.at
	putAdventureOccurrence(t, p, owner.PlayerID, d.EventIllusion, d.IllusionHiddenBoss, now, now.Add(2*time.Hour), "closure-e6-coop")
	created, err := mode.CreateCoop(ctx, owner, opPinned(revision))
	if err != nil {
		t.Fatal("create coop", err)
	}
	roomID := adventureRoomIDFrom(created)
	if roomID <= 0 {
		t.Fatalf("coop room %#v", created)
	}
	if _, err = mode.InviteCoop(ctx, owner, b.PlayerID, opPinned(revision)); err != nil {
		t.Fatal("coop invite", err)
	}
	for index, member := range []identity.ActorContext{b, c} {
		putAdventureOccurrence(t, p, member.PlayerID, d.EventIllusion, d.IllusionHiddenBoss, now, now.Add(2*time.Hour), fmt.Sprintf("closure-e6-coop-%d", index))
		if _, err = mode.EnterCoop(ctx, member, roomID, opPinned(revision)); err != nil {
			t.Fatal("coop join", err)
		}
	}
	if _, err = mode.EnterTeamFight(ctx, owner, opPinned(revision)); err != nil {
		t.Fatal("enter team fight", err)
	}
	firstPicks := map[identity.PlayerID][]int64{owner.PlayerID: ownerPicks[:2], b.PlayerID: bPicks, c.PlayerID: cPicks}
	for _, member := range []identity.ActorContext{owner, b, c} {
		for position, hero := range firstPicks[member.PlayerID] {
			if _, err = mode.SelectCoop(ctx, member, appadventure.PickRequest{PartnerID: hero, Position: int64(position + 1)}, opPinned(revision)); err != nil {
				t.Fatal("select", err)
			}
		}
	}
	for _, member := range []identity.ActorContext{owner, b, c} {
		if _, err = mode.PrepareCoop(ctx, member, opPinned(revision)); err != nil {
			t.Fatal("prepare coop", err)
		}
	}

	mode.Combat = saturatedFirst(mode.Combat.(cb.Service))
	if _, err = mode.StartCoop(ctx, owner, opPinned(revision)); !errors.Is(err, cb.ErrWorkerSaturated) {
		t.Fatalf("first START: %v", err)
	}
	locator := fmt.Sprintf("room:%d", roomID)
	if staged := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='ADVENTURE_ILLUSION' AND domain_locator=$1 AND state='STAGED'`, locator); staged != 1 {
		t.Fatalf("staged attempts %d", staged)
	}

	if _, err = mode.SelectCoop(ctx, owner, appadventure.PickRequest{PartnerID: ownerPicks[2], Position: 2}, opPinned(revision)); err != nil {
		t.Fatal("change pick", err)
	}
	report, err := mode.StartCoop(ctx, owner, opPinned(revision))
	if err != nil {
		t.Fatalf("same-room START with other picks: %v", err)
	}
	if text, _ := report["battle_report"].(string); text == "" {
		t.Fatal("the replay replied no report")
	}
	if attempts := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='ADVENTURE_ILLUSION' AND domain_locator=$1`, locator); attempts != 1 {
		t.Fatalf("the replay froze %d attempts", attempts)
	}
	frozen := append(append(append([]int64{}, ownerPicks[:2]...), bPicks...), cPicks...)
	if got := frozenTeamIdentities(t, p, "ADVENTURE_ILLUSION", locator); !slices.Equal(got, frozen) {
		t.Fatalf("frozen team %v != first picks %v", got, frozen)
	}
	if resolved := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='ADVENTURE_ILLUSION' AND domain_locator=$1 AND state='TERMINAL' AND terminal_kind='ADVENTURE_ILLUSION_TEAM_RESULT'`, locator); resolved != 1 {
		t.Fatalf("settled attempts %d", resolved)
	}
}
