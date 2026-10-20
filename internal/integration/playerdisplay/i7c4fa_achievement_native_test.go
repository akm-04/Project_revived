//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/achievementstore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	ach "gxb.local/backend/v2/internal/application/achievement"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	d "gxb.local/backend/v2/internal/domain/achievement"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"reflect"
	"testing"
)

type fixedCounts map[int64]int64

func (f fixedCounts) OwnedStateCountsTx(_ context.Context, _ ca.CoherentReadScope, _ identity.PlayerID, families []int64) map[int64]int64 {
	out := map[int64]int64{}
	for _, id := range families {
		if n, ok := f[id]; ok {
			out[id] = n
		}
	}
	return out
}

func catalogAchievements(p *pg.Pool, counts ach.Counter) ach.Service {
	values := i5store.Store{Queryer: p}
	content := contentstore.Store{Queryer: p}
	runner := tx.Runner{DB: p}
	grants := i5.Service{Runner: runner, Store: values, Content: content, Privileges: i5.BaselinePrivilegeProvider{}, Functions: i5.PetStarterFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{}, Backpack: values, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, RedeemSecret: []byte("i7c4fa-achievement-native-fixture-secret")}
	runtime := &ach.Runtime{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: runner}, Fresh: p, Active: content, Counts: counts, Fence: values, Grants: grants, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
	return ach.Service{Store: achievementstore.Store{}, Content: content, Population: libraryService(p, p), Runtime: runtime}
}

func entry(v ach.View, id int64) ach.Entry {
	for _, x := range v.Entries {
		if x.AchievementID == id {
			return x
		}
	}
	return ach.Entry{}
}

func TestI7C4FALegacyBackfillPointsClaimsRankAndNotices(t *testing.T) {
	p := pool(t)
	a, _ := libraryFixture(t, p, true)
	if _, tracked, e := (achievementstore.Store{}).ReadRootTx(ctx, p, a.PlayerID, false); e != nil || tracked {
		t.Fatal("fixture must start as a legacy character without a root", tracked, e)
	}
	s := catalogAchievements(p, fixedCounts{d.PetsID: 9, d.NormalHeroesID: 10})
	v, e := s.Load(ctx, a, op())
	if e != nil {
		t.Fatal(e)
	}
	if len(v.Entries) != 33 || entry(v, d.PetsID).Progress != 9 || entry(v, d.PetsID).CompleteTimes[1] == 0 || entry(v, d.PetsID).CompleteTimes[2] != 0 || entry(v, 100014).CompleteTimes[0] == 0 || entry(v, 100005).Status != d.ModeNotLive || entry(v, 100005).Progress != 0 {
		t.Fatal("legacy backfill view", v)
	}
	if v.TotalPoints != 2500 || v.PointLevel != 2 || v.Rank < 1 || !reflect.DeepEqual(v.AwardStatus, []int64{-1, 1, 0, 0, 0, 0, 0, 0, 0, 0}) {
		t.Fatal("points", v.TotalPoints, v.PointLevel, v.Rank, v.AwardStatus)
	}
	var notices int
	if e = p.QueryRow(ctx, `SELECT count(*) FROM achievement_notices WHERE player_id=$1`, int64(a.PlayerID)).Scan(&notices); e != nil || notices != 4 {
		t.Fatal("notice intents", notices, e)
	}
	taken, e := s.TakeNotices(ctx, a.PlayerID, op())
	if e != nil || len(taken) == 0 || len(taken) > 3 || taken[0].TotalPoints != 2500 || taken[0].PointLevel != 2 {
		t.Fatal("notice params", taken, e)
	}
	if again, e := s.TakeNotices(ctx, a.PlayerID, op()); e != nil || len(again) != 0 {
		t.Fatal("notices delivered twice", again, e)
	}
	first := op()
	claim, e := s.Claim(ctx, a, first)
	if e != nil || claim.Level != 2 || !reflect.DeepEqual(claim.AwardStatus, []int64{-1, -1, 0, 0, 0, 0, 0, 0, 0, 0}) {
		t.Fatal("first claim", claim, e)
	}
	replay, e := s.Claim(ctx, a, first)
	if e != nil || !reflect.DeepEqual(replay, claim) {
		t.Fatal("receipt replay", replay, e)
	}
	if _, e = s.Claim(ctx, a, op()); !errors.Is(e, ach.ErrNothingToClaim) {
		t.Fatal("claim beyond reached level must refuse", e)
	}
	higher := catalogAchievements(p, fixedCounts{d.PetsID: 15, d.NormalHeroesID: 150, d.TextbooksID: 30, d.RegionsID: 5})
	if v, e = higher.Load(ctx, a, op()); e != nil || v.TotalPoints != 12500 || v.PointLevel != 3 {
		t.Fatal("higher", v.TotalPoints, v.PointLevel, e)
	}
	if second, e := higher.Claim(ctx, a, op()); e != nil || second.Level != 3 {
		t.Fatal("second claim", second, e)
	}
	var items int64
	if e = p.QueryRow(ctx, `SELECT COALESCE(sum(quantity),0) FROM player_item_stacks WHERE player_id=$1 AND item_id IN (50001039,50001173)`, int64(a.PlayerID)).Scan(&items); e != nil || items != 3 {
		t.Fatal("granted level items", items, e)
	}
	lower := catalogAchievements(p, fixedCounts{d.PetsID: 1})
	after, e := lower.Load(ctx, a, op())
	if e != nil || after.TotalPoints != 12500 || entry(after, d.PetsID).Progress != 1 || entry(after, d.PetsID).CompleteTimes[2] == 0 {
		t.Fatal("tiers must survive a falling count", after, e)
	}
	b, _ := libraryFixture(t, p, false)
	richer, e := catalogAchievements(p, fixedCounts{d.PetsID: 15, d.NormalHeroesID: 150, d.TextbooksID: 30, d.RegionsID: 5, d.RoomsID: 15}).Load(ctx, b, op())
	if e != nil || richer.TotalPoints != 15000 {
		t.Fatal(richer.TotalPoints, e)
	}
	again, e := lower.Load(ctx, a, op())
	if e != nil || richer.Rank < 1 || again.Rank <= richer.Rank {
		t.Fatal("live trophy rank order", again.Rank, richer.Rank, e)
	}
}

func TestI7C4FAOwnerCountsReadCanonicalRoster(t *testing.T) {
	p := pool(t)
	a, rev := libraryFixture(t, p, false)
	counts := ach.OwnerCounts{Roster: characterstore.RosterMetricReader{Store: characterstore.Store{}, Content: contentstore.Store{}}, Kinds: contentstore.Store{}}
	var got map[int64]int64
	_, e := (tx.Runner{DB: p}).Run(ctx, opPinned(rev), ach.Profile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		scope, e := ca.NewCoherentReadScope(sc, rev, sc.Operation.StartedAt)
		if e != nil {
			return e
		}
		got = counts.OwnedStateCountsTx(c, scope, a.PlayerID, []int64{d.NormalHeroesID, d.AwakenedHeroesID})
		return nil
	})
	if e != nil || got[d.NormalHeroesID] != 1 {
		t.Fatal(got, e)
	}
}
