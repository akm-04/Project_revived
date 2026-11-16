//go:build postgres

package playerdisplay_test

import (
	"errors"
	"fmt"
	"testing"
	"time"

	cb "gxb.local/backend/v2/internal/application/combat"
	oc "gxb.local/backend/v2/internal/application/occult"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
)

// A permanent resolver failure must close the team fight and return the stage
// to selection, so the next 2377 freezes a new attempt for the same stage.
func TestI9_5BOccultTeamUnresolvedNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, aPicks := occultTeamOwner(t, p, server, 2, 10001002)
	b, bPicks := occultTeamOwner(t, p, server, 2, 10001003)
	c, cPicks := occultTeamOwner(t, p, server, 2, 10001004)
	// The library observation must sit after the fixture's database-clock
	// activation, so the mode's decision instant is not truncated below it.
	clock := &leagueClock{at: time.Now().UTC().Add(time.Minute)}
	s := occultMode(t, p, clock)
	s.Combat = permanentFirst(s.Combat.(cb.Service))

	created, err := s.CreateTeam(ctx, a, 2, op())
	if err != nil {
		t.Fatal(err)
	}
	roomID := occultRoomID(t, created)
	for _, member := range []identity.ActorContext{b, c} {
		if _, err = s.JoinRoom(ctx, member, roomID, op()); err != nil {
			t.Fatal("join", err)
		}
	}
	if _, err = s.StartChallenge(ctx, a, op()); err != nil {
		t.Fatal("challenge", err)
	}
	if _, err = s.TeamInvite(ctx, a, 20002, 1, op()); err != nil {
		t.Fatal("invite fight", err)
	}
	for _, member := range []identity.ActorContext{b, c} {
		if _, err = s.TeamAccept(ctx, member, 20002, 1, true, op()); err != nil {
			t.Fatal("accept", err)
		}
	}
	for _, entry := range []struct {
		actor identity.ActorContext
		pick  int64
	}{{a, aPicks[0]}, {b, bPicks[0]}, {c, cPicks[0]}} {
		if _, err = s.TeamSelect(ctx, entry.actor, oc.FormationRequest{CampaignID: 20002, SubID: 1, PartnerID: entry.pick, Position: 1}, op()); err != nil {
			t.Fatalf("select player %d hero %d: %v", entry.actor.PlayerID, entry.pick, err)
		}
	}
	for _, member := range []identity.ActorContext{a, b, c} {
		if _, err = s.TeamPrepare(ctx, member, 20002, 1, op()); err != nil {
			t.Fatal("prepare", err)
		}
	}

	if _, err = s.StartTeamFight(ctx, a, 20002, 1, op()); !errors.Is(err, cd.ErrResolverPermanent) {
		t.Fatalf("permanent resolver failure %v", err)
	}
	locator := fmt.Sprintf("room:%d", roomID)
	if closed := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='OCCULT' AND domain_locator=$1 AND state='TERMINAL' AND terminal_kind='OCCULT_TEAM_CLOSED'`, locator); closed != 1 {
		t.Fatalf("closed attempts %d", closed)
	}
	if state := occultRoomState(t, p, roomID); state.Team == nil || state.Team.AttemptID != "" || state.Team.FightStartedAt != 0 {
		t.Fatalf("stage did not return to selection %+v", state.Team)
	}

	fight, err := s.StartTeamFight(ctx, a, 20002, 1, op())
	if err != nil {
		t.Fatal("start after a closed attempt", err)
	}
	if report := occultTeamReport(t, fight); report == "" {
		t.Fatal("second start did not resolve a report")
	}
	if state := occultRoomState(t, p, roomID); state.Team == nil || state.Team.ReportKey == "" {
		t.Fatalf("room did not freeze the second report %+v", state.Team)
	}
	if attempts := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='OCCULT' AND domain_locator=$1`, locator); attempts != 2 {
		t.Fatalf("attempts after the retry %d", attempts)
	}
	if resolved := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='OCCULT' AND domain_locator=$1 AND state='TERMINAL' AND terminal_kind='OCCULT_TEAM_RESULT'`, locator); resolved != 1 {
		t.Fatalf("resolved attempts %d", resolved)
	}
}
