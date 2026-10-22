//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/achievementstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/leaguestore"
	ach "gxb.local/backend/v2/internal/application/achievement"
	app "gxb.local/backend/v2/internal/application/championsleague"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	display "gxb.local/backend/v2/internal/application/playerdisplay"
	"gxb.local/backend/v2/internal/application/playerroot"
	d "gxb.local/backend/v2/internal/domain/championsleague"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sync"
	"testing"
	"time"
)

type leagueClock struct {
	mu sync.RWMutex
	at time.Time
}

func (c *leagueClock) Now(context.Context) (time.Time, error) {
	c.mu.RLock()
	defer c.mu.RUnlock()
	return c.at, nil
}
func (c *leagueClock) Set(at time.Time) { c.mu.Lock(); c.at = at; c.mu.Unlock() }
func leagueService(t *testing.T, p *pg.Pool, clock gen.TimeAuthority) app.Service {
	t.Helper()
	fight := combatService(t, p)
	values := i5store.Store{Queryer: p}
	content := contentstore.Store{Queryer: p}
	runner := tx.Runner{DB: p}
	grants := i5.Service{Runner: runner, Store: values, Content: content, Privileges: i5.BaselinePrivilegeProvider{}, Functions: i5.PetStarterFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{}, Backpack: values, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, RedeemSecret: []byte("i7c5f-league-native-fixture-secret")}
	return app.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: clock}, Runner: runner}, Fresh: p, Store: leaguestore.Store{}, Content: content, Fence: values, Heroes: fight.Inputs.Heroes, Pets: fight.Inputs.Pets, Directory: i4store.PlayerDirectoryReader{}, Guilds: guildstore.Store{}, Progression: values, Combat: fight, Grants: grants, Mail: i5.SettlementMail{Store: values}, Achievements: ach.Service{Store: achievementstore.Store{}, Content: content, Population: libraryService(p, p)}, Players: i4store.PlayerRootLocker{}, Recipient: display.Service{Store: values, Content: content}, Entitlements: values, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}
