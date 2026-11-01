//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"errors"
	"sync"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/sharedroomstore"
	cb "gxb.local/backend/v2/internal/application/combat"
	oc "gxb.local/backend/v2/internal/application/occult"
	appsharedroom "gxb.local/backend/v2/internal/application/sharedroom"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/occult"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// occultTeamCombat counts the per-member settlement fan-out of one team fight.
type occultTeamCombat struct {
	cb.Service
	mu          sync.Mutex
	settlements map[identity.PlayerID]int
}

func (counted *occultTeamCombat) SettleMemberTx(c context.Context, t tx.Tx, request cb.MemberSettleRequest) (cb.MemberSettled, error) {
	settled, err := counted.Service.SettleMemberTx(c, t, request)
	if err != nil {
		return settled, err
	}
	counted.mu.Lock()
	defer counted.mu.Unlock()
	if counted.settlements == nil {
		counted.settlements = map[identity.PlayerID]int{}
	}
	counted.settlements[request.Member]++
	return settled, nil
}

func (counted *occultTeamCombat) settlementCount(member identity.PlayerID) int {
	counted.mu.Lock()
	defer counted.mu.Unlock()
	return counted.settlements[member]
}

// occultTeamOwner adds one real Hero per requested table to a gated owner.
func occultTeamOwner(t *testing.T, p *pg.Pool, server identity.LogicalServerID, tickets int64, tables ...int64) (identity.ActorContext, []int64) {
	t.Helper()
	a, _ := occultOwner(t, p, server, tickets)
	revision := installed(t, p)
	picks := make([]int64, 0, len(tables))
	for _, table := range tables {
		def := collectionResources(t, p, a, revision, table)
		h, err := ownerSummoner(p).SummonNormal(ctx, a, def.Template.TableID, def.Template.FragmentItemID, def.FragmentCount, op())
		if err != nil {
			t.Fatal("team hero", table, err)
		}
		picks = append(picks, h.Ref().PartnerID)
	}
	return a, picks
}

func occultTeamReport(t *testing.T, body map[string]any) string {
	t.Helper()
	report, ok := body["battle_report"].(string)
	if !ok || report == "" {
		t.Fatalf("team report %#v", body)
	}
	return report
}

func occultStoredReport(t *testing.T, body map[string]any) string {
	t.Helper()
	rows, ok := body["battle_report"].([]map[string]any)
	if !ok || len(rows) != 1 {
		t.Fatalf("stored report %#v", body)
	}
	report, _ := rows[0]["report"].(string)
	return report
}

func TestI9_8COccultTeamRoomPolicyNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, _ := occultOwner(t, p, server, 2)
	b, _ := occultOwner(t, p, server, 2)
	c, _ := occultOwner(t, p, server, 2)
	low, _ := occultOwner(t, p, server, 2)
	far, _ := occultOwner(t, p, server, 2)
	exec(t, p, `UPDATE player_directory_profiles SET lev=84 WHERE player_id=$1`, int64(low.PlayerID))
	exec(t, p, `UPDATE player_directory_profiles SET lev=94 WHERE player_id=$1`, int64(far.PlayerID))
	s, _ := occultTestMode(t, p)

	created, err := s.CreateTeam(ctx, a, 2, op())
	if err != nil {
		t.Fatal(err)
	}
	roomID := occultRoomID(t, created)
	if _, err = s.CreateTeam(ctx, a, 2, op()); err != nil {
		t.Fatal("a repeated create of the held chapter answers the room", err)
	}
	if _, err = s.Invite(ctx, a, low.PlayerID, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("level 84 invite", err)
	}
	if _, err = s.Invite(ctx, a, far.PlayerID, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("outside-band invite", err)
	}
	if _, err = s.Invite(ctx, a, b.PlayerID, op()); err != nil {
		t.Fatal("invite", err)
	}
	for _, member := range []identity.ActorContext{b, c} {
		if _, err = s.JoinRoom(ctx, member, roomID, op()); err != nil {
			t.Fatal("join", err)
		}
	}
	if _, err = s.JoinRoom(ctx, low, roomID, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("level 84 join", err)
	}
	if _, err = s.Kick(ctx, a, c.PlayerID, op()); err != nil {
		t.Fatal("kick", err)
	}
	if _, err = s.JoinRoom(ctx, c, roomID, op()); err == nil {
		t.Fatal("kicked player rejoined")
	}
	if _, err = s.ExitRoom(ctx, b, roomID, op()); err != nil {
		t.Fatal("member exit", err)
	}
	if _, err = s.ExitRoom(ctx, a, roomID, op()); err != nil {
		t.Fatal("owner exit", err)
	}
	if status := scalar(t, p, `SELECT count(*) FROM shared_rooms WHERE room_id=$1 AND status='CLOSED'`, roomID); status != 1 {
		t.Fatal("owner exit did not close the room")
	}
}

func TestI9_8COccultTeamInviteQuitNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, _ := occultOwner(t, p, server, 1)
	b, _ := occultOwner(t, p, server, 1)
	c, _ := occultOwner(t, p, server, 1)
	s, _ := occultTestMode(t, p)
	created, err := s.CreateTeam(ctx, a, 2, op())
	if err != nil {
		t.Fatal(err)
	}
	roomID := occultRoomID(t, created)
	for _, member := range []identity.ActorContext{b, c} {
		if _, err = s.JoinRoom(ctx, member, roomID, op()); err != nil {
			t.Fatal(err)
		}
	}
	if _, err = s.StartChallenge(ctx, a, op()); err != nil {
		t.Fatal(err)
	}
	invited, err := s.TeamInvite(ctx, a, 20002, 1, op())
	if err != nil || invited["is_auto_pass"] == true {
		t.Fatalf("team invite %#v %v", invited, err)
	}
	if _, err = s.TeamQuit(ctx, a, 20002, 1, op()); err != nil {
		t.Fatal("quit", err)
	}
	if _, err = s.TeamInvite(ctx, a, 20002, 1, op()); err != nil {
		t.Fatal("the stage was not freed after a quit", err)
	}
}

func TestI9_8COccultTeamAllOrNoneTicketsNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, _ := occultOwner(t, p, server, 2)
	b, _ := occultOwner(t, p, server, 2)
	c, _ := occultOwner(t, p, server, 0)
	s, _ := occultTestMode(t, p)
	created, err := s.CreateTeam(ctx, a, 2, op())
	if err != nil {
		t.Fatal(err)
	}
	roomID := occultRoomID(t, created)
	for _, member := range []identity.ActorContext{b, c} {
		if _, err = s.JoinRoom(ctx, member, roomID, op()); err != nil {
			t.Fatal(err)
		}
	}
	if _, err = s.StartChallenge(ctx, a, op()); err == nil {
		t.Fatal("a member short of tickets did not refuse the start")
	}
	for _, member := range []identity.ActorContext{a, b} {
		if got := occultTickets(t, p, member.PlayerID); got != 2 {
			t.Fatalf("all-or-none rolled back member %d to %d", member.PlayerID, got)
		}
	}
	room := occultRoomState(t, p, roomID)
	if room.Started() {
		t.Fatal("a refused start left the room started")
	}
	occultSetTickets(t, p, c.PlayerID, 1)
	exec(t, p, `UPDATE player_directory_profiles SET lev=84 WHERE player_id=$1`, int64(c.PlayerID))
	if _, err = s.StartChallenge(ctx, a, op()); err == nil {
		t.Fatal("a member below level 85 did not refuse the start")
	}
	exec(t, p, `UPDATE player_directory_profiles SET lev=100 WHERE player_id=$1`, int64(c.PlayerID))
	if _, err = s.StartChallenge(ctx, a, op()); err != nil {
		t.Fatal("start after the tickets were paid", err)
	}
	for _, member := range []identity.ActorContext{a, b} {
		if got := occultTickets(t, p, member.PlayerID); got != 1 {
			t.Fatalf("member %d ticket after start %d", member.PlayerID, got)
		}
	}
	if got := occultTickets(t, p, c.PlayerID); got != 0 {
		t.Fatalf("short member ticket after start %d", got)
	}
}

