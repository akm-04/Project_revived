//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/guildcampaigncontent"
	"gxb.local/backend/v2/internal/adapters/guildwire"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/campaignstore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/commerceprivilegestore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildcampaignstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/application/commerceprivilege"
	gen "gxb.local/backend/v2/internal/application/generation"
	app "gxb.local/backend/v2/internal/application/guildcampaign"
	"gxb.local/backend/v2/internal/application/guildcore"
	"gxb.local/backend/v2/internal/application/guildview"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/missioninputs"
	"gxb.local/backend/v2/internal/content/guildcampaigncatalog"
	"gxb.local/backend/v2/internal/content/guildcampaignpolicy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/guild"
	d "gxb.local/backend/v2/internal/domain/guildcampaign"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type campaignFixture struct {
	pool       *postgres.Pool
	rev        string
	server     identity.LogicalServerID
	leader     identity.ActorContext
	second     identity.ActorContext
	third      identity.ActorContext
	guild      guild.ID
	mode       app.Mode
	settings   app.Settings
	tables     map[int64]app.ChapterInfo
	at         time.Time
	leaderHero int64
	secondHero int64
	thirdHero  int64
}

func newCampaignFixture(t *testing.T) campaignFixture {
	t.Helper()
	p := pool(t)
	server := nativeServer(t, p)
	f := campaignFixture{pool: p, server: server}
	f.leader, f.rev = genuinePlayer(t, p, server)
	f.second, _ = genuinePlayer(t, p, server)
	f.third, _ = genuinePlayer(t, p, server)
	f.guild = guildFixture(t, p, f.leader, f.second, f.third)
	installed := must(guildcampaigncatalog.LoadBuiltin())(t, "catalog").Catalog
	catalog := guildcampaigncontent.Catalog{Installed: installed}
	policy := must(guildcampaignpolicy.LoadBuiltin())(t, "policy").Policy
	f.settings = guildcampaigncontent.Settings(policy, installed.Settings)
	f.tables = catalog.ChapterInfos()
	now, err := (postgres.AuthoritativeTime{Queryer: p}).Now(ctx)
	if err != nil {
		t.Fatal(err)
	}
	f.at = campaignSafeTime(now, f.settings.RestSecondsOfDay)
	store := guildcampaignstore.Store{}
	mail := appi5.SettlementMail{Store: i5store.Store{Queryer: p}}
	payout := app.Payout{Store: store, Mail: mail, Settings: f.settings, Tables: f.tables}
	combatService := combatService(t, p)
	missionOwner := genuineGrants(p)
	content := contentstore.Store{Queryer: p}
	values := i5store.Store{Queryer: p}
	missionOwner.Missions = &appi5.MissionMaterializer{Awakening: values, Activity: content, Store: values, Catalog: content,
		Observations: missioninputs.Reader{Spending: values, Heroes: characterstore.Store{Queryer: p}, Progression: values,
			Campaigns: campaignstore.Store{}, Books: bookService(p, p),
			Privileges: commerceprivilege.Provider{Store: commerceprivilegestore.Store{}, Content: content}}}
	missionOwner.MissionTime = postgres.AuthoritativeTime{Queryer: p}
	missionOwner.MissionFresh = p
	f.mode = app.Mode{
		Service: app.Service{Runner: tx.Runner{DB: p}, Store: store, Guilds: guildstore.Store{Queryer: p}, Catalog: catalog, Payout: payout,
			Mail: mail, Fence: i5store.Store{Queryer: p}, Players: i4store.PlayerRootLocker{},
			Notice: app.NoticeMail{Enabled: true, OpenTitle: policy.NoticeMail.OpenTitle, OpenBody: policy.NoticeMail.OpenBody,
				ResetTitle: policy.NoticeMail.ResetTitle, ResetBody: policy.NoticeMail.ResetBody, Sender: "Guild"}},
		ModeStore: store, Content: catalog, Tables: f.tables, Settings: f.settings,
		Combat: combatService, Grants: genuineGrants(p), Facts: appi5.ObjectiveFacts{Owner: missionOwner, Open: i5store.Store{Queryer: p}},
		Directory: i4store.PlayerDirectoryReader{}, Mail: mail, NoticeMail: mail, Fence: i5store.Store{Queryer: p}, Players: i4store.PlayerRootLocker{},
		Timed: gen.TimedRunner{Binder: gen.Binder{Time: postgres.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}}, Fresh: p,
	}
	f.leaderHero = bornHero(t, p, f.leader, f.rev, genuineHeroTable, 1).PartnerID
	f.secondHero = bornHero(t, p, f.second, f.rev, 10001002, 1).PartnerID
	f.thirdHero = bornHero(t, p, f.third, f.rev, 10001003, 1).PartnerID
	return f
}

// seedActivity credits the personal cap of 1000 a day for the given number of
// days to every member, as real activity producers would.
func (f campaignFixture) seedActivity(t *testing.T, days int) {
	t.Helper()
	now, err := (postgres.AuthoritativeTime{Queryer: f.pool}).Now(ctx)
	if err != nil {
		t.Fatal(err)
	}
	for day := 0; day < days; day++ {
		for _, member := range []identity.ActorContext{f.leader, f.second, f.third} {
			appendActivity(t, f.pool, member, modesDay(now)-int64(day), 1000)
		}
	}
}

func modesDay(at time.Time) int64 {
	// The game day begins 05:00 GMT+8; the fixture only needs one stable day.
	return (at.Unix() + 8*3600 - 5*3600) / 86400
}

// campaignSafeTime moves a rest-window instant forward inside the same game
// day, so the native fixture is not tied to the UTC hour it runs in.
func campaignSafeTime(at time.Time, rest [2]int64) time.Time {
	seconds := (at.Unix() + 8*3600) % 86400
	if seconds >= rest[0] && seconds < rest[1] {
		return at.Add(4 * time.Hour)
	}
	return at
}

func (f campaignFixture) op() operation.Context { return f.opAt(f.at) }

func (f campaignFixture) opAt(at time.Time) operation.Context {
	pinned := opPinned(f.rev)
	pinned.StartedAt = at.UTC()
	return pinned
}

func (f campaignFixture) chapter(t *testing.T) app.ChapterInfo {
	t.Helper()
	return f.tables[7]
}

func (f campaignFixture) copyID(t *testing.T) (int64, int64) {
	t.Helper()
	info := f.chapter(t)
	return info.ChapterID, info.Copies[0]
}

func (f campaignFixture) start(t *testing.T, a identity.ActorContext, chapterID, copyID, hero int64) app.Started {
	t.Helper()
	started, err := f.mode.Start(ctx, a, app.Fight{ChapterID: chapterID, CopyID: copyID, CampaignType: 7,
		Formation: strconv.FormatInt(hero, 10)}, f.op())
	if err != nil {
		t.Fatal("start", err)
	}
	return started
}

