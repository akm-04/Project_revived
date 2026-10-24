//go:build postgres

package playerdisplay_test

import (
	"context"
	"strconv"
	"strings"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/achievementstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/topfloorstore"
	ach "gxb.local/backend/v2/internal/application/achievement"
	"gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	app "gxb.local/backend/v2/internal/application/topfloor"
	"gxb.local/backend/v2/internal/domain/character"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func topFloorService(t *testing.T, p *pg.Pool) app.Service {
	t.Helper()
	fight := combatService(t, p)
	values, content := i5store.Store{Queryer: p}, contentstore.Store{Queryer: p}
	return app.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}}, Fresh: p, Store: topfloorstore.Store{}, Content: content,
		Fence: values, Functions: values, Privileges: i5.BaselinePrivilegeProvider{}, Costs: i5.MaterialCostDebiter{Store: values, Content: content}, Mail: i5.SettlementMail{Store: values},
		Achievements: ach.Service{Store: achievementstore.Store{}, Content: content, Population: libraryService(p, p)}, Combat: fight, Heroes: fight.Inputs.Heroes, Pets: fight.Inputs.Pets,
		Directory: i4store.PlayerDirectoryReader{}, Guilds: guildstore.Store{}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}

// topFloorPlayer is a genuine combat owner with function 4 open and an Achievement root.
func topFloorPlayer(t *testing.T, p *pg.Pool, server identity.LogicalServerID) (identity.ActorContext, string, character.HeroRef) {
	t.Helper()
	a, rev, ref := combatOwner(t, p, server)
	exec(t, p, `INSERT INTO player_function_eligibility(player_id,function_id,content_revision,source_fact_key,eligible_at)VALUES($1,4,$2,'function.lua:4:1|10',clock_timestamp()-interval '1 minute')`, int64(a.PlayerID), rev)
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	if e = (achievementstore.Store{}).InitFreshTx(ctx, tr, a.PlayerID, rev, time.Now().Add(-time.Hour)); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	return a, rev, ref
}

func scalar(t *testing.T, p *pg.Pool, sql string, args ...any) int64 {
	t.Helper()
	var n int64
	if e := p.QueryRow(ctx, sql, args...).Scan(&n); e != nil {
		t.Fatal(sql, e)
	}
	return n
}

