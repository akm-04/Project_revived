//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	"slices"
	"strconv"
	"strings"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/achievementstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/oneononestore"
	ach "gxb.local/backend/v2/internal/application/achievement"
	"gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	app "gxb.local/backend/v2/internal/application/oneonone"
	appdisplay "gxb.local/backend/v2/internal/application/playerdisplay"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	d "gxb.local/backend/v2/internal/domain/oneonone"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func oneOnOneService(t *testing.T, p *pg.Pool) app.Service {
	t.Helper()
	fight := combatService(t, p)
	values, content := i5store.Store{Queryer: p}, contentstore.Store{Queryer: p}
	return app.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}}, Fresh: p, Store: oneononestore.Store{}, Content: content,
		Fence: values, Privileges: i5.BaselinePrivilegeProvider{}, Costs: i5.MaterialCostDebiter{Store: values, Content: content}, Mail: i5.SettlementMail{Store: values},
		Achievements: ach.Service{Store: achievementstore.Store{}, Content: content, Population: libraryService(p, p)}, Combat: fight, Heroes: fight.Inputs.Heroes, Pets: fight.Inputs.Pets,
		Directory: i4store.PlayerDirectoryReader{}, Entitlements: values, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}

// oneOnOnePlayer is a genuine combat owner with level 60, 15 owned girls and an Achievement root.
func oneOnOnePlayer(t *testing.T, p *pg.Pool, server identity.LogicalServerID) (identity.ActorContext, []int64) {
	t.Helper()
	a, rev, ref := combatOwner(t, p, server)
	heroes := []int64{ref.PartnerID}
	s := ownerSummoner(p)
	// Distinct origin templates: an owner holds each template origin once.
	for table := int64(10001002); len(heroes) < 15; table++ {
		def := collectionResources(t, p, a, rev, table)
		h, err := s.SummonNormal(ctx, a, def.Template.TableID, def.Template.FragmentItemID, def.FragmentCount, op())
		if err != nil {
			t.Fatal(err)
		}
		heroes = append(heroes, h.Ref().PartnerID)
	}
	exec(t, p, `UPDATE player_directory_profiles SET lev=60 WHERE player_id=$1`, int64(a.PlayerID))
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	if e = (achievementstore.Store{}).InitFreshTx(ctx, tr, a.PlayerID, rev, time.Now().Add(-time.Hour)); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	return a, heroes
}

func oneOnOneCatalog(t *testing.T, p *pg.Pool) d.Catalog {
	t.Helper()
	content := contentstore.Store{Queryer: p}
	rev, err := content.ActiveRevision(ctx, p)
	if err != nil {
		t.Fatal(err)
	}
	catalog, err := content.OneOnOneCatalogTx(ctx, p, rev)
	if err != nil {
		t.Fatal(err)
	}
	return catalog
}

func teamsOf(heroes []int64, n int) []d.Team {
	out := []d.Team{}
	for i := range n {
		out = append(out, d.Team{Heroes: []int64{heroes[i]}})
	}
	return out
}

// startSettled repeats an identical START while its rounds are still resolving, as the stock client's retry does.
func startSettled(s app.Service, a identity.ActorContext, command app.StartCommand) (d.MatchView, error) {
	for {
		m, err := s.Start(ctx, a, command, op())
		if !errors.Is(err, app.ErrUnresolved) {
			return m, err
		}
	}
}

