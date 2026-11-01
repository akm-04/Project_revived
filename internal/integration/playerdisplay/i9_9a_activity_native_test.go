//go:build postgres

package playerdisplay_test

import (
	"context"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/guildpolicybridge"
	"gxb.local/backend/v2/internal/adapters/guildviewread"
	guildwire "gxb.local/backend/v2/internal/adapters/guildwire"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildprojection"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/guildcore"
	"gxb.local/backend/v2/internal/application/guildtea"
	"gxb.local/backend/v2/internal/application/guildview"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	il "gxb.local/backend/v2/internal/application/illusion"
	"gxb.local/backend/v2/internal/content/guildpolicy"
	"gxb.local/backend/v2/internal/content/guildteapolicy"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/projection/lobby"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
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
	for _, member := range append([]identity.ActorContext{leader}, members...) {
		exec(t, p, `INSERT INTO guild_membership_events(player_id,guild_id,event_kind,actor_player_id,occurred_at,policy_revision)VALUES($1,$2,'JOIN',$1,$3,'native-fixture')`, int64(member.PlayerID), gid, now)
	}
	return guild.ID(gid)
}

func appendActivity(t *testing.T, p *pg.Pool, a identity.ActorContext, day, amount int64) {
	t.Helper()
	exec(t, p, `INSERT INTO player_guild_activity_days(player_id,game_day,amount)VALUES($1,$2,$3) ON CONFLICT(player_id,game_day) DO UPDATE SET amount=player_guild_activity_days.amount+excluded.amount`, int64(a.PlayerID), day, amount)
}

func guildVitality(t *testing.T, p *pg.Pool, gid guild.ID) int64 {
	t.Helper()
	return scalar(t, p, `SELECT vitality FROM guilds WHERE guild_id=$1`, int64(gid))
}

// nativeServer isolates a test logical server in the low band guild ids fit.
func nativeServer(t *testing.T, p *pg.Pool) identity.LogicalServerID {
	t.Helper()
	for server := int64(900); server < 1000; server++ {
		tag, err := p.Raw().Exec(ctx, `INSERT INTO logical_servers(logical_server_id,name,first_opened_at,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,state_version,created_at)
			SELECT $1,'I9-9A native',clock_timestamp(),true,true,true,$2,$3,1,clock_timestamp() WHERE NOT EXISTS (SELECT 1 FROM logical_servers WHERE logical_server_id=$1)`, server, server*100000+25001, (server+1)*100000-1)
		if err != nil {
			t.Fatal(err)
		}
		if tag.RowsAffected() == 1 {
			return identity.LogicalServerID(server)
		}
	}
	t.Fatal("no isolated native server")
	return 0
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

// TestI9_9AGuildActivityBoardExactRowsAndServerScope pins rank order, row
// values and logical-server scoping for LOAD_RANK_LIST type 4.
func TestI9_9AGuildActivityBoardExactRowsAndServerScope(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	server := nativeServer(t, pool)
	a, b, c := rankingActor(t, pool, server, true), rankingActor(t, pool, server, true), rankingActor(t, pool, server, true)
	first := guildFixture(t, pool, a, b)
	second := guildFixture(t, pool, c)

	otherServer := nativeServer(t, pool)
	otherLeader, _ := playerRoot(t, pool, otherServer)
	foreign := guildFixture(t, pool, otherLeader)

	now, err := (pg.AuthoritativeTime{Queryer: pool}).Now(ctx)
	if err != nil {
		t.Fatal(err)
	}
	day := modes.Day(now)
	appendActivity(t, pool, a, day, 600)
	appendActivity(t, pool, b, day, 1000)
	appendActivity(t, pool, c, day, 700)
	appendActivity(t, pool, otherLeader, day, 1000)

	store := guildstore.Store{Queryer: pool}
	view := guildview.Service{Store: store, Directory: i4store.PlayerDirectoryReader{Queryer: pool}, Day: func(context.Context) (int64, error) { return day, nil }}
	rows, mine, err := view.ActivityRankList(ctx, a, 50)
	if err != nil {
		t.Fatal(err)
	}
	if len(rows) != 2 || mine != 1 {
		t.Fatalf("board rows=%+v mine=%d", rows, mine)
	}
	if rows[0].Rank != 1 || rows[0].Guild.GuildID != int64(first) || rows[0].Guild.ThreeDay != 1600 || rows[0].Guild.MemberNum != 2 {
		t.Fatalf("first board row %+v", rows[0])
	}
	if rows[1].Rank != 2 || rows[1].Guild.GuildID != int64(second) || rows[1].Guild.ThreeDay != 700 || rows[1].Guild.MemberNum != 1 {
		t.Fatalf("second board row %+v", rows[1])
	}
	for _, row := range rows {
		if row.Guild.GuildID == int64(foreign) {
			t.Fatalf("other logical server guild %d leaked into the board", foreign)
		}
	}

	wireBody := guildwire.GuildRankList(11, rows, mine)
	rankList := wireBody["rank_list"].([]map[string]any)[0]["rank_info"].(map[string]any)
	board := rankList["rank_info"].([]map[string]any)
	if len(board) != 2 || board[0]["guild_id"] != int64(first) || board[0]["three_huoyue"] != int64(1600) || board[0]["rank"] != int64(1) ||
		board[1]["guild_id"] != int64(second) || board[1]["three_huoyue"] != int64(700) || board[1]["rank"] != int64(2) {
		t.Fatalf("board wire %v", board)
	}
	if rankList["my_rank"].(map[string]any)["rank"] != int64(1) {
		t.Fatalf("board wire my_rank %v", rankList["my_rank"])
	}
}

func guildCoreService(t *testing.T, p *pg.Pool) guildcore.Service {
	t.Helper()
	artifact, err := guildpolicy.LoadBuiltin()
	if err != nil {
		t.Fatal(err)
	}
	binding, err := guildpolicybridge.FromBuiltin(artifact)
	if err != nil {
		t.Fatal(err)
	}
	cross := appi5.CrossOwner{Store: i5store.Store{}}
	return guildcore.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}}, Store: guildstore.Store{Queryer: p},
		Fencer: i5store.Store{}, PlayerRoots: i4store.PlayerRootLocker{}, Level: cross, Scalar: cross, LevelAndScalar: cross,
		Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, Policy: binding}
}

