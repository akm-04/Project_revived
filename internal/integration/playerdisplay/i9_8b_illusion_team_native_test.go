//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"reflect"
	"sync"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/sharedroomstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	cb "gxb.local/backend/v2/internal/application/combat"
	il "gxb.local/backend/v2/internal/application/illusion"
	appsharedroom "gxb.local/backend/v2/internal/application/sharedroom"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	di "gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// illusionTeamCombat runs the real worker and counts the per-member settlement
// fan-out the mode performs.
type illusionTeamCombat struct {
	cb.Service
	mu          sync.Mutex
	settlements map[identity.PlayerID]int
}

func (c *illusionTeamCombat) SettleMemberTx(ctx context.Context, t tx.Tx, request cb.MemberSettleRequest) (cb.MemberSettled, error) {
	settled, err := c.Service.SettleMemberTx(ctx, t, request)
	if err != nil {
		return settled, err
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.settlements == nil {
		c.settlements = map[identity.PlayerID]int{}
	}
	c.settlements[request.Member]++
	return settled, nil
}

func (c *illusionTeamCombat) settlementCount(member identity.PlayerID) int {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.settlements[member]
}

func illusionRoomState(t *testing.T, p *pg.Pool, roomID int64) di.RoomState {
	t.Helper()
	var raw string
	if err := p.QueryRow(ctx, `SELECT payload::text FROM shared_rooms WHERE room_id=$1`, roomID).Scan(&raw); err != nil {
		t.Fatal(err)
	}
	state, err := di.LoadRoomState([]byte(raw))
	if err != nil {
		t.Fatal(err)
	}
	return state
}

func illusionRoomID(t *testing.T, body map[string]any) int64 {
	t.Helper()
	roomID, ok := body["room_id"].(int64)
	if !ok || roomID <= 0 {
		t.Fatalf("room id %#v", body)
	}
	return roomID
}

func TestI9_8BIllusionTeamFightNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	clock := illusionTime(t)
	s := illusionService(t, p, clock, illusionPrivileges{level: 3}, illusionGuildSource{})
	team := &illusionTeamCombat{Service: s.Combat.(cb.Service)}
	s.Combat = team
	a, aPicks := illusionTeamOwner(t, p, server, 10001002)
	b, bPicks := illusionTeamOwner(t, p, server, 10001003, 10001004)
	c, cPicks := illusionTeamOwner(t, p, server, 10001005, 10001006)
	revision := installed(t, p)
	contentStore := contentstore.Store{Queryer: p}
	definition, err := contentStore.PetAcquisitionTx(ctx, p, revision, 10010001)
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
		t.Fatal(err)
	}
	roomID := illusionRoomID(t, created)
	for _, member := range []identity.ActorContext{b, c} {
		if _, err = s.EnterRoom(ctx, member, roomID, op()); err != nil {
			t.Fatal("join", err)
		}
	}
	if _, err = s.SetPartner(ctx, a, il.PartnerRequest{Heroes: []int64{aPicks[0]}}, op()); !errors.Is(err, di.ErrRefused) {
		t.Fatalf("a petless master pick was accepted: %v", err)
	}
	if _, err = s.SetPartner(ctx, a, il.PartnerRequest{Heroes: []int64{aPicks[0]}, PetID: ricky.PetID}, op()); err != nil {
		t.Fatal("master pick", err)
	}
	if _, err = s.SetPartner(ctx, b, il.PartnerRequest{Heroes: bPicks}, op()); err != nil {
		t.Fatal("mate 1 pick", err)
	}
	if _, err = s.SetPartner(ctx, c, il.PartnerRequest{Heroes: cPicks}, op()); err != nil {
		t.Fatal("mate 2 pick", err)
	}
	if _, err = s.Prepare(ctx, a, op()); err != nil {
		t.Fatal(err)
	}
	if _, err = s.Prepare(ctx, b, op()); err != nil {
		t.Fatal(err)
	}
	if _, err = s.Ready(ctx, c, op()); err != nil {
		t.Fatal(err)
	}
	fight, err := s.StartTeam(ctx, a, op())
	if err != nil {
		t.Fatal("team start", err)
	}
	content := reportContent(t, fight)
	if content == "" {
		t.Fatal("empty team report")
	}
	state := illusionRoomState(t, p, roomID)
	if state.AttemptID == "" || state.ReportID != state.AttemptID {
		t.Fatalf("room did not freeze the report %+v", state)
	}
	for _, member := range []identity.ActorContext{a, b, c} {
		if n := team.settlementCount(member.PlayerID); n != 1 {
			t.Fatalf("member %d settlement count %d", member.PlayerID, n)
		}
	}
	accepted := scalar(t, p, `SELECT pool_hurt FROM illusion_occurrences WHERE logical_server_id=$1`, int64(server))
	if accepted <= 0 {
		t.Fatal("team damage was not accepted")
	}
	for _, member := range []identity.ActorContext{a, b, c} {
		if n := scalar(t, p, `SELECT hurt FROM illusion_occurrence_results WHERE logical_server_id=$1 AND open_day=(SELECT open_day FROM illusion_occurrences WHERE logical_server_id=$1) AND player_id=$2`, int64(server), int64(member.PlayerID)); n != accepted {
			t.Fatalf("member %d result %d want %d", member.PlayerID, n, accepted)
		}
	}
	// A replayed 1358 returns the stored report without admitting or settling again.
	replay, err := s.StartTeam(ctx, a, op())
	if err != nil || !sameReport(t, reportContent(t, replay), content) {
		t.Fatalf("team replay %v", err)
	}
	for _, member := range []identity.ActorContext{a, b, c} {
		if n := team.settlementCount(member.PlayerID); n != 1 {
			t.Fatalf("team replay settled member %d %d times", member.PlayerID, n)
		}
	}
	report, err := s.GetReport(ctx, a, state.ReportID, op())
	if err != nil || !sameReport(t, reportContent(t, report), content) {
		t.Fatalf("1362 replay %v", err)
	}
	other, _ := illusionOwner(t, p, rankingServer(t, p))
	if _, err = s.GetReport(ctx, other, state.ReportID, op()); !errors.Is(err, di.ErrRefused) {
		t.Fatalf("1362 crossed a logical server: %v", err)
	}
}

