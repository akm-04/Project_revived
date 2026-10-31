//go:build postgres

package playerdisplay_test

import (
	"context"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/illusionstore"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/sharedroomstore"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	il "gxb.local/backend/v2/internal/application/illusion"
	"gxb.local/backend/v2/internal/application/publicstats"
	appsharedroom "gxb.local/backend/v2/internal/application/sharedroom"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/domain/statrules"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type illusionPrivileges struct{ level int64 }

func (p illusionPrivileges) SnapshotTx(context.Context, tx.Queryer, identity.PlayerID, time.Time) (i5.PrivilegeSnapshot, error) {
	return i5.PrivilegeSnapshot{ProviderRevision: "i9-8b-native", VIPLevel: p.level, SkillPointNaturalCap: 10}, nil
}

// illusionStatInputs pins the team power floor only; the Combat START still
// materializes the same heroes through its real raw-birth pipeline.
type illusionStatInputs struct{}

func (illusionStatInputs) HeroTx(context.Context, ca.CoherentReadScope, character.HeroRef, publicstats.View) (publicstats.Result, error) {
	return publicstats.Result{Stats: statrules.Result{Force: 1000}}, nil
}

type illusionGuildSource struct {
	byServer map[int64][]il.GuildSummary
}

func (g illusionGuildSource) GuildSummaries(_ context.Context, server identity.LogicalServerID) ([]il.GuildSummary, error) {
	return g.byServer[int64(server)], nil
}

func illusionService(t *testing.T, p *pg.Pool, clock gen.TimeAuthority, privileges i5.PrivilegeSnapshotProvider, guilds il.Guilds) il.Mode {
	t.Helper()
	fight := combatService(t, p)
	values := i5store.Store{Queryer: p}
	content := contentstore.Store{Queryer: p}
	runner := tx.Runner{DB: p}
	timed := gen.TimedRunner{Binder: gen.Binder{Time: clock}, Runner: runner}
	rooms := appsharedroom.Service{Timed: timed, Fresh: p, Store: sharedroomstore.Store{}, Fence: values, Players: i4store.PlayerRootLocker{}}
	fight.Inputs.Rooms = appsharedroom.AdmissionBinding{Store: sharedroomstore.Store{}, Family: il.RoomFamily, Slot: il.RoomSlot}
	return il.Mode{Timed: timed, Fresh: p, Store: illusionstore.Store{}, Content: content, Fence: values, Players: i4store.PlayerRootLocker{},
		Functions: values, Directory: i4store.PlayerDirectoryReader{}, Heroes: fight.Inputs.Heroes, Pets: fight.Inputs.Pets, Stats: illusionStatInputs{},
		Rooms: rooms, RoomStore: sharedroomstore.Store{}, Combat: fight, Privileges: privileges,
		Costs: i5.MaterialCostDebiter{Store: values, Content: content}, Facts: i5.ObjectiveFacts{Owner: compositeI5(p), Open: values},
		Guilds: guilds, Mail: i5.SettlementMail{Store: values}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}

// illusionOwner is a level-100 genuine combat owner with function 43 open and a
// real Hero, so every solo and team path runs against production providers.
func illusionOwner(t *testing.T, p *pg.Pool, server identity.LogicalServerID) (identity.ActorContext, int64) {
	t.Helper()
	a, _, ref := combatOwner(t, p, server)
	revision := installed(t, p)
	exec(t, p, `INSERT INTO player_function_eligibility(player_id,function_id,content_revision,source_fact_key,eligible_at)VALUES($1,43,$2,'function.lua:43:1|65',clock_timestamp()-interval '1 minute')
		ON CONFLICT(player_id,function_id)DO NOTHING`, int64(a.PlayerID), revision)
	exec(t, p, `UPDATE player_directory_profiles SET lev=100 WHERE player_id=$1`, int64(a.PlayerID))
	exec(t, p, `INSERT INTO player_pet_roots(player_id,next_pet_id,state_version,created_at,updated_at)VALUES($1,1,1,clock_timestamp(),clock_timestamp())
		ON CONFLICT(player_id)DO NOTHING`, int64(a.PlayerID))
	return a, ref.PartnerID
}

// illusionTeamOwner adds the requested real Hero to an owner. Table ids differ
// per team slot because C5 rejects duplicate hero table ids across the team.
func illusionTeamOwner(t *testing.T, p *pg.Pool, server identity.LogicalServerID, tables ...int64) (identity.ActorContext, []int64) {
	t.Helper()
	a, _ := illusionOwner(t, p, server)
	revision := installed(t, p)
	partners := make([]int64, 0, len(tables))
	for _, table := range tables {
		def := collectionResources(t, p, a, revision, table)
		h, err := ownerSummoner(p).SummonNormal(ctx, a, def.Template.TableID, def.Template.FragmentItemID, def.FragmentCount, op())
		if err != nil {
			t.Fatal("team hero", table, err)
		}
		partners = append(partners, h.Ref().PartnerID)
	}
	return a, partners
}

// illusionTime is a fixed 11:00 GMT+8 instant on a future modes.Day, inside the
// 08:00-21:58 opening window and before the 22:00 settlement.
func illusionTime(t *testing.T) *leagueClock {
	t.Helper()
	day := modes.Day(time.Now().UTC().Add(24 * time.Hour))
	return &leagueClock{at: modes.DayBegins(day).Add(6 * time.Hour)}
}

func illusionRemaining(t *testing.T, p *pg.Pool, server identity.LogicalServerID) (campaign, openDay, settled, poolHurt int64) {
	t.Helper()
	if err := p.QueryRow(ctx, `SELECT campaign_id,open_day,settled_open_day,pool_hurt FROM illusion_occurrences WHERE logical_server_id=$1`, int64(server)).
		Scan(&campaign, &openDay, &settled, &poolHurt); err != nil {
		t.Fatal(err)
	}
	return campaign, openDay, settled, poolHurt
}

func TestI9_8BIllusionInfoBuyNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, _ := illusionOwner(t, p, server)
	clock := illusionTime(t)
	s := illusionService(t, p, clock, illusionPrivileges{level: 3}, illusionGuildSource{})

	info, err := s.Info(ctx, a, op())
	if err != nil {
		t.Fatal(err)
	}
	paradise := info["paradise_info"].(map[string]any)
	if paradise["paradise_id"] != int64(d.FirstCampaignID) || paradise["count"] != int64(0) || info["challenge_times"] != int64(d.FreeChances) {
		t.Fatalf("fresh info %#v", info)
	}
	if _, err = s.Buy(ctx, a, op()); err == nil {
		t.Fatal("buy without crystal succeeded")
	}
	exec(t, p, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'crystal',1000,1,clock_timestamp())
		ON CONFLICT(player_id,resource_key)DO UPDATE SET amount=1000,state_version=player_currency_balances.state_version+1`, int64(a.PlayerID))
	bought, err := s.Buy(ctx, a, op())
	if err != nil || bought["challenge_times"] != int64(d.FreeChances+d.ChancesPerBuy) || bought["buy_times"] != int64(1) {
		t.Fatalf("buy %#v %v", bought, err)
	}
	if scalar(t, p, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID)) != 950 {
		t.Fatal("buy did not debit refresh_cost entry 1")
	}
	if _, err = s.Buy(ctx, a, op()); err == nil {
		t.Fatal("buy past the VIP cap succeeded")
	}
}

func TestI9_8BIllusionStartSettleDuplicateNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, partner := illusionOwner(t, p, server)
	clock := illusionTime(t)
	s := illusionService(t, p, clock, illusionPrivileges{level: 3}, illusionGuildSource{})
	formation := []int64{partner}

	if _, err := s.Start(ctx, a, il.StartRequest{Formation: []int64{partner, partner}}, op()); err == nil {
		t.Fatal("duplicate formation accepted")
	}
	if _, err := s.Start(ctx, a, il.StartRequest{Formation: formation}, op()); err != nil {
		t.Fatal(err)
	}
	if n := scalar(t, p, `SELECT count(*) FROM illusion_attempts WHERE player_id=$1 AND NOT resolved`, int64(a.PlayerID)); n != 1 {
		t.Fatal("attempt row", n)
	}
	if n := scalar(t, p, `SELECT chances FROM illusion_players WHERE player_id=$1`, int64(a.PlayerID)); n != d.FreeChances-1 {
		t.Fatal("chance not consumed", n)
	}
	settled, err := s.Settle(ctx, a, il.ResultRequest{Star: 1, Damage: 500, CostTime: 10, Formation: formation}, op())
	if err != nil || settled.Duplicate || settled.Body["rank"] != int64(1) || settled.Body["now_hurt"] != int64(500) || settled.Body["highest_hurt"] != int64(500) {
		t.Fatalf("settle %+v %v", settled, err)
	}
	duplicate, err := s.Settle(ctx, a, il.ResultRequest{Star: 1, Damage: 900, CostTime: 10, Formation: formation}, op())
	if err != nil || !duplicate.Duplicate || duplicate.Body["now_hurt"] != int64(500) || duplicate.Body["highest_hurt"] != int64(500) {
		t.Fatalf("duplicate %+v %v", duplicate, err)
	}
	if _, _, _, hurt := illusionRemaining(t, p, server); hurt != 500 {
		t.Fatal("duplicate settlement added pool damage", hurt)
	}
	if n := scalar(t, p, `SELECT best_hit FROM illusion_players WHERE player_id=$1`, int64(a.PlayerID)); n != 500 {
		t.Fatal("duplicate settlement changed the best hit", n)
	}
}

func TestI9_8BIllusionAbandonedStartNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, partner := illusionOwner(t, p, server)
	clock := illusionTime(t)
	s := illusionService(t, p, clock, illusionPrivileges{level: 3}, illusionGuildSource{})
	formation := []int64{partner}
	for range 2 {
		if _, err := s.Start(ctx, a, il.StartRequest{Formation: formation}, op()); err != nil {
			t.Fatal("start after an abandoned attempt", err)
		}
	}
	if n := scalar(t, p, `SELECT count(*) FROM illusion_attempts WHERE player_id=$1 AND NOT resolved`, int64(a.PlayerID)); n != 1 {
		t.Fatal("abandoned attempt kept open", n)
	}
	if n := scalar(t, p, `SELECT chances FROM illusion_players WHERE player_id=$1`, int64(a.PlayerID)); n != d.FreeChances-2 {
		t.Fatal("abandoned starts did not stay spent", n)
	}
	if _, err := s.Settle(ctx, a, il.ResultRequest{Star: 1, Damage: 700, CostTime: 5, Formation: formation}, op()); err != nil {
		t.Fatal("settle after abandoned start", err)
	}
}

func TestI9_8BIllusionClosedWindowAndRestDayNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, partner := illusionOwner(t, p, server)
	clock := illusionTime(t)
	s := illusionService(t, p, clock, illusionPrivileges{level: 3}, illusionGuildSource{})
	formation := []int64{partner}
	if _, err := s.Start(ctx, a, il.StartRequest{Formation: formation}, op()); err != nil {
		t.Fatal(err)
	}
	day := modes.Day(clock.at)
	clock.Set(modes.DayBegins(day).Add(17 * time.Hour)) // 22:00 GMT+8, closed and settlement
	if _, err := s.Start(ctx, a, il.StartRequest{Formation: formation}, op()); err == nil {
		t.Fatal("start inside the closed window")
	}
	clock.Set(modes.DayBegins(day + d.RestDays).Add(6 * time.Hour)) // rest day 11:00
	info, err := s.Info(ctx, a, op())
	if err != nil {
		t.Fatal(err)
	}
	if info["paradise_info"].(map[string]any)["count"] != int64(1) {
		t.Fatal("rest day reported open")
	}
	if _, err := s.Start(ctx, a, il.StartRequest{Formation: formation}, op()); err == nil {
		t.Fatal("start on the rest day")
	}
}

func TestI9_8BIllusionLateResultFrozenOccurrenceNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, partner := illusionOwner(t, p, server)
	clock := illusionTime(t)
	clock.Set(modes.DayBegins(modes.Day(clock.at)).Add(16*time.Hour + 30*time.Minute)) // 21:30 GMT+8
	s := illusionService(t, p, clock, illusionPrivileges{level: 3}, illusionGuildSource{})
	formation := []int64{partner}
	if _, err := s.Start(ctx, a, il.StartRequest{Formation: formation}, op()); err != nil {
		t.Fatal(err)
	}
	_, openDay, _, _ := illusionRemaining(t, p, server)
	clock.Set(modes.DayBegins(modes.Day(clock.at)).Add(17 * time.Hour))
	if _, err := (il.Reconciler{Service: s}).Reconcile(ctx, mustTimed(t, op(), clock.at), 100); err != nil {
		t.Fatal(err)
	}
	if campaign, next, _, _ := illusionRemaining(t, p, server); campaign != d.FirstCampaignID+1 || next != openDay+d.CycleDays {
		t.Fatalf("occurrence did not advance campaign=%d day=%d", campaign, next)
	}
	clock.Set(clock.at.Add(time.Minute))
	settled, err := s.Settle(ctx, a, il.ResultRequest{Star: 1, Damage: 700, CostTime: 5, Formation: formation}, op())
	if err != nil || settled.Duplicate || settled.Body["now_hurt"] != int64(700) {
		t.Fatalf("late settle %+v %v", settled, err)
	}
	if n := scalar(t, p, `SELECT hurt FROM illusion_occurrence_results WHERE logical_server_id=$1 AND open_day=$2 AND player_id=$3`, int64(server), openDay, int64(a.PlayerID)); n != 700 {
		t.Fatal("late result missed its frozen occurrence", n)
	}
	if _, _, _, hurt := illusionRemaining(t, p, server); hurt != 0 {
		t.Fatal("late result credited the live occurrence", hurt)
	}
}

func TestI9_8BIllusionSettlementOnceTwoServersNative(t *testing.T) {
	p := pool(t)
	first, second := rankingServer(t, p), rankingServer(t, p)
	a, aPartner := illusionOwner(t, p, first)
	b, bPartner := illusionOwner(t, p, second)
	clock := illusionTime(t)
	guilds := illusionGuildSource{}
	s := illusionService(t, p, clock, illusionPrivileges{level: 3}, guilds)
	for _, entry := range []struct {
		actor   identity.ActorContext
		partner int64
	}{
		{a, aPartner}, {b, bPartner},
	} {
		if _, err := s.Start(ctx, entry.actor, il.StartRequest{Formation: []int64{entry.partner}}, op()); err != nil {
			t.Fatal(err)
		}
		if _, err := s.Settle(ctx, entry.actor, il.ResultRequest{Star: 1, Damage: 1000, CostTime: 10, Formation: []int64{entry.partner}}, op()); err != nil {
			t.Fatal(err)
		}
	}
	exec(t, p, `UPDATE illusion_occurrences SET pool_hurt=pool_hp WHERE logical_server_id IN($1,$2)`, int64(first), int64(second))
	clock.Set(modes.DayBegins(modes.Day(clock.at)).Add(17 * time.Hour))
	timed := mustTimed(t, op(), clock.at)
	if out, err := (il.Reconciler{Service: s}).Reconcile(ctx, timed, 100); err != nil || out.Settled != 2 {
		t.Fatalf("reconcile %+v %v", out, err)
	}
	for _, entry := range []struct {
		server identity.LogicalServerID
		actor  identity.ActorContext
	}{
		{first, a}, {second, b},
	} {
		if n := scalar(t, p, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='ILLUSION_SETTLEMENT'`, int64(entry.actor.PlayerID)); n != 1 {
			t.Fatalf("server %d mail count %d", entry.server, n)
		}
		campaign, openDay, settled, _ := illusionRemaining(t, p, entry.server)
		if campaign != d.FirstCampaignID+1 || settled != openDay-d.CycleDays {
			t.Fatalf("server %d occurrence campaign=%d open=%d settled=%d", entry.server, campaign, openDay, settled)
		}
	}
	// Rank 1: person band coin 1600, gold 20% of 1000, the two kill-bonus item
	// rows, and no guild band from the empty guild source.
	lines := scalar(t, p, `SELECT count(*) FROM mail_attachments a JOIN mail_records m USING(mail_uuid) WHERE m.recipient_player_id=$1`, int64(a.PlayerID))
	if lines != int64(4) {
		t.Fatal("settlement line count", lines)
	}
	if n := scalar(t, p, `SELECT amount FROM mail_attachments a JOIN mail_records m USING(mail_uuid) WHERE m.recipient_player_id=$1 AND a.resource_key='paradise_coin'`, int64(a.PlayerID)); n != 1600 {
		t.Fatal("rank band coin", n)
	}
	if n := scalar(t, p, `SELECT amount FROM mail_attachments a JOIN mail_records m USING(mail_uuid) WHERE m.recipient_player_id=$1 AND a.resource_key='mana'`, int64(a.PlayerID)); n != 200 {
		t.Fatal("gold percent", n)
	}
	// A repeated reconcile is a no-op on both servers and mails nothing again.
	out, err := (il.Reconciler{Service: s}).Reconcile(ctx, timed, 100)
	if err != nil || out.Settled != 0 {
		t.Fatalf("second reconcile %+v %v", out, err)
	}
	if n := scalar(t, p, `SELECT count(*) FROM mail_records WHERE source_kind='ILLUSION_SETTLEMENT' AND recipient_player_id IN($1,$2)`, int64(a.PlayerID), int64(b.PlayerID)); n != 2 {
		t.Fatal("settlement mailed twice", n)
	}
}

