//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	"sync"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/worldbossstore"
	appcampaign "gxb.local/backend/v2/internal/application/campaign"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	app "gxb.local/backend/v2/internal/application/worldboss"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/domain/objective"
	d "gxb.local/backend/v2/internal/domain/worldboss"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func worldBossService(t *testing.T, p *pg.Pool, clock gen.TimeAuthority) app.Mode {
	t.Helper()
	fight := combatService(t, p)
	values, content := i5store.Store{Queryer: p}, contentstore.Store{Queryer: p}
	return app.Mode{Timed: gen.TimedRunner{Binder: gen.Binder{Time: clock}, Runner: tx.Runner{DB: p}}, Fresh: p, Store: worldbossstore.Store{}, Content: content,
		Fence: values, Players: i4store.PlayerRootLocker{}, Directory: i4store.PlayerDirectoryReader{}, Population: i4store.PlayerDirectoryReader{},
		Heroes: fight.Inputs.Heroes, Combat: fight, Privileges: i5.BaselinePrivilegeProvider{}, Costs: i5.MaterialCostDebiter{Store: values, Content: content},
		Mail: i5.SettlementMail{Store: values}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}

// worldBossActor is a genuine combat owner at the world boss open level with a purple hero.
func worldBossActor(t *testing.T, p *pg.Pool, server identity.LogicalServerID) (identity.ActorContext, int64) {
	t.Helper()
	a, _, ref := combatOwner(t, p, server)
	exec(t, p, `UPDATE player_heroes SET color=7,state_version=state_version+1 WHERE player_id=$1 AND partner_id=$2`, int64(a.PlayerID), ref.PartnerID)
	return a, ref.PartnerID
}

func worldBossSetPlayer(t *testing.T, p *pg.Pool, player identity.PlayerID, day, attempts, bestHit int64) {
	t.Helper()
	exec(t, p, `INSERT INTO worldboss_players(player_id,day,attempts,bought,swept_day,best_hit,best_hit_at,updated_at)VALUES($1,$2,$3,0,0,$4,0,clock_timestamp())
		ON CONFLICT(player_id)DO UPDATE SET day=$2,attempts=$3,bought=0,swept_day=0,best_hit=$4,best_hit_at=0,updated_at=clock_timestamp()`, int64(player), day, attempts, bestHit)
}

func worldBossOccurrence(t *testing.T, p *pg.Pool, server identity.LogicalServerID) (generation, boss, courage, courageDay int64) {
	t.Helper()
	if err := p.QueryRow(ctx, `SELECT generation,current_boss,courage,courage_day FROM worldboss_occurrences WHERE logical_server_id=$1`, int64(server)).Scan(&generation, &boss, &courage, &courageDay); err != nil {
		t.Fatal(err)
	}
	return generation, boss, courage, courageDay
}

func worldBossInfo(t *testing.T, body map[string]any) (attempts, bought, boss, canSweep, hurt, rank int64) {
	t.Helper()
	attempts = body["challenge_times"].(int64)
	bought = body["buy_times"].(int64)
	canSweep = body["can_sweep"].(int64)
	hurt = body["total_hurt"].(int64)
	rank = body["total_rank"].(int64)
	boss = body["boss_info"].(map[string]any)["current_boss"].(int64)
	return attempts, bought, boss, canSweep, hurt, rank
}

// worldBossTime is the fixed morning-of-day instant the fixtures run at; the
// 21:58 GMT+8 START window is open and the 22:00 courage update is not due.
func worldBossTime(t *testing.T) *leagueClock {
	t.Helper()
	day := modes.Day(time.Now().UTC().Add(24 * time.Hour))
	return &leagueClock{at: modes.DayBegins(day).Add(7 * time.Hour)}
}

func TestI9_8AWorldBossBuyNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, _ := worldBossActor(t, p, server)
	clock := worldBossTime(t)
	s := worldBossService(t, p, clock)

	info, err := s.Info(ctx, a, op())
	if err != nil {
		t.Fatal(err)
	}
	if attempts, bought, boss, canSweep, hurt, rank := worldBossInfo(t, info); attempts != d.AttemptsPerDay || bought != 0 || boss != d.FirstBossID || canSweep != 0 || hurt != 0 || rank != 0 {
		t.Fatalf("fresh info %#v", info)
	}
	if _, err = s.Buy(ctx, a, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatalf("buy with attempts remaining: %v", err)
	}
	exec(t, p, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'crystal',1000,1,clock_timestamp())
		ON CONFLICT(player_id,resource_key)DO UPDATE SET amount=1000,state_version=player_currency_balances.state_version+1`, int64(a.PlayerID))
	worldBossSetPlayer(t, p, a.PlayerID, modes.Day(clock.at), 0, 0)
	body, err := s.Buy(ctx, a, op())
	if err != nil {
		t.Fatal(err)
	}
	if attempts, bought, _, _, _, _ := worldBossInfo(t, body); attempts != d.AttemptsPerBuy || bought != 1 {
		t.Fatalf("buy response %#v", body)
	}
	if scalar(t, p, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID)) != 950 {
		t.Fatal("buy did not debit refresh_cost entry 1")
	}
	if _, err = s.Buy(ctx, a, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatalf("buy past the vip cap: %v", err)
	}
	info, err = s.Info(ctx, a, op())
	if err != nil {
		t.Fatal(err)
	}
	if attempts, bought, _, _, _, _ := worldBossInfo(t, info); attempts != d.AttemptsPerBuy || bought != 1 {
		t.Fatalf("info after buy %#v", info)
	}
}

func TestI9_8AWorldBossStartNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, partner := worldBossActor(t, p, server)
	clock := worldBossTime(t)
	s := worldBossService(t, p, clock)

	if _, err := s.Start(ctx, a, app.StartRequest{CampaignID: d.FirstBossID + 1, Formation: []int64{partner}}, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatalf("start on a future boss: %v", err)
	}
	if _, err := s.Start(ctx, a, app.StartRequest{CampaignID: d.FirstBossID, Formation: []int64{partner, partner}}, op()); !errors.Is(err, d.ErrInvalid) {
		t.Fatalf("duplicate formation: %v", err)
	}
	exec(t, p, `UPDATE player_heroes SET color=1,state_version=state_version+1 WHERE player_id=$1 AND partner_id=$2`, int64(a.PlayerID), partner)
	if _, err := s.Start(ctx, a, app.StartRequest{CampaignID: d.FirstBossID, Formation: []int64{partner}}, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatalf("start below purple: %v", err)
	}
	exec(t, p, `UPDATE player_heroes SET color=7,state_version=state_version+1 WHERE player_id=$1 AND partner_id=$2`, int64(a.PlayerID), partner)

	body, err := s.Start(ctx, a, app.StartRequest{CampaignID: d.FirstBossID, Formation: []int64{partner}}, op())
	if err != nil || len(body) != 0 {
		t.Fatalf("start %#v %v", body, err)
	}
	if n := scalar(t, p, `SELECT count(*) FROM worldboss_attempts WHERE player_id=$1 AND generation=1 AND campaign_id=$2 AND resolved=false`, int64(a.PlayerID), d.FirstBossID); n != 1 {
		t.Fatal("attempt row", n)
	}
	if scalar(t, p, `SELECT attempts FROM worldboss_players WHERE player_id=$1`, int64(a.PlayerID)) != d.AttemptsPerDay-1 {
		t.Fatal("start did not consume an attempt")
	}

	closed := &leagueClock{at: modes.DayBegins(modes.Day(clock.at)).Add(18 * time.Hour)} // 23:00 GMT+8
	s.Timed.Binder.Time = closed
	if _, err = s.Start(ctx, a, app.StartRequest{CampaignID: d.FirstBossID, Formation: []int64{partner}}, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatalf("start inside the closed window: %v", err)
	}
	if n := scalar(t, p, `SELECT attempts FROM worldboss_players WHERE player_id=$1`, int64(a.PlayerID)); n != d.AttemptsPerDay-1 {
		t.Fatal("closed start consumed an attempt", n)
	}
}

func TestI9_8AWorldBossSettleNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, partner := worldBossActor(t, p, server)
	clock := worldBossTime(t)
	s := worldBossService(t, p, clock)
	formation := []int64{partner}

	if _, err := s.Start(ctx, a, app.StartRequest{CampaignID: d.FirstBossID, Formation: formation}, op()); err != nil {
		t.Fatal(err)
	}
	if _, err := s.Settle(ctx, a, app.ResultRequest{CampaignID: d.FirstBossID, Damage: 500, Formation: []int64{partner + 1}}, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatalf("settle with a changed formation: %v", err)
	}
	settled, err := s.Settle(ctx, a, app.ResultRequest{CampaignID: d.FirstBossID, Damage: 500, Formation: formation}, op())
	if err != nil || settled.Duplicate || settled.Body["damage"] != int64(500) || settled.Body["total_hurt"] != int64(500) || settled.Body["total_rank"] != int64(1) {
		t.Fatalf("settle %+v %v", settled, err)
	}
	duplicate, err := s.Settle(ctx, a, app.ResultRequest{CampaignID: d.FirstBossID, Damage: 500, Formation: formation}, op())
	if err != nil || !duplicate.Duplicate || duplicate.Body["total_hurt"] != int64(500) {
		t.Fatalf("duplicate settle %+v %v", duplicate, err)
	}
	if total := scalar(t, p, `SELECT hurt FROM worldboss_player_totals WHERE logical_server_id=$1 AND generation=1 AND player_id=$2`, int64(server), int64(a.PlayerID)); total != 500 {
		t.Fatal("duplicate settle was applied twice", total)
	}

	// Clamp: courage is three points short of the first boss, so a ten
	// million report is accepted only as the remaining three.
	exec(t, p, `UPDATE worldboss_occurrences SET courage=$2 WHERE logical_server_id=$1`, int64(server), d.DamageCap*2-3)
	clock.Set(clock.at.Add(time.Minute))
	if _, err = s.Start(ctx, a, app.StartRequest{CampaignID: d.FirstBossID, Formation: formation}, op()); err != nil {
		t.Fatal(err)
	}
	clamped, err := s.Settle(ctx, a, app.ResultRequest{CampaignID: d.FirstBossID, Damage: d.DamageCap, Formation: formation}, op())
	if err != nil || clamped.Duplicate || clamped.Body["damage"] != int64(3) {
		t.Fatalf("clamped settle %+v %v", clamped, err)
	}
	generation, boss, courage, _ := worldBossOccurrence(t, p, server)
	if generation != 1 || boss != d.FirstBossID+1 || courage != d.DamageCap*2 {
		t.Fatalf("defeat after clamp gen=%d boss=%d courage=%d", generation, boss, courage)
	}
}

func TestI9_8AWorldBossSweepNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, partner := worldBossActor(t, p, server)
	clock := worldBossTime(t)
	s := worldBossService(t, p, clock)
	formation := []int64{partner}

	if _, err := s.Sweep(ctx, a, d.FirstBossID, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatalf("sweep without a recorded hit: %v", err)
	}
	if _, err := s.Start(ctx, a, app.StartRequest{CampaignID: d.FirstBossID, Formation: formation}, op()); err != nil {
		t.Fatal(err)
	}
	if _, err := s.Settle(ctx, a, app.ResultRequest{CampaignID: d.FirstBossID, Damage: 900, Formation: formation}, op()); err != nil {
		t.Fatal(err)
	}
	clock.Set(clock.at.Add(time.Minute))
	swept, err := s.Sweep(ctx, a, d.FirstBossID, op())
	if err != nil || swept.Duplicate || swept.Body["damage"] != int64(900) {
		t.Fatalf("sweep %+v %v", swept, err)
	}
	if n := scalar(t, p, `SELECT attempts FROM worldboss_players WHERE player_id=$1`, int64(a.PlayerID)); n != d.AttemptsPerDay-2 {
		t.Fatal("sweep attempt debit", n)
	}
	duplicate, err := s.Sweep(ctx, a, d.FirstBossID, op())
	if err != nil || !duplicate.Duplicate || duplicate.Body["damage"] != int64(900) {
		t.Fatalf("duplicate sweep %+v %v", duplicate, err)
	}
	if _, _, courage, _ := worldBossOccurrence(t, p, server); courage != 1800 {
		t.Fatal("sweep was applied twice", courage)
	}
}

func TestI9_8AWorldBossLateSettlementFencedNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	late, latePartner := worldBossActor(t, p, server)
	advance, advancePartner := worldBossActor(t, p, server)
	clock := worldBossTime(t)
	s := worldBossService(t, p, clock)

	if _, err := s.Start(ctx, late, app.StartRequest{CampaignID: d.FirstBossID, Formation: []int64{latePartner}}, op()); err != nil {
		t.Fatal(err)
	}
	if _, err := s.Start(ctx, advance, app.StartRequest{CampaignID: d.FirstBossID, Formation: []int64{advancePartner}}, op()); err != nil {
		t.Fatal(err)
	}
	exec(t, p, `UPDATE worldboss_occurrences SET courage=$2 WHERE logical_server_id=$1`, int64(server), d.DamageCap*2-1)
	clock.Set(clock.at.Add(time.Minute))
	if _, err := s.Settle(ctx, advance, app.ResultRequest{CampaignID: d.FirstBossID, Damage: 1, Formation: []int64{advancePartner}}, op()); err != nil {
		t.Fatal("advancing settlement", err)
	}
	if _, boss, _, _ := worldBossOccurrence(t, p, server); boss != d.FirstBossID+1 {
		t.Fatal("boss did not advance", boss)
	}
	clock.Set(clock.at.Add(time.Minute))
	_, err := s.Settle(ctx, late, app.ResultRequest{CampaignID: d.FirstBossID, Damage: 100, Formation: []int64{latePartner}}, op())
	if !errors.Is(err, d.ErrRefused) {
		t.Fatalf("late settlement was not fenced: %v", err)
	}
	if total := scalar(t, p, `SELECT count(*) FROM worldboss_player_totals WHERE logical_server_id=$1 AND generation=1 AND player_id=$2`, int64(server), int64(late.PlayerID)); total != 0 {
		t.Fatal("late settlement wrote a total")
	}
	if _, _, courage, _ := worldBossOccurrence(t, p, server); courage != d.DamageCap*2 {
		t.Fatal("late settlement changed courage", courage)
	}
}

func TestI9_8AWorldBossConcurrentSettlementNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, aPartner := worldBossActor(t, p, server)
	b, bPartner := worldBossActor(t, p, server)
	clock := worldBossTime(t)
	s := worldBossService(t, p, clock)

	if _, err := s.Start(ctx, a, app.StartRequest{CampaignID: d.FirstBossID, Formation: []int64{aPartner}}, op()); err != nil {
		t.Fatal(err)
	}
	if _, err := s.Start(ctx, b, app.StartRequest{CampaignID: d.FirstBossID, Formation: []int64{bPartner}}, op()); err != nil {
		t.Fatal(err)
	}
	var workers sync.WaitGroup
	failures := make(chan error, 2)
	for _, settle := range []struct {
		actor   identity.ActorContext
		partner int64
		damage  int64
	}{{a, aPartner, 1000}, {b, bPartner, 1000}} {
		workers.Add(1)
		go func(actor identity.ActorContext, partner, damage int64) {
			defer workers.Done()
			_, err := s.Settle(ctx, actor, app.ResultRequest{CampaignID: d.FirstBossID, Damage: damage, Formation: []int64{partner}}, op())
			failures <- err
		}(settle.actor, settle.partner, settle.damage)
	}
	workers.Wait()
	close(failures)
	for err := range failures {
		if err != nil {
			t.Fatal("concurrent settlement", err)
		}
	}
	if _, _, courage, _ := worldBossOccurrence(t, p, server); courage != 2000 {
		t.Fatal("concurrent settlements were not both applied", courage)
	}

	// One frozen attempt settled twice: the loser replays as the duplicate and
	// must not add damage a second time.
	c, cPartner := worldBossActor(t, p, server)
	if _, err := s.Start(ctx, c, app.StartRequest{CampaignID: d.FirstBossID, Formation: []int64{cPartner}}, op()); err != nil {
		t.Fatal(err)
	}
	results := make(chan app.Response, 2)
	failures = make(chan error, 2)
	var replay sync.WaitGroup
	for replayIndex := 0; replayIndex < 2; replayIndex++ {
		replay.Add(1)
		go func() {
			defer replay.Done()
			settled, err := s.Settle(ctx, c, app.ResultRequest{CampaignID: d.FirstBossID, Damage: 500, Formation: []int64{cPartner}}, op())
			failures <- err
			results <- settled
		}()
	}
	replay.Wait()
	close(failures)
	close(results)
	for err := range failures {
		if err != nil {
			t.Fatal("concurrent duplicate settlement", err)
		}
	}
	duplicates := 0
	for settled := range results {
		if settled.Duplicate {
			duplicates++
		}
	}
	if duplicates != 1 {
		t.Fatalf("expected exactly one duplicate reply, got %d", duplicates)
	}
	if _, _, courage, _ := worldBossOccurrence(t, p, server); courage != 2500 {
		t.Fatal("one frozen attempt was applied twice", courage)
	}
}

func TestI9_8AWorldBossDefeatMailNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, partner := worldBossActor(t, p, server)
	clock := worldBossTime(t)
	s := worldBossService(t, p, clock)
	formation := []int64{partner}

	if _, err := s.Start(ctx, a, app.StartRequest{CampaignID: d.FirstBossID, Formation: formation}, op()); err != nil {
		t.Fatal(err)
	}
	exec(t, p, `UPDATE worldboss_occurrences SET courage=$2 WHERE logical_server_id=$1`, int64(server), d.DamageCap*2-1)
	clock.Set(clock.at.Add(time.Minute))
	if _, err := s.Settle(ctx, a, app.ResultRequest{CampaignID: d.FirstBossID, Damage: 1, Formation: formation}, op()); err != nil {
		t.Fatal("defeating settlement", err)
	}
	mails := func() int64 {
		return scalar(t, p, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='WORLD_BOSS_DEFEAT'`, int64(a.PlayerID))
	}
	if mails() != 1 {
		t.Fatal("defeat mail missing")
	}
	if _, err := s.Settle(ctx, a, app.ResultRequest{CampaignID: d.FirstBossID, Damage: 1, Formation: formation}, op()); err != nil {
		t.Fatal("duplicate defeat settlement", err)
	}
	if mails() != 1 {
		t.Fatal("duplicate settlement mailed again")
	}
	timed, err := gen.NewTimedOperation(op(), clock.at)
	if err != nil {
		t.Fatal(err)
	}
	if _, err = (app.Reconciler{Service: s}).Reconcile(ctx, timed, 1000); err != nil {
		t.Fatal(err)
	}
	if mails() != 1 {
		t.Fatal("reconcile mailed the settled defeat again")
	}
}

func TestI9_8AWorldBossDailyCourageNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, _ := worldBossActor(t, p, server)
	clock := worldBossTime(t)
	clock.Set(modes.DayBegins(modes.Day(clock.at)).Add(18 * time.Hour)) // 23:00 GMT+8, after the 22:00 update
	s := worldBossService(t, p, clock)
	updateDay := d.CourageDayFor(clock.at)
	exec(t, p, `INSERT INTO worldboss_occurrences(logical_server_id,generation,current_boss,courage,courage_day,updated_at)VALUES($1,1,$2,0,$3,clock_timestamp())
		ON CONFLICT(logical_server_id)DO UPDATE SET generation=1,current_boss=$2,courage=0,courage_day=$3`, int64(server), d.FirstBossID, updateDay-1)
	worldBossSetPlayer(t, p, a.PlayerID, modes.Day(clock.at), 2, 0)

	level90 := scalar(t, p, `SELECT count(*) FROM player_directory_profiles WHERE lev>=90`)
	challengers := scalar(t, p, `SELECT count(*) FROM worldboss_players WHERE day=$1 AND attempts<$2`, modes.Day(clock.at), d.AttemptsPerDay)
	delta := d.DailyCourage(level90, challengers)
	timed, err := gen.NewTimedOperation(op(), clock.at)
	if err != nil {
		t.Fatal(err)
	}
	if _, err = (app.Reconciler{Service: s}).Reconcile(ctx, timed, 1000); err != nil {
		t.Fatal(err)
	}
	if _, _, courage, courageDay := worldBossOccurrence(t, p, server); courage != delta || courageDay != updateDay {
		t.Fatalf("daily courage courage=%d day=%d want=%d/%d", courage, courageDay, delta, updateDay)
	}
	if _, err = (app.Reconciler{Service: s}).Reconcile(ctx, timed, 1000); err != nil {
		t.Fatal(err)
	}
	if _, _, courage, _ := worldBossOccurrence(t, p, server); courage != delta {
		t.Fatal("daily courage applied twice", courage)
	}
}