func (f campaignFixture) waveEnemies(t *testing.T, started app.Started, star int64, damage int64, hp int64) app.Result {
	t.Helper()
	enemies := []app.ResultEnemy{}
	for _, enemy := range started.Waves[started.CurrentIndex] {
		enemies = append(enemies, app.ResultEnemy{HeroID: enemy.TableID, HP: hp, Index: started.CurrentIndex})
	}
	_ = star
	return app.Result{ChapterID: 7, CopyID: started.CopyID, CurrentIndex: started.CurrentIndex,
		Formation: "1", TotalDamage: damage, Star: star, Enemies: enemies}
}

func TestI9_9COpenNeedsOfficerPredecessorBalanceAndRollsBackNotice(t *testing.T) {
	f := newCampaignFixture(t)
	op := f.op()
	if _, err := f.mode.Open(ctx, f.second, 7, op); !errors.Is(err, d.ErrRefused) {
		t.Fatal("non-officer opened", err)
	}
	if _, err := f.mode.Open(ctx, f.leader, 8, op); !errors.Is(err, d.ErrRefused) {
		t.Fatal("chapter 8 opened without chapter 7", err)
	}
	f.seedActivity(t, 1)
	before := campaignMailCount(t, f.pool, f.second.PlayerID, appNoticeSource)
	if _, err := f.mode.Open(ctx, f.leader, 7, op); !errors.Is(err, d.ErrRefused) {
		t.Fatal("short balance opened", err)
	}
	if after := campaignMailCount(t, f.pool, f.second.PlayerID, appNoticeSource); after != before {
		t.Fatalf("notice mail survived a refused spend: %d -> %d", before, after)
	}
	f.seedActivity(t, 40)
	balance, err := f.mode.Open(ctx, f.leader, 7, op)
	if err != nil {
		t.Fatal("open", err)
	}
	if balance != 20000+3*40*1000-40000 {
		t.Fatalf("balance after open %d", balance)
	}
	if _, err := f.mode.Open(ctx, f.leader, 7, op); !errors.Is(err, d.ErrRefused) {
		t.Fatal("open over an open chapter", err)
	}
	if got := campaignMailCount(t, f.pool, f.second.PlayerID, appNoticeSource); got != before+1 {
		t.Fatalf("open notice mails %d", got)
	}
	f.seedActivity(t, 40)
	if _, err := f.mode.Reset(ctx, f.second, 7, op); !errors.Is(err, d.ErrRefused) {
		t.Fatal("non-officer reset", err)
	}
	if _, err := f.mode.Reset(ctx, f.leader, 7, op); !errors.Is(err, d.ErrRefused) {
		t.Fatal("reset of an untouched chapter", err)
	}
}

func TestI9_9CFightClaimCarryAttemptsLateAndDuplicate(t *testing.T) {
	f := newCampaignFixture(t)
	f.seedActivity(t, 40)
	if _, err := f.mode.Open(ctx, f.leader, 7, f.op()); err != nil {
		t.Fatal("open", err)
	}
	chapterID, copyID := f.copyID(t)
	claim, err := f.mode.Claim(ctx, f.second, copyID, f.op())
	if err != nil || claim.HolderID != int64(f.second.PlayerID) || claim.Stage != d.StagePrepare {
		t.Fatalf("first claim %+v err=%v", claim, err)
	}
	held, err := f.mode.Claim(ctx, f.third, copyID, f.op())
	if err != nil || held.HolderID != int64(f.second.PlayerID) {
		t.Fatalf("second claim saw holder %+v err=%v", held, err)
	}
	f.expireClaim(t, copyID)
	if reclaim, err := f.mode.Claim(ctx, f.third, copyID, f.op()); err != nil || reclaim.HolderID != int64(f.third.PlayerID) {
		t.Fatalf("lazy expiry reclaim %+v err=%v", reclaim, err)
	}
	if _, err := f.mode.Start(ctx, f.second, app.Fight{ChapterID: chapterID, CopyID: copyID, CampaignType: 7, Formation: "1"}, f.op()); !errors.Is(err, app.ErrHolder) {
		t.Fatal("second started another's claim", err)
	}
	heroThird := f.thirdHero
	started := f.start(t, f.third, chapterID, copyID, heroThird)
	loss := f.waveEnemies(t, started, 0, 1234, 77)
	settledLoss, err := f.mode.Settle(ctx, f.third, loss, f.op())
	if err != nil {
		t.Fatal("settle loss", err)
	}
	if clears := f.memberClears(t, f.third, chapterID); clears != 0 {
		t.Fatalf("loss consumed a clear: %d", clears)
	}
	detail, err := f.mode.MapDetail(ctx, f.third, copyID, f.op())
	if err != nil {
		t.Fatal("detail", err)
	}
	if detail.CurrentIndex != 1 || detail.Waves[1][0].HP != 77 {
		t.Fatalf("HP did not carry: %+v", detail.Waves[1][0])
	}
	// A retry of the settled loss replays the stored body as 30005 and writes
	// nothing: the wave keeps its HP, no clear, no second grant.
	goldBefore := f.balance(t, f.third, "mana")
	duplicateLoss, err := f.mode.Settle(ctx, f.third, loss, f.op())
	if err != nil || !duplicateLoss.Duplicate || duplicateLoss.Body["error_code"] != int64(30005) {
		t.Fatalf("duplicate loss %+v err=%v", duplicateLoss, err)
	}
	replayedAward := duplicateLoss.Body["rank_award"].(map[string]any)
	storedAward := settledLoss.Body["rank_award"].(map[string]any)
	if duplicateLoss.Body["coin_award"] != float64(settledLoss.Body["coin_award"].(int64)) ||
		replayedAward["crystal"] != float64(storedAward["crystal"].(int64)) || replayedAward["guild_coin"] != float64(storedAward["guild_coin"].(int64)) {
		t.Fatalf("duplicate loss body %+v vs %+v", duplicateLoss.Body, settledLoss.Body)
	}
	if goldAfter := f.balance(t, f.third, "mana"); goldAfter != goldBefore {
		t.Fatalf("duplicate loss paid again: %d -> %d", goldBefore, goldAfter)
	}
	if detail, err = f.mode.MapDetail(ctx, f.third, copyID, f.op()); err != nil || detail.CurrentIndex != 1 || detail.Waves[1][0].HP != 77 {
		t.Fatalf("duplicate loss wrote the copy: %+v err=%v", detail, err)
	}
	// The second member starts the same wave and clears it.
	if _, err := f.mode.Claim(ctx, f.second, copyID, f.op()); err != nil {
		t.Fatal("claim second", err)
	}
	heroSecond := f.secondHero
	second := f.start(t, f.second, chapterID, copyID, heroSecond)
	win := f.waveEnemies(t, second, 3, 5000, 0)
	win.Formation = strconv.FormatInt(heroSecond, 10)
	settled, err := f.mode.Settle(ctx, f.second, win, f.op())
	if err != nil || settled.Duplicate {
		t.Fatalf("settle win %+v err=%v", settled, err)
	}
	if clears := f.memberClears(t, f.second, chapterID); clears != 1 {
		t.Fatalf("clear not consumed: %d", clears)
	}
	win.Formation = strconv.FormatInt(heroSecond, 10)
	if duplicate, err := f.mode.Settle(ctx, f.second, win, f.op()); err != nil || !duplicate.Duplicate || duplicate.Body["error_code"] != int64(30005) {
		t.Fatalf("duplicate replay %+v err=%v", duplicate, err)
	}
	// A late result after the holder window writes nothing.
	if _, err := f.mode.Claim(ctx, f.second, copyID, f.op()); err != nil {
		t.Fatal("claim late", err)
	}
	lateStart := f.start(t, f.second, chapterID, copyID, heroSecond)
	f.expireClaim(t, copyID)
	before := f.copyIndex(t, copyID)
	if _, err := f.mode.Settle(ctx, f.second, f.waveEnemies(t, lateStart, 3, 9999, 0), f.op()); !errors.Is(err, app.ErrLate) {
		t.Fatal("late result", err)
	}
	if after := f.copyIndex(t, copyID); after != before {
		t.Fatalf("late result advanced the copy %d -> %d", before, after)
	}
}

