//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	"fmt"
	"testing"
	"time"

	guildwire "gxb.local/backend/v2/internal/adapters/guildwire"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildprojection"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/application/guildtea"
	"gxb.local/backend/v2/internal/application/guildview"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/content/guildteapolicy"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func activityOwner(p *pg.Pool) appi5.Service {
	values, content := i5store.Store{Queryer: p}, contentstore.Store{Queryer: p}
	return appi5.Service{Runner: tx.Runner{DB: p}, Store: values, Content: content, Privileges: appi5.BaselinePrivilegeProvider{}, Functions: appi5.PetStarterFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{},
		Backpack: values, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, RedeemSecret: []byte("i9-9a-native-fixture-secret")}
}

func contentOp(t *testing.T, p *pg.Pool, revision string) operation.Context {
	t.Helper()
	refs, err := policy.NewSet(policy.Ref{Name: "content", Version: revision})
	if err != nil {
		t.Fatal(err)
	}
	o, err := (operation.Factory{Clock: clock.System{}}).New(refs)
	if err != nil {
		t.Fatal(err)
	}
	return o
}

func guildFixture(t *testing.T, p *pg.Pool, leader identity.ActorContext, members ...identity.ActorContext) guild.ID {
	t.Helper()
	server := int64(leader.LogicalServerID)
	now := time.Now().UTC().Add(-time.Hour)
	var gid int64
	if err := p.QueryRow(ctx, `INSERT INTO guilds(guild_id,logical_server_id,name,icon,icon_frame,des,apply_type,min_allow_level,vitality,policy_revision,state_version,created_at,updated_at)
		SELECT $1*1000000+n,$1,'n'||n,20010001,0,'',0,1,20000,'native-fixture',1,$2,$2 FROM (SELECT COALESCE(MAX(guild_id%1000000),0)+1 AS n FROM guilds WHERE logical_server_id=$1) next RETURNING guild_id`, server, now).Scan(&gid); err != nil {
		t.Fatal(err)
	}
	exec(t, p, `INSERT INTO guild_memberships(player_id,guild_id,role,joined_at,membership_version,state_version,updated_at)VALUES($1,$2,1,$3,1,1,$3)`, int64(leader.PlayerID), gid, now)
	for _, member := range members {
		exec(t, p, `INSERT INTO guild_memberships(player_id,guild_id,role,joined_at,membership_version,state_version,updated_at)VALUES($1,$2,0,$3,1,1,$3)`, int64(member.PlayerID), gid, now)
	}
	return guild.ID(gid)
}

func appendActivity(t *testing.T, p *pg.Pool, a identity.ActorContext, day, amount int64) {
	t.Helper()
	exec(t, p, `INSERT INTO player_guild_activity_days(player_id,game_day,amount)VALUES($1,$2,$3) ON CONFLICT(player_id,game_day) DO UPDATE SET amount=player_guild_activity_days.amount+excluded.amount`, int64(a.PlayerID), day, amount)
}