func TestI9_8COccultTeamFightNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, aPicks := occultTeamOwner(t, p, server, 2, 10001002)
	b, bPicks := occultTeamOwner(t, p, server, 2, 10001003)
	c, cPicks := occultTeamOwner(t, p, server, 2, 10001004)
	nonMember, _ := occultOwner(t, p, server, 0)
	otherServer, _ := occultOwner(t, p, rankingServer(t, p), 0)
	s, _ := occultTestMode(t, p)
	team := &occultTeamCombat{Service: s.Combat.(cb.Service)}
	s.Combat = team

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
			t.Fatal("select", err)
		}
	}
	selected, err := s.Info(ctx, a, op())
	if err != nil {
		t.Fatal(err)
	}
	formations := selected["sub_campaign_info"].(map[string]any)["team_fight_infos"].(map[string]any)
	for member, raw := range formations {
		entry := raw.(map[string]any)
		if _, hasPet := entry["pet"]; hasPet {
			t.Fatalf("member %s without a pet carries a pet row %#v", member, entry)
		}
		if entry["is_prepare"] != int64(0) || len(entry["formation"].([]any)) != 2 {
			t.Fatalf("member %s team_fight_info %#v", member, entry)
		}
	}
	for _, member := range []identity.ActorContext{a, b, c} {
		if _, err = s.TeamPrepare(ctx, member, 20002, 1, op()); err != nil {
			t.Fatal("prepare", err)
		}
	}
	fight, err := s.StartTeamFight(ctx, a, 20002, 1, op())
	if err != nil {
		t.Fatal("start team fight", err)
	}
	report := occultTeamReport(t, fight)
	var decoded map[string]any
	if json.Unmarshal([]byte(report), &decoded) != nil || decoded["star"] == nil || decoded["fighter"] == nil {
		t.Fatalf("report shape %s", report)
	}
	state := occultRoomState(t, p, roomID)
	if state.Team == nil || state.Team.ReportKey == "" {
		t.Fatalf("the room did not freeze the report %+v", state.Team)
	}
	for _, member := range []identity.ActorContext{a, b, c} {
		if count := team.settlementCount(member.PlayerID); count != 1 {
			t.Fatalf("member %d settled %d times", member.PlayerID, count)
		}
	}
	stored, err := s.TeamReport(ctx, b, state.Team.ReportKey, op())
	if err != nil || occultStoredReport(t, stored) != report {
		t.Fatalf("2382 replay %v", err)
	}
	if _, err = s.TeamReport(ctx, nonMember, state.Team.ReportKey, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("a non-member read the report", err)
	}
	if _, err = s.TeamReport(ctx, otherServer, state.Team.ReportKey, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("another logical server read the report", err)
	}
	replay, err := s.StartTeamFight(ctx, a, 20002, 1, op())
	if err != nil || occultTeamReport(t, replay) != report {
		t.Fatalf("2377 replay %v", err)
	}
	for _, member := range []identity.ActorContext{a, b, c} {
		if count := team.settlementCount(member.PlayerID); count != 1 {
			t.Fatalf("replay settled member %d %d times", member.PlayerID, count)
		}
	}
}

