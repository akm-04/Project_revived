//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/binary"
	"errors"
	"reflect"
	"sync"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/rankingstore"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	gen "gxb.local/backend/v2/internal/application/generation"
	display "gxb.local/backend/v2/internal/application/playerdisplay"
	"gxb.local/backend/v2/internal/application/playerroot"
	app "gxb.local/backend/v2/internal/application/ranking"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	d "gxb.local/backend/v2/internal/domain/ranking"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Identity/resources below are explicit native fixtures. Counts are then read
// through the real canonical I4 and Character ports; no fake score provider is
// substituted. Nondefault acquisition uses privateHeroService's existing real
// SummonNormal command with the disclosed diagnostic capacity authorizer.
func rankingServer(t *testing.T, p *pg.Pool) identity.LogicalServerID {
	t.Helper()
	for i := 0; i < 20; i++ {
		u := uuid().Bytes()
		server := int64(1000 + int(binary.BigEndian.Uint16(u[:2])))
		tag, e := p.Raw().Exec(ctx, `INSERT INTO logical_servers(logical_server_id,name,first_opened_at,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,state_version,created_at)VALUES($1,'Ranking native',clock_timestamp(),true,true,true,$2,$3,1,clock_timestamp())ON CONFLICT DO NOTHING`, server, server*100000+25001, (server+1)*100000-1)
		if e != nil {
			t.Fatal(e)
		}
		if tag.RowsAffected() == 1 {
			return identity.LogicalServerID(server)
		}
	}
	t.Fatal("no isolated native server")
	return 0
}
func rankingActor(t *testing.T, p *pg.Pool, server identity.LogicalServerID, tracked bool) identity.ActorContext {
	t.Helper()
	a, s, g := uuid(), uuid(), uuid()
	var pid int64
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	if e = tr.QueryRow(ctx, `UPDATE logical_servers SET next_player_id=next_player_id+1 WHERE logical_server_id=$1 RETURNING next_player_id-1`, int64(server)).Scan(&pid); e != nil {
		t.Fatal(e)
	}
	rows := []struct {
		sql  string
		args []any
	}{
		{`INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',clock_timestamp())`, []any{a.String(), a.String()}},
		{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2,$3,clock_timestamp(),'i7c4c-ranking-native')`, []any{pid, a.String(), int64(server)}},
		{`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at)VALUES($1,$2,'i7c4c-ranking-native',clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour')`, []any{s.String(), a.String()}},
		{`INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at)VALUES($1,$2,$3,$4,$5,1,clock_timestamp())`, []any{g.String(), s.String(), a.String(), int64(server), pid}},
		{`INSERT INTO player_profiles(player_id,display_name,avatar_id,avatar_frame_id,player_type,state_version,created_at,updated_at)VALUES($1,'Ranker',110001001,0,0,1,clock_timestamp(),clock_timestamp())`, []any{pid}},
		{`INSERT INTO player_progression(player_id,level,exp,state_version,updated_at)VALUES($1,100,0,1,clock_timestamp())`, []any{pid}},
		{`INSERT INTO player_economy_owners(player_id,state_version,created_at)VALUES($1,1,clock_timestamp())`, []any{pid}},
		{`INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'mana',100000000,1,clock_timestamp())`, []any{pid}},
		{`INSERT INTO player_hero_roots(player_id,next_partner_id,sort_type,state_version,created_at,updated_at)VALUES($1,1,0,1,clock_timestamp(),clock_timestamp())`, []any{pid}},
		{`INSERT INTO player_directory_profiles(player_id,name,lev,avatar_id,avatar_frame_id,vip,conquer_lev,state_version,created_at,updated_at)VALUES($1,'Ranker',100,110001001,0,0,0,1,clock_timestamp(),clock_timestamp())`, []any{pid}},
	}
	for _, r := range rows {
		if _, e = tr.Exec(ctx, r.sql, r.args...); e != nil {
			t.Fatal(e)
		}
	}
	if tracked {
		b := logicalserver.BootstrapContext{PlayerID: identity.PlayerID(pid), LogicalServerID: server, Operation: op()}
		if e = (rankingstore.BootstrapContributor{}).PersistCharacterBootstrap(ctx, tr, b); e != nil {
			t.Fatal(e)
		}
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	aid, _ := identity.AccountIDFrom(a)
	sid, _ := identity.SessionIDFrom(s)
	cid, _ := identity.ContextIDFrom(g)
	return identity.ActorContext{AccountID: aid, AccountUID: identity.AccountUID(a.String()), SessionID: sid, ContextID: cid, LogicalServerID: server, PlayerID: identity.PlayerID(pid), ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
}
func rankingService(p *pg.Pool, db tx.Beginner) app.Service {
	return app.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: db}}, Fresh: p, Store: rankingstore.Store{}, Cohort: i4store.PlayerRootLocker{}, Directory: i4store.PlayerDirectoryReader{}, Metrics: privateMetricProvider(p), Content: contentstore.Store{Queryer: p}, Fence: i5store.Store{}, Players: i4store.PlayerRootLocker{}, Recipient: service(p, db), Ledger: i5store.Store{}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}