func TestI9_9AEnergyDebitCreditsActivityCapsAndGuildlessJoin(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	revision := installed(t, pool)
	owner := activityOwner(pool)
	a, b := bornActor(t, pool), bornActor(t, pool)
	guildFixture(t, pool, a, b)
	now, err := (pg.AuthoritativeTime{Queryer: pool}).Now(ctx)
	if err != nil {
		t.Fatal(err)
	}
	day := modes.Day(now)
	op := contentOp(t, pool, revision)

	tr, err := pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if _, err = owner.DebitTemporalTx(ctx, tr, a.PlayerID, appi5.EnergyKey, 1, op); err != nil {
		tr.Rollback(ctx)
		t.Fatalf("energy debit: %v", err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	store := guildstore.Store{Queryer: pool}
	activity, err := store.ReadPlayerActivity(ctx, a.PlayerID, day)
	if err != nil || activity.Today != 1 || activity.Lifetime != 1 {
		t.Fatalf("energy debit activity %+v %v", activity, err)
	}

	appendActivity(t, pool, a, day, 1200)
	activity, err = store.ReadPlayerActivity(ctx, a.PlayerID, day)
	if err != nil || activity.Today != guild.ActivityDailyCap || activity.Lifetime != guild.ActivityDailyCap {
		t.Fatalf("daily cap %+v %v", activity, err)
	}

	guildless := bornActor(t, pool)
	otherGuild := guildFixture(t, pool, bornActor(t, pool))
	appendActivity(t, pool, guildless, day, 500)
	tr, err = pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if err = store.MarkActivityFoldedTx(ctx, tr, guildless.PlayerID); err != nil {
		tr.Rollback(ctx)
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	exec(t, pool, `INSERT INTO guild_memberships(player_id,guild_id,role,joined_at,membership_version,state_version,updated_at)VALUES($1,$2,0,clock_timestamp(),1,1,clock_timestamp())`, int64(guildless.PlayerID), int64(otherGuild))
	unfolded, err := store.ReadUnfoldedActivity(ctx, otherGuild)
	if err != nil || unfolded != 0 {
		t.Fatalf("guildless spend credited: unfolded=%d %v", unfolded, err)
	}
}

func TestI9_9AGuildBalanceBoundedAndLeaveHalvesLifetime(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	a, b := bornActor(t, pool), bornActor(t, pool)
	gid := guildFixture(t, pool, a, b)
	now, err := (pg.AuthoritativeTime{Queryer: pool}).Now(ctx)
	if err != nil {
		t.Fatal(err)
	}
	day := modes.Day(now)
	appendActivity(t, pool, a, day, 600)
	appendActivity(t, pool, b, day, 1000)
	store := guildstore.Store{Queryer: pool}
	unfolded, err := store.ReadUnfoldedActivity(ctx, gid)
	if err != nil || guild.ActivityBalance(279000, unfolded) != guild.ActivityGuildCap {
		t.Fatalf("guild cap unfolded=%d %v", unfolded, err)
	}

	tr, err := pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	credited, err := store.FoldActivityTx(ctx, tr, []identity.PlayerID{a.PlayerID})
	if err != nil || credited != 600 {
		tr.Rollback(ctx)
		t.Fatalf("fold %d %v", credited, err)
	}
	if err = store.ForfeitActivityLifetimeTx(ctx, tr, a.PlayerID); err != nil {
		tr.Rollback(ctx)
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	activity, err := store.ReadPlayerActivity(ctx, a.PlayerID, day)
	if err != nil || activity.Lifetime != 300 {
		t.Fatalf("leave half lifetime %+v %v", activity, err)
	}
	unfolded, err = store.ReadUnfoldedActivity(ctx, gid)
	if err != nil || unfolded != 1000 {
		t.Fatalf("folded credit left unfolded=%d %v", unfolded, err)
	}

	view := guildview.Service{Store: store, Directory: i4store.PlayerDirectoryReader{Queryer: pool}, Day: func(context.Context) (int64, error) { return day, nil }}
	info, found, err := view.GuildInfo(ctx, a, gid)
	if err != nil || !found || info.ThreeHuoyue != 1600 {
		t.Fatalf("2565 three_huoyue %+v %v", info, err)
	}
	if wire := guildwire.Detail2565(info); wire["guild_info"].(map[string]any)["three_huoyue"] != int64(1600) {
		t.Fatalf("2565 wire %v", wire)
	}
	rows, mine, err := view.ActivityRankList(ctx, a, 50)
	found = false
	for _, row := range rows {
		if row.Guild.GuildID != int64(gid) {
			continue
		}
		found = row.Guild.ThreeDay == 1600 && mine == row.Rank
	}
	if err != nil || !found {
		t.Fatalf("LOAD_RANK_LIST type 4 board mine=%d %v", mine, err)
	}
	if wire := guildwire.GuildRankList(11, rows, mine); len(wire["rank_list"].([]map[string]any)[0]["rank_info"].(map[string]any)["rank_info"].([]map[string]any)) == 0 {
		t.Fatalf("rank wire %v", wire)
	}
}

func TestI9_9AIllusionAwardSourceKeyCreditsOnce(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	a := bornActor(t, pool)
	gid := guildFixture(t, pool, a)
	store := guildstore.Store{Queryer: pool}
	tr, err := pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	for i := 0; i < 2; i++ {
		if err = store.CreditActivityAwardTx(ctx, tr, int64(gid), "1:2:3:guild:"+fmt.Sprint(gid), 500); err != nil {
			tr.Rollback(ctx)
			t.Fatal(err)
		}
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	unfolded, err := store.ReadUnfoldedActivity(ctx, gid)
	if err != nil || unfolded != 500 {
		t.Fatalf("replay credited twice: %d %v", unfolded, err)
	}
}

func teaService(p *pg.Pool) guildtea.Service {
	values := i5store.Store{Queryer: p}
	owner := activityOwner(p)
	teaPolicy, err := guildteapolicy.LoadBuiltin()
	if err != nil {
		panic(err)
	}
	return guildtea.Service{Runner: tx.Runner{DB: p}, Store: guildstore.Store{Queryer: p}, Directory: i4store.PlayerDirectoryReader{},
		Content: contentstore.Store{Queryer: p}, Heroes: characterstore.Store{Queryer: p}, Inventory: values,
		Exchange: owner, Values: owner, Facts: appi5.ObjectiveFacts{Owner: owner, Open: values},
		Fence: values, Players: i4store.PlayerRootLocker{}, Policy: guildtea.Policy{RequestsPerDay: teaPolicy.RequestsPerDay, NormalNeed: teaPolicy.NormalNeed, SXNeed: teaPolicy.SXNeed, DonorFriendMedalPerScroll: teaPolicy.DonorFriendMedalPerScroll}}
}

func scrollForHero(t *testing.T, p *pg.Pool, revision string, table int64) int64 {
	t.Helper()
	var item int64
	if err := p.QueryRow(ctx, `SELECT r.item_id FROM gxb_content_resource_definitions r JOIN gxb_content_hero_templates h ON h.revision_id=r.revision_id AND h.table_id=r.partner_id
		WHERE r.revision_id=$1 AND h.table_id=$2 AND h.table_id=h.origin_table_id AND r.item_id IS NOT NULL ORDER BY r.item_id LIMIT 1`, revision, table).Scan(&item); err != nil {
		t.Fatal(err)
	}
	return item
}

func TestI9_9ATeaWishDonateClaimRefusalsAndExpiry(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	revision := installed(t, pool)
	a, b := bornActor(t, pool), bornActor(t, pool)
	guildFixture(t, pool, a, b)
	bornHero(t, pool, b, revision, 10001001, 1)
	scroll := scrollForHero(t, pool, revision, 10001001)
	exec(t, pool, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,$2,1,1,clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour')`, int64(a.PlayerID), scroll)
	now, err := (pg.AuthoritativeTime{Queryer: pool}).Now(ctx)
	if err != nil {
		t.Fatal(err)
	}
	day := modes.Day(now)
	service := teaService(pool)
	op := contentOp(t, pool, revision)
	exec(t, pool, `INSERT INTO objective_definitions(program_id,stock_family,objective_id,definition_revision,strategy,accepted_fact_kind,target,generation_kind,reward_plan,content_policy_version)
		VALUES('tea:fact',2,90028,'LEGACY_TEA','COMMITTED_DELTA','TEA_PARTY_DONATED',1,'STATIC','{"PlayerID":0,"Source":{"Domain":"mission","Operation":"claim","BusinessKey":"legacy","Occurrence":"","PolicyVersion":"I9_MISSIONS_V1"},"Lines":[{"Kind":"STACK_ITEM","ItemID":40001001,"Amount":1}]}'::jsonb,'I9_MISSIONS_V1') ON CONFLICT DO NOTHING`)
	exec(t, pool, `INSERT INTO player_mission_instances(player_id,program_id,objective_id,generation_id,definition_revision,progress,claim_state,state_version)VALUES($1,'tea:fact',90028,'','LEGACY_TEA',0,'UNCLAIMED',1)`, int64(a.PlayerID))

	if _, err = service.Request(ctx, b, scroll, op); err != nil {
		t.Fatalf("wish: %v", err)
	}
	if _, err = service.Request(ctx, b, scroll, op); !errors.Is(err, guildtea.ErrAlreadyWished) {
		t.Fatalf("second wish: %v", err)
	}
	state, err := service.Info(ctx, b, op, false)
	if err != nil || state.SelfWish.ItemID != scroll || state.SelfWish.NeedNum != 3 || state.WishFlag != 1 {
		t.Fatalf("tea info %+v %v", state, err)
	}
	if _, err = service.Present(ctx, b, b.PlayerID, op); !errors.Is(err, guildtea.ErrSelfDonation) {
		t.Fatalf("self donation: %v", err)
	}
	if _, err = service.Present(ctx, a, b.PlayerID, op); err != nil {
		t.Fatalf("donation: %v", err)
	}
	var progress int64
	if err = pool.QueryRow(ctx, `SELECT progress FROM player_mission_instances WHERE player_id=$1 AND objective_id=90028`, int64(a.PlayerID)).Scan(&progress); err != nil || progress != 1 {
		t.Fatalf("fact 123 progress %d %v", progress, err)
	}
	var stock, medal int64
	if err = pool.QueryRow(ctx, `SELECT COALESCE((SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=$2),0)`, int64(a.PlayerID), scroll).Scan(&stock); err != nil || stock != 0 {
		t.Fatalf("donor shard %d %v", stock, err)
	}
	if err = pool.QueryRow(ctx, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='friend_medal'`, int64(a.PlayerID)).Scan(&medal); err != nil || medal != 5 {
		t.Fatalf("friend medal %d %v", medal, err)
	}
	if _, err = service.Present(ctx, a, b.PlayerID, op); !errors.Is(err, guildtea.ErrAlreadyDonated) {
		t.Fatalf("second donation: %v", err)
	}

	claimed, err := service.Confirm(ctx, b, op)
	if err != nil || claimed.Award == nil || claimed.Award.ItemID != scroll || claimed.Award.Num != 1 {
		t.Fatalf("claim %+v %v", claimed, err)
	}
	var owned int64
	if err = pool.QueryRow(ctx, `SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=$2`, int64(b.PlayerID), scroll).Scan(&owned); err != nil || owned != 1 {
		t.Fatalf("claim stack %d %v", owned, err)
	}
	again, err := service.Confirm(ctx, b, op)
	if err != nil || again.Award != nil {
		t.Fatalf("claim idempotency %+v %v", again, err)
	}

	exec(t, pool, `INSERT INTO guild_tea_wishes(player_id,game_day,item_id,need_num,current_num)VALUES($1,$2,$3,3,0)`, int64(b.PlayerID), day-1, scroll)
	exec(t, pool, `INSERT INTO guild_tea_gifts(receiver_id,donor_id,game_day,item_id)VALUES($1,$2,$3,$4)`, int64(b.PlayerID), int64(a.PlayerID), day-1, scroll)
	if _, err = service.Info(ctx, b, op, false); err != nil {
		t.Fatal(err)
	}
	var expired int64
	if err = pool.QueryRow(ctx, `SELECT COUNT(*) FROM guild_tea_gifts WHERE receiver_id=$1 AND game_day=$2`, int64(b.PlayerID), day-1).Scan(&expired); err != nil || expired != 1 {
		t.Fatalf("read path wrote: expired rows %d %v", expired, err)
	}
	if _, err = service.Request(ctx, a, scroll, op); err != nil {
		// The donor owns no hero; a refusal still runs the command path if validation follows the purge order.
		if !errors.Is(err, guildtea.ErrUnknownScroll) && !errors.Is(err, guildtea.ErrNotOwner) {
			t.Fatal(err)
		}
	}
	exec(t, pool, `INSERT INTO guild_tea_gifts(receiver_id,donor_id,game_day,item_id)VALUES($1,$2,$3,$4) ON CONFLICT DO NOTHING`, int64(b.PlayerID), int64(a.PlayerID), day-2, scroll)
	if _, err = service.Confirm(ctx, b, op); err != nil && !errors.Is(err, guildtea.ErrNoWish) {
		t.Fatal(err)
	}
	if err = pool.QueryRow(ctx, `SELECT COUNT(*) FROM guild_tea_gifts WHERE receiver_id=$1 AND game_day<$2`, int64(b.PlayerID), day).Scan(&expired); err != nil || expired != 0 {
		t.Fatalf("expired gifts not removed by a command: %d %v", expired, err)
	}
}

func TestI9_9AMID1TeaEmbedCarriesSelfWish(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	a := bornActor(t, pool)
	guildFixture(t, pool, a)
	now, err := (pg.AuthoritativeTime{Queryer: pool}).Now(ctx)
	if err != nil {
		t.Fatal(err)
	}
	day := modes.Day(now)
	exec(t, pool, `INSERT INTO guild_tea_wishes(player_id,game_day,item_id,need_num,current_num)VALUES($1,$2,40001001,3,1)`, int64(a.PlayerID), day)
	detail := map[string]any{}
	if err = (guildprojection.TeaProjection{}).OverlayMID1(ctx, pool, a, false, now, detail); err != nil {
		t.Fatal(err)
	}
	entry, ok := detail["1808"].(map[string]any)
	if !ok {
		t.Fatalf("MID1 1808 missing: %v", detail)
	}
	wish, ok := entry["self_wish_info"].(map[string]any)
	if !ok || wish["item_id"] != int64(40001001) || wish["current_num"] != int64(1) || wish["need_num"] != int64(3) {
		t.Fatalf("MID1 1808 shape %v", entry)
	}
}
