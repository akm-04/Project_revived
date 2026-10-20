//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	"testing"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/achievementstore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	ach "gxb.local/backend/v2/internal/application/achievement"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/i5"
	display "gxb.local/backend/v2/internal/application/playerdisplay"
	app "gxb.local/backend/v2/internal/application/publicprofile"
	d "gxb.local/backend/v2/internal/domain/achievement"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/ranking"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Source skin items: 50001409 -> model 40001001 (Hero 10001001); 50001115 ->
// 40001002 and 50001483 -> 40002002 (Hero 10001002).
func skinCollector(t *testing.T, p *pg.Pool, a identity.ActorContext, rev string) {
	t.Helper()
	skillHero(t, p, a, rev, 10001001, 1)
	exec(t, p, `INSERT INTO player_hero_skin_entitlements(player_id,partner_id,model_id,expires_at)VALUES($1,1,40001001,NULL),($1,1,40002002,clock_timestamp()-interval '1 hour')`, int64(a.PlayerID))
	exec(t, p, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,50001409,1,1,clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour'),($1,50001115,2,1,clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour'),($1,50001483,0,1,clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour')`, int64(a.PlayerID))
}

func countingDisplay(p *pg.Pool) display.Service {
	s := display4a(p)
	s.CatalogExternal = cosmeticOriginRoutes(p)
	s.SkinItems = contentstore.Store{}
	return s
}

func countingMetrics(p *pg.Pool, trophies app.TrophyCounts) app.CanonicalMetricProvider {
	v := privateMetricProvider(p)
	v.Display = countingDisplay(p)
	v.Trophies = trophies
	return v
}

func coherentRead(t *testing.T, p *pg.Pool, rev string, read func(context.Context, tx.Scope, ca.CoherentReadScope) error) error {
	t.Helper()
	o := opPinned(rev)
	var e error
	o.Policies, e = policy.NewSet(append(o.Policies.Refs(), policy.Ref{Name: "roster-metrics", Version: app.RosterMetricPolicy})...)
	if e != nil {
		t.Fatal(e)
	}
	_, e = (tx.Runner{DB: p}).Run(ctx, o, i5.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, s tx.Scope) error {
		at, e := (pg.AuthoritativeTime{Queryer: s.Tx}).Now(c)
		if e != nil {
			return e
		}
		sc, e := ca.NewCoherentReadScope(s, rev, at)
		if e != nil {
			return e
		}
		return read(c, s, sc)
	})
	return e
}

func countedMetrics(t *testing.T, p *pg.Pool, provider app.CanonicalMetricProvider, a identity.ActorContext, rev string, ids []int64) map[int64]app.MetricObservation {
	t.Helper()
	out := map[int64]app.MetricObservation{}
	e := coherentRead(t, p, rev, func(c context.Context, s tx.Scope, sc ca.CoherentReadScope) error {
		values, e := provider.ReadMetricsScopeTx(c, s, app.MetricRequest{PlayerID: a.PlayerID, IDs: ids, ContentRevision: rev, ObservedAt: sc.ObservedAt})
		for _, v := range values {
			out[v.FieldID] = v
		}
		return e
	})
	if e != nil {
		t.Fatal(e)
	}
	return out
}

func TestI7C4FCCompleteFamiliesResolveOrStayUnavailable(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := rankingActor(t, p, rankingServer(t, p), true)
	skinCollector(t, p, a, rev)
	s := countingDisplay(p)
	e := coherentRead(t, p, rev, func(c context.Context, _ tx.Scope, sc ca.CoherentReadScope) error {
		for _, family := range []string{"avatar", "frame"} {
			o, e := s.ReadEligibilityTx(c, sc, display.EligibilityRequest{PlayerID: a.PlayerID, Family: family, CompleteFamily: true})
			if e != nil {
				t.Fatal("complete family", family, e)
			}
			if !o.CompleteFamily || len(o.MissingProviders) != 0 {
				t.Fatal("complete family flags", family, o.MissingProviders)
			}
			for _, f := range o.Facts {
				if f.Status == display.Unavailable {
					t.Fatal("unavailable row in a complete family", f)
				}
			}
		}
		frames, e := s.ReadEligibilityTx(c, sc, display.EligibilityRequest{PlayerID: a.PlayerID, Family: "frame"})
		if e != nil {
			return e
		}
		if f := fact4a(t, frames, 120001155, 0); f.Status != display.NotLive || f.Basis != "C6_COSMETIC_FORWARD_BINDINGS_V1" {
			t.Fatal("forward-bound frame", f)
		}
		if _, e = s.ReadEligibilityTx(c, sc, display.EligibilityRequest{PlayerID: a.PlayerID, Family: "title", CompleteFamily: true}); !errors.Is(e, display.ErrUnavailable) {
			t.Fatal("unrouted live titles read as a complete family", e)
		}
		titles, e := s.ReadEligibilityTx(c, sc, display.EligibilityRequest{PlayerID: a.PlayerID, Family: "title"})
		if e != nil {
			return e
		}
		expectStatus(t, titles, 100006, 0, display.NotLive)
		expectStatus(t, titles, 100059, 0, display.Unavailable)
		return nil
	})
	if e != nil {
		t.Fatal(e)
	}
}