// TestI9_9AProductionLeaveAndKickFoldVitality drives guildcore.Leave and Kick
// against the real store: the departing credit folds into the guild and the
// lifetime is halved (C5, C7).
func TestI9_9AProductionLeaveAndKickFoldVitality(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	leader, leaver, kicked := bornActor(t, pool), bornActor(t, pool), bornActor(t, pool)
	gid := guildFixture(t, pool, leader, leaver, kicked)
	now, err := (pg.AuthoritativeTime{Queryer: pool}).Now(ctx)
	if err != nil {
		t.Fatal(err)
	}
	day := modes.Day(now)
	appendActivity(t, pool, leaver, day, 600)
	appendActivity(t, pool, kicked, day, 400)
	core := guildCoreService(t, pool)

	if _, err = core.Leave(ctx, leaver, op()); err != nil {
		t.Fatalf("leave: %v", err)
	}
	if got := guildVitality(t, pool, gid); got != 20600 {
		t.Fatalf("leave folded vitality=%d", got)
	}
	activity, err := (guildstore.Store{Queryer: pool}).ReadPlayerActivity(ctx, leaver.PlayerID, day)
	if err != nil || activity.Lifetime != 300 || activity.Today != 600 {
		t.Fatalf("leave lifetime %+v %v", activity, err)
	}

	if _, err = core.Kick(ctx, leader, kicked.PlayerID, op()); err != nil {
		t.Fatalf("kick: %v", err)
	}
	if got := guildVitality(t, pool, gid); got != 21000 {
		t.Fatalf("kick folded vitality=%d", got)
	}
	activity, err = (guildstore.Store{Queryer: pool}).ReadPlayerActivity(ctx, kicked.PlayerID, day)
	if err != nil || activity.Lifetime != 200 || activity.Today != 400 {
		t.Fatalf("kick lifetime %+v %v", activity, err)
	}
}

