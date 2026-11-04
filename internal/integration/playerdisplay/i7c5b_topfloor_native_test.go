//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"errors"
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
	projection "gxb.local/backend/v2/internal/projection/topfloor"
)

func topFloorService(t *testing.T, p *pg.Pool) app.Service {
	t.Helper()
	fight := combatService(t, p)
	values, content := i5store.Store{Queryer: p}, contentstore.Store{Queryer: p}
	return app.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}}, Fresh: p, Store: topfloorstore.Store{}, Content: content,
		Fence: values, Functions: values, Privileges: i5.BaselinePrivilegeProvider{}, Costs: i5.MaterialCostDebiter{Store: values, Content: content}, Mail: i5.SettlementMail{Store: values},
		Achievements: ach.Service{Store: achievementstore.Store{}, Content: content, Population: libraryService(p, p)}, Combat: fight, Heroes: fight.Inputs.Heroes, Pets: fight.Inputs.Pets,
		Directory: i4store.PlayerDirectoryReader{}, Guilds: guildstore.Store{}, Facts: i5.ObjectiveFacts{Owner: compositeI5(p), Open: values}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
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

func formValue(t *testing.T, row map[string]any, key string) int64 {
	t.Helper()
	switch value := row[key].(type) {
	case int64:
		return value
	case int:
		return int64(value)
	case float64:
		return int64(value)
	case json.Number:
		number, err := value.Int64()
		if err != nil {
			t.Fatal(key, err)
		}
		return number
	case string:
		number, err := strconv.ParseInt(value, 10, 64)
		if err != nil {
			t.Fatal(key, err)
		}
		return number
	default:
		t.Fatalf("%s is %T, want a number", key, row[key])
		return 0
	}
}

func petTaskRotation(t *testing.T, catalog d.Catalog, at time.Time) time.Time {
	t.Helper()
	base := at.UTC().Truncate(24 * time.Hour).Add(12 * time.Hour)
	for week := int64(0); week < 60; week++ {
		candidate := base.Add(time.Duration(week) * 7 * 24 * time.Hour)
		rotation, err := catalog.TaskModes.Rotation(candidate)
		if err != nil {
			t.Fatal(err)
		}
		if rotation.Mode != d.TaskModeBanned || catalog.Frozen(candidate) {
			continue
		}
		return candidate
	}
	t.Fatal("no pet-allowed Top Floor task rotation within 60 weeks")
	return time.Time{}
}

func earnTaskChallenges(t *testing.T, database *pg.Pool, service app.Service, actor identity.ActorContext, hero character.HeroRef, clock *workplaceTime) {
	t.Helper()
	store := topfloorstore.Store{}
	current, err := service.Load(ctx, actor, op())
	if err != nil {
		t.Fatal(err)
	}
	transaction, err := database.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	if err = store.SwapTx(ctx, transaction, actor.LogicalServerID, d.Ranked{Rank: current.Rank, Occupant: d.Occupant{Player: actor.PlayerID}}, d.Ranked{Rank: 200, Occupant: d.Occupant{Robot: d.RobotTeams + 1 - 200}}); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	for challenge := 0; challenge < 10; challenge++ {
		exec(t, database, `UPDATE top_floor_players SET tickets_left=5 WHERE player_id=$1`, int64(actor.PlayerID))
		current, err = service.Load(ctx, actor, op())
		if err != nil {
			t.Fatal(err)
		}
		if len(current.Enemies) == 0 {
			t.Fatal("no normal challenge opponent")
		}
		if _, err = service.Start(ctx, actor, app.StartCommand{Formation: []int64{hero.PartnerID}, Enemy: current.Enemies[0].Occupant.TableID()}, op()); err != nil {
			t.Fatalf("challenge %d: %v", challenge, err)
		}
		clock.at = clock.at.Add(301 * time.Second)
	}
}