// A lost team fight saves the enemies' and the girls' end states (client rule 6,
// the user's memory of the original server): the next battle starts from them and
// a dead girl cannot be sent again.
func TestI9_8COccultTeamLossKeepsStatusNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, aPicks := occultTeamOwner(t, p, server, 2, 10001002, 10001005)
	b, bPicks := occultTeamOwner(t, p, server, 2, 10001003, 10001006)
	c, cPicks := occultTeamOwner(t, p, server, 2, 10001004, 10001007)
	s, clock := occultTestMode(t, p)
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
	type fighterRow struct {
		Initial map[string]any `json:"health_status"`
		Hero    struct {
			TableID int64 `json:"table_id"`
		} `json:"hero"`
	}
	type reportBody struct {
		Star    int64                 `json:"star"`
		Fighter map[string]fighterRow `json:"fighter"`
	}
	members := []identity.ActorContext{a, b, c}
	picks := [][]int64{aPicks, bPicks, cPicks}
	invite := func() {
		t.Helper()
		clock.Set(clock.at.Add(2 * time.Second))
		if _, err := s.TeamInvite(ctx, a, 20002, 1, op()); err != nil {
			t.Fatal("invite fight", err)
		}
		for _, member := range members[1:] {
			if _, err := s.TeamAccept(ctx, member, 20002, 1, true, op()); err != nil {
				t.Fatal("accept", err)
			}
		}
	}
	fight := func(pick int) reportBody {
		t.Helper()
		invite()
		for index, member := range members {
			request := oc.FormationRequest{CampaignID: 20002, SubID: 1, PartnerID: picks[index][pick], Position: 1}
			if _, err := s.TeamSelect(ctx, member, request, op()); err != nil {
				t.Fatal("select", err)
			}
			if _, err := s.TeamPrepare(ctx, member, 20002, 1, op()); err != nil {
				t.Fatal("prepare", err)
			}
		}
		body, err := s.StartTeamFight(ctx, a, 20002, 1, op())
		if err != nil {
			t.Fatal("start team fight", err)
		}
		var report reportBody
		if err = json.Unmarshal([]byte(occultTeamReport(t, body)), &report); err != nil {
			t.Fatal(err)
		}
		return report
	}
	enemies := func() map[string]d.EnemyStatus {
		t.Helper()
		return occultRoomState(t, p, roomID).Stages[keyOf(20002)][0].Enemies
	}
	if first := fight(0); first.Star != 0 {
		t.Fatalf("three level-one girls must lose this stage: star %d", first.Star)
	}
	lost := enemies()
	if len(lost) != 5 {
		t.Fatalf("a loss saves every monster: %+v", lost)
	}
	state := occultRoomState(t, p, roomID)
	for index, member := range members {
		status, recorded := state.Status(int64(member.PlayerID), picks[index][0])
		if !recorded || status.HP != 0 || status.LimitHP <= 0 {
			t.Fatalf("member %d girl %+v recorded %v", index, status, recorded)
		}
	}
	invite()
	if _, err = s.TeamSelect(ctx, a, oc.FormationRequest{CampaignID: 20002, SubID: 1, PartnerID: aPicks[0], Position: 1}, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("a dead girl was sent again", err)
	}
	if _, err = s.TeamQuit(ctx, a, 20002, 1, op()); err != nil {
		t.Fatal("quit", err)
	}
	second := fight(1)
	carried := 0
	for key, row := range second.Fighter {
		saved, isSaved := lost[keyOf(row.Hero.TableID)]
		if key[0] != 'B' || !isSaved {
			continue
		}
		if row.Initial["hp"] != saved.HP || row.Initial["mp"] != saved.MP {
			t.Fatalf("monster %s started at %v, saved %+v", key, row.Initial, saved)
		}
		carried++
	}
	if carried != 5 {
		t.Fatalf("carried %d monsters of 5: %+v", carried, lost)
	}
	for table, after := range enemies() {
		if after.HP > lost[table].HP {
			t.Fatalf("monster %s healed %v -> %v", table, lost[table].HP, after.HP)
		}
	}
}

