//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"errors"
	"reflect"
	"slices"
	"strconv"
	"strings"
	"sync"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/achievementstore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
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
	"gxb.local/backend/v2/internal/domain/grant"
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
		Fence: values, Functions: values, Privileges: i5.BaselinePrivilegeProvider{}, Costs: i5.MaterialCostDebiter{Store: values, Content: content}, FrameStacks: values, Mail: i5.SettlementMail{Store: values},
		Achievements: ach.Service{Store: achievementstore.Store{}, Content: content, Population: libraryService(p, p)}, Combat: fight, Heroes: fight.Inputs.Heroes, Pets: fight.Inputs.Pets, HeroPower: fight.Inputs.Stats,
		Directory: i4store.PlayerDirectoryReader{}, Guilds: guildstore.Store{}, Facts: i5.ObjectiveFacts{Owner: compositeI5(p), Open: values}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}

type blockedFrameClaimStore struct {
	i5.Store
	locked   chan struct{}
	release  <-chan struct{}
	lockOnce *sync.Once
}

func (store blockedFrameClaimStore) LockEconomyOwnerTx(ctx context.Context, transaction tx.Tx, player identity.PlayerID) error {
	if err := store.Store.LockEconomyOwnerTx(ctx, transaction, player); err != nil {
		return err
	}
	var waitErr error
	store.lockOnce.Do(func() {
		close(store.locked)
		select {
		case <-store.release:
		case <-ctx.Done():
			waitErr = ctx.Err()
		}
	})
	return waitErr
}

type observedFrameStackStore struct {
	i5.MaterialCostStore
	lockAttempted chan struct{}
	lockOnce      *sync.Once
}

func (store observedFrameStackStore) LockEconomyOwnerTx(ctx context.Context, transaction tx.Tx, player identity.PlayerID) error {
	store.lockOnce.Do(func() { close(store.lockAttempted) })
	return store.MaterialCostStore.LockEconomyOwnerTx(ctx, transaction, player)
}

type observedFrameMail struct {
	app.Mail
	lockAttempted chan struct{}
	lockOnce      *sync.Once
}