// TestI9_9AIllusionSettlementPaysPersonalAndGuildOnce runs the real settlement
// twice: every member gets the person band and the guild owner gets the
// community band exactly once per occurrence key.
func TestI9_9AIllusionSettlementPaysPersonalAndGuildOnce(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	server := nativeServer(t, pool)
	a, partner := illusionOwner(t, pool, server)
	b, _ := illusionOwner(t, pool, server)
	gid := guildFixture(t, pool, a, b)
	clock := illusionTime(t)
	guilds := illusionGuildSource{byServer: map[int64][]il.GuildSummary{int64(server): {{ID: int64(gid), Name: "Band", Members: []identity.PlayerID{a.PlayerID, b.PlayerID}}}}}
	s := illusionService(t, pool, clock, illusionPrivileges{level: 3}, guilds)
	s.GuildActivity = guildstore.Store{Queryer: pool}
	if _, err := s.Start(ctx, a, il.StartRequest{Formation: []int64{partner}}, op()); err != nil {
		t.Fatal(err)
	}
	if _, err := s.Settle(ctx, a, il.ResultRequest{Star: 1, Damage: 1000, CostTime: 10, Formation: []int64{partner}}, op()); err != nil {
		t.Fatal(err)
	}
	clock.Set(modes.DayBegins(modes.Day(clock.at)).Add(17 * time.Hour))
	timed := mustTimed(t, op(), clock.at)
	out, err := (il.Reconciler{Service: s}).Reconcile(ctx, timed, 100)
	if err != nil || out.Settled != 1 {
		t.Fatalf("settlement %+v %v", out, err)
	}
	for _, member := range []identity.ActorContext{a, b} {
		if n := scalar(t, pool, `SELECT COALESCE(SUM(a.amount),0) FROM mail_attachments a JOIN mail_records m USING(mail_uuid) WHERE m.recipient_player_id=$1 AND a.resource_key='guild_coin'`, int64(member.PlayerID)); n != 1000 {
			t.Fatalf("community person band for %d = %d", member.PlayerID, n)
		}
	}
	store := guildstore.Store{Queryer: pool}
	if unfolded, err := store.ReadUnfoldedActivity(ctx, gid); err != nil || unfolded != 10000 {
		t.Fatalf("guild community award unfolded=%d %v", unfolded, err)
	}
	before := scalar(t, pool, `SELECT COUNT(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='ILLUSION_SETTLEMENT'`, int64(a.PlayerID))

	out, err = (il.Reconciler{Service: s}).Reconcile(ctx, timed, 100)
	if err != nil || out.Settled != 0 {
		t.Fatalf("second settlement %+v %v", out, err)
	}
	if unfolded, err := store.ReadUnfoldedActivity(ctx, gid); err != nil || unfolded != 10000 {
		t.Fatalf("award credited twice unfolded=%d %v", unfolded, err)
	}
	if after := scalar(t, pool, `SELECT COUNT(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='ILLUSION_SETTLEMENT'`, int64(a.PlayerID)); after != before {
		t.Fatalf("second settlement mailed again: %d != %d", after, before)
	}
}

type teaAuthority map[string]identity.ActorContext

func (a teaAuthority) ResolveGameplayBearer(_ context.Context, token string, _ time.Time) (identity.ActorContext, error) {
	return a[token], nil
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
		Values: owner, Costs: appi5.MaterialCostDebiter{Store: values, Content: contentstore.Store{Queryer: p}}, Facts: appi5.ObjectiveFacts{Owner: owner, Open: values},
		Fence: values, Players: i4store.PlayerRootLocker{}, Policy: guildtea.Policy{RequestsPerDay: teaPolicy.Policy.RequestsPerDay, NormalNeed: teaPolicy.Policy.NormalNeed, SXNeed: teaPolicy.Policy.SXNeed, DonorFriendMedalPerScroll: teaPolicy.Policy.DonorFriendMedalPerScroll}}
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