func sameReport(t *testing.T, left, right string) bool {
	t.Helper()
	var a, b any
	if json.Unmarshal([]byte(left), &a) != nil || json.Unmarshal([]byte(right), &b) != nil {
		return false
	}
	return reflect.DeepEqual(a, b)
}

func reportContent(t *testing.T, body map[string]any) string {
	t.Helper()
	report, ok := body["report"].([]map[string]any)
	if !ok || len(report) != 1 {
		t.Fatalf("report array %#v", body)
	}
	content, _ := report[0]["content"].(string)
	return content
}

func TestI9_8BIllusionRoomPolicyNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	clock := illusionTime(t)
	s := illusionService(t, p, clock, illusionPrivileges{level: 3}, illusionGuildSource{})
	a, _ := illusionTeamOwner(t, p, server, 10001002)
	b, _ := illusionTeamOwner(t, p, server, 10001003)
	c, _ := illusionTeamOwner(t, p, server, 10001004)
	low, _ := illusionTeamOwner(t, p, server, 10001005)
	exec(t, p, `UPDATE player_directory_profiles SET lev=64 WHERE player_id=$1`, int64(low.PlayerID))

	created, err := s.CreateRoom(ctx, a, op())
	if err != nil {
		t.Fatal(err)
	}
	roomID := illusionRoomID(t, created)
	if _, err = s.CreateRoom(ctx, a, op()); err == nil {
		t.Fatal("second active room for one player")
	}
	if _, err = s.Invite(ctx, a, b.PlayerID, op()); err != nil {
		t.Fatal("invite", err)
	}
	if _, err = s.Invite(ctx, a, low.PlayerID, op()); err == nil {
		t.Fatal("invite below the level band")
	}
	for _, member := range []identity.ActorContext{b, c} {
		if _, err = s.EnterRoom(ctx, member, roomID, op()); err != nil {
			t.Fatal("enter", err)
		}
	}
	if _, err = s.RemovePlayer(ctx, a, c.PlayerID, op()); err != nil {
		t.Fatal("kick", err)
	}
	if _, err = s.EnterRoom(ctx, c, roomID, op()); err == nil {
		t.Fatal("kicked player rejoined")
	}
	if _, err = s.Prepare(ctx, b, op()); err != nil {
		t.Fatal(err)
	}
	reader := stockruntime.IllusionRoomNoticeReader{Store: sharedroomstore.Store{}, Directory: i4store.PlayerDirectoryReader{}, Queryer: p}
	notice, found, err := reader.ReadRoomNotice(ctx, fmt.Sprint(roomID))
	if err != nil || !found {
		t.Fatalf("518 read %v %v", found, err)
	}
	if !notice.Ready[b.PlayerID] || notice.Ready[a.PlayerID] || notice.Ready[c.PlayerID] {
		t.Fatalf("518 ready flags %#v", notice.Ready)
	}
	if _, err = s.CancelPrepare(ctx, b, op()); err != nil {
		t.Fatal(err)
	}
	notice, found, err = reader.ReadRoomNotice(ctx, fmt.Sprint(roomID))
	if err != nil || !found || notice.Ready[b.PlayerID] {
		t.Fatalf("518 stale ready %#v %v %v", notice.Ready, found, err)
	}
	if n := scalar(t, p, `SELECT count(*) FROM shared_room_seats WHERE room_id=$1 AND player_id=$2 AND ready`, roomID, int64(b.PlayerID)); n != 0 {
		t.Fatal("1363 did not clear readiness")
	}
	if _, err = s.ExitRoom(ctx, b, op()); err != nil {
		t.Fatal("mate exit", err)
	}
	if _, err = s.ExitRoom(ctx, a, op()); err != nil {
		t.Fatal("owner exit", err)
	}
	if status := scalar(t, p, `SELECT count(*) FROM shared_rooms WHERE room_id=$1 AND status='CLOSED'`, roomID); status != 1 {
		t.Fatal("owner exit did not close the room")
	}
}

func TestI9_8BIllusionConcurrentJoinNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	clock := illusionTime(t)
	s := illusionService(t, p, clock, illusionPrivileges{level: 3}, illusionGuildSource{})
	owner, _ := illusionTeamOwner(t, p, server, 10001002)
	seated, _ := illusionTeamOwner(t, p, server, 10001003)
	first, _ := illusionTeamOwner(t, p, server, 10001004)
	second, _ := illusionTeamOwner(t, p, server, 10001005)

	created, err := s.CreateRoom(ctx, owner, op())
	if err != nil {
		t.Fatal(err)
	}
	roomID := illusionRoomID(t, created)
	if _, err = s.EnterRoom(ctx, seated, roomID, op()); err != nil {
		t.Fatal(err)
	}
	var workers sync.WaitGroup
	results := make(chan error, 2)
	for _, contender := range []identity.ActorContext{first, second} {
		workers.Add(1)
		go func(member identity.ActorContext) {
			defer workers.Done()
			_, err := s.EnterRoom(ctx, member, roomID, op())
			results <- err
		}(contender)
	}
	workers.Wait()
	close(results)
	successes := 0
	for err := range results {
		if err == nil {
			successes++
		}
	}
	if successes != 1 {
		t.Fatalf("last seat winners %d", successes)
	}
	if n := scalar(t, p, `SELECT count(*) FROM shared_room_seats WHERE room_id=$1 AND stage='SEATED'`, roomID); n != 3 {
		t.Fatal("seat count", n)
	}
}

func TestI9_8BIllusionRoomExpiryNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	clock := illusionTime(t)
	s := illusionService(t, p, clock, illusionPrivileges{level: 3}, illusionGuildSource{})
	owner, _ := illusionTeamOwner(t, p, server, 10001002)
	created, err := s.CreateRoom(ctx, owner, op())
	if err != nil {
		t.Fatal(err)
	}
	roomID := illusionRoomID(t, created)
	exec(t, p, `UPDATE shared_rooms SET created_at=$2::timestamptz-interval '2 seconds',expires_at=$2::timestamptz-interval '1 second' WHERE room_id=$1`, roomID, clock.at)
	timed := mustTimed(t, op(), clock.at)
	reconciler := appsharedroom.Reconciler{Service: s.Rooms, Server: server, Routes: map[string]string{il.RoomFamily: il.RoomNoticeRoute}}
	if _, err = reconciler.Reconcile(ctx, timed, 100); err != nil {
		t.Fatal(err)
	}
	if status := scalar(t, p, `SELECT count(*) FROM shared_rooms WHERE room_id=$1 AND status='CLOSED'`, roomID); status != 1 {
		t.Fatal("expired room stayed open")
	}
	if _, err = s.EnterRoom(ctx, owner, roomID, op()); err == nil {
		t.Fatal("closed room accepted a join")
	}
}