func TestI7C5BTopFloorLadderFightSettlementNative(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	s := topFloorService(t, pool)
	server := rankingServer(t, pool)
	a, _, refA := topFloorPlayer(t, pool, server)
	b, _, refB := topFloorPlayer(t, pool, server)
	rev, err := (contentstore.Store{Queryer: pool}).ActiveRevision(ctx, pool)
	if err != nil {
		t.Fatal(err)
	}
	catalog, err := (contentstore.Store{Queryer: pool}).TopFloorCatalogTx(ctx, pool, rev)
	if err != nil {
		t.Fatal(err)
	}
	if catalog.Frozen(time.Now()) {
		t.Skip("21:00-21:30 GMT+8 settlement freeze admits no START")
	}

	// B02: the first LOAD seeds the robot ladder once and enters at the bottom.
	viewA, err := s.Load(ctx, a, op())
	if err != nil {
		t.Fatal(err)
	}
	viewB, err := s.Load(ctx, b, op())
	if err != nil {
		t.Fatal(err)
	}
	if viewA.Rank != d.RobotTeams+1 || viewB.Rank != d.RobotTeams+2 || viewA.Player.TicketsLeft != 5 || len(viewA.Enemies) != 3 {
		t.Fatalf("entry ranks %d %d enemies %d", viewA.Rank, viewB.Rank, len(viewA.Enemies))
	}
	if again, err := s.Load(ctx, a, op()); err != nil || again.Rank != viewA.Rank || scalar(t, pool, `SELECT size FROM top_floor_ladders WHERE logical_server_id=$1`, int64(server)) != d.RobotTeams+2 {
		t.Fatal("repeated LOAD must not re-enter", err)
	}
	if scalar(t, pool, `SELECT count(*) FROM top_floor_ranks WHERE logical_server_id=$1 AND robot_team=$2+1-rank`, int64(server), int64(d.RobotTeams)) != d.RobotTeams {
		t.Fatal("private policy robot seeding")
	}
	for _, e := range viewA.Enemies {
		if !e.Occupant.IsRobot() || e.Rank >= viewA.Rank || len(e.Heroes) == 0 {
			t.Fatalf("offered %+v", e)
		}
	}

	// B03: a buy needs exhausted tickets; a reset needs VIP arena_reset or a monthly card.
	if _, err = s.BuyTicket(ctx, a, op()); err == nil {
		t.Fatal("buy with tickets left accepted")
	}
	if err = s.SaveDefense(ctx, b, []int64{refB.PartnerID}, 0, op()); err != nil {
		t.Fatal(err)
	}
	if err = s.SaveDefense(ctx, a, []int64{refA.PartnerID + 999}, 0, op()); err == nil {
		t.Fatal("unowned defense hero accepted")
	}

	// B04/B05/B07/B09: START against an offered robot settles once and replays.
	enemy := viewA.Enemies[0]
	command := app.StartCommand{Formation: []int64{refA.PartnerID}, Enemy: enemy.Occupant.TableID()}
	fight, err := s.Start(ctx, a, command, op())
	if err != nil {
		t.Fatal(err)
	}
	if fight.Report == nil || len(fight.Formation) != 1 || !fight.Enemy.Occupant.IsRobot() {
		t.Fatalf("robot fight %+v", fight.Enemy)
	}
	replay, err := s.Start(ctx, a, command, op())
	if err != nil || string(replay.Report) != string(fight.Report) || replay.Win != fight.Win {
		t.Fatal("identical START must replay the recorded result", err)
	}
	rankA := scalar(t, pool, `SELECT rank FROM top_floor_ranks WHERE player_id=$1`, int64(a.PlayerID))
	wantRank := int64(d.RobotTeams + 1)
	if fight.Win {
		wantRank = enemy.Rank
	}
	if rankA != wantRank || scalar(t, pool, `SELECT tickets_left FROM top_floor_players WHERE player_id=$1`, int64(a.PlayerID)) != 4 {
		t.Fatalf("rank %d want %d or ticket drift", rankA, wantRank)
	}
	if fight.Win != (fight.AwardCrystal > 0) || fight.Win && fight.AwardCrystal != catalog.BestRankReward(d.RobotTeams+1, enemy.Rank) {
		t.Fatal("best rank reward", fight.AwardCrystal)
	}
	if fight.Win && scalar(t, pool, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='TOP_FLOOR_BEST_RANK'`, int64(a.PlayerID)) != 1 {
		t.Fatal("best rank mail")
	}
	if _, err = s.Start(ctx, a, app.StartCommand{Formation: []int64{refA.PartnerID}, Enemy: viewA.Enemies[1].Occupant.TableID()}, op()); err == nil {
		t.Fatal("cooldown must refuse the next START")
	}
	records, err := s.Records(ctx, a)
	if err != nil || len(records) != 1 || !records[0].Record.Attack || records[0].Record.Win != fight.Win {
		t.Fatal("records", err, len(records))
	}
	if report, err := s.Report(ctx, records[0].Record.AttemptID.String()); err != nil || string(report) != string(fight.Report) {
		t.Fatal("report replay", err)
	}
	if report, err := s.Report(ctx, "00000000-0000-4000-8000-000000000000"); err != nil || report != nil {
		t.Fatal("unknown report must answer out of date", err)
	}
	if scalar(t, pool, `SELECT fights FROM top_floor_partner_usage WHERE player_id=$1 AND partner_id=$2`, int64(a.PlayerID), refA.PartnerID) != 1 {
		t.Fatal("partner usage")
	}
	if history, err := s.PublicHistoryTx(ctx, pool, a.PlayerID, time.Now()); err != nil || history.Fights < 1 || len(history.Partners) != 1 || history.Partners[0].PartnerID != refA.PartnerID || history.Partners[0].Fights != 1 {
		t.Fatal("1829 ARENA history", history, err)
	}

	// B04: player vs player through the defender's saved defense (OWNED_FOREIGN).
	exec(t, pool, `UPDATE top_floor_players SET offered=$2::jsonb,state_version=state_version+1 WHERE player_id=$1`, int64(b.PlayerID), `[{"player":`+strconv.FormatInt(int64(a.PlayerID), 10)+`}]`)
	if err = s.SaveDefense(ctx, a, []int64{refA.PartnerID}, 0, op()); err != nil {
		t.Fatal(err)
	}
	before := map[identity.PlayerID]int64{a.PlayerID: scalar(t, pool, `SELECT rank FROM top_floor_ranks WHERE player_id=$1`, int64(a.PlayerID)), b.PlayerID: scalar(t, pool, `SELECT rank FROM top_floor_ranks WHERE player_id=$1`, int64(b.PlayerID))}
	pvp, err := s.Start(ctx, b, app.StartCommand{Formation: []int64{refB.PartnerID}, Enemy: int64(a.PlayerID) % d.RegionStride}, op())
	if err != nil {
		t.Fatal(err)
	}
	after := scalar(t, pool, `SELECT rank FROM top_floor_ranks WHERE player_id=$1`, int64(b.PlayerID))
	if pvp.Enemy.Occupant.Player != a.PlayerID || (pvp.Win && before[a.PlayerID] < before[b.PlayerID]) != (after == before[a.PlayerID]) {
		t.Fatalf("pvp swap win=%v before=%v after=%d", pvp.Win, before, after)
	}
	defense, err := s.Records(ctx, a)
	if err != nil || len(defense) != 2 || defense[0].Record.Attack || defense[0].Record.Win == pvp.Win {
		t.Fatal("defender record", err)
	}
	info, _, err := s.RecordInfo(ctx, a, defense[0].Record.ID)
	if err != nil || info.CanAvenge != (pvp.Win && info.AvengeType == 0) {
		t.Fatal("revenge state", err, info.CanAvenge, info.AvengeType)
	}

	// B06/B08: owed cutoffs settle from the unchanged ladder once; a top-3 streak earns tier 1.
	exec(t, pool, `UPDATE top_floor_ranks SET robot_team=CASE WHEN rank=1 THEN NULL ELSE (SELECT robot_team FROM top_floor_ranks WHERE logical_server_id=$1 AND rank=1) END, player_id=CASE WHEN rank=1 THEN $2 ELSE NULL END WHERE logical_server_id=$1 AND (rank=1 OR player_id=$2)`, int64(server), int64(a.PlayerID))
	latest := catalog.LatestCutoffDay(time.Now())
	exec(t, pool, `UPDATE top_floor_ladders SET settled_day=$2,state_version=state_version+1 WHERE logical_server_id=$1`, int64(server), latest-3)
	settled, err := s.SettleDue(ctx, server, op())
	if err != nil || settled != 3 {
		t.Fatal("settle due", settled, err)
	}
	if again, err := s.SettleDue(ctx, server, op()); err != nil || again != 0 {
		t.Fatal("settlement must be once", again, err)
	}
	if scalar(t, pool, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='TOP_FLOOR_DAILY' AND body LIKE '%rank at 1 %'`, int64(a.PlayerID)) != 3 ||
		scalar(t, pool, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='TOP_FLOOR_DAILY_FRAME'`, int64(a.PlayerID)) != 1 ||
		scalar(t, pool, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='TOP_FLOOR_DAILY'`, int64(b.PlayerID)) != 3 {
		t.Fatal("daily mails")
	}
	if scalar(t, pool, `SELECT count(*) FROM mail_attachments m JOIN mail_records r USING(mail_uuid) WHERE r.recipient_player_id=$1 AND r.source_kind='TOP_FLOOR_DAILY' AND m.resource_key='arena_coin' AND m.amount=800`, int64(a.PlayerID)) != 3 {
		t.Fatal("rank 1 arena_coin attachment")
	}
	if scalar(t, pool, `SELECT current FROM achievement_streaks WHERE player_id=$1`, int64(a.PlayerID)) != 3 || scalar(t, pool, `SELECT count(*) FROM achievement_streaks WHERE player_id=$1 AND complete_times->0 <> 'null'::jsonb AND complete_times->1 = 'null'::jsonb`, int64(a.PlayerID)) != 1 {
		t.Fatal("Challenger streak tier 1")
	}
	list, err := s.RankList(ctx, a)
	if err != nil || list.MyRank != 1 || len(list.Rows) != 50 || list.Rows[0].Occupant.Player != a.PlayerID {
		t.Fatal("rank list", err, list.MyRank)
	}
	if !strings.Contains(catalog.MailText, "%d") {
		t.Fatal("source mail text")
	}
}

