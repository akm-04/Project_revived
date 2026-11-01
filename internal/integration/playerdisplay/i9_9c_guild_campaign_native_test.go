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
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/guildcampaignstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	gen "gxb.local/backend/v2/internal/application/generation"
	app "gxb.local/backend/v2/internal/application/guildcampaign"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/content/guildcampaigncatalog"
	"gxb.local/backend/v2/internal/content/guildcampaignpolicy"
	"gxb.local/backend/v2/internal/domain/guild"
	d "gxb.local/backend/v2/internal/domain/guildcampaign"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type campaignFixture struct {
	pool     *postgres.Pool
	rev      string
	server   identity.LogicalServerID
	leader   identity.ActorContext
	second   identity.ActorContext
	third    identity.ActorContext
	guild    guild.ID
	mode     app.Mode
	settings app.Settings
	tables   map[int64]app.ChapterInfo
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
	f.settings = app.Settings{AttemptsPerChapterDay: policy.AttemptsPerChapterDay, PrepareSeconds: policy.PrepareSeconds,
		BattleSeconds: policy.BattleSeconds, RestSecondsOfDay: policy.RestSecondsOfDay, ApplicationsPerDay: policy.ApplicationsPerDay,
		BossRankFactor: policy.BossDamageRankFactor, RetentionDays: policy.GuildLogRetentionDays, RewardHurtRank: installed.RewardHurtRank,
		RankThresholds: installed.RankThresholds, RankPercents: installed.RankPercents, DistRewardTime: installed.DistRewardTime,
		RewardParamPerMille: installed.RewardParamPerMile, RewardTimeLimitSecond: installed.RewardTimeLimit,
		FirstRewardDiamond: installed.FirstRewardDiamond, FirstRewardCoin: installed.FirstRewardCoin}
	f.tables = map[int64]app.ChapterInfo{}
	for _, chapter := range installed.Chapters {
		info, _ := catalog.ChapterInfo(chapter.ChapterID)
		f.tables[chapter.ChapterID] = info
	}
	store := guildcampaignstore.Store{}
	mail := appi5.SettlementMail{Store: i5store.Store{Queryer: p}}
	payout := app.Payout{Store: store, Mail: mail, Settings: f.settings, Tables: f.tables}
	combatService := combatService(t, p)
	f.mode = app.Mode{
		Service: app.Service{Runner: tx.Runner{DB: p}, Store: store, Guilds: guildstore.Store{Queryer: p}, Catalog: catalog, Payout: payout,
			Mail: mail, Fence: i5store.Store{Queryer: p}, Players: i4store.PlayerRootLocker{},
			Notice: app.NoticeMail{Enabled: true, OpenTitle: policy.NoticeMail.OpenTitle, OpenBody: policy.NoticeMail.OpenBody,
				ResetTitle: policy.NoticeMail.ResetTitle, ResetBody: policy.NoticeMail.ResetBody, Sender: "Guild"}},
		ModeStore: store, Content: catalog, Tables: f.tables, Settings: f.settings,
		Combat: combatService, Grants: genuineGrants(p), Facts: appi5.ObjectiveFacts{Owner: genuineGrants(p), Open: i5store.Store{Queryer: p}},
		Directory: i4store.PlayerDirectoryReader{}, Mail: mail, NoticeMail: mail, Fence: i5store.Store{Queryer: p}, Players: i4store.PlayerRootLocker{},
		Timed: gen.TimedRunner{Binder: gen.Binder{Time: postgres.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}}, Fresh: p,
	}
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

func (f campaignFixture) op() operation.Context { return opPinned(f.rev) }

func (f campaignFixture) chapter(t *testing.T) app.ChapterInfo {
	t.Helper()
	return f.tables[7]
}

func (f campaignFixture) copyID(t *testing.T) (int64, int64) {
	t.Helper()
	info := f.chapter(t)
	return info.ChapterID, info.Copies[0]
}

func (f campaignFixture) hero(t *testing.T, a identity.ActorContext) int64 {
	t.Helper()
	return bornHero(t, f.pool, a, f.rev, genuineHeroTable, 1).PartnerID
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
	heroThird := f.hero(t, f.third)
	started := f.start(t, f.third, chapterID, copyID, heroThird)
	loss := f.waveEnemies(t, started, 0, 1234, 77)
	if _, err := f.mode.Settle(ctx, f.third, loss, f.op()); err != nil {
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
	// A duplicate of a settled loss inside the window gets 30021, not 30005.
	if _, err := f.mode.Settle(ctx, f.third, loss, f.op()); !errors.Is(err, app.ErrLate) {
		t.Fatal("duplicate loss", err)
	}
	// The second member starts the same wave and clears it.
	if _, err := f.mode.Claim(ctx, f.second, copyID, f.op()); err != nil {
		t.Fatal("claim second", err)
	}
	heroSecond := f.hero(t, f.second)
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
	if err := f.removeMember(t, f.second); err != nil {
		t.Fatal("forfeit", err)
	}
	if registered := f.registered(t, chapterID, f.second); registered {
		t.Fatal("leaver still registered")
	}
	exec(t, f.pool, `DELETE FROM guild_memberships WHERE player_id=$1 AND guild_id=$2`, int64(f.second.PlayerID), int64(f.guild))
	exec(t, f.pool, `INSERT INTO guild_memberships(player_id,guild_id,role,joined_at,membership_version,state_version,updated_at)VALUES($1,$2,0,clock_timestamp(),1,1,clock_timestamp())`, int64(f.second.PlayerID), int64(f.guild))
	if registered := f.registered(t, chapterID, f.second); registered {
		t.Fatal("rejoining restored registration before reset")
	}
	if _, err := f.mode.Start(ctx, f.second, app.Fight{ChapterID: chapterID, CopyID: copyID, CampaignType: 7, Formation: "1"}, f.op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("unregistered member started", err)
	}
	tr := f.openTx(t)
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

func (f campaignFixture) removeMember(t *testing.T, a identity.ActorContext) error {
	t.Helper()
	tr, err := f.pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	if err := f.mode.RemoveMemberTx(ctx, tr, f.guild, a.PlayerID); err != nil {
		return err
	}
	return tr.Commit(ctx)
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
	exec(t, f.pool, `UPDATE guild_campaign_copies SET last_fight_time=clock_timestamp()-interval '10 minutes', start_fight_time=clock_timestamp()-interval '10 minutes' WHERE guild_id=$1 AND copy_id=$2`, int64(f.guild), copyID)
}

func (f campaignFixture) memberClears(t *testing.T, a identity.ActorContext, chapterID int64) int64 {
	t.Helper()
	now, err := (postgres.AuthoritativeTime{Queryer: f.pool}).Now(ctx)
	if err != nil {
		t.Fatal(err)
	}
	clears, err := (guildcampaignstore.Store{}).MemberClearsTx(ctx, f.pool, a.PlayerID, chapterID, modesDay(now))
	if err != nil {
		t.Fatal(err)
	}
	return clears
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

const (
	appNoticeSource = "GUILD_CAMPAIGN_NOTICE"
	appPayoutSource = "GUILD_CAMPAIGN_PAYOUT"
)

var _ = context.Background
var _ = fmt.Sprint
var _ = json.Marshal