func TestI7C4FCSkinTrophyAndCosmeticMetrics(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := rankingActor(t, p, rankingServer(t, p), true)
	skinCollector(t, p, a, rev)
	achievements := catalogAchievements(p, fixedCounts{d.PetsID: 9})
	metrics := countedMetrics(t, p, countingMetrics(p, achievements), a, rev, []int64{1003, 1004, 1005, 1006})
	if v := metrics[1003]; v.Value != 2 || v.Owner != "PlayerDisplay" || v.PrivatePolicy != display.SkinCollectionPolicy {
		t.Fatal("1003 counts each held model once and skips expired entitlements and empty stacks", v)
	}
	if v := metrics[1004]; v.Value != 0 || v.PopulationVersion != 0 {
		t.Fatal("unobserved legacy root records no trophies", v)
	}
	eligible := map[string]int64{}
	e := coherentRead(t, p, rev, func(c context.Context, _ tx.Scope, sc ca.CoherentReadScope) error {
		for _, family := range []string{"frame", "avatar"} {
			o, e := countingDisplay(p).ReadEligibilityTx(c, sc, display.EligibilityRequest{PlayerID: a.PlayerID, Family: family, CompleteFamily: true})
			if e != nil {
				return e
			}
			for _, f := range o.Facts {
				if f.Status == display.Eligible {
					eligible[family]++
				}
			}
		}
		return nil
	})
	if e != nil {
		t.Fatal(e)
	}
	if metrics[1005].Value != eligible["frame"] || metrics[1006].Value != eligible["avatar"] || eligible["frame"] < 1 || eligible["avatar"] < 1 {
		t.Fatal("1005/1006 equal ELIGIBLE facts", metrics[1005], metrics[1006], eligible)
	}

	if _, e = achievements.Load(ctx, a, op()); e != nil {
		t.Fatal(e)
	}
	if v := countedMetrics(t, p, countingMetrics(p, achievements), a, rev, []int64{1004})[1004]; v.Value != 2 || v.PopulationVersion < 1 {
		t.Fatal("1004 counts recorded tiers: Pets bronze and silver at 9 pets", v)
	}
}

func TestI7C4FCSkinsAchievementBackfillsFromSkinCount(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := rankingActor(t, p, rankingServer(t, p), true)
	skinCollector(t, p, a, rev)
	counts := ach.OwnerCounts{Roster: characterstore.RosterMetricReader{Store: characterstore.Store{}, Content: contentstore.Store{}}, Kinds: contentstore.Store{}, Skins: countingDisplay(p)}
	s := catalogAchievements(p, counts)
	if e := s.Observe(ctx, a, op(), ach.Families["Hero"]); e != nil {
		t.Fatal(e)
	}
	streaks, e := (achievementstore.Store{}).ReadStreaksTx(ctx, p, a.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	for _, v := range streaks {
		if v.AchievementID != d.SkinsID {
			continue
		}
		if v.Current != 2 || v.CompleteTimes[0] == nil || v.CompleteTimes[1] != nil {
			t.Fatal("100016 tiers 1/10/20 over two held skins", v)
		}
		return
	}
	t.Fatal("legacy skins achievement not backfilled", streaks)
}

func TestI7C4FCSkinsBoardRanksAndTitlesSevenDays(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	server := rankingServer(t, p)
	a := rankingActor(t, p, server, true)
	b := rankingActor(t, p, server, true)
	skinCollector(t, p, b, rev)
	skillHero(t, p, a, rev, 10001001, 1)
	s := rankingService(p, p)
	s.Metrics = countingMetrics(p, nil)
	board, e := s.ReadBoard(ctx, ranking.SkinsBoard, a, op())
	if e != nil {
		t.Fatal(e)
	}
	if len(board.Entries) != 2 || board.Entries[0].Metric.Player != b.PlayerID || board.Entries[0].Metric.Value != 2 || board.Entries[0].Metric.FieldID != 1003 || board.Entries[1].Metric.Value != 0 {
		t.Fatal(board.Entries)
	}
	var winner, title int64
	if e = p.QueryRow(ctx, `SELECT player_id,title_id FROM ranking_girls_awards WHERE logical_server_id=$1 AND policy_id=$2`, int64(server), ranking.SkinsPolicy).Scan(&winner, &title); e != nil || winner != int64(b.PlayerID) || title != 100063 {
		t.Fatal("Skins No.1 title", winner, title, e)
	}
	ds := countingDisplay(p)
	ds.CatalogExternal = append(cosmeticOriginRoutes(p), display.CatalogOriginRoute{Family: "title", First: 100063, Last: 100066, Owner: s})
	e = coherentRead(t, p, rev, func(c context.Context, _ tx.Scope, sc ca.CoherentReadScope) error {
		titles, e := ds.ReadEligibilityTx(c, sc, display.EligibilityRequest{PlayerID: b.PlayerID, Family: "title"})
		if e != nil {
			return e
		}
		f := expectStatus(t, titles, 100063, 0, display.Eligible)
		if len(f.Origins) != 1 || f.Origins[0].Owner != "Ranking" || f.Origins[0].StartsAt == nil || f.Origins[0].EndTime != f.Origins[0].StartsAt.Unix()+ranking.BoardTitleDuration {
			t.Fatal("Skins title lasts seven days", f)
		}
		expectStatus(t, titles, 100064, 0, display.Ineligible)
		return nil
	})
	if e != nil {
		t.Fatal(e)
	}
}
