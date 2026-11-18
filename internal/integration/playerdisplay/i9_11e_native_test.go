//go:build postgres

package playerdisplay_test

import (
	"context"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/achievementstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	ach "gxb.local/backend/v2/internal/application/achievement"
	d "gxb.local/backend/v2/internal/domain/achievement"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func runAchievementTx(t *testing.T, p *pg.Pool, rev string, body func(context.Context, tx.Tx) error) error {
	t.Helper()
	_, e := (tx.Runner{DB: p}).Run(ctx, opPinned(rev), ach.Profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		return body(c, sc.Tx)
	})
	return e
}

func achievementEntries(t *testing.T, s ach.Service, a identity.ActorContext) map[int64]ach.Entry {
	t.Helper()
	v, e := s.Load(ctx, a, op())
	if e != nil {
		t.Fatal(e)
	}
	out := map[int64]ach.Entry{}
	for _, x := range v.Entries {
		out[x.AchievementID] = x
	}
	return out
}

func TestI9_11E_FantasyFactsAreBoundedAndSettlementRetryIsNoop(t *testing.T) {
	p := pool(t)
	a := bornActor(t, p)
	rev := installed(t, p)
	s := catalogAchievements(p, fixedCounts{})
	at := time.Now().UTC().Truncate(time.Microsecond)
	fantasy := func(campaign, day, rank, hurt int64) error {
		return runAchievementTx(t, p, rev, func(c context.Context, tr tx.Tx) error {
			return s.ObserveFantasyTx(c, tr, rev, a.PlayerID, campaign, day, rank, hurt, at)
		})
	}
	if e := fantasy(100001, 100, 2, 100); e != nil {
		t.Fatal(e)
	}
	entries := achievementEntries(t, s, a)
	if entries[d.FantasyTopRankID].Progress != 1 || entries[d.FantasyTopRankID].CompleteTimes[0] == 0 || entries[d.FantasyDamageID].Progress != 0 {
		t.Fatalf("top-3 fact %+v", entries)
	}
	first := entries[d.FantasyTopRankID].CompleteTimes[0]
	// Below the threshold and outside the top 3 changes nothing.
	if e := fantasy(100002, 101, 9, d.FantasyDamageThreshold-1); e != nil {
		t.Fatal(e)
	}
	if entries = achievementEntries(t, s, a); entries[d.FantasyTopRankID].Progress != 1 || entries[d.FantasyDamageID].Progress != 0 {
		t.Fatalf("unqualified settlement %+v", entries)
	}
	// A second campaign earns tier 2 (threshold 3 needs a third).
	if e := fantasy(100002, 101, 2, d.FantasyDamageThreshold-1); e != nil {
		t.Fatal(e)
	}
	entries = achievementEntries(t, s, a)
	if entries[d.FantasyTopRankID].Progress != 2 || entries[d.FantasyTopRankID].CompleteTimes[1] != 0 {
		t.Fatalf("second campaign %+v", entries)
	}
	// A settlement retry of the same campaign is a no-op: no duplicate fact and
	// no moved completion time.
	if e := fantasy(100002, 101, 2, d.FantasyDamageThreshold-1); e != nil {
		t.Fatal(e)
	}
	retried := achievementEntries(t, s, a)
	if retried[d.FantasyTopRankID].Progress != 2 || retried[d.FantasyTopRankID].CompleteTimes[0] != first {
		t.Fatalf("retry changed progress %+v", retried)
	}
	if n := scalar(t, p, `SELECT count(*) FROM achievement_boss_facts WHERE player_id=$1 AND achievement_id=$2`, int64(a.PlayerID), d.FantasyTopRankID); n != 2 {
		t.Fatalf("one row per campaign, got %d", n)
	}
	// Damage reaches the named 5,000,000 threshold; tier 2 of top-3 needs six.
	if e := fantasy(100003, 102, 1, d.FantasyDamageThreshold); e != nil {
		t.Fatal(e)
	}
	entries = achievementEntries(t, s, a)
	if entries[d.FantasyTopRankID].Progress != 3 || entries[d.FantasyTopRankID].CompleteTimes[1] == 0 || entries[d.FantasyDamageID].Progress != 1 || entries[d.FantasyDamageID].CompleteTimes[0] == 0 {
		t.Fatalf("threshold facts %+v", entries)
	}
	if e := fantasy(100004, 103, 12, d.FantasyDamageThreshold); e != nil {
		t.Fatal(e)
	}
	if entries = achievementEntries(t, s, a); entries[d.FantasyDamageID].Progress != 2 || entries[d.FantasyTopRankID].Progress != 3 {
		t.Fatalf("damage campaign counted once %+v", entries)
	}
}

