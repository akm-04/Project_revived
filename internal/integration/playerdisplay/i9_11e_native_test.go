//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"strconv"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/achievementstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	ach "gxb.local/backend/v2/internal/application/achievement"
	il "gxb.local/backend/v2/internal/application/illusion"
	d "gxb.local/backend/v2/internal/domain/achievement"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
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

// countingAchievements delegates to the production service and records how many
// observations the summon transaction made, so a receipt replay can prove it
// observed nothing.
type countingAchievements struct {
	next  ach.Service
	calls int
}

func (c *countingAchievements) ObserveMediumTenPullTx(ctx context.Context, t tx.Tx, player identity.PlayerID, revision string, girls int64, at time.Time) error {
	c.calls++
	return c.next.ObserveMediumTenPullTx(ctx, t, player, revision, girls, at)
}

// dispatchedProgress reads one achievement row through MID 1302, the stock reply.
func dispatchedProgress(t *testing.T, service ach.Service, a identity.ActorContext, id int64) int64 {
	t.Helper()
	response := (stockruntime.AchievementDispatcher{Authority: playtestAuthority{a}, Service: service}).Dispatch(ctx, playtestRequest(a, 1302, map[string]any{}))
	if response.HTTPStatus != 200 {
		t.Fatalf("1302 HTTP %d %#v", response.HTTPStatus, response.Body)
	}
	rows, ok := response.Body["achieve_list"].([]map[string]any)
	if !ok {
		t.Fatalf("achieve_list type %T", response.Body["achieve_list"])
	}
	for _, row := range rows {
		if row["achieve_id"] != id {
			continue
		}
		progress, ok := row["progress"].(int64)
		if !ok {
			t.Fatalf("row %d progress type %T", id, row["progress"])
		}
		return progress
	}
	t.Fatalf("row %d missing from 1302", id)
	return 0
}

// girlRows counts the reply rows SummonResultWindow plays a girl animation for.
func girlRows(t *testing.T, body map[string]any) int64 {
	t.Helper()
	rows, ok := body["result"].([]any)
	if !ok {
		t.Fatalf("result type %T", body["result"])
	}
	var girls int64
	for _, raw := range rows {
		row, ok := raw.(map[string]any)
		if !ok {
			t.Fatalf("result row type %T", raw)
		}
		partner, _ := row["is_partner"].(bool)
		stone, _ := row["to_stone"].(bool)
		if partner || stone {
			girls++
		}
	}
	return girls
}

func canonicalReply(t *testing.T, body map[string]any) string {
	t.Helper()
	raw, err := json.Marshal(body)
	if err != nil {
		t.Fatal(err)
	}
	return string(raw)
}