func TestI9_8COccultTeamConcurrentJoinNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	owner, _ := occultOwner(t, p, server, 1)
	seated, _ := occultOwner(t, p, server, 1)
	first, _ := occultOwner(t, p, server, 1)
	second, _ := occultOwner(t, p, server, 1)
	s, _ := occultTestMode(t, p)
	created, err := s.CreateTeam(ctx, owner, 2, op())
	if err != nil {
		t.Fatal(err)
	}
	roomID := occultRoomID(t, created)
	if _, err = s.JoinRoom(ctx, seated, roomID, op()); err != nil {
		t.Fatal(err)
	}
	var workers sync.WaitGroup
	results := make(chan error, 2)
	for _, contender := range []identity.ActorContext{first, second} {
		workers.Add(1)
		go func(member identity.ActorContext) {
			defer workers.Done()
			_, err := s.JoinRoom(ctx, member, roomID, op())
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

func TestI9_8COccultTeamRoomExpiryNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	owner, _ := occultOwner(t, p, server, 1)
	visitor, _ := occultOwner(t, p, server, 1)
	s, clock := occultTestMode(t, p)
	created, err := s.CreateTeam(ctx, owner, 2, op())
	if err != nil {
		t.Fatal(err)
	}
	roomID := occultRoomID(t, created)
	exec(t, p, `UPDATE shared_rooms SET created_at=$2::timestamptz-interval '2 seconds',expires_at=$2::timestamptz-interval '1 second' WHERE room_id=$1`, roomID, clock.at)
	if _, err = (appsharedroom.Reconciler{Service: s.Rooms, Routes: map[string]string{oc.RoomFamily: oc.RoomNoticeRoute}}).Reconcile(ctx, mustTimed(t, op(), clock.at), 100); !errors.Is(err, appsharedroom.ErrUnavailable) {
		t.Fatalf("an unscoped reconciler was allowed: %v", err)
	}
	reconciler := appsharedroom.Reconciler{Service: s.Rooms, AllServers: true, Routes: map[string]string{oc.RoomFamily: oc.RoomNoticeRoute}}
	if _, err = reconciler.Reconcile(ctx, mustTimed(t, op(), clock.at), 100); err != nil {
		t.Fatal(err)
	}
	if status := scalar(t, p, `SELECT count(*) FROM shared_rooms WHERE room_id=$1 AND status='CLOSED'`, roomID); status != 1 {
		t.Fatal("expired room stayed open")
	}
	if _, err = s.JoinRoom(ctx, visitor, roomID, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("closed room accepted a join", err)
	}
}

func TestI9_8COccultTeamReportRetentionNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	owner, _ := occultOwner(t, p, server, 1)
	s, clock := occultTestMode(t, p)
	if _, err := s.CreateTeam(ctx, owner, 2, op()); err != nil {
		t.Fatal(err)
	}
	room, found, err := (sharedroomstore.Store{}).ReadPlayerRoomTx(ctx, p, owner.PlayerID, oc.RoomFamily, oc.RoomSlot)
	if err != nil || !found {
		t.Fatal(found, err)
	}
	key := "occult-native-retention"
	exec(t, p, `DELETE FROM occult_reports WHERE report_id=$1`, key)
	if err = (occultstoreForTest{}).insertReport(ctx, p, key, int64(server), room.ID, int64(owner.PlayerID), clock.at); err != nil {
		t.Fatal(err)
	}
	if _, err = s.TeamReport(ctx, owner, key, op()); err != nil {
		t.Fatal("fresh report", err)
	}
	clock.Set(clock.at.Add(8 * 24 * time.Hour))
	if _, err = s.TeamReport(ctx, owner, key, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("an expired report was served", err)
	}
}

// occultstoreForTest inserts a report row directly; the fight path stores its
// own report in TestI9_8COccultTeamFightNative.
type occultstoreForTest struct{}

func (occultstoreForTest) insertReport(c context.Context, p *pg.Pool, key string, server, room int64, member int64, at time.Time) error {
	if _, err := p.Raw().Exec(c, `INSERT INTO occult_runs(room_id,logical_server_id,chapter_id,campaign_type,started_at)VALUES($1,$2,2,1,$3) ON CONFLICT(room_id)DO NOTHING`, room, server, at); err != nil {
		return err
	}
	_, err := p.Raw().Exec(c, `INSERT INTO occult_reports(report_id,logical_server_id,room_id,member_ids,content,created_at,expires_at)
		VALUES($1,$2,$3,ARRAY[$4]::bigint[],'{"battle_report":"{}","awards":{}}'::jsonb,$5,$5::timestamptz+interval '7 days')`, key, server, room, member, at)
	return err
}