func rankingSummon(t *testing.T, p *pg.Pool, a identity.ActorContext, rev string, table int64) {
	t.Helper()
	co := contentstore.Store{Queryer: p}
	def, e := co.HeroNormalSummonTx(ctx, p, rev, table)
	if e != nil {
		t.Fatal(e)
	}
	exec(t, p, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,$2,10000,1,clock_timestamp(),clock_timestamp()) ON CONFLICT(player_id,item_id)DO UPDATE SET quantity=10000`, int64(a.PlayerID), def.Template.FragmentItemID)
	if _, e = privateHeroService(p).SummonNormal(ctx, a, table, def.Template.FragmentItemID, def.FragmentCount, op()); e != nil {
		t.Fatal(e)
	}
}
func rankingCount(t *testing.T, p *pg.Pool, server identity.LogicalServerID, table string) int64 {
	t.Helper()
	var n int64
	if e := p.QueryRow(ctx, `SELECT count(*) FROM `+table+` WHERE logical_server_id=$1`, int64(server)).Scan(&n); e != nil {
		t.Fatal(e)
	}
	return n
}
func TestI7C4CRankingGenuineCoherentCohortFirstWeeklyWinnersAndReplay(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	server := rankingServer(t, p)
	a := rankingActor(t, p, server, true)
	b := rankingActor(t, p, server, true)
	rankingSummon(t, p, a, rev, 10001001)
	s := rankingService(p, p)
	o := op()
	first, e := s.ReadBoard(ctx, d.GirlsBoard, a, o)
	if e != nil {
		t.Fatal(e)
	}
	if len(first.Entries) != 2 || first.Entries[0].Metric.Player != a.PlayerID || first.Entries[0].Metric.Value != 1 || first.Entries[1].Metric.Value != 0 {
		t.Fatal(first)
	}
	if rankingCount(t, p, server, "ranking_girls_awards") != 1 || rankingCount(t, p, server, "ranking_girls_periods") != 1 {
		t.Fatal("award/period count")
	}
	// A later genuine current population change changes the fresh board, while
	// the first immutable weekly generation remains the title settlement basis.
	rankingSummon(t, p, b, rev, 10001001)
	rankingSummon(t, p, b, rev, 10001002)
	later, e := s.ReadBoard(ctx, d.GirlsBoard, b, op())
	if e != nil || later.Generation != first.Generation+1 || later.Entries[0].Metric.Player != b.PlayerID || later.Entries[0].Metric.Value != 2 {
		t.Fatal(later, e)
	}
	if rankingCount(t, p, server, "ranking_girls_awards") != 1 {
		t.Fatal("weekly winners refreshed")
	}
	replay, e := s.ReadBoard(ctx, d.GirlsBoard, a, o)
	if e != nil || !reflect.DeepEqual(first, replay) {
		t.Fatal("historic snapshot receipt changed", e)
	}
	if rankingCount(t, p, server, "ranking_girls_snapshots") != 2 {
		t.Fatal("replay published new generation")
	}
	ds := service(p, p)
	ds.CatalogExternal = s
	selected, e := ds.Execute(ctx, a, display.Command{Kind: "title", ID: 100059}, op())
	if e != nil || selected.Wire["title_info"] == nil {
		t.Fatal(selected, e)
	}
	if _, e = ds.Execute(ctx, b, display.Command{Kind: "title", ID: 100059}, op()); !errors.Is(e, display.ErrRequest) {
		t.Fatal("nonwinner selected title", e)
	}
	obs, e := s.ReadCatalogDisplayOriginsTx(ctx, p, display.CatalogOriginRequest{PlayerID: a.PlayerID, Family: "title", CatalogID: 100059, Revision: rev, ObservedAt: time.Now().UTC()})
	if e != nil || !obs.Qualified || !obs.CompleteHistory || len(obs.Origins) != 1 {
		t.Fatal(obs, e)
	}
	if _, e = ds.Read(ctx, a, "titles", op()); !errors.Is(e, display.ErrUnavailable) {
		t.Fatal("partial owner promoted whole title picker", e)
	}
}
func TestI7C4CRankingMissingCanonicalParticipantBlocksWholeSnapshot(t *testing.T) {
	p := pool(t)
	installed(t, p)
	server := rankingServer(t, p)
	a := rankingActor(t, p, server, true)
	b := rankingActor(t, p, server, true)
	exec(t, p, `DELETE FROM player_hero_roots WHERE player_id=$1`, int64(b.PlayerID))
	s := rankingService(p, p)
	if _, e := s.RefreshBoard(ctx, d.GirlsBoard, a, op()); e == nil {
		t.Fatal("missing canonical owner omitted or supplied zero")
	}
	if rankingCount(t, p, server, "ranking_girls_snapshots") != 0 || rankingCount(t, p, server, "ranking_girls_roots") != 0 {
		t.Fatal("failed snapshot/root leaked")
	}
}
func TestI7C4CRankingConcurrentRefreshAndSettlementConverge(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	server := rankingServer(t, p)
	a := rankingActor(t, p, server, true)
	rankingSummon(t, p, a, rev, 10001001)
	s := rankingService(p, p)
	var wg sync.WaitGroup
	errs := make(chan error, 4)
	for i := 0; i < 4; i++ {
		wg.Add(1)
		go func() { defer wg.Done(); _, e := s.ReadBoard(ctx, d.GirlsBoard, a, op()); errs <- e }()
	}
	wg.Wait()
	close(errs)
	// Stale already-bound decision instants may be refused after waiting for a
	// newer observation; they must not resample time or publish partial state.
	successes := 0
	for e := range errs {
		if e == nil {
			successes++
		} else if !errors.Is(e, d.ErrStale) {
			t.Fatal(e)
		}
	}
	if successes < 1 || rankingCount(t, p, server, "ranking_girls_periods") != 1 || rankingCount(t, p, server, "ranking_girls_awards") != 1 {
		t.Fatal("concurrent settlement diverged", successes)
	}
	var mirrors int64
	if e := p.QueryRow(ctx, `SELECT count(*) FROM player_cosmetic_entitlements WHERE player_id=$1 AND catalog_id=100059`, int64(a.PlayerID)).Scan(&mirrors); e != nil || mirrors != 1 {
		t.Fatal(mirrors, e)
	}
}
func TestI7C4CRankingLegacyUnknownAndFreshNegativeAreDistinct(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	server := rankingServer(t, p)
	known := rankingActor(t, p, server, true)
	unknown := rankingActor(t, p, server, false)
	s := rankingService(p, p)
	for _, a := range []identity.ActorContext{known, unknown} {
		q := display.CatalogOriginRequest{PlayerID: a.PlayerID, Family: "title", CatalogID: 100059, Revision: rev, ObservedAt: time.Now().UTC()}
		v, e := s.ReadCatalogDisplayOriginsTx(ctx, p, q)
		if e != nil || !v.Qualified || len(v.Origins) != 0 || v.CompleteHistory != (a.PlayerID == known.PlayerID) {
			t.Fatal(v, e)
		}
		ds := service(p, p)
		ds.CatalogExternal = s
		_, e = ds.Execute(ctx, a, display.Command{Kind: "title", ID: 100059}, op())
		want := display.ErrUnavailable
		if a.PlayerID == known.PlayerID {
			want = display.ErrRequest
		}
		if !errors.Is(e, want) {
			t.Fatal("unknown history became zero", a.PlayerID, e)
		}
	}
}

type rankingFailRecipient struct{ Inner app.Recipient }

var errRankingRecipient = errors.New("injected ranking recipient failure after real write")

func (f rankingFailRecipient) ReceiveOriginTx(c context.Context, tr tx.Tx, r playerroot.Root, o display.Origin) error {
	if e := f.Inner.ReceiveOriginTx(c, tr, r, o); e != nil {
		return e
	}
	return errRankingRecipient
}
func TestI7C4CRankingAtomicRecipientRollbackAndRetry(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	server := rankingServer(t, p)
	a := rankingActor(t, p, server, true)
	rankingSummon(t, p, a, rev, 10001001)
	s := rankingService(p, p)
	snapshot, e := s.RefreshBoard(ctx, d.GirlsBoard, a, op())
	if e != nil {
		t.Fatal(e)
	}
	broken := s
	broken.Recipient = rankingFailRecipient{Inner: s.Recipient}
	if _, e = broken.SettlePendingBoard(ctx, d.GirlsBoard, server, op()); !errors.Is(e, errRankingRecipient) {
		t.Fatal(e)
	}
	if rankingCount(t, p, server, "ranking_girls_awards") != 0 {
		t.Fatal("canonical award leaked")
	}
	var mirrors int64
	if e = p.QueryRow(ctx, `SELECT count(*) FROM player_cosmetic_entitlements WHERE player_id=$1`, int64(a.PlayerID)).Scan(&mirrors); e != nil || mirrors != 0 {
		t.Fatal("recipient leaked", mirrors, e)
	}
	pending, e := (rankingstore.Store{}).PendingBoardPeriodsTx(ctx, p, d.GirlsBoard, server)
	if e != nil || len(pending) != 1 || pending[0].Generation != snapshot.Generation {
		t.Fatal(pending, e)
	}
	result, e := s.SettlePendingBoard(ctx, d.GirlsBoard, server, op())
	if e != nil || len(result) != 1 || result[0].SnapshotDigest != snapshot.Digest || rankingCount(t, p, server, "ranking_girls_awards") != 1 {
		t.Fatal(result, e)
	}
	again, e := s.SettlePendingBoard(ctx, d.GirlsBoard, server, op())
	if e != nil || len(again) != 0 || rankingCount(t, p, server, "ranking_girls_awards") != 1 {
		t.Fatal(again, e)
	}
}
func TestI7C4CRankingUnknownCommitPositiveAndAbsenceUnresolved(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	server := rankingServer(t, p)
	a := rankingActor(t, p, server, true)
	rankingSummon(t, p, a, rev, 10001001)
	ambiguous := rankingService(p, metricCommitDB{p, true})
	o := op()
	first, e := ambiguous.RefreshBoard(ctx, d.GirlsBoard, a, o)
	if e != nil {
		t.Fatal(e)
	}
	again, e := rankingService(p, p).RefreshBoard(ctx, d.GirlsBoard, a, o)
	if e != nil || !reflect.DeepEqual(first, again) {
		t.Fatal("unknown commit proof lost", e)
	}
	settled, e := ambiguous.SettlePendingBoard(ctx, d.GirlsBoard, server, op())
	if e != nil || len(settled) != 1 || rankingCount(t, p, server, "ranking_girls_awards") != 1 {
		t.Fatal(settled, e)
	}
	// Commit result is deliberately made ambiguous while the real transaction is
	// rolled back. Generic receipt absence must remain unresolved, not replay.
	otherServer := rankingServer(t, p)
	other := rankingActor(t, p, otherServer, true)
	absent := rankingService(p, metricCommitDB{p, false})
	if _, e = absent.RefreshBoard(ctx, d.GirlsBoard, other, op()); e == nil {
		t.Fatal("absence treated as positive commit")
	}
	if rankingCount(t, p, otherServer, "ranking_girls_snapshots") != 0 || rankingCount(t, p, otherServer, "ranking_girls_roots") != 0 {
		t.Fatal("rolled back unknown left snapshot")
	}
}
func TestI7C4CRankingFixedExpiryAndUnknownLegacyExpiry(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	for _, tracked := range []bool{true, false} {
		server := rankingServer(t, p)
		a := rankingActor(t, p, server, tracked)
		rankingSummon(t, p, a, rev, 10001001)
		s := rankingService(p, p)
		snapshot, e := s.ReadBoard(ctx, d.GirlsBoard, a, op())
		if e != nil {
			t.Fatal(e)
		}
		ds := service(p, p)
		ds.CatalogExternal = s
		if _, e = ds.Execute(ctx, a, display.Command{Kind: "title", ID: 100059}, op()); e != nil {
			t.Fatal(e)
		}
		end := snapshot.ObservedAt.Unix() + d.BoardTitleDuration
		before, e := ds.ObserveTx(ctx, p, a.PlayerID, rev, time.Unix(end-1, 999999999).UTC())
		if e != nil || before.TitleID != 100059 || before.TitleEndTime != end {
			t.Fatal(before, e)
		}
		for _, at := range []time.Time{time.Unix(end, 0).UTC(), time.Unix(end+1, 0).UTC()} {
			expired, e := ds.ObserveTx(ctx, p, a.PlayerID, rev, at)
			if tracked {
				if e != nil || expired.TitleID != 0 {
					t.Fatal("fresh qualified expiry", expired, e)
				}
			} else if !errors.Is(e, display.ErrUnavailable) {
				t.Fatal("unknown legacy history fabricated as absence", expired, e)
			}
		}
		// Selection/reload cannot extend the immutable deadline.
		if _, e = ds.Execute(ctx, a, display.Command{Kind: "title", ID: 100059}, op()); e != nil {
			t.Fatal(e)
		}
		v, e := s.ReadCatalogDisplayOriginsTx(ctx, p, display.CatalogOriginRequest{PlayerID: a.PlayerID, Family: "title", CatalogID: 100059, Revision: rev, ObservedAt: time.Now().UTC()})
		if e != nil || len(v.Origins) != 1 || v.Origins[0].EndTime != end {
			t.Fatal(v, e)
		}
	}
}
func TestI7C4CRankingRecipientMismatchIsNotQualifiedOrigin(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	server := rankingServer(t, p)
	a := rankingActor(t, p, server, true)
	rankingSummon(t, p, a, rev, 10001001)
	s := rankingService(p, p)
	if _, e := s.ReadBoard(ctx, d.GirlsBoard, a, op()); e != nil {
		t.Fatal(e)
	}
	exec(t, p, `UPDATE player_cosmetic_entitlements SET end_time=end_time+1 WHERE player_id=$1 AND catalog_id=100059`, int64(a.PlayerID))
	q := display.CatalogOriginRequest{PlayerID: a.PlayerID, Family: "title", CatalogID: 100059, Revision: rev, ObservedAt: time.Now().UTC()}
	if _, e := s.ReadCatalogDisplayOriginsTx(ctx, p, q); !errors.Is(e, display.ErrConflict) {
		t.Fatal("recipient mirror became canonical truth", e)
	}
}

func TestI7C4CRankingScopedFactsKeepUnrelatedOriginsUnknown(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	server := rankingServer(t, p)
	a := rankingActor(t, p, server, true)
	rankingSummon(t, p, a, rev, 10001001)
	rank := rankingService(p, p)
	if _, e := rank.ReadBoard(ctx, d.GirlsBoard, a, op()); e != nil {
		t.Fatal(e)
	}
	ds := display4a(p)
	ds.CatalogExternal = rank
	var facts display.EligibilityObservation
	_, _, e := rank.Timed.Run(ctx, opPinned(rev), app.Profile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc gen.TimedScope) error {
		witness, e := ca.NewCoherentReadScope(tx.Scope{Tx: sc.Tx, Operation: sc.Operation.Operation(), Attempt: sc.Attempt, Options: sc.Options}, rev, sc.Operation.DecisionAt())
		if e != nil {
			return e
		}
		facts, e = ds.ReadEligibilityTx(c, witness, display.EligibilityRequest{PlayerID: a.PlayerID, Family: "title"})
		if e != nil {
			return e
		}
		if _, e = ds.ReadEligibilityTx(c, witness, display.EligibilityRequest{PlayerID: a.PlayerID, Family: "title", CompleteFamily: true}); !errors.Is(e, display.ErrUnavailable) {
			t.Fatal("scoped positives promoted complete family", e)
		}
		return nil
	})
	if e != nil {
		t.Fatal(e)
	}
	winner := fact4a(t, facts, 100059, 0)
	if winner.Status != display.Eligible || len(winner.Origins) != 1 || winner.Origins[0].Owner != "Ranking" {
		t.Fatal("genuine winner absent", winner)
	}
	for _, id := range []int64{100060, 100061, 100062} {
		if f := fact4a(t, facts, id, 0); f.Status != display.Ineligible {
			t.Fatal("fresh known negative became unknown", f)
		}
	}
	if f := fact4a(t, facts, 100063, 0); f.Status != display.Ineligible {
		t.Fatal("Skins board title is a Ranking-owned known negative", f)
	}
	if f := fact4a(t, facts, 100022, 0); f.Status != display.Unavailable {
		t.Fatal("Ranking owner certified unrelated Library title", f)
	}
	if facts.CompleteFamily || len(facts.MissingProviders) == 0 {
		t.Fatal("partial facts promoted complete", facts)
	}
}