func leagueReset(t *testing.T, p *pg.Pool) {
	t.Helper()
	exec(t, p, `DELETE FROM league_cosmetic_origins;DELETE FROM league_settlements;DELETE FROM league_matches;DELETE FROM league_players;DELETE FROM league_competitions;`)
}
func leagueCatalog(t *testing.T, p *pg.Pool) d.Catalog {
	t.Helper()
	rev := installed(t, p)
	c, e := (contentstore.Store{}).LeagueCatalogTx(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	return c
}
func leaguePlayer(t *testing.T, p *pg.Pool, server identity.LogicalServerID, level int64) (identity.ActorContext, int64) {
	t.Helper()
	a, rev, h := combatOwner(t, p, server)
	exec(t, p, `UPDATE player_progression SET level=$2 WHERE player_id=$1`, int64(a.PlayerID), level)
	exec(t, p, `UPDATE player_directory_profiles SET lev=$2 WHERE player_id=$1`, int64(a.PlayerID), level)
	exec(t, p, `INSERT INTO player_function_eligibility(player_id,function_id,content_revision,source_fact_key,eligible_at)VALUES($1,91,$2,'function.lua:91:1|70',clock_timestamp()-interval '1 minute')`, int64(a.PlayerID), rev)
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
	return a, h.PartnerID
}
func leagueDo(t *testing.T, s app.Service, a identity.ActorContext, c app.Command) app.Reply {
	t.Helper()
	v, e := s.Execute(ctx, a, c, op())
	if e != nil {
		t.Fatalf("%s: %v", c.Kind, e)
	}
	return v
}
func leagueActors(t *testing.T, p *pg.Pool) (app.Service, *leagueClock, d.Catalog, identity.ActorContext, identity.ActorContext, int64, int64) {
	t.Helper()
	leagueReset(t, p)
	cat := leagueCatalog(t, p)
	at := cat.SeasonAt(time.Now().Add(90 * 24 * time.Hour)).OpensAt.Add(10 * time.Hour)
	clock := &leagueClock{at: at}
	s := leagueService(t, p, clock)
	a, ha := leaguePlayer(t, p, rankingServer(t, p), 100)
	b, hb := leaguePlayer(t, p, rankingServer(t, p), 100)
	for _, x := range []struct {
		a identity.ActorContext
		h int64
	}{{a, ha}, {b, hb}} {
		leagueDo(t, s, x.a, app.Command{Kind: "INFO"})
		leagueDo(t, s, x.a, app.Command{Kind: "DEFENSE", Lineup: d.Lineup{Heroes: []int64{x.h}}})
	}
	return s, clock, cat, a, b, ha, hb
}
func leagueFight(t *testing.T, s app.Service, a, b identity.ActorContext, hero int64) app.Reply {
	t.Helper()
	leagueDo(t, s, a, app.Command{Kind: "ENEMY", Enemy: b.PlayerID})
	cmd := app.Command{Kind: "FIGHT", Enemy: b.PlayerID, Lineup: d.Lineup{Heroes: []int64{hero}}}
	for i := 0; i < 100; i++ {
		v := leagueDo(t, s, a, cmd)
		if len(v.Report) > 0 {
			return v
		}
	}
	t.Fatal("battle never resolved")
	return app.Reply{}
}
func leagueScalar(t *testing.T, p *pg.Pool, sql string, args ...any) int64 {
	t.Helper()
	var n int64
	if e := p.QueryRow(ctx, sql, args...).Scan(&n); e != nil {
		t.Fatal(e)
	}
	return n
}
func TestI7C5FLeagueGenuineFightReplayAndClockNative(t *testing.T) {
	p := pool(t)
	s, clock, cat, a, b, ha, _ := leagueActors(t, p)
	// A projection-only level cannot establish admission.
	low, lowRev, _ := combatOwner(t, p, rankingServer(t, p))
	exec(t, p, `UPDATE player_directory_profiles SET lev=100 WHERE player_id=$1`, int64(low.PlayerID))
	exec(t, p, `UPDATE player_progression SET level=1 WHERE player_id=$1`, int64(low.PlayerID))
	exec(t, p, `INSERT INTO player_function_eligibility(player_id,function_id,content_revision,source_fact_key,eligible_at)VALUES($1,91,$2,'function.lua:91:1|70',clock_timestamp()-interval '1 minute')`, int64(low.PlayerID), lowRev)
	if _, e := s.Execute(ctx, low, app.Command{Kind: "INFO"}, op()); e == nil {
		t.Fatal("directory projection became gameplay authority")
	}
	if _, e := s.Execute(ctx, a, app.Command{Kind: "DEFENSE", Lineup: d.Lineup{Heroes: []int64{10001001}}}, op()); e == nil {
		t.Fatal("tableID accepted as owned instance")
	}
	leagueDo(t, s, a, app.Command{Kind: "ENEMY", Enemy: b.PlayerID})
	cmd := app.Command{Kind: "FIGHT", Enemy: b.PlayerID, Lineup: d.Lineup{Heroes: []int64{ha}}}
	var wg sync.WaitGroup
	outcomes := make(chan error, 3)
	for i := 0; i < 3; i++ {
		wg.Add(1)
		go func() { defer wg.Done(); _, e := s.Execute(ctx, a, cmd, op()); outcomes <- e }()
	}
	wg.Wait()
	close(outcomes)
	for e := range outcomes {
		if e != nil {
			t.Fatal("concurrent fight intent", e)
		}
	}
	fight := leagueDo(t, s, a, cmd)
	if len(fight.Report) == 0 {
		t.Fatal("concurrent fight never finished")
	}

	if fight.Match.Status != "SETTLED" || len(fight.Report) == 0 || fight.Match.Delta == 0 {
		t.Fatal("genuine fight", fight.Match)
	}
	if leagueScalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='ACADEMY_LEAGUE' AND actor_player_id=$1`, int64(a.PlayerID)) != 1 {
		t.Fatal("attempt multiplicity")
	}
	replay := leagueDo(t, s, a, app.Command{Kind: "FIGHT", Enemy: b.PlayerID, Lineup: d.Lineup{Heroes: []int64{ha}}})
	if replay.Match.ID != fight.Match.ID || string(replay.Report) != string(fight.Report) {
		t.Fatal("retry changed battle")
	}
	players, e := s.Store.PlayersTx(ctx, p, false)
	if e != nil {
		t.Fatal(e)
	}
	var total int64
	for _, x := range players {
		total += x.Points
	}
	if total != 4000 {
		t.Fatal("points not conserved", total)
	}
	records := leagueDo(t, s, a, app.Command{Kind: "RECORDS"})
	if len(records.Records) != 1 {
		t.Fatal("records")
	}
	id := records.Records[0].WireID
	r := leagueDo(t, s, a, app.Command{Kind: "RECORDS", RecordID: id})
	if string(r.Report) != string(fight.Report) {
		t.Fatal("replay locator")
	}
	// No invented report from the client; expiry leaves durable records intact.
	clock.Set(fight.Match.SettledAt.Add(app.ReportRetention.Window))
	r = leagueDo(t, s, a, app.Command{Kind: "RECORDS", RecordID: id})
	if len(r.Report) != 0 || len(r.Records) != 1 {
		t.Fatal("expired replay lost record")
	}
	// Canonical owner clock reversal refuses effects.
	clock.Set(cat.SeasonNumbered(fight.Match.Season).OpensAt)
	if _, e = s.Execute(ctx, a, app.Command{Kind: "INFO"}, op()); e == nil {
		t.Fatal("backwards clock accepted mutation")
	}
}
func TestI7C5FLeagueSeasonOriginsTenRealSeasonsNative(t *testing.T) {
	p := pool(t)
	s, clock, cat, a, b, ha, _ := leagueActors(t, p)
	first, _ := clock.Now(ctx)
	season := cat.SeasonAt(first)
	for n := int64(1); n <= 10; n++ {
		if n > 1 {
			clock.Set(season.OpensAt.Add(10 * time.Hour))
			if e := s.Due(ctx, op(), 100); e != nil {
				t.Fatal(e)
			}
			leagueDo(t, s, a, app.Command{Kind: "INFO"})
			leagueDo(t, s, b, app.Command{Kind: "INFO"})
		}
		fight := leagueFight(t, s, a, b, ha)
		clock.Set(season.ClosesAt)
		if e := s.Due(ctx, op(), 100); e != nil {
			t.Fatal("season cutoff", e)
		}
		snap, ok, e := s.Store.SettlementTx(ctx, p, "SEASON", season.Number)
		if e != nil || !ok || len(snap.Rows) != 2 {
			t.Fatal("snapshot", e)
		}
		for _, who := range []identity.ActorContext{a, b} {
			rows, e := s.ReadCatalogDisplayOriginsTx(ctx, p, display.CatalogOriginRequest{PlayerID: who.PlayerID, Family: "title", CatalogID: cat.TitleIDs[n-1], Revision: snap.Revision, ObservedAt: season.ClosesAt})
			if e != nil || !rows.Qualified || len(rows.Origins) != 1 || rows.CompleteHistory {
				t.Fatal("canonical title proof", n, e, rows)
			}
		}
		// Rest freezes outcomes, not the next season. No reset or repeat payout.
		info := leagueDo(t, s, a, app.Command{Kind: "INFO"})
		if info.Info.Active || info.Info.Player.Season != season.Number {
			t.Fatal("rest reset early")
		}
		if _, e = s.Execute(ctx, a, app.Command{Kind: "FIGHT", Enemy: b.PlayerID, Lineup: d.Lineup{Heroes: []int64{ha}}}, op()); e == nil {
			t.Fatal("rest fight accepted")
		}
		if e = s.Due(ctx, op(), 100); e != nil {
			t.Fatal(e)
		}
		if leagueScalar(t, p, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='CHAMPIONS_LEAGUE_SEASON'`, int64(a.PlayerID)) != n {
			t.Fatal("duplicate/missing season mail", n)
		}
		if fight.Match.Attempt.IsZero() {
			t.Fatal("synthetic season result")
		}
		season = cat.SeasonNumbered(season.Number + 1)
	}
	if leagueScalar(t, p, `SELECT count(*) FROM league_cosmetic_origins WHERE player_id=$1 AND family='title'`, int64(a.PlayerID)) != 10 {
		t.Fatal("cumulative title profile")
	}
	// Exact mirror deletion makes the scoped provider fail closed.
	exec(t, p, `DELETE FROM player_cosmetic_entitlements WHERE player_id=$1 AND origin_owner='ChampionsLeague' AND family='title' AND catalog_id=$2`, int64(a.PlayerID), cat.TitleIDs[9])
	rev, _ := s.Content.ActiveRevision(ctx, p)
	if _, e := s.ReadCatalogDisplayOriginsTx(ctx, p, display.CatalogOriginRequest{PlayerID: a.PlayerID, Family: "title", CatalogID: cat.TitleIDs[9], Revision: rev, ObservedAt: season.OpensAt}); e == nil {
		t.Fatal("orphan origin qualified")
	}
}