func TestI9_9CAttemptCapAndRegistrationForfeit(t *testing.T) {
	f := newCampaignFixture(t)
	f.seedActivity(t, 40)
	if _, err := f.mode.Open(ctx, f.leader, 7, f.op()); err != nil {
		t.Fatal("open", err)
	}
	chapterID, copyID := f.copyID(t)
	core := guildCoreService(t, f.pool)
	core.Campaign = f.mode.Service
	if _, err := core.Leave(ctx, f.second, op()); err != nil {
		t.Fatal("leave", err)
	}
	if registered := f.registered(t, chapterID, f.second); registered {
		t.Fatal("leaver still registered")
	}
	// Guildcore refuses a same-guild rejoin for 2 days, so the fixture uses the
	// guild owner's membership insert rather than raw SQL for the rejoin.
	tr, err := f.pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	rejoin := guild.Membership{PlayerID: f.second.PlayerID, GuildID: f.guild, Role: guild.Member, JoinedAt: f.at, MembershipVersion: 1, StateVersion: 1, UpdatedAt: f.at}
	if err := (guildstore.Store{Queryer: f.pool}).InsertMembershipTx(ctx, tr, rejoin); err != nil {
		tr.Rollback(ctx)
		t.Fatal("rejoin", err)
	}
	if err := tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if registered := f.registered(t, chapterID, f.second); registered {
		t.Fatal("rejoining restored registration before reset")
	}
	if _, err := f.mode.Start(ctx, f.second, app.Fight{ChapterID: chapterID, CopyID: copyID, CampaignType: 7, Formation: "1"}, f.op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("unregistered member started", err)
	}
	tr = f.openTx(t)
	if err := f.mode.CloseGuildTx(ctx, tr, f.guild); err != nil {
		t.Fatal("dissolve", err)
	}
	if err := tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if rows := f.chapterRows(t); rows != 0 {
		t.Fatalf("dissolve left %d chapter rows", rows)
	}
}

func TestI9_9CPayoutOncePerRunAndAwardSlot(t *testing.T) {
	f := newCampaignFixture(t)
	payout := app.Payout{Store: guildcampaignstore.Store{}, Mail: appi5.SettlementMail{Store: i5store.Store{Queryer: f.pool}}, Settings: f.settings, Tables: f.tables}
	run := int64(1)
	chapter := d.Chapter{GuildID: int64(f.guild), ChapterID: 7, Run: run, Win: true, Percent: 1, StartTime: time.Now().UTC().Add(-time.Hour)}
	end := time.Now().UTC()
	chapter.EndTime = &end
	members := []identity.PlayerID{f.leader.PlayerID, f.second.PlayerID}
	tr, err := f.pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if err := payout.PayRunTx(ctx, tr, chapter, members, end); err != nil {
		t.Fatal("payout", err)
	}
	if err := payout.PayRunTx(ctx, tr, chapter, members, end); err != nil {
		t.Fatal("payout replay", err)
	}
	if err := tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	for _, member := range members {
		if got := campaignMailCount(t, f.pool, member, appPayoutSource); got != 1 {
			t.Fatalf("member %d paid %d times", member, got)
		}
	}
	tr, err = f.pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	chapter.Run = run + 1
	if err := payout.PayRunTx(ctx, tr, chapter, members, end); err != nil {
		t.Fatal("new-run payout", err)
	}
	if err := tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if got := campaignMailCount(t, f.pool, f.second.PlayerID, appPayoutSource); got != 2 {
		t.Fatalf("new run did not pay once: %d", got)
	}
}

func (f campaignFixture) openTx(t *testing.T) tx.Tx {
	t.Helper()
	tr, err := f.pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = tr.Rollback(ctx) })
	return tr
}

func (f campaignFixture) expireClaim(t *testing.T, copyID int64) {
	t.Helper()
	exec(t, f.pool, `UPDATE guild_campaign_copies SET last_fight_time=$3, start_fight_time=$3 WHERE guild_id=$1 AND copy_id=$2`, int64(f.guild), copyID, f.at.Add(-10*time.Minute))
}

func (f campaignFixture) memberClears(t *testing.T, a identity.ActorContext, chapterID int64) int64 {
	t.Helper()
	clears, err := (guildcampaignstore.Store{}).MemberClearsTx(ctx, f.pool, a.PlayerID, chapterID, modesDay(f.at))
	if err != nil {
		t.Fatal(err)
	}
	return clears
}

func (f campaignFixture) balance(t *testing.T, a identity.ActorContext, resource string) int64 {
	t.Helper()
	return scalar(t, f.pool, `SELECT COALESCE((SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key=$2),0)`, int64(a.PlayerID), resource)
}

func (f campaignFixture) copyIndex(t *testing.T, copyID int64) int64 {
	t.Helper()
	return scalar(t, f.pool, `SELECT current_index FROM guild_campaign_copies WHERE guild_id=$1 AND copy_id=$2`, int64(f.guild), copyID)
}

func (f campaignFixture) chapterRows(t *testing.T) int64 {
	t.Helper()
	return scalar(t, f.pool, `SELECT count(*) FROM guild_campaign_chapters WHERE guild_id=$1`, int64(f.guild))
}

func (f campaignFixture) registered(t *testing.T, chapterID int64, a identity.ActorContext) bool {
	t.Helper()
	registered, err := (guildcampaignstore.Store{}).IsRegisteredTx(ctx, f.pool, int64(f.guild), chapterID, a.PlayerID)
	if err != nil {
		t.Fatal(err)
	}
	return registered
}