// TestI9_11E_MediumTenPullThroughTheSummonDispatcher drives MID 50 through the
// stock dispatcher: the production pull settles, 100012 follows the returned
// rows, and a same-operation replay returns the stored reply and observes nothing.
func TestI9_11E_MediumTenPullThroughTheSummonDispatcher(t *testing.T) {
	p := pool(t)
	a := companionActor(t, p)
	installed(t, p)
	exec(t, p, `UPDATE player_currency_balances SET amount=3000 WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID))
	achievements := catalogAchievements(p, fixedCounts{})
	counter := &countingAchievements{next: achievements}
	mode := summonMode(p)
	mode.Achievements = counter
	dispatcher := stockruntime.SummonDispatcher{Authority: playtestAuthority{a}, Service: mode}
	request := playtestRequest(a, 50, map[string]any{"summon_type": int64(2), "summon_index": int64(2)})

	response := dispatcher.Dispatch(ctx, request)
	if response.HTTPStatus != 200 {
		t.Fatalf("medium ten-pull HTTP %d %#v", response.HTTPStatus, response.Body)
	}
	girls := girlRows(t, response.Body)
	if girls < 1 {
		t.Fatalf("ten rows played no girl animation: %#v", response.Body["result"])
	}
	if counter.calls != 1 {
		t.Fatalf("observations after one pull = %d", counter.calls)
	}
	if progress := dispatchedProgress(t, achievements, a, d.MediumTenPullID); progress != girls {
		t.Fatalf("100012 progress %d, reply girls %d", progress, girls)
	}

	replayed := dispatcher.Dispatch(ctx, request)
	if replayed.HTTPStatus != 200 || canonicalReply(t, replayed.Body) != canonicalReply(t, response.Body) {
		t.Fatalf("receipt replay HTTP %d body %#v", replayed.HTTPStatus, replayed.Body)
	}
	if counter.calls != 1 {
		t.Fatalf("receipt replay observed the fact again: calls %d", counter.calls)
	}
	if progress := dispatchedProgress(t, achievements, a, d.MediumTenPullID); progress != girls {
		t.Fatalf("receipt replay moved 100012 to %d", progress)
	}
}

// TestI9_11E_FantasySettlementThroughTheIllusionReconciler drives MID 1346 and
// 1347 through the stock dispatcher, then the production occurrence reconciler:
// the frozen board rank and burst size become 100006/100007, and a second
// reconcile mails and observes nothing.
func TestI9_11E_FantasySettlementThroughTheIllusionReconciler(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	installed(t, p)
	clock := illusionTime(t)
	mode := illusionService(t, p, clock, illusionPrivileges{level: 3}, illusionGuildSource{})
	achievements := catalogAchievements(p, fixedCounts{})
	a, aPartner := illusionOwner(t, p, server)
	b, bPartner := illusionOwner(t, p, server)
	for _, actor := range []identity.ActorContext{a, b} {
		if _, err := achievements.Load(ctx, actor, op()); err != nil {
			t.Fatalf("login 1302 %v", err)
		}
	}
	dispatch := func(actor identity.ActorContext, mid uint16, params map[string]any) httpedge.Response {
		t.Helper()
		return (stockruntime.IllusionDispatcher{Authority: playtestAuthority{actor}, Service: mode}).Dispatch(ctx, playtestRequest(actor, mid, params))
	}
	fight := func(actor identity.ActorContext, partner, damage int64) {
		t.Helper()
		formation := strconv.FormatInt(partner, 10)
		if started := dispatch(actor, 1346, map[string]any{"formation": formation}); started.HTTPStatus != 200 {
			t.Fatalf("1346 HTTP %d %#v", started.HTTPStatus, started.Body)
		}
		settled := dispatch(actor, 1347, map[string]any{"star": int64(0), "total_damage": damage, "formation": formation, "cost_time": int64(10)})
		if settled.HTTPStatus != 200 {
			t.Fatalf("1347 HTTP %d %#v", settled.HTTPStatus, settled.Body)
		}
	}
	// Rank 1 is a loss at exactly the 5,000,000 damage threshold; rank 2 is below
	// it. A kill-based rank basis would pass 0 and fail the settlement.
	fight(a, aPartner, d.FantasyDamageThreshold)
	fight(b, bPartner, 400)

	clock.Set(modes.DayBegins(modes.Day(clock.at)).Add(17 * time.Hour))
	out, err := (il.Reconciler{Service: mode}).Reconcile(ctx, mustTimed(t, op(), clock.at), 100)
	if err != nil || out.Settled < 1 {
		t.Fatalf("reconcile %+v %v", out, err)
	}
	if progress := dispatchedProgress(t, achievements, a, d.FantasyTopRankID); progress != 1 {
		t.Fatalf("rank 1 player 100006 = %d", progress)
	}
	if progress := dispatchedProgress(t, achievements, a, d.FantasyDamageID); progress != 1 {
		t.Fatalf("threshold player 100007 = %d", progress)
	}
	if progress := dispatchedProgress(t, achievements, b, d.FantasyTopRankID); progress != 1 {
		t.Fatalf("rank 2 player 100006 = %d", progress)
	}
	if progress := dispatchedProgress(t, achievements, b, d.FantasyDamageID); progress != 0 {
		t.Fatalf("sub-threshold player 100007 = %d", progress)
	}
	if n := scalar(t, p, `SELECT count(*) FROM achievement_boss_facts WHERE player_id=$1`, int64(a.PlayerID)); n != 2 {
		t.Fatalf("rank 1 player facts %d", n)
	}
	if n := scalar(t, p, `SELECT count(*) FROM achievement_boss_facts WHERE player_id=$1`, int64(b.PlayerID)); n != 1 {
		t.Fatalf("rank 2 player facts %d", n)
	}
	if n := scalar(t, p, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='ILLUSION_SETTLEMENT'`, int64(a.PlayerID)); n == 0 {
		t.Fatal("settlement mailed no rank reward")
	}
	replay, err := (il.Reconciler{Service: mode}).Reconcile(ctx, mustTimed(t, op(), clock.at), 100)
	if err != nil || replay.Settled != 0 {
		t.Fatalf("second reconcile %+v %v", replay, err)
	}
	if progress := dispatchedProgress(t, achievements, a, d.FantasyTopRankID); progress != 1 {
		t.Fatalf("retry moved 100006 to %d", progress)
	}
	if n := scalar(t, p, `SELECT count(*) FROM achievement_boss_facts WHERE player_id=$1`, int64(a.PlayerID)); n != 2 {
		t.Fatalf("retry duplicated facts %d", n)
	}
}

// TestI9_11E_LegacyPlayerKeepsTheFantasyFact covers a character who never loaded
// 1302: the settlement fact must create the achievement root instead of being
// silently dropped by observePlayerTx.
func TestI9_11E_LegacyPlayerKeepsTheFantasyFact(t *testing.T) {
	p := pool(t)
	a := actor(t, p)
	rev := installed(t, p)
	s := catalogAchievements(p, fixedCounts{})
	if _, tracked, err := (achievementstore.Store{}).ReadRootTx(ctx, p, a.PlayerID, false); err != nil || tracked {
		t.Fatalf("fixture must start without an achievement root: %v %v", tracked, err)
	}
	at := time.Now().UTC().Truncate(time.Microsecond)
	if err := runAchievementTx(t, p, rev, func(c context.Context, tr tx.Tx) error {
		return s.ObserveFantasyTx(c, tr, rev, a.PlayerID, 100001, 100, 1, 0, at)
	}); err != nil {
		t.Fatal(err)
	}
	entries := achievementEntries(t, s, a)
	if entries[d.FantasyTopRankID].Progress != 1 || entries[d.FantasyTopRankID].CompleteTimes[0] == 0 {
		t.Fatalf("legacy rank fact %+v", entries[d.FantasyTopRankID])
	}
}