func TestI7C5COneOnOneEntryMatchSettlementNative(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	s := oneOnOneService(t, pool)
	a, heroesA := oneOnOnePlayer(t, pool, rankingServer(t, pool))
	b, heroesB := oneOnOnePlayer(t, pool, rankingServer(t, pool))
	catalog := oneOnOneCatalog(t, pool)

	// C02: the gate needs level 55 and 15 girls; entry is Junior 3 with 4300 points.
	low, _, _ := combatOwner(t, pool, a.LogicalServerID)
	if _, err := s.Load(ctx, low, op()); err == nil {
		t.Fatal("a player below level 55 with one girl entered")
	}
	viewA, err := s.Load(ctx, a, op())
	if err != nil {
		t.Fatal(err)
	}
	viewB, err := s.Load(ctx, b, op())
	if err != nil {
		t.Fatal(err)
	}
	if viewA.Player.Level != d.LevelJunior3 || viewA.Player.Points != 4300 || viewA.Player.TriesLeft != 10 || viewA.Ranked.Global <= 5000 || viewA.Ranked.ServerRank != 1 || viewB.Ranked.ServerRank != 1 {
		t.Fatalf("entry %+v %+v", viewA.Ranked, viewB.Ranked)
	}
	if again, err := s.Load(ctx, a, op()); err != nil || again.Player.StateVersion != viewA.Player.StateVersion || scalar(t, pool, `SELECT count(*) FROM one_on_one_competitions`) != 1 {
		t.Fatal("repeated LOAD must not re-enter", err)
	}

	// C03: exact team count, owned and distinct members.
	if err = s.ChangeTeams(ctx, a, teamsOf(heroesA, 2), op()); err == nil {
		t.Fatal("two teams accepted for Junior")
	}
	if err = s.ChangeTeams(ctx, a, []d.Team{{Heroes: []int64{heroesA[0]}}, {Heroes: []int64{heroesA[0]}}, {Heroes: []int64{heroesA[1]}}}, op()); err == nil {
		t.Fatal("a hero in two teams accepted")
	}
	if err = s.ChangeTeams(ctx, a, []d.Team{{Heroes: []int64{slices.Max(heroesA) + 1000}}, {Heroes: []int64{heroesA[1]}}, {Heroes: []int64{heroesA[2]}}}, op()); err == nil {
		t.Fatal("an unowned hero accepted")
	}
	for _, x := range []struct {
		a      identity.ActorContext
		heroes []int64
	}{{a, heroesA}, {b, heroesB}} {
		if err = s.ChangeTeams(ctx, x.a, teamsOf(x.heroes, 3), op()); err != nil {
			t.Fatal(err)
		}
	}
	exec(t, pool, `UPDATE one_on_one_players SET points=4500,state_version=state_version+1 WHERE player_id=$1`, int64(b.PlayerID))

	// C04: candidates are better members of the same group with a defense, across servers.
	pointsOf := func(pid identity.PlayerID) int64 {
		return scalar(t, pool, `SELECT points FROM one_on_one_players WHERE player_id=$1`, int64(pid))
	}
	for _, x := range []identity.ActorContext{a, b} {
		offered, err := s.Match(ctx, x, op())
		if err != nil {
			t.Fatal(err)
		}
		for _, o := range offered {
			if o.Ranked.Level < d.LevelJunior1 || o.Ranked.Points < pointsOf(x.PlayerID) || o.Face.Player == x.PlayerID {
				t.Fatal("candidates are better members of the same group", o.Ranked)
			}
		}
	}
	// The fixture pins B as A's offered opponent; the competition may already hold other Juniors (restored databases).
	exec(t, pool, `UPDATE one_on_one_players SET offered=$2::jsonb,state_version=state_version+1 WHERE player_id=$1`, int64(a.PlayerID), "["+strconv.FormatInt(int64(b.PlayerID), 10)+"]")
	enemy, err := s.EnemyTeam(ctx, b.PlayerID)
	if err != nil || len(enemy) != 3 || len(enemy[0].Heroes) != 1 {
		t.Fatal("GET_ENEMY_TEAM", err, len(enemy))
	}
	if !catalog.Open(time.Now()) {
		t.Skip("1 on 1 START is closed outside 08:00-22:00 GMT+8")
	}

	// C05/C06/C11: a best-of-three match settles once, moves Elo points and records both sides.
	command := app.StartCommand{Formations: teamsOf(heroesA, 3), Enemy: b.PlayerID}
	if _, err = s.Start(ctx, a, app.StartCommand{Formations: teamsOf(heroesA, 2), Enemy: b.PlayerID}, op()); err == nil {
		t.Fatal("two formations accepted against three defense teams")
	}
	started := time.Now()
	result, err := startSettled(s, a, command)
	if err != nil {
		t.Fatal(err)
	}
	t.Logf("best-of-three START with resolution and settlement took %s (rounds %v)", time.Since(started), result.Wins)
	if len(result.Wins) < 2 || len(result.Wins) > 3 || len(result.ReportKeys) != len(result.Wins) || result.Arena.Player.TriesLeft != 9 {
		t.Fatalf("match %+v", result)
	}
	gain := catalog.Gain(4300, 4500)
	if !result.Win {
		gain = -catalog.Gain(4500, 4300)
	}
	pointsA := scalar(t, pool, `SELECT points FROM one_on_one_players WHERE player_id=$1`, int64(a.PlayerID))
	pointsB := scalar(t, pool, `SELECT points FROM one_on_one_players WHERE player_id=$1`, int64(b.PlayerID))
	if pointsA != 4300+gain || pointsB != 4500-gain {
		t.Fatalf("Elo points %d %d gain %d", pointsA, pointsB, gain)
	}
	replay, err := startSettled(s, a, command)
	if err != nil || replay.Win != result.Win || strings.Join(replay.ReportKeys, ",") != strings.Join(result.ReportKeys, ",") {
		t.Fatal("identical START must return the recorded match", err)
	}
	if _, err = s.Start(ctx, a, app.StartCommand{Formations: teamsOf(heroesA[3:], 3), Enemy: b.PlayerID}, op()); err == nil {
		t.Fatal("junior cooldown must refuse the next START")
	}
	if scalar(t, pool, `SELECT count(*) FROM one_on_one_matches WHERE attacker_id=$1 AND status='SETTLED'`, int64(a.PlayerID)) != 1 ||
		scalar(t, pool, `SELECT count(*) FROM combat_attempts a JOIN one_on_one_rounds r USING(attempt_id) WHERE a.state='TERMINAL'`) != int64(len(result.Wins)) {
		t.Fatal("match and rounds settled once")
	}
	if scalar(t, pool, `SELECT count(*) FROM combat_attempts a JOIN one_on_one_rounds r USING(attempt_id) WHERE a.state='STAGED'`) != int64(3-len(result.Wins)) {
		t.Fatal("a round after the decision must stay unsimulated")
	}
	report, err := s.Report(ctx, result.ReportKeys[0])
	if err != nil || len(report) == 0 {
		t.Fatal("round report", err)
	}
	if keys, err := s.DefenseReportKeys(ctx, b); err != nil || len(keys) != len(result.ReportKeys) {
		t.Fatal("defense report keys", err, keys)
	}
	records, err := s.Records(ctx, b)
	if err != nil || len(records) != 1 || records[0].Record.Attack || records[0].Record.Win == result.Win || records[0].Attacker.Player != a.PlayerID {
		t.Fatal("defender record", err)
	}
	detail, err := s.RecordDetail(ctx, records[0].Record.ID)
	if err != nil || len(detail.Wins) != len(result.Wins) || len(detail.Attack) != len(result.Wins) {
		t.Fatal("record detail", err)
	}
	if scalar(t, pool, `SELECT fights FROM one_on_one_players WHERE player_id=$1`, int64(b.PlayerID)) != 1 ||
		scalar(t, pool, `SELECT count(*) FROM one_on_one_partner_usage WHERE player_id=$1`, int64(a.PlayerID)) < 2 {
		t.Fatal("history facts")
	}
	wantStreak := int64(0)
	if result.Win {
		wantStreak = 1
	}
	if scalar(t, pool, `SELECT COALESCE(max(current),0) FROM achievement_streaks WHERE player_id=$1 AND achievement_id=100028`, int64(a.PlayerID)) != wantStreak {
		t.Fatal("win streak producer")
	}

	// C08: a promotion match against a Senior with fewer saved teams forfeits the missing rounds; two wins promote.
	// Fixture slots are cleared first: restored databases keep earlier runs' Masters/Seniors.
	exec(t, pool, `UPDATE one_on_one_players SET level=5,slot=NULL,points=3000,state_version=state_version+1 WHERE slot IN (1,501) AND player_id NOT IN ($1,$2)`, int64(a.PlayerID), int64(b.PlayerID))
	exec(t, pool, `UPDATE one_on_one_players SET level=2,slot=501,teams=$2::jsonb,state_version=state_version+1 WHERE player_id=$1`, int64(b.PlayerID), `[{"heroes":[`+strconv.FormatInt(heroesB[0], 10)+`],"pet":0}]`)
	exec(t, pool, `UPDATE one_on_one_players SET level=3,points=4900,mode=2,candidates=$2::jsonb,promotion_week=1,state_version=state_version+1 WHERE player_id=$1`, int64(a.PlayerID), "["+strconv.FormatInt(int64(b.PlayerID), 10)+"]")
	promote := app.StartCommand{Formations: teamsOf(heroesA, 5), Enemy: b.PlayerID}
	for i := range 3 {
		exec(t, pool, `UPDATE one_on_one_players SET last_promotion_at=NULL,state_version=state_version+1 WHERE player_id=$1`, int64(a.PlayerID))
		promote.Formations = teamsOf(heroesA[i:], 5)
		m, err := startSettled(s, a, promote)
		if err != nil {
			t.Fatal(err)
		}
		if !m.Win || m.ReportKeys[len(m.ReportKeys)-1] != "" {
			t.Fatalf("a Senior with one saved team forfeits rounds 2-5 %+v", m)
		}
		if scalar(t, pool, `SELECT mode FROM one_on_one_players WHERE player_id=$1`, int64(a.PlayerID)) == 1 {
			break
		}
	}
	if scalar(t, pool, `SELECT slot FROM one_on_one_players WHERE player_id=$1`, int64(a.PlayerID)) != 501 || scalar(t, pool, `SELECT level FROM one_on_one_players WHERE player_id=$1`, int64(b.PlayerID)) != d.LevelJunior1 {
		t.Fatal("promotion swaps slot, level and points")
	}

	// C07/C09/C10: owed Wednesday/Sunday settlements mail legend_reward by server rank once, titles on Sundays.
	exec(t, pool, `UPDATE one_on_one_players SET level=1,slot=1,state_version=state_version+1 WHERE player_id=$1`, int64(a.PlayerID))
	now := time.Now()
	latest := catalog.LatestSettlement(now)
	// The fixture replays its own window; earlier runs on the same database settled it already.
	exec(t, pool, `DELETE FROM one_on_one_settlement_ranks WHERE day>$1`, latest-8)
	exec(t, pool, `DELETE FROM one_on_one_settlements WHERE day>$1`, latest-8)
	exec(t, pool, `UPDATE one_on_one_competitions SET settled_through=$1,state_version=state_version+1`, latest-8)
	settled, err := s.Due(ctx, op())
	if err != nil || settled < 2 {
		t.Fatal("owed settlements", settled, err)
	}
	if again, err := s.Due(ctx, op()); err != nil || again != 0 {
		t.Fatal("settlement must be once", again, err)
	}
	if scalar(t, pool, `SELECT count(*) FROM mail_attachments m JOIN mail_records r USING(mail_uuid) WHERE r.recipient_player_id=$1 AND r.source_kind='ONE_ON_ONE_REWARD' AND m.resource_key='top_coin' AND m.amount=2100`, int64(a.PlayerID)) != int64(settled) ||
		scalar(t, pool, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='ONE_ON_ONE_FRAME'`, int64(a.PlayerID)) != 1 {
		t.Fatal("reward and frame mails")
	}
	// The top_coin income (ENABLED_R4) is claimable through the stock mail claim.
	wire := scalar(t, pool, `SELECT min(wire_id) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='ONE_ON_ONE_REWARD' AND namespace='NORMAL'`, int64(a.PlayerID))
	values := i5store.Store{Queryer: pool}
	claims := i5.Service{Runner: tx.Runner{DB: pool}, Store: values, Content: contentstore.Store{Queryer: pool}, Privileges: i5.BaselinePrivilegeProvider{}, Functions: i5.PetStarterFunctionAnnouncements{},
		Directory: i4store.DirectoryLevelProjection{}, Backpack: values, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: pool}}
	if _, err = claims.ClaimMail(ctx, a, mail.Address{Namespace: mail.Normal, WireID: wire}, op()); err != nil {
		t.Fatal("claim 1 on 1 reward mail", err)
	}
	if scalar(t, pool, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='top_coin'`, int64(a.PlayerID)) != 2100 {
		t.Fatal("top_coin credited by the claim")
	}
	sundays := scalar(t, pool, `SELECT count(*) FROM one_on_one_settlement_ranks WHERE player_id=$1 AND title_id=100002`, int64(a.PlayerID))
	if sundays < 1 || scalar(t, pool, `SELECT current FROM achievement_streaks WHERE player_id=$1 AND achievement_id=100002`, int64(a.PlayerID)) < 1 {
		t.Fatal("Sunday title and Dominator streak", sundays)
	}
	rev, _ := (contentstore.Store{Queryer: pool}).ActiveRevision(ctx, pool)
	origins, err := s.ReadCatalogDisplayOriginsTx(ctx, pool, appdisplay.CatalogOriginRequest{PlayerID: a.PlayerID, Family: "title", CatalogID: 100002, Revision: rev, ObservedAt: time.Now()})
	if err != nil || !origins.Qualified || !origins.CompleteHistory || int64(len(origins.Origins)) != sundays {
		t.Fatal("title origins", err, len(origins.Origins))
	}
	list, err := s.RankList(ctx, a, true)
	if err != nil || list.Mine.Global != 1 || list.Rows[0].Face.Player != a.PlayerID {
		t.Fatal("global rank list", err)
	}
}