type leagueRecipientFailure struct{ base app.Recipient }

func (f leagueRecipientFailure) ReceiveOriginTx(c context.Context, t tx.Tx, r playerroot.Root, o display.Origin) error {
	if e := f.base.ReceiveOriginTx(c, t, r, o); e != nil {
		return e
	}
	return errors.New("injected after recipient insert")
}
func TestI7C5FLeagueCutoffRollbackUnknownCommitNative(t *testing.T) {
	p := pool(t)
	s, clock, cat, a, b, ha, _ := leagueActors(t, p)
	leagueFight(t, s, a, b, ha)
	at, _ := clock.Now(ctx)
	season := cat.SeasonAt(at)
	clock.Set(season.ClosesAt)
	good := s.Recipient
	s.Recipient = leagueRecipientFailure{good}
	if e := s.Due(ctx, op(), 100); e == nil {
		t.Fatal("injected recipient failure hidden")
	}
	if leagueScalar(t, p, `SELECT count(*) FROM league_settlements WHERE kind='SEASON'`) != 0 || leagueScalar(t, p, `SELECT count(*) FROM league_cosmetic_origins`) != 0 || leagueScalar(t, p, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='CHAMPIONS_LEAGUE_SEASON'`, int64(a.PlayerID)) != 0 {
		t.Fatal("partial season effects leaked")
	}
	s.Recipient = good
	s.Timed.Runner.DB = metricCommitDB{p, true}
	if e := s.Due(ctx, op(), 100); e != nil {
		t.Fatal("positive cutoff COMMIT proof", e)
	}
	// A missing receipt after ambiguous rollback is UNKNOWN, never success.
	clock.Set(season.NextAt.Add(10 * time.Hour))
	s.Timed.Runner.DB = p
	if e := s.Due(ctx, op(), 100); e != nil {
		t.Fatal(e)
	}
	s.Timed.Runner.DB = metricCommitDB{p, false}
	_, e := s.Execute(ctx, a, app.Command{Kind: "DEFENSE", Lineup: d.Lineup{Heroes: []int64{ha}}}, op())
	var unknown *tx.UnknownCommitError
	if !errors.As(e, &unknown) {
		t.Fatal("absence became success", e)
	}
}
func TestI7C5FLeagueAdmissionUnknownCommitAndCanonicalPromotionNative(t *testing.T) {
	p := pool(t)
	s, clock, _, a, _, ha, _ := leagueActors(t, p)
	s.Timed.Runner.DB = metricCommitDB{p, true}
	cmd := app.Command{Kind: "DEFENSE", Lineup: d.Lineup{Heroes: []int64{ha}}}
	if _, e := s.Execute(ctx, a, cmd, op()); e != nil {
		t.Fatal("positive command COMMIT proof", e)
	}
	// Enter a genuine lower-group mode state, then change its canonical input.
	s.Timed.Runner.DB = p
	low, hero := leaguePlayer(t, p, rankingServer(t, p), 70)
	leagueDo(t, s, low, app.Command{Kind: "INFO"})
	leagueDo(t, s, low, app.Command{Kind: "DEFENSE", Lineup: d.Lineup{Heroes: []int64{hero}}})
	exec(t, p, `UPDATE player_progression SET level=100,state_version=state_version+1 WHERE player_id=$1`, int64(low.PlayerID))
	exec(t, p, `UPDATE player_directory_profiles SET lev=100 WHERE player_id=$1`, int64(low.PlayerID))
	at, _ := clock.Now(ctx)
	clock.Set(at.Add(time.Second))
	v := leagueDo(t, s, low, app.Command{Kind: "INFO"})
	if v.Info.Player.Group != 3 || v.Info.Player.Points != 2000 || !v.Info.Player.ChoicePending || v.Info.Player.Prior.Group != 1 {
		t.Fatal("promotion", v.Info.Player)
	}
	leagueDo(t, s, low, app.Command{Kind: "CHOOSE", UseOriginal: false})
	v = leagueDo(t, s, low, app.Command{Kind: "INFO"})
	if v.Info.Player.Choice != 0 || v.Info.Player.ChoicePending {
		t.Fatal("choice")
	}

}

func TestI7C5FLeagueDailyConcurrentOverflowAndProtectionNative(t *testing.T) {
	p := pool(t)
	s, clock, cat, a, b, ha, _ := leagueActors(t, p)
	leagueFight(t, s, a, b, ha)
	// New intent cannot bypass an opponent's actual protection reservation.
	leagueDo(t, s, a, app.Command{Kind: "ENEMY", Enemy: b.PlayerID})
	if _, e := s.Execute(ctx, a, app.Command{Kind: "FIGHT", Enemy: b.PlayerID, Lineup: d.Lineup{Heroes: []int64{ha}}}, op()); e == nil {
		t.Fatal("protection bypass")
	}
	at, _ := clock.Now(ctx)
	clock.Set(cat.DayAt(cat.Day(at) + 1).Add(time.Second))
	if e := s.Due(ctx, op(), 100); e != nil {
		t.Fatal(e)
	}
	if _, e := s.Execute(ctx, a, app.Command{Kind: "CLAIM"}, op()); e == nil {
		t.Fatal("yesterday win claimed today's chest")
	}
	fight := leagueFight(t, s, a, b, ha)
	winner := a
	if !fight.Match.Win {
		winner = b
	}
	// Saturate one actual source gift item using its catalog cap, forcing I5 overflow Mail.
	info := leagueDo(t, s, winner, app.Command{Kind: "INFO"})
	gift := cat.DailyGift(info.Info.Player.LastDay.Group, info.Info.Player.LastDay.Rank)
	if len(gift.Items) == 0 {
		t.Fatal("missing actual gift")
	}
	item := int64(50001005)
	found := false
	for _, it := range gift.Items {
		if it[0] == item {
			found = true
		}
	}
	if !found {
		t.Fatal("expected source gift overflow item", gift)
	}
	// Source ordinary stack cap9999: verified below by the real I5 settlement.
	exec(t, p, `INSERT INTO player_item_stacks(player_id,item_id,quantity,acquired_at,updated_at)VALUES($1,$2,9999,clock_timestamp(),clock_timestamp()) ON CONFLICT(player_id,item_id)DO UPDATE SET quantity=9999`, int64(winner.PlayerID), item)
	before := leagueScalar(t, p, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1`, int64(winner.PlayerID))
	var wg sync.WaitGroup
	errs := make(chan error, 8)
	success := make(chan app.Reply, 8)
	for i := 0; i < 8; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			v, e := s.Execute(ctx, winner, app.Command{Kind: "CLAIM"}, op())
			if e == nil {
				success <- v
			} else {
				errs <- e
			}
		}()
	}
	wg.Wait()
	close(success)
	close(errs)
	if len(success) != 1 {
		t.Fatal("daily award multiplicity", len(success), len(errs))
	}
	for e := range errs {
		var unknown *tx.UnknownCommitError
		if errors.As(e, &unknown) {
			t.Fatal("unexpected ambiguous commit", e)
		}
	}
	if leagueScalar(t, p, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1`, int64(winner.PlayerID)) != before+1 {
		t.Fatal("overflow Mail not exactly once")
	}
	if leagueScalar(t, p, `SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=$2`, int64(winner.PlayerID), item) != 9999 {
		t.Fatal("overflow exceeded cap")
	}
	for i := 0; i < 2; i++ {
		if _, e := s.Execute(ctx, winner, app.Command{Kind: "CLAIM"}, op()); e == nil {
			t.Fatal("new operation repeated daily payout")
		}
	}
	if leagueScalar(t, p, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1`, int64(winner.PlayerID)) != before+1 {
		t.Fatal("duplicate overflow Mail")
	}
}

