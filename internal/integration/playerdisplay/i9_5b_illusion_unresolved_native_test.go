//go:build postgres

package playerdisplay_test

import (
	"errors"
	"fmt"
	"testing"

	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	cb "gxb.local/backend/v2/internal/application/combat"
	il "gxb.local/backend/v2/internal/application/illusion"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
)

// A permanent resolver failure must close the team attempt and clear the room's
// pointer, so the next 1358 in the same room freezes a new attempt.
func TestI9_5BIllusionTeamUnresolvedNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	clock := illusionTime(t)
	s := illusionService(t, p, clock, illusionPrivileges{level: 3}, illusionGuildSource{})
	s.Combat = permanentFirst(s.Combat.(cb.Service))
	a, _ := illusionTeamOwner(t, p, server, 10001002)
	b, _ := illusionTeamOwner(t, p, server, 10001003, 10001004)
	c, _ := illusionTeamOwner(t, p, server, 10001005, 10001006)
	revision := installed(t, p)
	definition, err := (contentstore.Store{Queryer: p}).PetAcquisitionTx(ctx, p, revision, 10010001)
	if err != nil {
		t.Fatal(err)
	}
	grantGenuine(t, p, a, revision, "illusion master pet", []grant.Line{
		{Kind: grant.StackItem, ItemID: definition.EggItemID, Amount: 1},
		{Kind: grant.ScalarCurrency, ResourceKey: "crystal", Amount: 10000}})
	pets := genuinePetService(p)
	ricky := must(pets.Summon(ctx, a, 10010001, op()))(t, "pet summon")
	must(pets.CleanCD(ctx, a, ricky.PetID, op()))(t, "pet hatch")

	created, err := s.CreateRoom(ctx, a, op())
	if err != nil {
		t.Fatal("create room", err)
	}
	roomID := illusionRoomID(t, created)
	for _, member := range []identity.ActorContext{b, c} {
		if _, err = s.EnterRoom(ctx, member, roomID, op()); err != nil {
			t.Fatal("join", err)
		}
	}
	if _, err = s.Prepare(ctx, a, op()); err != nil {
		t.Fatal("master 1351", err)
	}
	for _, step := range []struct {
		actor identity.ActorContext
		pick  il.PartnerRequest
	}{
		{a, il.PartnerRequest{Heroes: []int64{}, PetID: 10010001}},
		{a, il.PartnerRequest{Heroes: []int64{10001002}, PetID: 10010001}},
		{b, il.PartnerRequest{Heroes: []int64{10001003, 10001004}}},
		{c, il.PartnerRequest{Heroes: []int64{10001005, 10001006}}},
	} {
		if _, err = s.SetPartner(ctx, step.actor, step.pick, op()); err != nil {
			t.Fatal("pick", err)
		}
	}
	for _, member := range []identity.ActorContext{a, b, c} {
		if _, err = s.Ready(ctx, member, op()); err != nil {
			t.Fatal("1357", err)
		}
	}

	if _, err = s.StartTeam(ctx, a, op()); !errors.Is(err, cd.ErrResolverPermanent) {
		t.Fatalf("permanent resolver failure %v", err)
	}
	locator := fmt.Sprintf("room:%d", roomID)
	if closed := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='ILLUSION' AND domain_locator=$1 AND state='TERMINAL' AND terminal_kind='ILLUSION_TEAM_CLOSED'`, locator); closed != 1 {
		t.Fatalf("closed attempts %d", closed)
	}
	if state := illusionRoomState(t, p, roomID); state.AttemptID != "" {
		t.Fatalf("room still points at the closed attempt %+v", state)
	}

	fight, err := s.StartTeam(ctx, a, op())
	if err != nil {
		t.Fatal("start after a closed attempt", err)
	}
	if content := reportContent(t, fight); content == "" {
		t.Fatal("second start did not resolve a report")
	}
	if state := illusionRoomState(t, p, roomID); state.ReportID == "" || state.ReportID != state.AttemptID {
		t.Fatalf("room did not freeze the second report %+v", state)
	}
	if attempts := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='ILLUSION' AND domain_locator=$1`, locator); attempts != 2 {
		t.Fatalf("attempts after the retry %d", attempts)
	}
	if resolved := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='ILLUSION' AND domain_locator=$1 AND state='TERMINAL' AND terminal_kind='ILLUSION_TEAM_RESULT'`, locator); resolved != 1 {
		t.Fatalf("resolved attempts %d", resolved)
	}
}