// TestI9_10TopFloorTaskPopupAndEmptyDefenseNative exercises the stock 291/295
// field paths through the production service and projection, and classifies a
// found task player with an empty saved defense as a business refusal.
func TestI9_10TopFloorTaskPopupAndEmptyDefenseNative(t *testing.T) {
	database := pool(t)
	service := topFloorService(t, database)
	server := rankingServer(t, database)
	actor, revision, hero := topFloorPlayer(t, database, server)
	catalog, err := (contentstore.Store{Queryer: database}).TopFloorCatalogTx(ctx, database, revision)
	if err != nil {
		t.Fatal(err)
	}
	clock := &workplaceTime{at: time.Now().UTC()}
	service.Timed.Binder.Time = clock
	clock.at = petTaskRotation(t, catalog, clock.at)
	earnTaskChallenges(t, database, service, actor, hero, clock)

	pet := statPet(t, database, actor, revision)
	if err = service.SaveTaskDefense(ctx, actor, d.TaskModeDefense{Heroes: []int64{hero.PartnerID}, Pet: pet.PetID}, op()); err != nil {
		t.Fatal("save task defense", err)
	}
	view, err := service.LoadTask(ctx, actor, op(), false)
	if err != nil {
		t.Fatal("load task", err)
	}
	if len(view.Enemies) != 3 {
		t.Fatalf("load task offers %d", len(view.Enemies))
	}

	store := topfloorstore.Store{}
	period, found, err := store.ReadTaskPeriodTx(ctx, database, server, view.Rotation.Number, false)
	if err != nil || !found {
		t.Fatal("task period", err, found)
	}
	self, found, err := store.ReadTaskPlayerTx(ctx, database, actor.PlayerID, period, false)
	if err != nil || !found {
		t.Fatal("task player", err, found)
	}
	selfRank, found, err := store.TaskRankOfTx(ctx, database, server, period.Rotation.Number, d.Occupant{Player: actor.PlayerID})
	if err != nil || !found {
		t.Fatal("task rank", err, found)
	}

	own, err := service.TaskFormation(ctx, actor, int64(actor.PlayerID))
	if err != nil {
		t.Fatal("295 player formation", err)
	}
	ownRow := projection.Formation(own)
	if ownRow["is_robot"] != false {
		t.Fatalf("player row is_robot = %#v, want the boolean false", ownRow["is_robot"])
	}
	if own.Occupant.Player != actor.PlayerID || own.Rank != selfRank || own.Wins != self.Player.Wins {
		t.Fatalf("player identity/rank/wins %+v rank=%d wins=%d", own.Occupant, own.Rank, own.Wins)
	}
	if formValue(t, ownRow, "table_id") != int64(actor.PlayerID)%d.RegionStride || formValue(t, ownRow, "rank") != selfRank || formValue(t, ownRow, "win") != self.Player.Wins {
		t.Fatalf("player projection %+v", ownRow)
	}
	if formValue(t, ownRow, "force") != own.Force {
		t.Fatalf("player force %d want %d", formValue(t, ownRow, "force"), own.Force)
	}
	ownHeroes, ok := ownRow["heros"].([]map[string]any)
	if !ok || len(ownHeroes) != 1 {
		t.Fatalf("player heroes %#v", ownRow["heros"])
	}
	if formValue(t, ownHeroes[0], "partner_id") != hero.PartnerID || formValue(t, ownHeroes[0], "lev") <= 0 || formValue(t, ownHeroes[0], "star") <= 0 || formValue(t, ownHeroes[0], "color") <= 0 {
		t.Fatalf("player hero populate fields %+v", ownHeroes[0])
	}
	if _, known := catalog.TaskModes.HeroCamps[formValue(t, ownHeroes[0], "table_id")]; !known {
		t.Fatalf("player hero table %d has no Hero.populate table", formValue(t, ownHeroes[0], "table_id"))
	}
	for _, key := range []string{"skills", "equips", "fumos", "skin_ids", "spirit_equip", "spirit_item"} {
		if _, present := ownHeroes[0][key]; !present {
			t.Fatalf("player hero row missing %s: %+v", key, ownHeroes[0])
		}
	}
	ownPet, ok := ownRow["pet"].(map[string]any)
	if !ok {
		t.Fatalf("player pet row %#v", ownRow["pet"])
	}
	if formValue(t, ownPet, "pet_id") != pet.PetID || formValue(t, ownPet, "table_id") != pet.TableID {
		t.Fatalf("pet identity %+v", ownPet)
	}
	for _, key := range []string{"star", "lev", "color", "skills"} {
		if _, present := ownPet[key]; !present {
			t.Fatalf("pet row missing %s: %+v", key, ownPet)
		}
	}

	robotRows, err := store.TaskRangeTx(ctx, database, server, period.Rotation.Number, 5, 5)
	if err != nil || len(robotRows) != 1 || !robotRows[0].Occupant.IsRobot() {
		t.Fatal("robot rank fixture", err, len(robotRows))
	}
	robotDisplay, err := service.TaskFormation(ctx, actor, int64(server)*d.RegionStride+robotRows[0].Occupant.Robot)
	if err != nil {
		t.Fatal("295 robot formation", err)
	}
	robotRow := projection.Formation(robotDisplay)
	if robotRow["is_robot"] != true {
		t.Fatalf("robot row is_robot = %#v, want the boolean true", robotRow["is_robot"])
	}
	robotHeroes, ok := robotRow["heros"].([]map[string]any)
	if !ok || len(robotHeroes) == 0 {
		t.Fatalf("robot heroes %#v", robotRow["heros"])
	}
	for _, robotHero := range robotHeroes {
		partner := formValue(t, robotHero, "partner_id")
		if partner <= 0 || formValue(t, robotHero, "table_id") != partner {
			t.Fatalf("robot hero template ids %+v", robotHero)
		}
		if _, known := catalog.TaskModes.HeroCamps[partner]; !known {
			t.Fatalf("robot template %d has no Hero.populate table", partner)
		}
		if formValue(t, robotHero, "lev") <= 0 || formValue(t, robotHero, "star") <= 0 || formValue(t, robotHero, "color") <= 0 {
			t.Fatalf("robot hero populate fields %+v", robotHero)
		}
		for _, key := range []string{"skills", "equips", "fumos", "skin_ids", "spirit_equip", "spirit_item"} {
			if _, present := robotHero[key]; !present {
				t.Fatalf("robot hero row missing %s: %+v", key, robotHero)
			}
		}
	}
	if _, present := robotRow["pet"]; present {
		t.Fatal("robot formation must not carry a pet")
	}

	// A second occupant with no saved defense sits at the first probe of the
	// challenger's best band, so 282 and the special rank list must omit it.
	other, _, _ := topFloorPlayer(t, database, server)
	otherPlayer := catalog.NewPlayer(other.PlayerID, server, revision, d.RobotTeams+2, clock.at)
	probes := catalog.OfferRanks(server, actor.PlayerID, selfRank, self.Player.TicketDay, self.Player.RefreshCount)
	if len(probes) == 0 || len(probes[0]) == 0 {
		t.Fatal("no offer probe")
	}
	target := probes[0][0]
	defender, err := store.TaskRangeTx(ctx, database, server, period.Rotation.Number, target, target)
	if err != nil || len(defender) != 1 {
		t.Fatal("target rank", err, len(defender))
	}
	transaction, err := database.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	if err = store.InsertTaskPlayerTx(ctx, transaction, d.TaskModePlayer{Player: otherPlayer, PeriodNumber: period.Rotation.Number}, period); err != nil {
		t.Fatal("insert undefended task player", err)
	}
	if err = store.AppendTaskPlayerTx(ctx, transaction, server, period.Rotation.Number, d.RobotTeams+2, other.PlayerID); err != nil {
		t.Fatal("append undefended rank", err)
	}
	if err = store.SwapTaskRanksTx(ctx, transaction, server, period.Rotation.Number, d.Ranked{Rank: d.RobotTeams + 2, Occupant: d.Occupant{Player: other.PlayerID}}, defender[0]); err != nil {
		t.Fatal("place undefended rank", err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}

	if _, err = service.TaskFormation(ctx, actor, int64(other.PlayerID)); !errors.Is(err, d.ErrRefused) {
		t.Fatalf("empty saved defense must be a business refusal, got %v", err)
	}
	offers, err := service.LoadTask(ctx, actor, op(), false)
	if err != nil {
		t.Fatalf("282 must skip an empty-defense occupant in a probed band: %v", err)
	}
	if len(offers.Enemies) != 3 {
		t.Fatalf("load task offers %d after skip", len(offers.Enemies))
	}
	for _, enemy := range offers.Enemies {
		if enemy.Occupant.Player == other.PlayerID {
			t.Fatal("empty-defense occupant was offered")
		}
	}
	if rank, _, err := store.TaskRankOfTx(ctx, database, server, period.Rotation.Number, d.Occupant{Player: other.PlayerID}); err != nil || rank != target {
		t.Fatalf("undefended rank row changed to %d/%v", rank, err)
	}

	transaction, err = database.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	top, err := store.TaskRangeTx(ctx, database, server, period.Rotation.Number, 1, 1)
	if err != nil || len(top) != 1 {
		t.Fatal("top rank", err, len(top))
	}
	otherRank, _, err := store.TaskRankOfTx(ctx, database, server, period.Rotation.Number, d.Occupant{Player: other.PlayerID})
	if err != nil {
		t.Fatal(err)
	}
	if err = store.SwapTaskRanksTx(ctx, transaction, server, period.Rotation.Number, d.Ranked{Rank: otherRank, Occupant: d.Occupant{Player: other.PlayerID}}, top[0]); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	before, err := store.TaskRangeTx(ctx, database, server, period.Rotation.Number, 1, 50)
	if err != nil {
		t.Fatal(err)
	}
	list, err := service.TaskRankList(ctx, actor)
	if err != nil {
		t.Fatalf("special rank list must skip an empty-defense row: %v", err)
	}
	for _, row := range list.Rows {
		if row.Occupant.Player == other.PlayerID {
			t.Fatal("empty-defense occupant leaked into the special rank list")
		}
	}
	if len(list.Rows) != len(before)-1 {
		t.Fatalf("special rank list rows %d want %d", len(list.Rows), len(before)-1)
	}
	after, err := store.TaskRangeTx(ctx, database, server, period.Rotation.Number, 1, 50)
	if err != nil || len(after) != len(before) {
		t.Fatal("rank rows changed", err, len(after))
	}
	for index := range before {
		if before[index].Rank != after[index].Rank || before[index].Occupant != after[index].Occupant {
			t.Fatalf("rank row %d changed: %+v -> %+v", before[index].Rank, before[index].Occupant, after[index].Occupant)
		}
	}

	contentErrorRevision := strings.Repeat("a", 64)
	exec(t, database, `DELETE FROM gxb_content_revisions WHERE revision_id=$1`, contentErrorRevision)
	exec(t, database, `INSERT INTO gxb_content_revisions(revision_id,content_sha256,schema_version,compiler_version,parser_version,manifest) SELECT $2,decode($2,'hex'),schema_version,$3,parser_version,jsonb_set(jsonb_set(manifest,'{revision_id}',to_jsonb($2::text)),'{compiler_version}',to_jsonb($3::text)) FROM gxb_content_revisions WHERE revision_id=$1`, revision, contentErrorRevision, "i9-10-content-error-fixture")
	exec(t, database, `UPDATE top_floor_task_periods SET content_revision=$3 WHERE logical_server_id=$1 AND period_number=$2`, int64(server), period.Rotation.Number, contentErrorRevision)
	if _, err = service.TaskRankList(ctx, actor); err == nil {
		t.Fatal("genuine content/provider error must propagate")
	}
	exec(t, database, `UPDATE top_floor_task_periods SET content_revision=$3 WHERE logical_server_id=$1 AND period_number=$2`, int64(server), period.Rotation.Number, revision)
	exec(t, database, `DELETE FROM gxb_content_revisions WHERE revision_id=$1`, contentErrorRevision)
}