func TestI9_11E_MediumTenPullIsAHighWaterGirlCount(t *testing.T) {
	p := pool(t)
	a := bornActor(t, p)
	rev := installed(t, p)
	s := catalogAchievements(p, fixedCounts{})
	at := time.Now().UTC().Truncate(time.Microsecond)
	pull := func(girls int64) error {
		return runAchievementTx(t, p, rev, func(c context.Context, tr tx.Tx) error {
			return s.ObserveMediumTenPullTx(c, tr, a.PlayerID, rev, girls, at)
		})
	}
	if e := pull(3); e != nil {
		t.Fatal(e)
	}
	entries := achievementEntries(t, s, a)
	if entries[d.MediumTenPullID].Progress != 3 || entries[d.MediumTenPullID].CompleteTimes[0] == 0 || entries[d.MediumTenPullID].Status != d.Qualified {
		t.Fatalf("medium ten-pull %+v", entries[d.MediumTenPullID])
	}
	earned := entries[d.MediumTenPullID].CompleteTimes[0]
	if e := pull(2); e != nil {
		t.Fatal(e)
	}
	if entries = achievementEntries(t, s, a); entries[d.MediumTenPullID].Progress != 3 {
		t.Fatalf("a lower pull must not lower progress %+v", entries[d.MediumTenPullID])
	}
	if e := pull(4); e != nil {
		t.Fatal(e)
	}
	if entries = achievementEntries(t, s, a); entries[d.MediumTenPullID].Progress != 4 || entries[d.MediumTenPullID].CompleteTimes[1] == 0 {
		t.Fatalf("tier 2 at 4 %+v", entries[d.MediumTenPullID])
	}
	if e := pull(4); e != nil {
		t.Fatal(e)
	}
	if retried := achievementEntries(t, s, a); retried[d.MediumTenPullID].CompleteTimes[0] != earned || retried[d.MediumTenPullID].Progress != 4 {
		t.Fatalf("pull retry changed the fact %+v", retried[d.MediumTenPullID])
	}
}

func TestI9_11E_LoginDetailClaimsNoticesOnceAndSilencesThePush(t *testing.T) {
	p := pool(t)
	a := bornActor(t, p)
	rev := installed(t, p)
	s := catalogAchievements(p, fixedCounts{})
	at := time.Now().UTC().Truncate(time.Microsecond)
	exec(t, p, `INSERT INTO achievement_notices(player_id,achievement_id,tier,complete_time)VALUES($1,100013,1,$2),($1,100008,1,$2)`, int64(a.PlayerID), at)
	projection := achievementstore.BootstrapProjection{Store: achievementstore.Store{}, Content: contentstore.Store{Queryer: p}, Active: contentstore.Store{Queryer: p}}
	login := func(loginAt time.Time) []int64 {
		t.Helper()
		write, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
		if e != nil {
			t.Fatal(e)
		}
		if e = (achievementstore.NoticeLoginReconciler{}).ReconcileCharacterLogin(ctx, write, a, op(), loginAt); e != nil {
			t.Fatal(e)
		}
		if e = write.Commit(ctx); e != nil {
			t.Fatal(e)
		}
		read, e := p.Begin(ctx, tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true})
		if e != nil {
			t.Fatal(e)
		}
		defer read.Rollback(ctx)
		detail := map[string]any{}
		if e = projection.OverlayMID1(ctx, read, a, false, loginAt, detail); e != nil {
			t.Fatal(e)
		}
		ids, ok := detail["1304"].([]int64)
		if !ok {
			t.Fatalf("detail 1304 type %T", detail["1304"])
		}
		return ids
	}
	ids := login(at)
	if len(ids) != 1 || ids[0] != 100013 {
		t.Fatalf("login detail ids %v (hidden 100008 must stay silent)", ids)
	}
	// The notice-17 push reads pending notices; the login consumed them.
	if taken, e := s.TakeNotices(ctx, a.PlayerID, opPinned(rev)); e != nil || len(taken) != 0 {
		t.Fatalf("notices pushed after login: %+v, %v", taken, e)
	}
	if again := login(at.Add(time.Second)); len(again) != 0 {
		t.Fatalf("a second login re-showed %v", again)
	}
	if n := scalar(t, p, `SELECT count(*) FROM achievement_notices WHERE player_id=$1 AND delivered_at IS NULL`, int64(a.PlayerID)); n != 0 {
		t.Fatalf("pending notices %d", n)
	}
}