// C08: the promotion opening fills empty Senior slots with the best Junior 1 players.
func TestI7C5COneOnOneVacancyFillNative(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	s := oneOnOneService(t, pool)
	a, _ := oneOnOnePlayer(t, pool, rankingServer(t, pool))
	catalog := oneOnOneCatalog(t, pool)
	if _, err := s.Load(ctx, a, op()); err != nil {
		t.Fatal(err)
	}
	exec(t, pool, `UPDATE one_on_one_players SET level=5,slot=NULL,points=3000,state_version=state_version+1 WHERE player_id<>$1 AND level<=2`, int64(a.PlayerID))
	exec(t, pool, `UPDATE one_on_one_players SET points=99999,level=3,state_version=state_version+1 WHERE player_id=$1`, int64(a.PlayerID))
	week := catalog.LatestPromotion(time.Now())
	exec(t, pool, `UPDATE one_on_one_competitions SET opened_through=$1,closed_through=$1,settled_through=$2,master_count=0,senior_count=0,state_version=state_version+1`, week-7, catalog.LatestSettlement(time.Now()))
	if _, err := s.Due(ctx, op()); err != nil {
		t.Fatal(err)
	}
	if scalar(t, pool, `SELECT level FROM one_on_one_players WHERE player_id=$1`, int64(a.PlayerID)) != d.LevelSenior || scalar(t, pool, `SELECT opened_through FROM one_on_one_competitions`) != week {
		t.Fatal("vacancy fill")
	}
}