// B02: concurrent first entries keep ranks contiguous and unique under the ladder root.
func TestI7C5BTopFloorConcurrentEntryNative(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	s := topFloorService(t, pool)
	server := rankingServer(t, pool)
	actors := []identity.ActorContext{}
	for range 6 {
		a, _, _ := topFloorPlayer(t, pool, server)
		actors = append(actors, a)
	}
	errs := make(chan error, len(actors))
	for _, a := range actors {
		go func() {
			_, err := s.Load(ctx, a, op())
			errs <- err
		}()
	}
	for range actors {
		if err := <-errs; err != nil {
			t.Fatal(err)
		}
	}
	size := scalar(t, pool, `SELECT size FROM top_floor_ladders WHERE logical_server_id=$1`, int64(server))
	if size != d.RobotTeams+6 || scalar(t, pool, `SELECT count(*) FROM top_floor_ranks WHERE logical_server_id=$1`, int64(server)) != size ||
		scalar(t, pool, `SELECT max(rank) FROM top_floor_ranks WHERE logical_server_id=$1`, int64(server)) != size ||
		scalar(t, pool, `SELECT count(DISTINCT player_id) FROM top_floor_ranks WHERE logical_server_id=$1 AND player_id IS NOT NULL`, int64(server)) != 6 {
		t.Fatal("ladder not contiguous", size)
	}
}