// TestI9_9ATeaWishDonateClaimThroughProductionDispatcher drives 1808-1811
// through GuildTeaDispatcher: refusals are 409 with an error_code body, the
// donation pays friend_medal from the content resource row, and the MID1
// projection overlays the real balance.
func TestI9_9ATeaWishDonateClaimThroughProductionDispatcher(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	revision := installed(t, pool)
	a, b, c := bornActor(t, pool), bornActor(t, pool), bornActor(t, pool)
	gid := guildFixture(t, pool, a, b)
	exec(t, pool, `INSERT INTO guild_memberships(player_id,guild_id,role,joined_at,membership_version,state_version,updated_at)VALUES($1,$2,0,clock_timestamp(),1,1,clock_timestamp())`, int64(c.PlayerID), int64(gid))
	bornHero(t, pool, b, revision, 10001001, 1)
	bornHero(t, pool, c, revision, 10001001, 1)
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

	dispatcher := stockruntime.GuildTeaDispatcher{Authority: teaAuthority{"donor": a, "receiver": b, "third": c}, Service: service}
	call := func(token string, mid uint16, params map[string]any) httpedge.Response {
		return dispatcher.Dispatch(ctx, httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{Operation: op, MID: mid, Params: params,
			Claims: wire.CredentialClaims{Token: token, Region: int64(a.LogicalServerID)}, ReceivedAt: time.Now().UTC()}})
	}
	if got := call("receiver", 1809, map[string]any{"item_id": scroll}); got.HTTPStatus != 200 {
		t.Fatalf("wish=%+v", got)
	}
	if got := call("receiver", 1809, map[string]any{"item_id": scroll}); got.HTTPStatus != 409 || got.Body["error_code"] != int64(1) {
		t.Fatalf("second wish refusal=%+v", got)
	}
	if got := call("donor", 1810, map[string]any{"player_id": int64(a.PlayerID)}); got.HTTPStatus != 409 || got.Body["error_code"] != int64(1) {
		t.Fatalf("self donation refusal=%+v", got)
	}
	if got := call("donor", 1810, map[string]any{"player_id": int64(b.PlayerID)}); got.HTTPStatus != 200 {
		t.Fatalf("donation=%+v", got)
	} else if wishes, ok := got.Body["wish_list"].([]any); !ok || len(wishes) != 1 || wishes[0].(map[string]any)["can_present_gift"] != false {
		t.Fatalf("donation body %v", got.Body)
	}
	var progress int64
	if err = pool.QueryRow(ctx, `SELECT progress FROM player_mission_instances WHERE player_id=$1 AND objective_id=90028`, int64(a.PlayerID)).Scan(&progress); err != nil || progress != 1 {
		t.Fatalf("fact 123 progress %d %v", progress, err)
	}
	if stock := scalar(t, pool, `SELECT COALESCE((SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=$2),0)`, int64(a.PlayerID), scroll); stock != 0 {
		t.Fatalf("donor shard %d", stock)
	}
	medal := scalar(t, pool, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='friend_medal'`, int64(a.PlayerID))
	if medal != 10 {
		t.Fatalf("friend medal %d", medal)
	}
	if got := call("donor", 1810, map[string]any{"player_id": int64(b.PlayerID)}); got.HTTPStatus != 409 || got.Body["error_code"] != int64(1) {
		t.Fatalf("second donation refusal=%+v", got)
	}

	// A donor with no scroll left fails the stack debit after the friend-medal
	// grant: the whole 1810 transaction must roll back.
	if got := call("third", 1809, map[string]any{"item_id": scroll}); got.HTTPStatus != 200 {
		t.Fatalf("third wish=%+v", got)
	}
	if got := call("donor", 1810, map[string]any{"player_id": int64(c.PlayerID)}); got.HTTPStatus != 409 || got.Body["error_code"] != int64(1) {
		t.Fatalf("insufficient stock refusal=%+v", got)
	}
	if again := scalar(t, pool, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='friend_medal'`, int64(a.PlayerID)); again != 10 {
		t.Fatalf("failed donation kept the grant: friend_medal=%d", again)
	}
	if gifts := scalar(t, pool, `SELECT COUNT(*) FROM guild_tea_gifts WHERE receiver_id=$1`, int64(c.PlayerID)); gifts != 0 {
		t.Fatalf("failed donation kept a gift row: %d", gifts)
	}
	if current := scalar(t, pool, `SELECT current_num FROM guild_tea_wishes WHERE player_id=$1 AND game_day=$2`, int64(c.PlayerID), day); current != 0 {
		t.Fatalf("failed donation advanced the wish: %d", current)
	}

	detail, err := lobby.BuildMID1Detail(lobby.BootstrapView{Actor: a, RegionName: "native", Now: now})
	if err != nil {
		t.Fatal(err)
	}
	projection := i5store.BootstrapProjection{Content: contentstore.Store{Queryer: pool}, Privileges: appi5.BaselinePrivilegeProvider{}, MaxHeroColor: appi5.PreservationMaxHeroColorProvider{}}
	if err = projection.OverlayMID1(ctx, pool, a, false, now, detail); err != nil {
		t.Fatal(err)
	}
	if got := detail["17"].(map[string]any)["friend_medal"]; got != int64(10) {
		t.Fatalf("MID1 friend_medal=%v", got)
	}

	claimed := call("receiver", 1811, nil)
	if claimed.HTTPStatus != 200 {
		t.Fatalf("claim=%+v", claimed)
	}
	award, ok := claimed.Body["award"].(map[string]any)
	if !ok || award["item"] != scroll || award["num"] != int64(1) {
		t.Fatalf("claim award %v", claimed.Body)
	}
	if owned := scalar(t, pool, `SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=$2`, int64(b.PlayerID), scroll); owned != 1 {
		t.Fatalf("claim stack %d", owned)
	}
	if again := call("receiver", 1811, nil); again.HTTPStatus != 200 || again.Body["award"] != nil {
		t.Fatalf("claim idempotency %+v", again)
	}

	exec(t, pool, `INSERT INTO guild_tea_wishes(player_id,game_day,item_id,need_num,current_num)VALUES($1,$2,$3,3,0) ON CONFLICT DO NOTHING`, int64(b.PlayerID), day-1, scroll)
	exec(t, pool, `INSERT INTO guild_tea_gifts(receiver_id,donor_id,game_day,item_id)VALUES($1,$2,$3,$4) ON CONFLICT DO NOTHING`, int64(b.PlayerID), int64(a.PlayerID), day-1, scroll)
	if got := call("receiver", 1808, map[string]any{"is_self": int64(1)}); got.HTTPStatus != 200 {
		t.Fatalf("info after expiry fixtures=%+v", got)
	}
	if expired := scalar(t, pool, `SELECT COUNT(*) FROM guild_tea_gifts WHERE receiver_id=$1 AND game_day=$2`, int64(b.PlayerID), day-1); expired != 1 {
		t.Fatalf("read path wrote expired gifts: %d", expired)
	}
	if expired := scalar(t, pool, `SELECT COUNT(*) FROM guild_tea_wishes WHERE player_id=$1 AND game_day=$2`, int64(b.PlayerID), day-1); expired != 1 {
		t.Fatalf("read path wrote expired wishes: %d", expired)
	}
	if got := call("receiver", 1811, nil); got.HTTPStatus != 200 {
		t.Fatalf("expiry command=%+v", got)
	}
	if expired := scalar(t, pool, `SELECT COUNT(*) FROM guild_tea_gifts WHERE receiver_id=$1 AND game_day<$2`, int64(b.PlayerID), day); expired != 0 {
		t.Fatalf("expired gifts not removed by a command: %d", expired)
	}
	if expired := scalar(t, pool, `SELECT COUNT(*) FROM guild_tea_wishes WHERE player_id=$1 AND game_day<$2`, int64(b.PlayerID), day); expired != 0 {
		t.Fatalf("expired wishes not removed by a command: %d", expired)
	}
}

// TestI9_9A616AnswersGuildlessPlayer proves the production dispatcher answers
// 616 for a player with no guild and no view dependency (C11).
func TestI9_9A616AnswersGuildlessPlayer(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	a := bornActor(t, pool)
	dispatcher := stockruntime.GuildDispatcher{Authority: teaAuthority{"guildless": a}, View: guildviewread.Reader{Runner: tx.Runner{DB: pool}}}
	got := dispatcher.Dispatch(ctx, httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{MID: 616,
		Claims: wire.CredentialClaims{Token: "guildless", Region: int64(a.LogicalServerID)}, ReceivedAt: time.Now().UTC()}})
	if got.HTTPStatus != 200 || len(got.Body) != 0 {
		t.Fatalf("616 guildless=%+v", got)
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