func TestI7C5FLeagueBubbleEligibilitySelectionExpiryNative(t *testing.T) {
	p := pool(t)
	s, clock, cat, a, b, ha, _ := leagueActors(t, p)
	leagueFight(t, s, a, b, ha)
	at, _ := clock.Now(ctx)
	season := cat.SeasonAt(at)
	clock.Set(season.ClosesAt)
	if e := s.Due(ctx, op(), 100); e != nil {
		t.Fatal(e)
	}
	rev, _ := s.Content.ActiveRevision(ctx, p)
	awards, e := s.Store.OriginsTx(ctx, p, a.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	var bubble display.Origin
	for _, x := range awards {
		if x.Origin.Family == "bubble" {
			bubble = x.Origin
		}
	}
	if bubble.CatalogID == 0 || bubble.EndTime != season.ClosesAt.Unix()+cat.BubbleSeconds {
		t.Fatal("source bubble duration", bubble)
	}
	view := display4a(p)
	view.Time = clock
	view.CatalogExternal = display.CatalogOriginRoutes{{Family: "bubble", First: 10002, Last: 10007, Owner: s}, {Family: "title", First: 100104, Last: 100121, Owner: s}}
	read := func(at time.Time) display.EligibilityObservation {
		t.Helper()
		var out display.EligibilityObservation
		_, e := (tx.Runner{DB: p}).Run(ctx, opPinned(rev), i5.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, x tx.Scope) error {
			sc, e := ca.NewCoherentReadScope(x, rev, at)
			if e != nil {
				return e
			}
			out, e = view.ReadEligibilityTx(c, sc, display.EligibilityRequest{PlayerID: a.PlayerID, Family: "bubble"})
			return e
		})
		if e != nil {
			t.Fatal(e)
		}
		return out
	}
	findStatus := func(o display.EligibilityObservation, id int64) string {
		for _, f := range o.Facts {
			if f.CatalogID == id {
				return f.Status
			}
		}
		t.Fatal("missing bubble fact", id)
		return ""
	}
	if findStatus(read(season.ClosesAt), bubble.CatalogID) != display.Eligible {
		t.Fatal("genuine bubble unavailable")
	}
	if _, e = view.Execute(ctx, a, display.Command{Kind: "bubble", ID: bubble.CatalogID}, op()); e != nil {
		t.Fatal("select genuine bubble", e)
	}
	clock.Set(time.Unix(bubble.EndTime, 0))
	if findStatus(read(time.Unix(bubble.EndTime, 0)), bubble.CatalogID) == display.Eligible {
		t.Fatal("expired bubble eligible")
	}
	if _, e = view.Execute(ctx, a, display.Command{Kind: "bubble", ID: bubble.CatalogID}, op()); e == nil {
		t.Fatal("expired bubble selected")
	}
}