// C02: concurrent first entries create one competition and distinct players.
func TestI7C5COneOnOneConcurrentEntryNative(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	s := oneOnOneService(t, pool)
	server := rankingServer(t, pool)
	actors := []identity.ActorContext{}
	for range 3 {
		a, _ := oneOnOnePlayer(t, pool, server)
		actors = append(actors, a)
	}
	errs := make(chan error, len(actors))
	for _, a := range actors {
		go func() {
			_, err := s.Load(ctx, a, op())
			errs <- err
		}()
	}
	for range actors {
		if err := <-errs; err != nil {
			t.Fatal(err)
		}
	}
	if scalar(t, pool, `SELECT count(*) FROM one_on_one_competitions`) != 1 || scalar(t, pool, `SELECT count(*) FROM one_on_one_players WHERE logical_server_id=$1`, int64(server)) != 3 {
		t.Fatal("concurrent entry")
	}
}

// stalledRounds withholds resolution from START, as if the client vanished.
type stalledRounds struct{ app.Combat }

func (stalledRounds) ResolveDetached(context.Context, operation.Context, ids.UUID) *combat.Flight {
	f := &combat.Flight{Done: make(chan struct{}), Err: cd.ErrResolverRetryable}
	close(f.Done)
	return f
}

// C05: an abandoned match is resolved and settled once by the reconcile provider.
func TestI7C5COneOnOneReconcileAbandonedNative(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	s := oneOnOneService(t, pool)
	a, heroesA := oneOnOnePlayer(t, pool, rankingServer(t, pool))
	b, heroesB := oneOnOnePlayer(t, pool, rankingServer(t, pool))
	if !oneOnOneCatalog(t, pool).Open(time.Now()) {
		t.Skip("1 on 1 START is closed outside 08:00-22:00 GMT+8")
	}
	for _, x := range []struct {
		a      identity.ActorContext
		heroes []int64
	}{{a, heroesA}, {b, heroesB}} {
		if _, err := s.Load(ctx, x.a, op()); err != nil {
			t.Fatal(err)
		}
		if err := s.ChangeTeams(ctx, x.a, teamsOf(x.heroes, 3), op()); err != nil {
			t.Fatal(err)
		}
	}
	exec(t, pool, `UPDATE one_on_one_players SET offered=$2::jsonb,state_version=state_version+1 WHERE player_id=$1`, int64(a.PlayerID), "["+strconv.FormatInt(int64(b.PlayerID), 10)+"]")
	exec(t, pool, `UPDATE one_on_one_players SET points=4800,state_version=state_version+1 WHERE player_id=$1`, int64(b.PlayerID))
	stalled := s
	stalled.Combat = stalledRounds{s.Combat}
	if _, err := stalled.Start(ctx, a, app.StartCommand{Formations: teamsOf(heroesA, 3), Enemy: b.PlayerID}, op()); err == nil {
		t.Fatal("an unresolved match must not answer a result")
	}
	exec(t, pool, `UPDATE one_on_one_matches SET started_at=started_at-interval '5 minutes' WHERE attacker_id=$1`, int64(a.PlayerID))
	timed, err := gen.Binder{Time: pg.AuthoritativeTime{Queryer: pool}}.Bind(ctx, op())
	if err != nil {
		t.Fatal(err)
	}
	for range 2 {
		if _, err = (app.Reconciler{Service: s}).Reconcile(ctx, timed, 50); err != nil {
			t.Fatal(err)
		}
	}
	if scalar(t, pool, `SELECT count(*) FROM one_on_one_matches WHERE attacker_id=$1 AND status='SETTLED'`, int64(a.PlayerID)) != 1 ||
		scalar(t, pool, `SELECT count(*) FROM one_on_one_records WHERE owner_player_id=$1`, int64(a.PlayerID)) != 1 {
		t.Fatal("abandoned match not settled once")
	}
}