func campaignMailCount(t *testing.T, p *postgres.Pool, a identity.PlayerID, source string) int64 {
	t.Helper()
	return scalar(t, p, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind=$2`, int64(a), source)
}

func (f campaignFixture) store() guildcampaignstore.Store { return guildcampaignstore.Store{} }

// beginSingleCopy keeps only the chosen copy of the open run so one clear wins
// the chapter.
func (f campaignFixture) beginSingleCopy(t *testing.T) (int64, int64) {
	t.Helper()
	chapterID, copyID := f.copyID(t)
	copy, found, err := f.store().ReadCopyTx(ctx, f.pool, int64(f.guild), chapterID, copyID)
	if err != nil || !found {
		t.Fatalf("single copy %v found=%v", err, found)
	}
	registered, err := f.store().ListRegisteredTx(ctx, f.pool, int64(f.guild), chapterID)
	if err != nil {
		t.Fatal(err)
	}
	tr := f.openTx(t)
	chapter := d.Chapter{GuildID: int64(f.guild), ChapterID: chapterID, Run: 1, StartTime: f.at}
	if err := f.store().BeginRunTx(ctx, tr, chapter, []d.Copy{{CopyID: copyID, Waves: copy.Waves}}, registered); err != nil {
		t.Fatal("single copy run", err)
	}
	if err := tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	return chapterID, copyID
}

func (f campaignFixture) bossCopy(t *testing.T, chapterID int64) int64 {
	t.Helper()
	for _, id := range f.tables[chapterID].Copies {
		if info, known := f.mode.Content.CopyInfo(chapterID, id); known && info.BossFight {
			return id
		}
	}
	t.Fatalf("chapter %d has no boss copy", chapterID)
	return 0
}

func (f campaignFixture) mutateCopy(t *testing.T, chapterID, copyID int64, change func(*d.Copy, map[int64][]app.EnemyRow)) {
	t.Helper()
	tr := f.openTx(t)
	copy, found, err := f.store().LockCopyTx(ctx, tr, int64(f.guild), chapterID, copyID)
	if err != nil || !found {
		t.Fatalf("lock copy %v found=%v", err, found)
	}
	waves := map[int64][]app.EnemyRow{}
	if len(copy.Waves) > 0 {
		if err := json.Unmarshal(copy.Waves, &waves); err != nil {
			t.Fatal(err)
		}
	}
	change(&copy, waves)
	if copy.Waves, err = json.Marshal(waves); err != nil {
		t.Fatal(err)
	}
	if err := f.store().SaveCopyTx(ctx, tr, copy); err != nil {
		t.Fatal(err)
	}
	if err := tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}

func killWaves(waves map[int64][]app.EnemyRow, killed ...int64) {
	for _, wave := range killed {
		for index := range waves[wave] {
			waves[wave][index].Health = 1
			waves[wave][index].HP = 0
		}
	}
}

// prepareChapterClear leaves every copy won but keep, and keep on its last wave.
func (f campaignFixture) prepareChapterClear(t *testing.T) (int64, int64) {
	t.Helper()
	chapterID, keep := f.copyID(t)
	rows, err := f.store().ListCopiesTx(ctx, f.pool, int64(f.guild), chapterID)
	if err != nil {
		t.Fatal(err)
	}
	for _, row := range rows {
		copyID := row.CopyID
		if copyID == keep {
			f.mutateCopy(t, chapterID, copyID, func(copy *d.Copy, waves map[int64][]app.EnemyRow) {
				copy.CurrentIndex = 3
				copy.Percent = 2.0 / 3
				killWaves(waves, 1, 2)
			})
			continue
		}
		f.mutateCopy(t, chapterID, copyID, func(copy *d.Copy, waves map[int64][]app.EnemyRow) {
			copy.Win = true
			copy.CurrentIndex = 3
			copy.Percent = 1
			killWaves(waves, 1, 2, 3)
		})
	}
	return chapterID, keep
}

func (f campaignFixture) startAt(t *testing.T, a identity.ActorContext, chapterID, copyID, hero int64, at time.Time) app.Started {
	t.Helper()
	started, err := f.mode.Start(ctx, a, app.Fight{ChapterID: chapterID, CopyID: copyID, CampaignType: 7, Formation: strconv.FormatInt(hero, 10)}, f.opAt(at))
	if err != nil {
		t.Fatalf("start at %v: %v", at, err)
	}
	return started
}

func resultFor(chapterID int64, started app.Started, damage, star, hp int64) app.Result {
	enemies := make([]app.ResultEnemy, 0, len(started.Waves[started.CurrentIndex]))
	for _, enemy := range started.Waves[started.CurrentIndex] {
		enemies = append(enemies, app.ResultEnemy{HeroID: enemy.TableID, HP: hp, Index: started.CurrentIndex})
	}
	return app.Result{ChapterID: chapterID, CopyID: started.CopyID, CurrentIndex: started.CurrentIndex,
		Formation: "1", TotalDamage: damage, Star: star, Enemies: enemies}
}

func (f campaignFixture) fight(t *testing.T, a identity.ActorContext, chapterID, copyID, hero, damage, star, hp int64, at time.Time) app.Settled {
	t.Helper()
	started := f.startAt(t, a, chapterID, copyID, hero, at)
	settled, err := f.mode.Settle(ctx, a, resultFor(chapterID, started, damage, star, hp), f.opAt(at))
	if err != nil {
		t.Fatalf("fight at %v: %v", at, err)
	}
	return settled
}

// atGMT8Seconds is the UTC instant of a GMT+8 wall-clock second on at's day.
func atGMT8Seconds(at time.Time, seconds int64) time.Time {
	wall := at.UTC().Add(8 * time.Hour)
	midnight := time.Date(wall.Year(), wall.Month(), wall.Day(), 0, 0, 0, 0, time.UTC)
	return midnight.Add(time.Duration(seconds)*time.Second - 8*time.Hour)
}

func (f campaignFixture) nextSlot(at time.Time) time.Time {
	for _, seconds := range f.settings.DistRewardTime {
		if candidate := atGMT8Seconds(at, seconds); candidate.After(at) {
			return candidate
		}
	}
	return atGMT8Seconds(at.Add(24*time.Hour), f.settings.DistRewardTime[0])
}

func (f campaignFixture) logCount(t *testing.T, logType int64) int64 {
	t.Helper()
	return scalar(t, f.pool, `SELECT count(*) FROM guild_campaign_log WHERE guild_id=$1 AND log_type=$2`, int64(f.guild), logType)
}

// factRecords counts the durable objective-fact rows for condition 117's fact
// kind (GUILD_ACTIVITY). The mission objective itself is gated for a level-1
// fixture, so the receipt is the row that proves each settlement recorded once.
func (f campaignFixture) factRecords(t *testing.T, a identity.ActorContext) int64 {
	t.Helper()
	return scalar(t, f.pool, `SELECT count(*) FROM gxb_operation_receipts WHERE owner_kind='player' AND owner_key=$1 AND domain='objective' AND operation='mission-source-fact'`, strconv.FormatInt(int64(a.PlayerID), 10))
}

func (f campaignFixture) payoutMails(t *testing.T, a identity.ActorContext) int64 {
	t.Helper()
	return campaignMailCount(t, f.pool, a.PlayerID, appPayoutSource)
}

const (
	appNoticeSource = "GUILD_CAMPAIGN_NOTICE"
	appPayoutSource = "GUILD_CAMPAIGN_PAYOUT"
)

var _ = context.Background
var _ = fmt.Sprint
var _ = json.Marshal

func (f campaignFixture) core(t *testing.T) guildcore.Service {
	t.Helper()
	service := guildCoreService(t, f.pool)
	service.Campaign = f.mode.Service
	service.Rental = rentalService(t, f.pool)
	return service
}

func (f campaignFixture) damage(t *testing.T, player identity.PlayerID, chapterID int64) int64 {
	t.Helper()
	return scalar(t, f.pool, `SELECT COALESCE((SELECT best_damage FROM guild_campaign_damage WHERE guild_id=$1 AND chapter_id=$2 AND run=1 AND player_id=$3),0)`,
		int64(f.guild), chapterID, int64(player))
}

func (f campaignFixture) awardMails(t *testing.T, player identity.ActorContext) int64 {
	t.Helper()
	return campaignMailCount(t, f.pool, player.PlayerID, "GUILD_CAMPAIGN_AWARD")
}

func TestI9_9CReplayLastStrikeAndChapterClear(t *testing.T) {
	f := newCampaignFixture(t)
	f.seedActivity(t, 40)
	if _, err := f.mode.Open(ctx, f.leader, 7, f.op()); err != nil {
		t.Fatal("open", err)
	}
	chapterID, plainCopy := f.copyID(t)
	copyID := f.bossCopy(t, chapterID)
	for _, id := range []int64{plainCopy, copyID} {
		f.mutateCopy(t, chapterID, id, func(copy *d.Copy, waves map[int64][]app.EnemyRow) {
			copy.CurrentIndex = 3
			copy.Percent = 2.0 / 3
			killWaves(waves, 1, 2)
		})
	}
	if logs := f.logCount(t, int64(d.LogFinalHit)); logs != 0 {
		t.Fatalf("log 7 before any clear: %d", logs)
	}
	beforeCoin := f.balance(t, f.leader, "team_dungeon_coin")
	f.fight(t, f.second, chapterID, plainCopy, f.secondHero, 4000, 3, 0, f.at)
	if got := f.balance(t, f.second, "team_dungeon_coin"); got != 0 {
		t.Fatalf("last strike paid on a copy without the boss: %d", got)
	}
	won := f.fight(t, f.leader, chapterID, copyID, f.leaderHero, 4000, 3, 0, f.at)
	if got := f.balance(t, f.leader, "team_dungeon_coin") - beforeCoin; got != f.settings.LastStrikeCoin {
		t.Fatalf("last strike coin %d, want %d", got, f.settings.LastStrikeCoin)
	}
	if logs := f.logCount(t, int64(d.LogFinalHit)); logs != 0 {
		t.Fatalf("log 7 on a copy clear that did not win the chapter: %d", logs)
	}
	retry, err := f.mode.Settle(ctx, f.leader, resultFor(chapterID, app.Started{CopyID: copyID, CurrentIndex: 3}, 4000, 3, 0), f.opAt(f.at.Add(time.Minute)))
	if err != nil || !retry.Duplicate || retry.Body["error_code"] != int64(30005) {
		t.Fatalf("copy win retry %+v err=%v", retry, err)
	}
	replayedAward := retry.Body["rank_award"].(map[string]any)
	storedAward := won.Body["rank_award"].(map[string]any)
	if retry.Body["coin_award"] != float64(won.Body["coin_award"].(int64)) ||
		replayedAward["crystal"] != float64(storedAward["crystal"].(int64)) || replayedAward["guild_coin"] != float64(storedAward["guild_coin"].(int64)) {
		t.Fatalf("copy win retry body %+v vs %+v", retry.Body, won.Body)
	}
	if got := f.balance(t, f.leader, "team_dungeon_coin"); got != beforeCoin+f.settings.LastStrikeCoin {
		t.Fatalf("retry paid the last strike again: %d", got)
	}
}

func TestI9_9CChapterClearPayoutOnceAndLateReset(t *testing.T) {
	f := newCampaignFixture(t)
	f.seedActivity(t, 40)
	if _, err := f.mode.Open(ctx, f.leader, 7, f.op()); err != nil {
		t.Fatal("open", err)
	}
	chapterID, copyID := f.prepareChapterClear(t)
	cleared := f.fight(t, f.leader, chapterID, copyID, f.leaderHero, 4000, 3, 0, f.at)
	for _, member := range []identity.ActorContext{f.leader, f.second, f.third} {
		if got := f.payoutMails(t, member); got != 1 {
			t.Fatalf("payout mails for %d = %d", member.PlayerID, got)
		}
	}
	if logs := f.logCount(t, int64(d.LogFinalHit)); logs != 1 {
		t.Fatalf("chapter clear log 7 = %d", logs)
	}
	latest := f.at.Add(time.Minute)
	retry, err := f.mode.Settle(ctx, f.leader, resultFor(chapterID, app.Started{CopyID: copyID, CurrentIndex: 3}, 4000, 3, 0), f.opAt(latest))
	if err != nil || !retry.Duplicate || retry.Body["error_code"] != int64(30005) {
		t.Fatalf("final hit retry %+v err=%v", retry, err)
	}
	if retry.Body["coin_award"] != float64(cleared.Body["coin_award"].(int64)) {
		t.Fatalf("final hit retry gold %v vs %v", retry.Body["coin_award"], cleared.Body["coin_award"])
	}
	if logs := f.logCount(t, int64(d.LogFinalHit)); logs != 1 {
		t.Fatalf("retry wrote a second log 7: %d", logs)
	}
	resetAt := f.at.Add(8 * 24 * time.Hour)
	if _, err := f.mode.Reset(ctx, f.leader, 7, f.opAt(resetAt)); err != nil {
		t.Fatalf("late reset %v", err)
	}
	for _, member := range []identity.ActorContext{f.leader, f.second, f.third} {
		if got := f.payoutMails(t, member); got != 1 {
			t.Fatalf("late reset paid %d again: %d", member.PlayerID, got)
		}
	}
	if run := scalar(t, f.pool, `SELECT run FROM guild_campaign_chapters WHERE guild_id=$1 AND chapter_id=$2`, int64(f.guild), chapterID); run != 2 {
		t.Fatalf("reset run %d", run)
	}
}

// TestI9_9CAwardQueue applies through 606 and drives the real reconciler. The
// won chapter is seeded through the campaign owner.
func TestI9_9CAwardQueue(t *testing.T) {
	f := newCampaignFixture(t)
	f.seedActivity(t, 40)
	if _, err := f.mode.Open(ctx, f.leader, 7, f.op()); err != nil {
		t.Fatal("open", err)
	}
	chapterID, _ := f.copyID(t)
	info := f.chapter(t)
	slot := f.nextSlot(f.at)
	tr := f.openTx(t)
	if err := f.store().UpsertDamageTx(ctx, tr, int64(f.guild), chapterID, 1, int64(f.second.PlayerID), 1000, f.at); err != nil {
		t.Fatal(err)
	}
	if err := f.store().UpsertDamageTx(ctx, tr, int64(f.guild), chapterID, 1, int64(f.third.PlayerID), 500, f.at); err != nil {
		t.Fatal(err)
	}
	if err := f.store().SaveChapterProgressTx(ctx, tr, int64(f.guild), chapterID, 1, 1, true, &f.at); err != nil {
		t.Fatal(err)
	}
	seed := app.AwardSeed{AwardID: info.Items[0], Remaining: 1, ExpiresAt: f.at.Add(time.Duration(f.settings.RewardTimeLimitSecond) * time.Second), NextSlot: slot}
	if err := f.store().InsertAwardsTx(ctx, tr, int64(f.guild), chapterID, 1, []app.AwardSeed{seed}); err != nil {
		t.Fatal(err)
	}
	if err := tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}

	for _, applicant := range []identity.ActorContext{f.second, f.third} {
		if _, err := f.mode.ApplyReward(ctx, applicant, chapterID, info.Items[0], f.op()); err != nil {
			t.Fatalf("apply %d: %v", applicant.PlayerID, err)
		}
	}
	for attempt := 0; attempt < 3; attempt++ {
		if _, err := f.mode.ApplyReward(ctx, f.third, chapterID, info.Items[0], f.op()); err != nil {
			t.Fatalf("third apply %d: %v", attempt+2, err)
		}
	}
	if _, err := f.mode.ApplyReward(ctx, f.third, chapterID, info.Items[0], f.op()); !errors.Is(err, app.ErrUnavailable) {
		t.Fatalf("fifth application in a day: %v", err)
	}

	decision := slot.Add(time.Second)
	mode := f.mode
	mode.Timed = gen.TimedRunner{Binder: gen.Binder{Time: fixedTime{at: decision}}, Runner: tx.Runner{DB: f.pool}}
	reconciler := app.Reconciler{Mode: mode}
	out, err := reconciler.Reconcile(ctx, mustTimed(t, f.opAt(decision), decision), 100)
	if err != nil || out.Settled != 1 {
		t.Fatalf("first reconcile %+v err=%v", out, err)
	}
	if got := f.awardMails(t, f.second); got != 1 {
		t.Fatalf("rank one award mails %d", got)
	}
	if got := f.awardMails(t, f.third); got != 0 {
		t.Fatalf("rank two award mails %d", got)
	}
	distributed, err := f.mode.DistributeRecord(ctx, f.second, f.op())
	if err != nil || len(distributed) != 1 || distributed[0].ItemID != info.Items[0] {
		t.Fatalf("615 rows %+v err=%v", distributed, err)
	}
	if again, err := reconciler.Reconcile(ctx, mustTimed(t, f.opAt(decision), decision), 100); err != nil || again.Settled != 0 {
		t.Fatalf("second reconcile %+v err=%v", again, err)
	}

	tr = f.openTx(t)
	missed := app.AwardRow{GuildID: int64(f.guild), ChapterID: chapterID, Run: 1, AwardID: info.Items[0], Remaining: 1, NextSlot: slot.Add(-2 * time.Hour)}
	if err := f.store().SaveAwardTx(ctx, tr, missed); err != nil {
		t.Fatal(err)
	}
	if err := tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	later := slot.Add(3 * time.Hour)
	mode.Timed = gen.TimedRunner{Binder: gen.Binder{Time: fixedTime{at: later}}, Runner: tx.Runner{DB: f.pool}}
	reconciler = app.Reconciler{Mode: mode}
	out, err = reconciler.Reconcile(ctx, mustTimed(t, f.opAt(later), later), 100)
	if err != nil || out.Settled != 1 {
		t.Fatalf("missed slot reconcile %+v err=%v", out, err)
	}
	rows, err := f.store().ListAwardsTx(ctx, f.pool, int64(f.guild), chapterID, 1)
	if err != nil || len(rows) != 1 || !rows[0].NextSlot.After(later) {
		t.Fatalf("missed slot next %+v err=%v", rows, err)
	}
	if rows[0].Remaining != 0 {
		t.Fatalf("missed slot remaining %d", rows[0].Remaining)
	}
}

func TestI9_9CRankTieBossDoubleAndRecordReward(t *testing.T) {
	f := newCampaignFixture(t)
	f.seedActivity(t, 40)
	if _, err := f.mode.Open(ctx, f.leader, 7, f.op()); err != nil {
		t.Fatal("open", err)
	}
	chapterID, _ := f.copyID(t)
	info := f.chapter(t)
	bossCopy := f.bossCopy(t, chapterID)
	plain := make([]int64, 0, len(info.Copies))
	for _, id := range info.Copies {
		if id != bossCopy {
			plain = append(plain, id)
		}
	}
	tieCopy, recordCopy := plain[0], plain[1]
	bossSettled := f.fight(t, f.second, chapterID, bossCopy, f.secondHero, 1000, 0, 50, f.at)
	if got := f.damage(t, f.second.PlayerID, chapterID); got != 2000 {
		t.Fatalf("boss wave rank damage %d, want 2000", got)
	}
	if bossSettled.Body["coin_award"] != int64(100) {
		t.Fatalf("boss wave doubled gold %v", bossSettled.Body["coin_award"])
	}
	tieAt := f.at.Add(time.Minute)
	f.fight(t, f.third, chapterID, tieCopy, f.thirdHero, 2000, 0, 50, tieAt)
	rows, err := f.mode.DamageRank(ctx, f.second, chapterID, f.op())
	if err != nil {
		t.Fatal(err)
	}
	if len(rows) != 2 || rows[0].Profile.PlayerID != f.second.PlayerID || rows[1].Profile.PlayerID != f.third.PlayerID || rows[0].Damage != rows[1].Damage {
		t.Fatalf("tie order %+v", rows)
	}
	crystalBefore := f.balance(t, f.second, "crystal")
	coinBefore := f.balance(t, f.second, "guild_coin")
	first := f.fight(t, f.second, chapterID, recordCopy, f.secondHero, 1000, 0, 50, f.at.Add(2*time.Minute))
	firstAward := first.Body["rank_award"].(map[string]any)
	if fmt.Sprint(firstAward["crystal"]) != fmt.Sprint(f.settings.RecordRewardCrystal) ||
		f.balance(t, f.second, "crystal")-crystalBefore != f.settings.RecordRewardCrystal || f.balance(t, f.second, "guild_coin")-coinBefore != f.settings.RecordRewardBadge {
		t.Fatalf("record reward first %+v", firstAward)
	}
	crystalBefore, coinBefore = f.balance(t, f.second, "crystal"), f.balance(t, f.second, "guild_coin")
	lower := f.fight(t, f.second, chapterID, recordCopy, f.secondHero, 500, 0, 50, f.at.Add(3*time.Minute))
	lowerAward := lower.Body["rank_award"].(map[string]any)
	if fmt.Sprint(lowerAward["crystal"]) != "0" || fmt.Sprint(lowerAward["guild_coin"]) != "0" ||
		f.balance(t, f.second, "crystal") != crystalBefore || f.balance(t, f.second, "guild_coin") != coinBefore {
		t.Fatalf("lower fight paid %+v", lowerAward)
	}
	higher := f.fight(t, f.second, chapterID, recordCopy, f.secondHero, 1500, 0, 50, f.at.Add(4*time.Minute))
	higherAward := higher.Body["rank_award"].(map[string]any)
	if fmt.Sprint(higherAward["crystal"]) != fmt.Sprint(f.settings.RecordRewardCrystal) ||
		f.balance(t, f.second, "crystal")-crystalBefore != f.settings.RecordRewardCrystal {
		t.Fatalf("higher fight reward %+v", higherAward)
	}
}

func TestI9_9CAttemptCapRestWindowAndLateJoin(t *testing.T) {
	f := newCampaignFixture(t)
	f.seedActivity(t, 40)
	if _, err := f.mode.Open(ctx, f.leader, 7, f.op()); err != nil {
		t.Fatal("open", err)
	}
	chapterID, _ := f.copyID(t)
	info := f.chapter(t)
	for index := 0; index < 2; index++ {
		f.fight(t, f.second, chapterID, info.Copies[index], f.secondHero, 5000, 3, 0, f.at.Add(time.Duration(index)*time.Minute))
	}
	if _, err := f.mode.Start(ctx, f.second, app.Fight{ChapterID: chapterID, CopyID: info.Copies[2], CampaignType: 7,
		Formation: strconv.FormatInt(f.secondHero, 10)}, f.op()); !errors.Is(err, d.ErrRefused) {
		t.Fatalf("third start with no attempts left: %v", err)
	}

	// Two concurrent fights already consumed both attempts when a live result
	// settles: the clearing 610 is refused and the copy is not advanced.
	race := newCampaignFixture(t)
	race.seedActivity(t, 40)
	if _, err := race.mode.Open(ctx, race.leader, 7, race.op()); err != nil {
		t.Fatal("open race fixture", err)
	}
	raceChapter, raceCopy := race.copyID(t)
	started := race.startAt(t, race.second, raceChapter, raceCopy, race.secondHero, race.at)
	tr := race.openTx(t)
	for attempt := 0; attempt < 2; attempt++ {
		if err := race.store().BumpMemberClearsTx(ctx, tr, race.second.PlayerID, raceChapter, modesDay(race.at)); err != nil {
			t.Fatal(err)
		}
	}
	if err := tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if _, err := race.mode.Settle(ctx, race.second, resultFor(raceChapter, started, 5000, 3, 0), race.op()); !errors.Is(err, d.ErrRefused) {
		t.Fatalf("clearing result after two concurrent fights: %v", err)
	}
	if index := race.copyIndex(t, raceCopy); index != 1 {
		t.Fatalf("refused concurrent clear advanced the copy to %d", index)
	}

	rest := f.settings.RestSecondsOfDay
	restStart := atGMT8Seconds(f.at.Add(24*time.Hour), rest[0])
	restFixture := newCampaignFixture(t)
	restFixture.seedActivity(t, 40)
	if _, err := restFixture.mode.Open(ctx, restFixture.leader, 7, restFixture.op()); err != nil {
		t.Fatal("open rest fixture", err)
	}
	restChapter, restCopy := restFixture.copyID(t)
	if _, err := restFixture.mode.Start(ctx, restFixture.second, app.Fight{ChapterID: restChapter, CopyID: restCopy, CampaignType: 7, Formation: strconv.FormatInt(restFixture.secondHero, 10)}, restFixture.opAt(restStart.Add(-2*time.Minute))); err != nil {
		t.Fatalf("start before the rest window: %v", err)
	}
	if _, err := restFixture.mode.Settle(ctx, restFixture.second, app.Result{ChapterID: restChapter, CopyID: restCopy, CurrentIndex: 1, Formation: "1", TotalDamage: 100, Star: 0}, restFixture.opAt(restStart.Add(30*time.Second))); err != nil {
		t.Fatalf("settle across the rest window: %v", err)
	}
	if _, err := restFixture.mode.Start(ctx, restFixture.third, app.Fight{ChapterID: restChapter, CopyID: restCopy, CampaignType: 7, Formation: strconv.FormatInt(restFixture.thirdHero, 10)}, restFixture.opAt(restStart.Add(time.Minute))); !errors.Is(err, d.ErrRefused) {
		t.Fatalf("start inside the rest window: %v", err)
	}

	late := newCampaignFixture(t)
	late.seedActivity(t, 40)
	if _, err := late.mode.Open(ctx, late.leader, 7, late.op()); err != nil {
		t.Fatal("open late fixture", err)
	}
	lateChapter, lateCopy := late.copyID(t)
	joiner, _ := genuinePlayer(t, late.pool, late.server)
	tr = late.openTx(t)
	member := guild.Membership{PlayerID: joiner.PlayerID, GuildID: late.guild, Role: guild.Member, JoinedAt: late.at, MembershipVersion: 1, StateVersion: 1, UpdatedAt: late.at}
	if err := (guildstore.Store{Queryer: late.pool}).InsertMembershipTx(ctx, tr, member); err != nil {
		t.Fatal(err)
	}
	if err := tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if _, err := late.mode.Claim(ctx, joiner, lateCopy, late.op()); !errors.Is(err, d.ErrRefused) {
		t.Fatalf("late joiner claimed: %v", err)
	}
	if _, err := late.mode.Start(ctx, joiner, app.Fight{ChapterID: lateChapter, CopyID: lateCopy, CampaignType: 7, Formation: "1"}, late.op()); !errors.Is(err, d.ErrRefused) {
		t.Fatalf("late joiner fought: %v", err)
	}
}

func TestI9_9CLeaveKickAndDissolveForfeit(t *testing.T) {
	f := newCampaignFixture(t)
	f.seedActivity(t, 40)
	if _, err := f.mode.Open(ctx, f.leader, 7, f.op()); err != nil {
		t.Fatal("open", err)
	}
	chapterID, copyID := f.copyID(t)
	core := f.core(t)
	if _, err := core.Leave(ctx, f.second, op()); err != nil {
		t.Fatal("leave", err)
	}
	if _, err := f.mode.Start(ctx, f.second, app.Fight{ChapterID: chapterID, CopyID: copyID, CampaignType: 7, Formation: strconv.FormatInt(f.secondHero, 10)}, f.op()); !errors.Is(err, d.ErrRefused) {
		t.Fatalf("leaver started: %v", err)
	}

	fightFixture := newCampaignFixture(t)
	fightFixture.seedActivity(t, 40)
	if _, err := fightFixture.mode.Open(ctx, fightFixture.leader, 7, fightFixture.op()); err != nil {
		t.Fatal("open fight fixture", err)
	}
	fightChapter, fightCopy := fightFixture.copyID(t)
	started := fightFixture.startAt(t, fightFixture.second, fightChapter, fightCopy, fightFixture.secondHero, fightFixture.at)
	fightCore := fightFixture.core(t)
	if _, err := fightCore.Leave(ctx, fightFixture.second, op()); err != nil {
		t.Fatal("leave during the fight", err)
	}
	if _, err := fightFixture.mode.Settle(ctx, fightFixture.second, resultFor(fightChapter, started, 5000, 3, 0), fightFixture.op()); !errors.Is(err, d.ErrRefused) {
		t.Fatalf("leaver settled: %v", err)
	}
	if index := fightFixture.copyIndex(t, fightCopy); index != 1 {
		t.Fatalf("leaver settlement advanced the copy to %d", index)
	}

	kickFixture := newCampaignFixture(t)
	kickFixture.seedActivity(t, 40)
	if _, err := kickFixture.mode.Open(ctx, kickFixture.leader, 7, kickFixture.op()); err != nil {
		t.Fatal("open kick fixture", err)
	}
	kickChapter, kickCopy := kickFixture.copyID(t)
	kickCore := kickFixture.core(t)
	if _, err := kickCore.Kick(ctx, kickFixture.leader, kickFixture.third.PlayerID, op()); err != nil {
		t.Fatal("kick", err)
	}
	if kickFixture.registered(t, kickChapter, kickFixture.third) {
		t.Fatal("kicked member still registered")
	}
	if _, err := kickFixture.mode.Start(ctx, kickFixture.third, app.Fight{ChapterID: kickChapter, CopyID: kickCopy, CampaignType: 7, Formation: strconv.FormatInt(kickFixture.thirdHero, 10)}, kickFixture.op()); !errors.Is(err, d.ErrRefused) {
		t.Fatalf("kicked member started: %v", err)
	}

	dissolveFixture := newCampaignFixture(t)
	dissolveFixture.seedActivity(t, 40)
	if _, err := dissolveFixture.mode.Open(ctx, dissolveFixture.leader, 7, dissolveFixture.op()); err != nil {
		t.Fatal("open dissolve fixture", err)
	}
	dissolveCore := dissolveFixture.core(t)
	for _, member := range []identity.ActorContext{dissolveFixture.second, dissolveFixture.third} {
		if _, err := dissolveCore.Kick(ctx, dissolveFixture.leader, member.PlayerID, op()); err != nil {
			t.Fatal("kick before dissolve", err)
		}
	}
	if _, err := dissolveCore.Dissolve(ctx, dissolveFixture.leader, op()); err != nil {
		t.Fatal("dissolve", err)
	}
	if rows := dissolveFixture.chapterRows(t); rows != 0 {
		t.Fatalf("dissolve left %d chapter rows", rows)
	}
	if rows := scalar(t, dissolveFixture.pool, `SELECT count(*) FROM guild_campaign_copies WHERE guild_id=$1`, int64(dissolveFixture.guild)); rows != 0 {
		t.Fatalf("dissolve left %d copy rows", rows)
	}
	if rows := scalar(t, dissolveFixture.pool, `SELECT count(*) FROM guild_campaign_registrations WHERE guild_id=$1`, int64(dissolveFixture.guild)); rows != 0 {
		t.Fatalf("dissolve left %d registration rows", rows)
	}
}

func TestI9_9CBorrowedGirlThroughARealOffer(t *testing.T) {
	f := newCampaignFixture(t)
	f.seedActivity(t, 40)
	grantGenuine(t, f.pool, f.third, f.rev, "borrow-mana", []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "mana", Amount: 10000}})
	if _, err := f.mode.Open(ctx, f.leader, 7, f.op()); err != nil {
		t.Fatal("open", err)
	}
	chapterID, copyID := f.copyID(t)
	rental := rentalService(t, f.pool)
	if err := rental.Place(ctx, f.second, guild.RentalHero, f.secondHero, opPinned(f.rev)); err != nil {
		t.Fatalf("place offer: %v", err)
	}
	combat := combatService(t, f.pool)
	combat.Inputs.Lending = rental
	f.mode.Combat = combat
	before := f.balance(t, f.third, "mana")
	started, err := f.mode.Start(ctx, f.third, app.Fight{ChapterID: chapterID, CopyID: copyID, CampaignType: 7,
		Formation: strconv.FormatInt(f.thirdHero, 10), RentPlayer: int64(f.second.PlayerID), RentFormation: f.secondHero}, f.op())
	if err != nil {
		t.Fatalf("borrowed start: %v", err)
	}
	if started.CurrentIndex != 1 {
		t.Fatalf("borrowed start index %d", started.CurrentIndex)
	}
	fee := scalar(t, f.pool, `SELECT COALESCE((SELECT cost_mana FROM guild_rental_uses WHERE borrower_id=$1 AND lender_id=$2 AND kind='HERO' AND campaign_type=7),0)`,
		int64(f.third.PlayerID), int64(f.second.PlayerID))
	if fee <= 0 || before-f.balance(t, f.third, "mana") != fee {
		t.Fatalf("borrow fee %d, mana %d -> %d", fee, before, f.balance(t, f.third, "mana"))
	}
	if got := scalar(t, f.pool, `SELECT count(*) FROM guild_rental_uses WHERE borrower_id=$1 AND lender_id=$2 AND campaign_type=7 AND unit_id=$3`,
		int64(f.third.PlayerID), int64(f.second.PlayerID), f.secondHero); got != 1 {
		t.Fatalf("frozen borrowed row count %d", got)
	}

	outsider, _ := genuinePlayer(t, f.pool, f.server)
	guildFixture(t, f.pool, outsider)
	outsiderHero := bornHero(t, f.pool, outsider, f.rev, genuineHeroTable, 1).PartnerID
	if err := rental.Place(ctx, outsider, guild.RentalHero, outsiderHero, opPinned(f.rev)); err != nil {
		t.Fatalf("outside offer: %v", err)
	}
	if _, err := f.mode.Start(ctx, f.third, app.Fight{ChapterID: chapterID, CopyID: copyID, CampaignType: 7,
		Formation: strconv.FormatInt(f.thirdHero, 10), RentPlayer: int64(outsider.PlayerID), RentFormation: outsiderHero}, f.op()); err == nil {
		t.Fatal("borrowed a girl from outside the guild")
	}
}

func TestI9_9CChallengeFactsAndMemberRow(t *testing.T) {
	f := newCampaignFixture(t)
	f.seedActivity(t, 40)
	if _, err := f.mode.Open(ctx, f.leader, 7, f.op()); err != nil {
		t.Fatal("open", err)
	}
	if logs, err := f.mode.GuildLog(ctx, f.leader, f.op()); err != nil || len(logs) != 1 || logs[0].Type != int64(d.LogOpenChapter) {
		t.Fatalf("open log %+v %v", logs, err)
	}
	chapterID, copyID := f.beginSingleCopy(t)
	f.fight(t, f.leader, chapterID, copyID, f.leaderHero, 4000, 3, 0, f.at)
	if records := f.factRecords(t, f.leader); records != 1 {
		t.Fatalf("win fact records %d", records)
	}
	f.fight(t, f.leader, chapterID, copyID, f.leaderHero, 100, 0, 50, f.at.Add(time.Minute))
	if records := f.factRecords(t, f.leader); records != 2 {
		t.Fatalf("loss fact records %d", records)
	}
	challenges, err := f.store().CopyChallengeTimesTx(ctx, f.pool, []identity.PlayerID{f.leader.PlayerID}, modesDay(f.at))
	if err != nil || challenges[f.leader.PlayerID] != 1 {
		t.Fatalf("copy_challenge_times %v %v", challenges, err)
	}
	row := guildwire.Member(guildview.Member{PlayerID: int64(f.leader.PlayerID), CopyChallengeTime: challenges[f.leader.PlayerID]})
	if row["copy_challenge_times"] != int64(1) {
		t.Fatalf("612 member row %+v", row)
	}
	logs, err := f.mode.GuildLog(ctx, f.leader, f.op())
	if err != nil || len(logs) == 0 {
		t.Fatalf("guild log %+v %v", logs, err)
	}
	for _, row := range logs {
		if row.Type == 0 {
			t.Fatalf("609 row without type %+v", row)
		}
	}
}