// Standalone fresh production-clock smoke; qualification selects it before the
// injected future-calendar cases. It proves PostgreSQL time, not a client run.
func TestI7C5FLeagueProductionClockInfoNative(t *testing.T) {
	p := pool(t)
	leagueReset(t, p)
	s := leagueService(t, p, pg.AuthoritativeTime{Queryer: p})
	a, _ := leaguePlayer(t, p, rankingServer(t, p), 100)
	before, e := (pg.AuthoritativeTime{Queryer: p}).Now(ctx)
	if e != nil {
		t.Fatal(e)
	}
	v := leagueDo(t, s, a, app.Command{Kind: "INFO"})
	after, e := (pg.AuthoritativeTime{Queryer: p}).Now(ctx)
	if e != nil {
		t.Fatal(e)
	}
	if v.Info.At.Before(before) || v.Info.At.After(after) || v.Info.Player.Season != leagueCatalog(t, p).SeasonAt(v.Info.At).Number {
		t.Fatal("production time or season", v.Info)
	}
}

// A read-only handoff probe against a populated relocated database; no reset,
// new fight or altered clock can hide a missing durable owner/reference.
func TestI7C5FLeagueRecoveredRowsNative(t *testing.T) {
	p := pool(t)
	s := leagueService(t, p, pg.AuthoritativeTime{Queryer: p})
	root, ok, e := s.Store.RootTx(ctx, p, false)
	if e != nil || !ok {
		t.Fatal("missing recovered League", e)
	}
	players, e := s.Store.PlayersTx(ctx, p, false)
	if e != nil || len(players) < 2 {
		t.Fatal("missing recovered players", e)
	}
	if leagueScalar(t, p, `SELECT count(*) FROM league_matches WHERE payload->>'Status'='SETTLED'`) < 1 {
		t.Fatal("missing genuine recovered match")
	}
	for _, x := range players {
		if e := x.Validate(); e != nil {
			t.Fatal(e)
		}
		awards, e := s.Store.OriginsTx(ctx, p, x.ID)
		if e != nil {
			t.Fatal(e)
		}
		for _, a := range awards {
			at := root.UpdatedAt
			if at.Before(*a.Origin.StartsAt) {
				at = *a.Origin.StartsAt
			}
			_, e = s.ReadCatalogDisplayOriginsTx(ctx, p, display.CatalogOriginRequest{PlayerID: x.ID, Family: a.Origin.Family, CatalogID: a.Origin.CatalogID, Revision: root.Revision, ObservedAt: at})
			if e != nil {
				t.Fatal("recovered origin", e)
			}
		}
	}
}