func TestI9_8BIllusionMemberTeamNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	member, picks := illusionTeamOwner(t, p, server, 10001002, 10001003)
	other, _ := illusionOwner(t, p, rankingServer(t, p))
	clock := illusionTime(t)
	s := illusionService(t, p, clock, illusionPrivileges{level: 3}, illusionGuildSource{})

	revision := installed(t, p)
	content := contentstore.Store{Queryer: p}
	definition, err := content.PetAcquisitionTx(ctx, p, revision, 10010001)
	if err != nil {
		t.Fatal(err)
	}
	grantGenuine(t, p, member, revision, "illusion rank pet", []grant.Line{
		{Kind: grant.StackItem, ItemID: definition.EggItemID, Amount: 1},
		{Kind: grant.ScalarCurrency, ResourceKey: "crystal", Amount: 10000}})
	pets := genuinePetService(p)
	ricky := must(pets.Summon(ctx, member, 10010001, op()))(t, "pet summon")
	must(pets.CleanCD(ctx, member, ricky.PetID, op()))(t, "pet hatch")

	if _, err = s.Start(ctx, member, il.StartRequest{Formation: []int64{picks[0]}, PetID: ricky.PetID}, op()); err != nil {
		t.Fatal(err)
	}
	if _, err = s.Settle(ctx, member, il.ResultRequest{Star: 1, Damage: 100, CostTime: 5, Formation: []int64{picks[0]}, PetID: ricky.PetID}, op()); err != nil {
		t.Fatal(err)
	}
	_, openDay, _, _ := illusionRemaining(t, p, server)
	exec(t, p, `INSERT INTO illusion_attempts(attempt_id,player_id,logical_server_id,open_day,campaign_id,room_id,formation,frozen_at,resolved,damage)
		VALUES('stale-illusion-attempt',$1,$2,$3,$4,NULL,$5,$6,true,0)`,
		int64(member.PlayerID), int64(server), openDay-2, int64(di.FirstCampaignID), fmt.Sprint(picks[1]), clock.at.Unix())

	body, err := s.MemberTeam(ctx, member, member.PlayerID, op())
	if err != nil {
		t.Fatal(err)
	}
	heroes, ok := body["heros"].([]map[string]any)
	if !ok || len(heroes) != 1 || heroes[0]["partner_id"] != picks[0] {
		t.Fatalf("1364 read the wrong occurrence %#v", body)
	}
	pet, ok := body["pet"].(map[string]any)
	if !ok || pet["pet_id"] != ricky.PetID {
		t.Fatalf("1364 pet %#v", body["pet"])
	}
	if _, err = s.MemberTeam(ctx, member, other.PlayerID, op()); !errors.Is(err, di.ErrRefused) {
		t.Fatalf("1364 crossed a logical server: %v", err)
	}
}

// C11: settlement advances the occurrence and the rank board stays frozen on
// the settled day, so 1364 must read the team of that day, not the new campaign.
func TestI9_8BIllusionMemberTeamFrozenBoardNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, partner := illusionOwner(t, p, server)
	clock := illusionTime(t)
	s := illusionService(t, p, clock, illusionPrivileges{level: 3}, illusionGuildSource{})
	if _, err := s.Start(ctx, a, il.StartRequest{Formation: []int64{partner}}, op()); err != nil {
		t.Fatal(err)
	}
	if _, err := s.Settle(ctx, a, il.ResultRequest{Star: 1, Damage: 1000, CostTime: 5, Formation: []int64{partner}}, op()); err != nil {
		t.Fatal(err)
	}
	settledDay := modes.Day(clock.at)
	clock.Set(modes.DayBegins(settledDay).Add(17 * time.Hour))
	if _, err := (il.Reconciler{Service: s}).Reconcile(ctx, mustTimed(t, op(), clock.at), 100); err != nil {
		t.Fatal(err)
	}
	clock.Set(modes.DayBegins(settledDay + di.RestDays).Add(6 * time.Hour))
	body, err := s.MemberTeam(ctx, a, a.PlayerID, op())
	if err != nil {
		t.Fatal(err)
	}
	heroes, ok := body["heros"].([]map[string]any)
	if !ok || len(heroes) != 1 || heroes[0]["partner_id"] != partner {
		t.Fatalf("1364 lost the frozen team on the rest day %#v", body)
	}
}
