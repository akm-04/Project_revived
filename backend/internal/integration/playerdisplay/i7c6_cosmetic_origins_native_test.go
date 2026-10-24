//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/arenastore"
	"gxb.local/backend/v2/internal/adapters/postgres/bookstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	apparena "gxb.local/backend/v2/internal/application/arena"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/i5"
	app "gxb.local/backend/v2/internal/application/playerdisplay"
	book "gxb.local/backend/v2/internal/domain/bookskill"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func cosmeticOriginRoutes(p *pg.Pool) app.CatalogOriginRoutes {
	content := contentstore.Store{Queryer: p}
	return app.CatalogOriginRoutes{
		{Family: "title", First: 100022, Last: 100023, Owner: app.ProgressTitleOrigins{Owner: "Library", TitleType: 5, Content: content, Progress: libraryService(p, p)}},
		{Family: "title", First: 100024, Last: 100025, Owner: app.ProgressTitleOrigins{Owner: "BookSkill", TitleType: 6, Content: content, Progress: bookService(p, p)}},
		{Family: "title", First: 100026, Last: 100028, Owner: app.ProgressTitleOrigins{Owner: "Dormhouse", TitleType: 7, Content: content, Progress: dormService(p, p)}},
		{Family: "avatar", First: 110006001, Last: 110006001, Owner: apparena.Service{Store: arenastore.Store{}, Content: content}},
	}
}

func cosmeticFacts(t *testing.T, p *pg.Pool, a identity.ActorContext, rev, family string) app.EligibilityObservation {
	t.Helper()
	s := display4a(p)
	s.CatalogExternal = cosmeticOriginRoutes(p)
	var out app.EligibilityObservation
	_, e := (tx.Runner{DB: p}).Run(ctx, opPinned(rev), i5.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, s2 tx.Scope) error {
		at, e := (pg.AuthoritativeTime{Queryer: s2.Tx}).Now(c)
		if e != nil {
			return e
		}
		sc, e := ca.NewCoherentReadScope(s2, rev, at)
		if e != nil {
			return e
		}
		out, e = s.ReadEligibilityTx(c, sc, app.EligibilityRequest{PlayerID: a.PlayerID, Family: family})
		return e
	})
	if e != nil {
		t.Fatal(e)
	}
	return out
}

func expectStatus(t *testing.T, o app.EligibilityObservation, id, category int64, want string) app.EligibilityFact {
	t.Helper()
	f := fact4a(t, o, id, category)
	if f.Status != want {
		t.Fatal("catalog row", id, "status", f.Status, "want", want, f)
	}
	return f
}

func TestI7C6MarriageTitlesKeepHighWaterNative(t *testing.T) {
	p := pool(t)
	a, rev := libraryFixture(t, p, true)
	root, e := (librarystore.Store{}).ReadRootTx(ctx, p, a.PlayerID)
	if e != nil || root.MarriedHighWater != 1 {
		t.Fatal("marriage raises the high-water mark", root.MarriedHighWater, e)
	}
	expectStatus(t, cosmeticFacts(t, p, a, rev, "title"), 100022, 0, app.Ineligible)

	exec(t, p, `UPDATE player_library_roots SET married_high_water=30 WHERE player_id=$1`, int64(a.PlayerID))
	exec(t, p, `UPDATE player_library_heroes SET is_married=false WHERE player_id=$1`, int64(a.PlayerID))
	facts := cosmeticFacts(t, p, a, rev, "title")
	if f := expectStatus(t, facts, 100022, 0, app.Eligible); len(f.Origins) != 1 || f.Origins[0].Owner != "Library" || f.Origins[0].EndTime != 0 {
		t.Fatal("kept marriage title origin", f)
	}
	expectStatus(t, facts, 100023, 0, app.Ineligible)
	expectStatus(t, facts, 100024, 0, app.Unavailable)

	ds := service(p, p)
	ds.CatalogExternal = cosmeticOriginRoutes(p)
	if selected, e := ds.Execute(ctx, a, app.Command{Kind: "title", ID: 100022}, op()); e != nil || selected.Wire["title_info"] == nil {
		t.Fatal(selected, e)
	}
	if _, e = ds.Execute(ctx, a, app.Command{Kind: "title", ID: 100023}, op()); !errors.Is(e, app.ErrRequest) {
		t.Fatal("50-marriage title selected below its condition", e)
	}
}