type worldBossFactLog struct {
	inner appcampaign.Facts
	mu    sync.Mutex
	kinds []string
}

func (f *worldBossFactLog) PrepareTx(c context.Context, t tx.Tx, player identity.PlayerID, op gen.TimedOperation) (context.Context, error) {
	return f.inner.PrepareTx(c, t, player, op)
}

func (f *worldBossFactLog) RecordTx(c context.Context, t tx.Tx, op operation.Context, facts ...objective.Fact) error {
	f.mu.Lock()
	for _, fact := range facts {
		f.kinds = append(f.kinds, fact.Kind)
	}
	f.mu.Unlock()
	return f.inner.RecordTx(c, t, op, facts...)
}

func (f *worldBossFactLog) count(kind string) int {
	f.mu.Lock()
	defer f.mu.Unlock()
	total := 0
	for _, recorded := range f.kinds {
		if recorded == kind {
			total++
		}
	}
	return total
}

func TestI9_8AProphecyFactNative(t *testing.T) {
	p := pool(t)
	a, revision := bornActor(t, p), installed(t, p)
	bornHero(t, p, a, revision, 10001001, 1)
	compositeLevel(t, p, a, revision, 100)
	exec(t, p, `UPDATE player_heroes SET color=7,state_version=state_version+1 WHERE player_id=$1 AND partner_id=1`, int64(a.PlayerID))
	lines := []grant.Line{{Kind: grant.Temporal, ResourceKey: "energy", Amount: 1000}, {Kind: grant.ScalarCurrency, ResourceKey: "crystal", Amount: 1000}}
	if _, err := compositeI5(p).AdminGrant(ctx, authority().Operator, a.PlayerID, uuid().String(), "I9_8A_NATIVE", lines, opPinned(revision)); err != nil {
		t.Fatal(err)
	}
	s := campaignMode(t, p)
	facts := &worldBossFactLog{inner: s.Facts}
	s.Facts = facts
	catalog, err := s.Content.CampaignCatalogTx(ctx, p, revision)
	if err != nil {
		t.Fatal(err)
	}
	day := modes.Day(time.Now().UTC())
	timeTravel, timeTravelOK := catalog.Group(14)
	for !timeTravelOK || !timeTravel.Scheduled(catalog, day) {
		day++
		if timeTravel, timeTravelOK = catalog.Group(14); !timeTravelOK {
			t.Fatal("missing Time Travel group")
		}
	}
	clock := &leagueClock{at: modes.DayBegins(day).Add(time.Hour)}
	s.Timed.Binder.Time = clock
	prophecy, ok := catalog.Group(catalog.Prophecy(day))
	if !ok {
		t.Fatal("missing Prophecy group")
	}
	formation := []int64{0, 0, 0, 0, 1}
	for _, trial := range []struct {
		name     string
		campaign int64
		kind     int64
	}{
		{"Time Travel", timeTravel.Nodes[0], timeTravel.ID},
		{"Prophecy", prophecy.Nodes[0], prophecy.ID},
	} {
		if _, err = s.Fight(ctx, a, appcampaign.Fight{CampaignID: trial.campaign, Type: trial.kind, Formation: formation}, op()); err != nil {
			t.Fatalf("%s fight: %v", trial.name, err)
		}
		if _, err = s.Result(ctx, a, appcampaign.Result{CampaignID: trial.campaign, Type: trial.kind, Star: 3, Formation: formation}, op()); err != nil {
			t.Fatalf("%s result: %v", trial.name, err)
		}
		if trial.name == "Time Travel" && facts.count("INFINITY_BOSS_DEFEATED") != 0 {
			t.Fatal("Time Travel emitted the Prophecy fact")
		}
	}
	if facts.count("INFINITY_BOSS_DEFEATED") != 1 {
		t.Fatalf("Prophecy fact count %d", facts.count("INFINITY_BOSS_DEFEATED"))
	}
	if facts.count("CAMPAIGN_TRIAL_WIN") != 2 {
		t.Fatalf("trial win fact count %d", facts.count("CAMPAIGN_TRIAL_WIN"))
	}
}