func TestI9_8BIllusionSettlementCommunityBandNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, partner := illusionOwner(t, p, server)
	b, _ := illusionOwner(t, p, server)
	clock := illusionTime(t)
	guilds := illusionGuildSource{byServer: map[int64][]il.GuildSummary{int64(server): {{ID: 9001, Name: "Band", Members: []identity.PlayerID{a.PlayerID, b.PlayerID}}}}}
	s := illusionService(t, p, clock, illusionPrivileges{level: 3}, guilds)
	if _, err := s.Start(ctx, a, il.StartRequest{Formation: []int64{partner}}, op()); err != nil {
		t.Fatal(err)
	}
	if _, err := s.Settle(ctx, a, il.ResultRequest{Star: 1, Damage: 1000, CostTime: 10, Formation: []int64{partner}}, op()); err != nil {
		t.Fatal(err)
	}
	clock.Set(modes.DayBegins(modes.Day(clock.at)).Add(17 * time.Hour))
	if _, err := (il.Reconciler{Service: s}).Reconcile(ctx, mustTimed(t, op(), clock.at), 100); err != nil {
		t.Fatal(err)
	}
	if n := scalar(t, p, `SELECT amount FROM mail_attachments a JOIN mail_records m USING(mail_uuid) WHERE m.recipient_player_id=$1 AND a.resource_key='guild_coin'`, int64(a.PlayerID)); n != 1000 {
		t.Fatal("community band guild coin for the participant", n)
	}
	if n := scalar(t, p, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='ILLUSION_SETTLEMENT'`, int64(b.PlayerID)); n != 1 {
		t.Fatal("non-participating guild member did not receive the community band", n)
	}
	if n := scalar(t, p, `SELECT count(*) FROM mail_attachments a JOIN mail_records m USING(mail_uuid) WHERE m.recipient_player_id=$1`, int64(b.PlayerID)); n != 1 {
		t.Fatal("guild-only mail carried other rewards", n)
	}
}

func TestI9_8BIllusionCycleCampaignIDNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, partner := illusionOwner(t, p, server)
	clock := illusionTime(t)
	s := illusionService(t, p, clock, illusionPrivileges{level: 3}, illusionGuildSource{})
	info, err := s.Info(ctx, a, op())
	if err != nil {
		t.Fatal(err)
	}
	if id := info["paradise_info"].(map[string]any)["paradise_id"]; id != int64(d.FirstCampaignID) {
		t.Fatalf("fresh campaign id %v", id)
	}
	if _, err = s.Start(ctx, a, il.StartRequest{Formation: []int64{partner}}, op()); err != nil {
		t.Fatal(err)
	}
	clock.Set(modes.DayBegins(modes.Day(clock.at)).Add(17 * time.Hour))
	if _, err = (il.Reconciler{Service: s}).Reconcile(ctx, mustTimed(t, op(), clock.at), 100); err != nil {
		t.Fatal(err)
	}
	clock.Set(modes.DayBegins(modes.Day(clock.at) + d.CycleDays).Add(6 * time.Hour))
	info, err = s.Info(ctx, a, op())
	if err != nil {
		t.Fatal(err)
	}
	if id := info["paradise_info"].(map[string]any)["paradise_id"]; id != int64(d.FirstCampaignID)+1 {
		t.Fatalf("next campaign id %v", id)
	}
}

func mustTimed(t *testing.T, op operation.Context, at time.Time) gen.TimedOperation {
	t.Helper()
	timed, err := gen.NewTimedOperation(op, at)
	if err != nil {
		t.Fatal(err)
	}
	return timed
}

// Downtime past the next opening delays the settlement; it neither skips the
// rewards nor lets anyone fight the stale boss meanwhile.
func TestI9_8BIllusionSettlementSurvivesDowntimeNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, partner := illusionOwner(t, p, server)
	clock := illusionTime(t)
	s := illusionService(t, p, clock, illusionPrivileges{level: 3}, illusionGuildSource{})
	formation := []int64{partner}
	if _, err := s.Start(ctx, a, il.StartRequest{Formation: formation}, op()); err != nil {
		t.Fatal(err)
	}
	if _, err := s.Settle(ctx, a, il.ResultRequest{Star: 1, Damage: 1000, CostTime: 10, Formation: formation}, op()); err != nil {
		t.Fatal(err)
	}
	_, openDay, _, _ := illusionRemaining(t, p, server)
	clock.Set(modes.DayBegins(openDay + 3).Add(4 * time.Hour))
	exec(t, p, `UPDATE account_sessions SET absolute_expires_at=$2,idle_timeout_seconds=NULL WHERE session_id=$1`, a.SessionID.UUID().String(), clock.at.Add(24*time.Hour))
	if _, err := s.Start(ctx, a, il.StartRequest{Formation: formation}, op()); err == nil {
		t.Fatal("a start reached the unsettled occurrence")
	}
	timed := mustTimed(t, op(), clock.at)
	if _, err := (il.Reconciler{Service: s}).Reconcile(ctx, timed, 100); err != nil {
		t.Fatal(err)
	}
	if n := scalar(t, p, `SELECT count(*) FROM mail_records WHERE source_kind='ILLUSION_SETTLEMENT' AND recipient_player_id=$1`, int64(a.PlayerID)); n != 1 {
		t.Fatal("downtime lost the settlement", n)
	}
	if campaign, next, _, _ := illusionRemaining(t, p, server); campaign != d.FirstCampaignID+1 || next != openDay+d.CycleDays {
		t.Fatalf("occurrence did not advance campaign=%d day=%d", campaign, next)
	}
}