func TestI7C6BookshelfAndVillaTitlesNative(t *testing.T) {
	p := pool(t)
	a, rev, _ := bookFixture(t, p)
	skillHero(t, p, a, rev, 10001001, 1)
	expectStatus(t, cosmeticFacts(t, p, a, rev, "title"), 100024, 0, app.Ineligible)
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	r, e := (bookstore.Store{}).LockRootTx(ctx, tr, a.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	if r.Facts.Buildings == nil {
		r.Facts.Buildings = map[int64]book.Building{}
	}
	r.Facts.Buildings[4] = book.Building{Level: 50}
	old := r.Version
	r.Version++
	r.UpdatedAt = time.Now().UTC().Add(-time.Minute)
	if e = (bookstore.Store{}).SaveRootTx(ctx, tr, r, old); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	facts := cosmeticFacts(t, p, a, rev, "title")
	expectStatus(t, facts, 100024, 0, app.Eligible)
	expectStatus(t, facts, 100025, 0, app.Ineligible)

	v, rev, _ := dormFixture(t, p)
	expectStatus(t, cosmeticFacts(t, p, v, rev, "title"), 100026, 0, app.Ineligible)
	exec(t, p, `INSERT INTO player_dorm_rooms(player_id,house_id,table_id,house_type,creation_revision,floor,position,comfort,expansion_level,state_version,furniture_record,created_at,updated_at)SELECT $1,100+g,1000001,4,$2,g,1,0,0,1,'{}'::jsonb,clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour' FROM generate_series(1,30) g`, int64(v.PlayerID), rev)
	facts = cosmeticFacts(t, p, v, rev, "title")
	expectStatus(t, facts, 100026, 0, app.Eligible)
	expectStatus(t, facts, 100027, 0, app.Ineligible)
}

func TestI7C6ArenaChampionAvatarFromSettlementNative(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	player := func() identity.ActorContext {
		a := actor(t, p)
		skillHero(t, p, a, rev, 10001001, 1)
		return a
	}
	champion, expired := player(), player()
	settle := func(a identity.ActorContext, ago string) {
		season := 1_000_000 + int64(a.PlayerID)
		exec(t, p, `INSERT INTO arena_settlements(season,cutoff_at,settled_at,competition_version,content_revision,recipients)VALUES($1,clock_timestamp()-$3::interval,clock_timestamp()-$3::interval,1,$2,1)`, season, rev, ago)
		exec(t, p, `INSERT INTO arena_settlement_ranks(season,player_id,season_rank,level,star,point,champion)VALUES($1,$2,1,1,0,0,true)`, season, int64(a.PlayerID))
	}
	settle(champion, "10 days")
	settle(expired, "61 days")
	f := expectStatus(t, cosmeticFacts(t, p, champion, rev, "avatar"), 110006001, 5, app.Eligible)
	if len(f.Origins) != 1 || f.Origins[0].Owner != "Arena" || f.Origins[0].StartsAt == nil || f.Origins[0].EndTime != f.Origins[0].StartsAt.Unix()+60*86400 {
		t.Fatal("champion avatar lasts 60 days from settlement", f)
	}
	expectStatus(t, cosmeticFacts(t, p, expired, rev, "avatar"), 110006001, 5, app.Ineligible)
	expectStatus(t, cosmeticFacts(t, p, player(), rev, "avatar"), 110006001, 5, app.Ineligible)
}