func (mail observedFrameMail) LockRecipientsTx(ctx context.Context, transaction tx.Tx, recipients []identity.PlayerID) error {
	mail.lockOnce.Do(func() { close(mail.lockAttempted) })
	return mail.Mail.LockRecipientsTx(ctx, transaction, recipients)
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
	if err = s.SaveDefense(ctx, a, []int64{refA.PartnerID}, 0, op()); err != nil {
		t.Fatal("attacker saved defense", err)
	}
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
	// The fixture offered a player directly, so record the rank snapshot an offer
	// response would have written; START compares against it.
	pvpSnapshot := topfloorstore.Store{}
	pvpTx, err := pool.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer pvpTx.Rollback(ctx)
	if err = pvpSnapshot.SaveOfferSnapshotTx(ctx, pvpTx, d.OfferSnapshot{Player: b.PlayerID, Server: server, Scope: d.OfferScopeNormal, Generation: 0,
		ChallengerRank: scalar(t, pool, `SELECT rank FROM top_floor_ranks WHERE player_id=$1`, int64(b.PlayerID)),
		Offers:         []d.Ranked{{Rank: scalar(t, pool, `SELECT rank FROM top_floor_ranks WHERE player_id=$1`, int64(a.PlayerID)), Occupant: d.Occupant{Player: a.PlayerID}}},
		UpdatedAt:      time.Now().UTC()}); err != nil {
		t.Fatal(err)
	}
	if err = pvpTx.Commit(ctx); err != nil {
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

func TestI9_10TopFloorSettlementWaitsForConcurrentFrameClaimNative(t *testing.T) {
	p := pool(t)
	defer p.Close()
	s := topFloorService(t, p)
	server := rankingServer(t, p)
	a, revision, _ := topFloorPlayer(t, p, server)
	content := contentstore.Store{Queryer: p}
	catalog, err := content.TopFloorCatalogTx(ctx, p, revision)
	if err != nil {
		t.Fatal(err)
	}
	frameReward, found := catalog.RewardFor(1)
	if !found || frameReward.FrameID <= 0 {
		t.Fatal("rank-1 frame reward missing")
	}
	if _, err := s.Load(ctx, a, op()); err != nil {
		t.Fatal(err)
	}
	exec(t, p, `UPDATE top_floor_ranks SET robot_team=CASE WHEN rank=1 THEN NULL ELSE (SELECT robot_team FROM top_floor_ranks WHERE logical_server_id=$1 AND rank=1) END, player_id=CASE WHEN rank=1 THEN $2 ELSE NULL END WHERE logical_server_id=$1 AND (rank=1 OR player_id=$2)`, int64(server), int64(a.PlayerID))
	latest := catalog.LatestCutoffDay(time.Now())
	exec(t, p, `UPDATE top_floor_ladders SET settled_day=$2,state_version=state_version+1 WHERE logical_server_id=$1`, int64(server), latest-1)

	values := i5store.Store{Queryer: p}
	transaction, err := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	frameMail, _, err := (i5.SettlementMail{Store: values}).DeliverTx(ctx, transaction, i5.SettlementMailRequest{Recipient: a.PlayerID, SourceKind: "PLAYTEST_FRAME_CLAIM", SourceKey: "top-floor-concurrent", Title: "Frame reward", Sender: "Academy", Body: "Claim the frame", PolicyVersion: "i9-10-playtest-v1", Lines: []grant.Line{{Kind: grant.StackItem, ItemID: frameReward.FrameID, Amount: 1}}, At: time.Now().UTC()})
	if err != nil {
		transaction.Rollback(ctx)
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}

	release := make(chan struct{})
	var releaseOnce sync.Once
	defer releaseOnce.Do(func() { close(release) })
	claimLocked := make(chan struct{})
	claims := genuineGrants(p)
	claims.Store = blockedFrameClaimStore{Store: claims.Store, locked: claimLocked, release: release, lockOnce: &sync.Once{}}
	claimDone := make(chan error, 1)
	go func() {
		_, claimErr := claims.ClaimMail(ctx, a, frameMail.Address, op())
		claimDone <- claimErr
	}()
	select {
	case <-claimLocked:
	case <-time.After(10 * time.Second):
		t.Fatal("frame claim did not acquire the Economy owner lock")
	}

	settlementMailLockAttempted := make(chan struct{})
	settlementLockAttempted := make(chan struct{})
	s.Mail = observedFrameMail{Mail: s.Mail, lockAttempted: settlementMailLockAttempted, lockOnce: &sync.Once{}}
	s.FrameStacks = observedFrameStackStore{MaterialCostStore: values, lockAttempted: settlementLockAttempted, lockOnce: &sync.Once{}}
	type settlementResult struct {
		settled int
		err     error
	}
	settlementDone := make(chan settlementResult, 1)
	go func() {
		settled, settlementErr := s.SettleDue(ctx, server, op())
		settlementDone <- settlementResult{settled: settled, err: settlementErr}
	}()
	select {
	case <-settlementMailLockAttempted:
	case <-time.After(10 * time.Second):
		t.Fatal("settlement did not reach the mail namespace locks")
	}
	releaseOnce.Do(func() { close(release) })
	if err = <-claimDone; err != nil {
		t.Fatal("concurrent frame claim", err)
	}
	select {
	case <-settlementLockAttempted:
	case <-time.After(10 * time.Second):
		t.Fatal("settlement did not reach the Economy owner locks")
	}
	settled := <-settlementDone
	if settled.err != nil || settled.settled != 1 {
		t.Fatalf("settlement result: %+v", settled)
	}
	if stackQuantity(t, p, a.PlayerID, frameReward.FrameID) != 1 ||
		scalar(t, p, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='TOP_FLOOR_DAILY_FRAME'`, int64(a.PlayerID)) != 0 ||
		scalar(t, p, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='TOP_FLOOR_DAILY'`, int64(a.PlayerID)) != 1 ||
		scalar(t, p, `SELECT count(*) FROM mail_attachments m JOIN mail_records r USING(mail_uuid) WHERE r.recipient_player_id=$1 AND r.source_kind='TOP_FLOOR_DAILY' AND m.resource_key='arena_coin' AND m.amount=800`, int64(a.PlayerID)) != 1 {
		t.Fatal("concurrent claim ownership or daily reward mail is incorrect")
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
	if err = s.SaveDefense(ctx, a, []int64{ref.PartnerID}, 0, op()); err != nil {
		t.Fatal("saved defense", err)
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

// A retried START while the resolver withholds the result replays the original
// admission: same attempt, one ticket, then one settlement when it resolves.
func TestI9_10TopFloorPendingStartReplayNative(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	s := topFloorService(t, pool)
	server := rankingServer(t, pool)
	a, _, ref := topFloorPlayer(t, pool, server)
	view, err := s.Load(ctx, a, op())
	if err != nil {
		t.Fatal(err)
	}
	if err = s.SaveDefense(ctx, a, []int64{ref.PartnerID}, 0, op()); err != nil {
		t.Fatal("saved defense", err)
	}
	command := app.StartCommand{Formation: []int64{ref.PartnerID}, Enemy: view.Enemies[0].Occupant.TableID()}
	stalled := s
	stalled.Combat = stalledCombat{s.Combat}
	tickets := func() int64 {
		return scalar(t, pool, `SELECT tickets_left FROM top_floor_players WHERE player_id=$1`, int64(a.PlayerID))
	}
	latest := func() d.Fight {
		fight, found, readErr := (topfloorstore.Store{}).LatestFightTx(ctx, pool, a.PlayerID)
		if readErr != nil || !found {
			t.Fatalf("latest fight found=%v err=%v", found, readErr)
		}
		return fight
	}
	first, err := stalled.Start(ctx, a, command, op())
	if err != nil || first.Report != nil {
		t.Fatalf("pending START report=%v err=%v", first.Report, err)
	}
	pending := latest()
	if pending.Status != d.StatusStarted || tickets() != 4 {
		t.Fatalf("first admission status=%s tickets=%d", pending.Status, tickets())
	}
	second, err := stalled.Start(ctx, a, command, op())
	if err != nil || second.Report != nil {
		t.Fatalf("pending retry report=%v err=%v", second.Report, err)
	}
	replayed := latest()
	if replayed.AttemptID != pending.AttemptID || replayed.Status != d.StatusStarted || tickets() != 4 {
		t.Fatalf("retry attempt=%s want=%s status=%s tickets=%d", replayed.AttemptID, pending.AttemptID, replayed.Status, tickets())
	}
	if scalar(t, pool, `SELECT count(*) FROM top_floor_fights WHERE challenger_id=$1`, int64(a.PlayerID)) != 1 {
		t.Fatal("retry admitted a second fight")
	}
	resolved, err := s.Start(ctx, a, command, op())
	if err != nil || resolved.Report == nil {
		t.Fatalf("resolved retry report=%v err=%v", resolved.Report, err)
	}
	settled := latest()
	if settled.AttemptID != pending.AttemptID || settled.Status != d.StatusSettled || tickets() != 4 {
		t.Fatalf("settled attempt=%s want=%s status=%s tickets=%d", settled.AttemptID, pending.AttemptID, settled.Status, tickets())
	}
	if scalar(t, pool, `SELECT count(*) FROM top_floor_records WHERE owner_player_id=$1`, int64(a.PlayerID)) != 1 {
		t.Fatal("retry settled a second record")
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

// taskRotationForRule selects a rotation from the pinned source schedule. The
// fixed 2027 date is a pure fixture for the in-memory binder; the host clock is
// neither read nor moved. Frozen windows and camp submode rotations are skipped.
func taskRotationForRule(t *testing.T, catalog d.Catalog, accept func(d.TaskModeRule) bool) time.Time {
	t.Helper()
	base := time.Date(2027, 1, 1, 12, 0, 0, 0, time.UTC)
	for week := int64(0); week < 520; week++ {
		candidate := base.Add(time.Duration(week) * 7 * 24 * time.Hour)
		rotation, err := catalog.TaskModes.Rotation(candidate)
		if err != nil {
			t.Fatal(err)
		}
		rule, found := catalog.TaskModes.Rule(rotation.Mode)
		if !found || rotation.Submode != 0 || catalog.Frozen(candidate) || !accept(rule) {
			continue
		}
		return candidate
	}
	t.Fatal("no matching Top Floor task rotation in the pinned source schedule")
	return time.Time{}
}

func assertNumericList(t *testing.T, row map[string]any, key string, minimum int) {
	t.Helper()
	value := reflect.ValueOf(row[key])
	if !value.IsValid() || (value.Kind() != reflect.Slice && value.Kind() != reflect.Array) || value.Len() < minimum {
		t.Fatalf("%s = %#v, want at least %d numeric entries: %+v", key, row[key], minimum, row)
	}
	for index := 0; index < value.Len(); index++ {
		switch value.Index(index).Interface().(type) {
		case int, int64, float64, json.Number:
		default:
			t.Fatalf("%s[%d] is %T, want a number", key, index, value.Index(index).Interface())
		}
	}
}

func assertList(t *testing.T, row map[string]any, key string, minimum int) {
	t.Helper()
	value := reflect.ValueOf(row[key])
	if !value.IsValid() || (value.Kind() != reflect.Slice && value.Kind() != reflect.Array) || value.Len() < minimum {
		t.Fatalf("%s = %#v, want at least %d entries: %+v", key, row[key], minimum, row)
	}
}

func assertMap(t *testing.T, row map[string]any, key string) {
	t.Helper()
	if _, ok := row[key].(map[string]any); !ok {
		t.Fatalf("%s = %#v, want an object: %+v", key, row[key], row)
	}
}

func earnTaskChallenges(t *testing.T, database *pg.Pool, service app.Service, actor identity.ActorContext, hero character.HeroRef, clock *workplaceTime) {
	t.Helper()
	store := topfloorstore.Store{}
	current, err := service.Load(ctx, actor, op())
	if err != nil {
		t.Fatal(err)
	}
	if err = service.SaveDefense(ctx, actor, []int64{hero.PartnerID}, 0, op()); err != nil {
		t.Fatal("normal defense for task-mode eligibility", err)
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
	clock := &workplaceTime{}
	service.Timed.Binder.Time = clock
	storedHero, err := (characterstore.Store{}).ReadHeroByPartnerIDTx(ctx, database, actor.PlayerID, hero.PartnerID)
	if err != nil {
		t.Fatal(err)
	}
	clock.at = taskRotationForRule(t, catalog, func(rule d.TaskModeRule) bool {
		if !rule.PetAllowed || rule.ID == d.TaskModeCamp {
			return false
		}
		return !slices.Contains(rule.BannedTables, storedHero.TableID)
	})
	rotation, err := catalog.TaskModes.Rotation(clock.at)
	if err != nil {
		t.Fatal(err)
	}
	rule, found := catalog.TaskModes.Rule(rotation.Mode)
	if !found {
		t.Fatal("selected rotation rule")
	}
	earnTaskChallenges(t, database, service, actor, hero, clock)

	pet := statPet(t, database, actor, revision)
	defense := d.TaskModeDefense{Heroes: []int64{hero.PartnerID}, Pet: pet.PetID}
	if rule.LeaderAllowed {
		defense.Leader = hero.PartnerID
	}
	if err = service.SaveTaskDefense(ctx, actor, defense, op()); err != nil {
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
	// The returned hero rows carry no qualified force, so teamForce yields exactly
	// zero; this is not a power proof (the client-side getZhandouli power is
	// proven only by the stock scenario).
	if formValue(t, ownRow, "force") != 0 {
		t.Fatalf("player force %d, want the exact unqualified 0", formValue(t, ownRow, "force"))
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
	assertNumericList(t, ownHeroes[0], "skills", 6)
	assertNumericList(t, ownHeroes[0], "equips", 6)
	assertNumericList(t, ownHeroes[0], "fumos", 6)
	assertNumericList(t, ownHeroes[0], "spirit_equip", 6)
	assertList(t, ownHeroes[0], "spirit_item", 6)
	assertMap(t, ownHeroes[0], "skin_ids")
	ownPet, ok := ownRow["pet"].(map[string]any)
	if !ok {
		t.Fatalf("player pet row %#v", ownRow["pet"])
	}
	if formValue(t, ownPet, "pet_id") != pet.PetID || formValue(t, ownPet, "table_id") != pet.TableID {
		t.Fatalf("pet identity %+v", ownPet)
	}
	if formValue(t, ownPet, "star") <= 0 || formValue(t, ownPet, "lev") <= 0 || formValue(t, ownPet, "color") <= 0 {
		t.Fatalf("pet populate fields %+v", ownPet)
	}
	assertNumericList(t, ownPet, "skills", 1)

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
		assertNumericList(t, robotHero, "skills", 6)
		assertNumericList(t, robotHero, "equips", 6)
		assertNumericList(t, robotHero, "fumos", 6)
		assertList(t, robotHero, "spirit_equip", 0)
		assertList(t, robotHero, "spirit_item", 0)
		assertMap(t, robotHero, "skin_ids")
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
}

// TestI9_10TopFloorInvalidTaskDefensePropagatesNative proves a row-level
// nonempty but formation-invalid saved defense is ErrInvalid from every read,
// not omitted like the empty-defense category, and that rank state is untouched.
func TestI9_10TopFloorInvalidTaskDefensePropagatesNative(t *testing.T) {
	database := pool(t)
	service := topFloorService(t, database)
	server := rankingServer(t, database)
	actor, revision, actorHero := topFloorPlayer(t, database, server)
	catalog, err := (contentstore.Store{Queryer: database}).TopFloorCatalogTx(ctx, database, revision)
	if err != nil {
		t.Fatal(err)
	}
	clock := &workplaceTime{}
	service.Timed.Binder.Time = clock
	clock.at = taskRotationForRule(t, catalog, func(rule d.TaskModeRule) bool { return rule.HeroSlots == 1 })
	earnTaskChallenges(t, database, service, actor, actorHero, clock)
	view, err := service.LoadTask(ctx, actor, op(), false)
	if err != nil {
		t.Fatal("load task", err)
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

	invalid, _, invalidHero := topFloorPlayer(t, database, server)
	definition := collectionResources(t, database, invalid, revision, 10001002)
	summoned, err := ownerSummoner(database).SummonNormal(ctx, invalid, definition.Template.TableID, definition.Template.FragmentItemID, definition.FragmentCount, op())
	if err != nil {
		t.Fatal("second invalid-defense hero", err)
	}
	invalidPlayer := catalog.NewPlayer(invalid.PlayerID, server, revision, d.RobotTeams+2, clock.at)
	invalidPlayer.Defense = []int64{invalidHero.PartnerID, summoned.Ref().PartnerID}
	invalidTaskPlayer := d.TaskModePlayer{Player: invalidPlayer, PeriodNumber: period.Rotation.Number}
	rule, found := catalog.TaskModes.Rule(view.Rotation.Mode)
	if !found {
		t.Fatal("rotation rule")
	}
	firstHero, err := (characterstore.Store{}).ReadHeroByPartnerIDTx(ctx, database, invalid.PlayerID, invalidHero.PartnerID)
	if err != nil {
		t.Fatal("first invalid-defense hero", err)
	}
	fixtureHeroes := []character.Hero{firstHero, summoned}
	fixtureParts := make([]int64, 0, len(fixtureHeroes))
	fixtureTables := make([]int64, 0, len(fixtureHeroes))
	for _, hero := range fixtureHeroes {
		camp, known := catalog.TaskModes.HeroCamps[hero.TableID]
		if !known || camp < 1 || camp > 4 {
			t.Fatalf("fixture hero %d has no known 1..4 source camp (camp=%d known=%v)", hero.TableID, camp, known)
		}
		if slices.Contains(rule.BannedTables, hero.TableID) {
			t.Fatalf("fixture hero %d is banned in the selected rotation", hero.TableID)
		}
		fixtureParts = append(fixtureParts, hero.PartnerID)
		fixtureTables = append(fixtureTables, hero.TableID)
	}
	if !slices.Equal(invalidPlayer.Defense, fixtureParts) {
		t.Fatalf("invalid defense %v differs from fixture %v", invalidPlayer.Defense, fixtureParts)
	}
	formation, err := catalog.TaskModes.Heroes(fixtureParts, fixtureTables)
	if err != nil {
		t.Fatal("fixture formation", err)
	}
	if rule.LeaderAllowed {
		invalidTaskPlayer.Leader = firstHero.PartnerID
	}
	widened := rule
	widened.HeroSlots = len(formation)
	if err = widened.ValidateFormation(formation, invalidPlayer.DefensePet, invalidTaskPlayer.Leader, view.Rotation.Submode); err != nil {
		t.Fatalf("fixture heroes violate a non-slot constraint: %v", err)
	}
	if len(invalidPlayer.Defense) <= rule.HeroSlots {
		t.Fatalf("invalid defense %d does not overflow rule slots %d", len(invalidPlayer.Defense), rule.HeroSlots)
	}
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
	if err = store.InsertTaskPlayerTx(ctx, transaction, invalidTaskPlayer, period); err != nil {
		t.Fatal("insert invalid-defense task player", err)
	}
	if err = store.AppendTaskPlayerTx(ctx, transaction, server, period.Rotation.Number, d.RobotTeams+2, invalid.PlayerID); err != nil {
		t.Fatal("append invalid-defense rank", err)
	}
	if err = store.SwapTaskRanksTx(ctx, transaction, server, period.Rotation.Number, d.Ranked{Rank: d.RobotTeams + 2, Occupant: d.Occupant{Player: invalid.PlayerID}}, defender[0]); err != nil {
		t.Fatal("place invalid-defense rank", err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}

	ranks := func() []d.Ranked {
		rows, readErr := store.TaskRangeTx(ctx, database, server, period.Rotation.Number, 1, 50)
		if readErr != nil {
			t.Fatal(readErr)
		}
		return rows
	}
	unchanged := func(before []d.Ranked) {
		after := ranks()
		if len(before) != len(after) {
			t.Fatalf("rank row count changed %d -> %d", len(before), len(after))
		}
		for index := range before {
			if before[index] != after[index] {
				t.Fatalf("rank row %d changed: %+v -> %+v", before[index].Rank, before[index], after[index])
			}
		}
	}

	before := ranks()
	if _, err = service.TaskFormation(ctx, actor, int64(invalid.PlayerID)); !errors.Is(err, d.ErrInvalid) {
		t.Fatalf("nonempty invalid task defense must be ErrInvalid from 295, got %v", err)
	}
	unchanged(before)
	if _, err = service.LoadTask(ctx, actor, op(), false); !errors.Is(err, d.ErrInvalid) {
		t.Fatalf("nonempty invalid task defense must be ErrInvalid from 282, got %v", err)
	}
	unchanged(before)

	transaction, err = database.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	top, err := store.TaskRangeTx(ctx, database, server, period.Rotation.Number, 1, 1)
	if err != nil || len(top) != 1 {
		t.Fatal("top rank", err, len(top))
	}
	invalidRank, _, err := store.TaskRankOfTx(ctx, database, server, period.Rotation.Number, d.Occupant{Player: invalid.PlayerID})
	if err != nil {
		t.Fatal(err)
	}
	if err = store.SwapTaskRanksTx(ctx, transaction, server, period.Rotation.Number, d.Ranked{Rank: invalidRank, Occupant: d.Occupant{Player: invalid.PlayerID}}, top[0]); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	before = ranks()
	if _, err = service.TaskRankList(ctx, actor); !errors.Is(err, d.ErrInvalid) {
		t.Fatalf("nonempty invalid task defense must be ErrInvalid from the special rank list, got %v", err)
	}
	unchanged(before)
}

// TestI9_10TopFloorFormationProjectsHeroPowerNative proves the 291/295 ranking
// popup row carries the canonical owner force the stock enemy board reads.
func TestI9_10TopFloorFormationProjectsHeroPowerNative(t *testing.T) {
	p := pool(t)
	defer p.Close()
	s := topFloorService(t, p)
	server := rankingServer(t, p)
	a, _, _ := topFloorPlayer(t, p, server)
	b, _, refB := topFloorPlayer(t, p, server)
	if _, err := s.Load(ctx, a, op()); err != nil {
		t.Fatal(err)
	}
	if _, err := s.Load(ctx, b, op()); err != nil {
		t.Fatal(err)
	}
	if err := s.SaveDefense(ctx, b, []int64{refB.PartnerID}, 0, op()); err != nil {
		t.Fatal(err)
	}
	display, err := s.Formation(ctx, a, int64(b.PlayerID), op())
	if err != nil {
		t.Fatal(err)
	}
	row := projection.Formation(display)
	heroes, ok := row["heros"].([]map[string]any)
	if !ok || len(heroes) == 0 {
		t.Fatalf("formation heroes %#v", row["heros"])
	}
	var total int64
	for _, hero := range heroes {
		force := formValue(t, hero, "force")
		if force <= 0 {
			t.Fatalf("hero force %d is not the canonical owner power", force)
		}
		total += force
	}
	if total <= 0 || formValue(t, row, "force") != total {
		t.Fatalf("team force %d != hero sum %d", formValue(t, row, "force"), total)
	}
}