// stalledCombat withholds resolution from START, as if the client vanished.
type stalledCombat struct{ app.Combat }

func (stalledCombat) Resolve(context.Context, operation.Context, ids.UUID) (combat.Resolved, error) {
	return combat.Resolved{}, cd.ErrResolverRetryable
}

// B11: an abandoned fight is resolved and settled once by the reconcile provider.
func TestI7C5BTopFloorReconcileAbandonedNative(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	s := topFloorService(t, pool)
	server := rankingServer(t, pool)
	a, _, ref := topFloorPlayer(t, pool, server)
	view, err := s.Load(ctx, a, op())
	if err != nil {
		t.Fatal(err)
	}
	stalled := s
	stalled.Combat = stalledCombat{s.Combat}
	pending, err := stalled.Start(ctx, a, app.StartCommand{Formation: []int64{ref.PartnerID}, Enemy: view.Enemies[0].Occupant.TableID()}, op())
	if err != nil || pending.Report != nil {
		t.Fatal("pending START must return no report", err)
	}
	exec(t, pool, `UPDATE top_floor_fights SET started_at=started_at-interval '5 minutes' WHERE challenger_id=$1`, int64(a.PlayerID))
	timed, err := gen.Binder{Time: pg.AuthoritativeTime{Queryer: pool}}.Bind(ctx, op())
	if err != nil {
		t.Fatal(err)
	}
	if _, err = (app.Reconciler{Service: s}).Reconcile(ctx, timed, 50); err != nil {
		t.Fatal(err)
	}
	if scalar(t, pool, `SELECT count(*) FROM top_floor_fights WHERE challenger_id=$1 AND status='SETTLED'`, int64(a.PlayerID)) != 1 ||
		scalar(t, pool, `SELECT count(*) FROM top_floor_records WHERE owner_player_id=$1`, int64(a.PlayerID)) != 1 {
		t.Fatal("abandoned fight not settled once")
	}
	if _, err = (app.Reconciler{Service: s}).Reconcile(ctx, timed, 50); err != nil || scalar(t, pool, `SELECT count(*) FROM top_floor_records WHERE owner_player_id=$1`, int64(a.PlayerID)) != 1 {
		t.Fatal("repeat reconcile", err)
	}
}
