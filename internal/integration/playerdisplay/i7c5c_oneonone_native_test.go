//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"slices"
	"strconv"
	"strings"
	"sync"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/achievementstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/oneononestore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	ach "gxb.local/backend/v2/internal/application/achievement"
	"gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	app "gxb.local/backend/v2/internal/application/oneonone"
	appdisplay "gxb.local/backend/v2/internal/application/playerdisplay"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/domain/mail"
	d "gxb.local/backend/v2/internal/domain/oneonone"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

func oneOnOneService(t *testing.T, p *pg.Pool) app.Service {
	t.Helper()
	fight := combatService(t, p)
	values, content := i5store.Store{Queryer: p}, contentstore.Store{Queryer: p}
	return app.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}}, Fresh: p, Store: oneononestore.Store{}, Content: content,
		Fence: values, Privileges: i5.BaselinePrivilegeProvider{}, Costs: i5.MaterialCostDebiter{Store: values, Content: content}, FrameStacks: values, Mail: i5.SettlementMail{Store: values},
		Achievements: ach.Service{Store: achievementstore.Store{}, Content: content, Population: libraryService(p, p)}, Combat: fight, Heroes: fight.Inputs.Heroes, Pets: fight.Inputs.Pets,
		Directory: i4store.PlayerDirectoryReader{}, Entitlements: values, Facts: i5.ObjectiveFacts{Owner: compositeI5(p), Open: values}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}

// oneOnOnePlayer is a genuine combat owner with level 60, 15 owned girls and an Achievement root.
func oneOnOnePlayer(t *testing.T, p *pg.Pool, server identity.LogicalServerID) (identity.ActorContext, []int64) {
	t.Helper()
	a, rev, ref := combatOwner(t, p, server)
	heroes := []int64{ref.PartnerID}
	s := ownerSummoner(p)
	// Distinct origin templates: an owner holds each template origin once.
	for table := int64(10001002); len(heroes) < 15; table++ {
		def := collectionResources(t, p, a, rev, table)
		h, err := s.SummonNormal(ctx, a, def.Template.TableID, def.Template.FragmentItemID, def.FragmentCount, op())
		if err != nil {
			t.Fatal(err)
		}
		heroes = append(heroes, h.Ref().PartnerID)
	}
	exec(t, p, `UPDATE player_directory_profiles SET lev=60 WHERE player_id=$1`, int64(a.PlayerID))
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
	return a, heroes
}

func oneOnOneCatalog(t *testing.T, p *pg.Pool) d.Catalog {
	t.Helper()
	content := contentstore.Store{Queryer: p}
	rev, err := content.ActiveRevision(ctx, p)
	if err != nil {
		t.Fatal(err)
	}
	catalog, err := content.OneOnOneCatalogTx(ctx, p, rev)
	if err != nil {
		t.Fatal(err)
	}
	return catalog
}

type oneOnOneFrameOnlyContent struct {
	contentstore.Store
}

func (content oneOnOneFrameOnlyContent) OneOnOneCatalogTx(requestContext context.Context, databaseQuery tx.Queryer, revision string) (d.Catalog, error) {
	catalog, catalogError := content.Store.OneOnOneCatalogTx(requestContext, databaseQuery, revision)
	if catalogError != nil {
		return d.Catalog{}, catalogError
	}
	catalog.Rewards = append([]d.Reward(nil), catalog.Rewards...)
	for index := range catalog.Rewards {
		catalog.Rewards[index].Crystal = 0
		catalog.Rewards[index].Mana = 0
		catalog.Rewards[index].TopCoin = 0
		catalog.Rewards[index].Items = nil
	}
	return catalog, nil
}

func teamsOf(heroes []int64, n int) []d.Team {
	out := []d.Team{}
	for i := range n {
		out = append(out, d.Team{Heroes: []int64{heroes[i]}})
	}
	return out
}

func teamsOfFive(heroes []int64, n int) []d.Team {
	out := []d.Team{}
	for i := range n {
		out = append(out, d.Team{Heroes: heroes[i*5 : i*5+5]})
	}
	return out
}

// pinOneOnOneOffer overwrites the issued MATCH list with one deterministic
// target and the ranks the production MATCH path would have recorded.
func pinOneOnOneOffer(t *testing.T, p *pg.Pool, actor identity.ActorContext, enemy identity.PlayerID) {
	t.Helper()
	standings, err := (oneononestore.Store{}).StandingsTx(ctx, p)
	if err != nil {
		t.Fatal(err)
	}
	catalog := oneOnOneCatalog(t, p)
	snapshot := catalog.OfferSnapshot(catalog.Rank(standings), actor.PlayerID, []identity.PlayerID{enemy})
	if snapshot == nil {
		t.Fatalf("player %d is not in the standings", actor.PlayerID)
	}
	raw, err := json.Marshal(snapshot)
	if err != nil {
		t.Fatal(err)
	}
	exec(t, p, `UPDATE one_on_one_players SET offered=$2::jsonb,offer_snapshot=$3::jsonb,state_version=state_version+1 WHERE player_id=$1`,
		int64(actor.PlayerID), "["+strconv.FormatInt(int64(enemy), 10)+"]", string(raw))
}

// inOneOnOneBand reports whether target sits in a band an offer for self draws
// from now, the weaker condition offered before D488 parity.
func inOneOnOneBand(t *testing.T, p *pg.Pool, self, target identity.PlayerID) bool {
	t.Helper()
	standings, err := (oneononestore.Store{}).StandingsTx(ctx, p)
	if err != nil {
		t.Fatal(err)
	}
	catalog := oneOnOneCatalog(t, p)
	ranked := catalog.Rank(standings)
	me, ok := d.Find(ranked, self)
	if !ok {
		t.Fatalf("player %d is not in the standings", self)
	}
	other, ok := d.Find(ranked, target)
	if !ok {
		t.Fatalf("player %d is not in the standings", target)
	}
	for _, band := range catalog.Bands(me.InGroup, me.Global) {
		if other.InGroup >= band[0] && other.InGroup <= band[1] {
			return true
		}
	}
	return false
}

// startSettled repeats an identical START while its rounds are still resolving, as the stock client's retry does.
func startSettled(s app.Service, a identity.ActorContext, command app.StartCommand) (d.MatchView, error) {
	for {
		m, err := s.Start(ctx, a, command, op())
		if !errors.Is(err, app.ErrUnresolved) {
			return m, err
		}
	}
}

func TestI9_10OneOnOneSettlementWaitsForConcurrentFrameClaimNative(t *testing.T) {
	databasePool := pool(t)
	defer databasePool.Close()
	service := oneOnOneService(t, databasePool)
	logicalServer := rankingServer(t, databasePool)
	actor, _ := oneOnOnePlayer(t, databasePool, logicalServer)
	catalog := oneOnOneCatalog(t, databasePool)
	frameReward, found := catalog.RewardFor(1)
	if !found || frameReward.FrameID <= 0 {
		t.Fatal("rank-1 frame reward missing")
	}
	if _, loadError := service.Load(ctx, actor, op()); loadError != nil {
		t.Fatal(loadError)
	}
	exec(t, databasePool, `UPDATE one_on_one_players SET level=5,slot=NULL,state_version=state_version+1 WHERE slot=1 AND player_id<>$1`, int64(actor.PlayerID))
	exec(t, databasePool, `UPDATE one_on_one_players SET level=1,slot=1,state_version=state_version+1 WHERE player_id=$1`, int64(actor.PlayerID))

	values := i5store.Store{Queryer: databasePool}
	transaction, beginError := databasePool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if beginError != nil {
		t.Fatal(beginError)
	}
	frameMail, _, deliveryError := (i5.SettlementMail{Store: values}).DeliverTx(ctx, transaction, i5.SettlementMailRequest{Recipient: actor.PlayerID, SourceKind: "PLAYTEST_FRAME_CLAIM", SourceKey: "one-on-one-concurrent", Title: "Frame reward", Sender: "Academy", Body: "Claim the frame", PolicyVersion: "i9-10-playtest-v1", Lines: []grant.Line{{Kind: grant.StackItem, ItemID: frameReward.FrameID, Amount: 1}}, At: time.Now().UTC()})
	if deliveryError != nil {
		transaction.Rollback(ctx)
		t.Fatal(deliveryError)
	}
	if commitError := transaction.Commit(ctx); commitError != nil {
		t.Fatal(commitError)
	}

	latest := catalog.LatestSettlement(time.Now())
	exec(t, databasePool, `DELETE FROM one_on_one_settlement_ranks WHERE day>$1`, latest-8)
	exec(t, databasePool, `DELETE FROM one_on_one_settlements WHERE day>$1`, latest-8)
	exec(t, databasePool, `UPDATE one_on_one_competitions SET settled_through=$1,state_version=state_version+1`, latest-8)
	service.Content = oneOnOneFrameOnlyContent{Store: contentstore.Store{Queryer: databasePool}}

	release := make(chan struct{})
	var releaseOnce sync.Once
	defer releaseOnce.Do(func() { close(release) })
	claimLocked := make(chan struct{})
	claims := genuineGrants(databasePool)
	claims.Store = blockedFrameClaimStore{Store: claims.Store, locked: claimLocked, release: release, lockOnce: &sync.Once{}}
	claimDone := make(chan error, 1)
	go func() {
		_, claimError := claims.ClaimMail(ctx, actor, frameMail.Address, op())
		claimDone <- claimError
	}()
	select {
	case <-claimLocked:
	case <-time.After(10 * time.Second):
		t.Fatal("frame claim did not acquire the Economy owner lock")
	}

	settlementMailLockAttempted := make(chan struct{})
	settlementLockAttempted := make(chan struct{})
	service.Mail = observedFrameMail{Mail: service.Mail, lockAttempted: settlementMailLockAttempted, lockOnce: &sync.Once{}}
	service.FrameStacks = observedFrameStackStore{MaterialCostStore: values, lockAttempted: settlementLockAttempted, lockOnce: &sync.Once{}}
	type settlementResult struct {
		applied int
		failure error
	}
	settlementDone := make(chan settlementResult, 1)
	go func() {
		applied, settlementError := service.Due(ctx, op())
		settlementDone <- settlementResult{applied: applied, failure: settlementError}
	}()
	select {
	case <-settlementMailLockAttempted:
	case <-time.After(10 * time.Second):
		t.Fatal("settlement did not reach the mail namespace locks")
	}
	releaseOnce.Do(func() { close(release) })
	if claimError := <-claimDone; claimError != nil {
		t.Fatal("concurrent frame claim", claimError)
	}
	select {
	case <-settlementLockAttempted:
	case <-time.After(10 * time.Second):
		t.Fatal("settlement did not reach the Economy owner locks")
	}
	settled := <-settlementDone
	if settled.failure != nil || settled.applied < 1 {
		t.Fatalf("settlement result: %+v", settled)
	}
	if stackQuantity(t, databasePool, actor.PlayerID, frameReward.FrameID) != 1 ||
		scalar(t, databasePool, `SELECT count(*) FROM one_on_one_settlement_ranks WHERE player_id=$1 AND day>$2`, int64(actor.PlayerID), latest-8) == 0 ||
		scalar(t, databasePool, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='ONE_ON_ONE_FRAME'`, int64(actor.PlayerID)) != 0 ||
		scalar(t, databasePool, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='ONE_ON_ONE_REWARD'`, int64(actor.PlayerID)) != 0 {
		t.Fatal("settlement did not observe the claimed frame or emitted an empty reward mail")
	}
}

func TestI7C5COneOnOneEntryMatchSettlementNative(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	s := oneOnOneService(t, pool)
	facts := countPVPFights(s.Facts.(i5.ObjectiveFacts))
	s.Facts = facts
	a, heroesA := oneOnOnePlayer(t, pool, rankingServer(t, pool))
	b, heroesB := oneOnOnePlayer(t, pool, rankingServer(t, pool))
	catalog := oneOnOneCatalog(t, pool)

	// C02: the gate needs level 55 and 15 girls; entry is Junior 3 with 4300 points.
	low, _, _ := combatOwner(t, pool, a.LogicalServerID)
	if _, err := s.Load(ctx, low, op()); err == nil {
		t.Fatal("a player below level 55 with one girl entered")
	}
	viewA, err := s.Load(ctx, a, op())
	if err != nil {
		t.Fatal(err)
	}
	viewB, err := s.Load(ctx, b, op())
	if err != nil {
		t.Fatal(err)
	}
	if viewA.Player.Level != d.LevelJunior3 || viewA.Player.Points != 4300 || viewA.Player.TriesLeft != 10 || viewA.Ranked.Global <= 5000 || viewA.Ranked.ServerRank != 1 || viewB.Ranked.ServerRank != 1 {
		t.Fatalf("entry %+v %+v", viewA.Ranked, viewB.Ranked)
	}
	if again, err := s.Load(ctx, a, op()); err != nil || again.Player.StateVersion != viewA.Player.StateVersion || scalar(t, pool, `SELECT count(*) FROM one_on_one_competitions`) != 1 {
		t.Fatal("repeated LOAD must not re-enter", err)
	}

	// C03: exact team count, owned and distinct members.
	if err = s.ChangeTeams(ctx, a, teamsOf(heroesA, 2), op()); err == nil {
		t.Fatal("two teams accepted for Junior")
	}
	if err = s.ChangeTeams(ctx, a, []d.Team{{Heroes: []int64{heroesA[0]}}, {Heroes: []int64{heroesA[0]}}, {Heroes: []int64{heroesA[1]}}}, op()); err == nil {
		t.Fatal("a hero in two teams accepted")
	}
	if err = s.ChangeTeams(ctx, a, []d.Team{{Heroes: []int64{slices.Max(heroesA) + 1000}}, {Heroes: []int64{heroesA[1]}}, {Heroes: []int64{heroesA[2]}}}, op()); err == nil {
		t.Fatal("an unowned hero accepted")
	}
	for _, x := range []struct {
		a      identity.ActorContext
		heroes []int64
	}{{a, heroesA}, {b, heroesB}} {
		if err = s.ChangeTeams(ctx, x.a, teamsOf(x.heroes, 3), op()); err != nil {
			t.Fatal(err)
		}
	}
	exec(t, pool, `UPDATE one_on_one_players SET points=4500,state_version=state_version+1 WHERE player_id=$1`, int64(b.PlayerID))

	// C04: candidates are better members of the same group with a defense, across servers.
	pointsOf := func(pid identity.PlayerID) int64 {
		return scalar(t, pool, `SELECT points FROM one_on_one_players WHERE player_id=$1`, int64(pid))
	}
	for _, x := range []identity.ActorContext{a, b} {
		offered, err := s.Match(ctx, x, op())
		if err != nil {
			t.Fatal(err)
		}
		for _, o := range offered {
			if o.Ranked.Level < d.LevelJunior1 || o.Ranked.Points < pointsOf(x.PlayerID) || o.Face.Player == x.PlayerID {
				t.Fatal("candidates are better members of the same group", o.Ranked)
			}
		}
	}
	// The fixture pins B as A's offered opponent; the competition may already hold other Juniors (restored databases).
	pinOneOnOneOffer(t, pool, a, b.PlayerID)
	enemy, err := s.EnemyTeam(ctx, b.PlayerID)
	if err != nil || len(enemy) != 3 || len(enemy[0].Heroes) != 1 {
		t.Fatal("GET_ENEMY_TEAM", err, len(enemy))
	}
	if !catalog.Open(time.Now()) {
		t.Skip("1 on 1 START is closed outside 08:00-22:00 GMT+8")
	}

	// C05/C06/C11: a best-of-three match settles once, moves Elo points and records both sides.
	command := app.StartCommand{Formations: teamsOf(heroesA, 3), Enemy: b.PlayerID}
	if _, err = s.Start(ctx, a, app.StartCommand{Formations: teamsOf(heroesA, 2), Enemy: b.PlayerID}, op()); err == nil {
		t.Fatal("two formations accepted against three defense teams")
	}
	started := time.Now()
	result, err := startSettled(s, a, command)
	if err != nil {
		t.Fatal(err)
	}
	t.Logf("best-of-three START with resolution and settlement took %s (rounds %v)", time.Since(started), result.Wins)
	if len(result.Wins) < 2 || len(result.Wins) > 3 || len(result.ReportKeys) != len(result.Wins) || result.Arena.Player.TriesLeft != 9 {
		t.Fatalf("match %+v", result)
	}
	if facts.of(a.PlayerID) != 1 {
		t.Fatal("a settled 1on1 match is one PVP_FIGHT fact", facts.of(a.PlayerID))
	}
	gain := catalog.Gain(4300, 4500)
	if !result.Win {
		gain = -catalog.Gain(4500, 4300)
	}
	pointsA := scalar(t, pool, `SELECT points FROM one_on_one_players WHERE player_id=$1`, int64(a.PlayerID))
	pointsB := scalar(t, pool, `SELECT points FROM one_on_one_players WHERE player_id=$1`, int64(b.PlayerID))
	if pointsA != 4300+gain || pointsB != 4500-gain {
		t.Fatalf("Elo points %d %d gain %d", pointsA, pointsB, gain)
	}
	replay, err := startSettled(s, a, command)
	if err != nil || replay.Win != result.Win || strings.Join(replay.ReportKeys, ",") != strings.Join(result.ReportKeys, ",") {
		t.Fatal("identical START must return the recorded match", err)
	}
	if _, err = s.Start(ctx, a, app.StartCommand{Formations: teamsOf(heroesA[3:], 3), Enemy: b.PlayerID}, op()); err == nil {
		t.Fatal("junior cooldown must refuse the next START")
	}
	if scalar(t, pool, `SELECT count(*) FROM one_on_one_matches WHERE attacker_id=$1 AND status='SETTLED'`, int64(a.PlayerID)) != 1 ||
		scalar(t, pool, `SELECT count(*) FROM combat_attempts a JOIN one_on_one_rounds r USING(attempt_id) JOIN one_on_one_matches m USING(match_id) WHERE a.state='TERMINAL' AND m.attacker_id=$1`, int64(a.PlayerID)) != int64(len(result.Wins)) {
		t.Fatal("match and rounds settled once")
	}
	if scalar(t, pool, `SELECT count(*) FROM combat_attempts a JOIN one_on_one_rounds r USING(attempt_id) JOIN one_on_one_matches m USING(match_id) WHERE a.state='STAGED' AND m.attacker_id=$1`, int64(a.PlayerID)) != int64(3-len(result.Wins)) {
		t.Fatal("a round after the decision must stay unsimulated")
	}
	report, err := s.Report(ctx, result.ReportKeys[0], op())
	if err != nil || len(report) == 0 {
		t.Fatal("round report", err)
	}
	if keys, err := s.DefenseReportKeys(ctx, b, op()); err != nil || len(keys) != len(result.ReportKeys) {
		t.Fatal("defense report keys", err, keys)
	}
	records, err := s.Records(ctx, b, op())
	if err != nil || len(records) != 1 || records[0].Record.Attack || records[0].Record.Win == result.Win || records[0].Attacker.Player != a.PlayerID {
		t.Fatal("defender record", err)
	}
	detail, err := s.RecordDetail(ctx, records[0].Record.ID)
	if err != nil || len(detail.Wins) != len(result.Wins) || len(detail.Attack) != len(result.Wins) {
		t.Fatal("record detail", err)
	}
	if scalar(t, pool, `SELECT fights FROM one_on_one_players WHERE player_id=$1`, int64(b.PlayerID)) != 1 ||
		scalar(t, pool, `SELECT count(*) FROM one_on_one_partner_usage WHERE player_id=$1`, int64(a.PlayerID)) < 2 {
		t.Fatal("history facts")
	}
	if history, err := s.PublicHistoryTx(ctx, pool, b.PlayerID, time.Now()); err != nil || history.Fights != 1 || history.Version <= 0 {
		t.Fatal("1829 SUPER_ARENA defender history", history, err)
	}
	if history, err := s.PublicHistoryTx(ctx, pool, a.PlayerID, time.Now()); err != nil || len(history.Partners) < 2 || history.Partners[0].Fights < 1 {
		t.Fatal("1829 SUPER_ARENA partner usage", history, err)
	}
	wantStreak := int64(0)
	if result.Win {
		wantStreak = 1
	}
	if scalar(t, pool, `SELECT COALESCE(max(current),0) FROM achievement_streaks WHERE player_id=$1 AND achievement_id=100028`, int64(a.PlayerID)) != wantStreak {
		t.Fatal("win streak producer")
	}

	// C08: a promotion match against a Senior with fewer saved teams forfeits the missing rounds; two wins promote.
	// Fixture slots are cleared first: restored databases keep earlier runs' Masters/Seniors.
	exec(t, pool, `UPDATE one_on_one_players SET level=5,slot=NULL,points=3000,state_version=state_version+1 WHERE slot IN (1,501) AND player_id NOT IN ($1,$2)`, int64(a.PlayerID), int64(b.PlayerID))
	exec(t, pool, `UPDATE one_on_one_players SET level=2,slot=501,teams=$2::jsonb,state_version=state_version+1 WHERE player_id=$1`, int64(b.PlayerID), `[{"heroes":[`+strconv.FormatInt(heroesB[0], 10)+`],"pet":0}]`)
	exec(t, pool, `UPDATE one_on_one_players SET level=3,points=4900,mode=2,candidates=$2::jsonb,promotion_week=1,state_version=state_version+1 WHERE player_id=$1`, int64(a.PlayerID), "["+strconv.FormatInt(int64(b.PlayerID), 10)+"]")
	promote := app.StartCommand{Formations: teamsOf(heroesA, 5), Enemy: b.PlayerID}
	for i := range 3 {
		exec(t, pool, `UPDATE one_on_one_players SET last_promotion_at=NULL,state_version=state_version+1 WHERE player_id=$1`, int64(a.PlayerID))
		promote.Formations = teamsOf(heroesA[i:], 5)
		m, err := startSettled(s, a, promote)
		if err != nil {
			t.Fatal(err)
		}
		if !m.Win || m.ReportKeys[len(m.ReportKeys)-1] != "" {
			t.Fatalf("a Senior with one saved team forfeits rounds 2-5 %+v", m)
		}
		if scalar(t, pool, `SELECT mode FROM one_on_one_players WHERE player_id=$1`, int64(a.PlayerID)) == 1 {
			break
		}
	}
	if scalar(t, pool, `SELECT slot FROM one_on_one_players WHERE player_id=$1`, int64(a.PlayerID)) != 501 || scalar(t, pool, `SELECT level FROM one_on_one_players WHERE player_id=$1`, int64(b.PlayerID)) != d.LevelJunior1 {
		t.Fatal("promotion swaps slot, level and points")
	}

	// C07/C09/C10: owed Wednesday/Sunday settlements mail legend_reward by server rank once, titles on Sundays.
	exec(t, pool, `UPDATE one_on_one_players SET level=1,slot=1,state_version=state_version+1 WHERE player_id=$1`, int64(a.PlayerID))
	now := time.Now()
	latest := catalog.LatestSettlement(now)
	revision, err := (contentstore.Store{Queryer: pool}).ActiveRevision(ctx, pool)
	if err != nil {
		t.Fatal(err)
	}
	grantGenuine(t, pool, a, revision, "owned one-on-one frame fixture", []grant.Line{{Kind: grant.StackItem, ItemID: 120001005, Amount: 1}})
	// The fixture replays its own window; earlier runs on the same database settled it already.
	exec(t, pool, `DELETE FROM one_on_one_settlement_ranks WHERE day>$1`, latest-8)
	exec(t, pool, `DELETE FROM one_on_one_settlements WHERE day>$1`, latest-8)
	exec(t, pool, `UPDATE one_on_one_competitions SET settled_through=$1,state_version=state_version+1`, latest-8)
	settled, err := s.Due(ctx, op())
	if err != nil || settled < 2 {
		t.Fatal("owed settlements", settled, err)
	}
	if again, err := s.Due(ctx, op()); err != nil || again != 0 {
		t.Fatal("settlement must be once", again, err)
	}
	if scalar(t, pool, `SELECT count(*) FROM mail_attachments m JOIN mail_records r USING(mail_uuid) WHERE r.recipient_player_id=$1 AND r.source_kind='ONE_ON_ONE_REWARD' AND m.resource_key='top_coin' AND m.amount=2100`, int64(a.PlayerID)) != int64(settled) ||
		scalar(t, pool, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='ONE_ON_ONE_FRAME'`, int64(a.PlayerID)) != 0 ||
		scalar(t, pool, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='ONE_ON_ONE_FRAME'`, int64(b.PlayerID)) != 1 {
		t.Fatal("reward and frame mails")
	}
	// The top_coin income (ENABLED_R4) is claimable through the stock mail claim.
	wire := scalar(t, pool, `SELECT min(wire_id) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='ONE_ON_ONE_REWARD' AND namespace='NORMAL'`, int64(a.PlayerID))
	values := i5store.Store{Queryer: pool}
	claims := i5.Service{Runner: tx.Runner{DB: pool}, Store: values, Content: contentstore.Store{Queryer: pool}, Privileges: i5.BaselinePrivilegeProvider{}, Functions: i5.PetStarterFunctionAnnouncements{},
		Directory: i4store.DirectoryLevelProjection{}, Backpack: values, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: pool}}
	if _, err = claims.ClaimMail(ctx, a, mail.Address{Namespace: mail.Normal, WireID: wire}, op()); err != nil {
		t.Fatal("claim 1 on 1 reward mail", err)
	}
	if scalar(t, pool, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='top_coin'`, int64(a.PlayerID)) != 2100 {
		t.Fatal("top_coin credited by the claim")
	}
	sundays := scalar(t, pool, `SELECT count(*) FROM one_on_one_settlement_ranks WHERE player_id=$1 AND title_id=100002`, int64(a.PlayerID))
	if sundays < 1 || scalar(t, pool, `SELECT current FROM achievement_streaks WHERE player_id=$1 AND achievement_id=100002`, int64(a.PlayerID)) < 1 {
		t.Fatal("Sunday title and Dominator streak", sundays)
	}
	rev, _ := (contentstore.Store{Queryer: pool}).ActiveRevision(ctx, pool)
	origins, err := s.ReadCatalogDisplayOriginsTx(ctx, pool, appdisplay.CatalogOriginRequest{PlayerID: a.PlayerID, Family: "title", CatalogID: 100002, Revision: rev, ObservedAt: time.Now()})
	if err != nil || !origins.Qualified || !origins.CompleteHistory || int64(len(origins.Origins)) != sundays {
		t.Fatal("title origins", err, len(origins.Origins))
	}
	list, err := s.RankList(ctx, a, true)
	if err != nil || list.Mine.Global != 1 || list.Rows[0].Face.Player != a.PlayerID {
		t.Fatal("global rank list", err)
	}
}

// C08: the promotion opening fills empty Senior slots with the best Junior 1 players.
func TestI7C5COneOnOneVacancyFillNative(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	s := oneOnOneService(t, pool)
	a, _ := oneOnOnePlayer(t, pool, rankingServer(t, pool))
	catalog := oneOnOneCatalog(t, pool)
	if _, err := s.Load(ctx, a, op()); err != nil {
		t.Fatal(err)
	}
	exec(t, pool, `UPDATE one_on_one_players SET level=5,slot=NULL,points=3000,state_version=state_version+1 WHERE player_id<>$1 AND level<=2`, int64(a.PlayerID))
	exec(t, pool, `UPDATE one_on_one_players SET points=99999,level=3,state_version=state_version+1 WHERE player_id=$1`, int64(a.PlayerID))
	week := catalog.LatestPromotion(time.Now())
	exec(t, pool, `UPDATE one_on_one_competitions SET opened_through=$1,closed_through=$1,settled_through=$2,master_count=0,senior_count=0,state_version=state_version+1`, week-7, catalog.LatestSettlement(time.Now()))
	if _, err := s.Due(ctx, op()); err != nil {
		t.Fatal(err)
	}
	if scalar(t, pool, `SELECT level FROM one_on_one_players WHERE player_id=$1`, int64(a.PlayerID)) != d.LevelSenior || scalar(t, pool, `SELECT opened_through FROM one_on_one_competitions`) != week {
		t.Fatal("vacancy fill")
	}
}

// C02: concurrent first entries create one competition and distinct players.
func TestI7C5COneOnOneConcurrentEntryNative(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	s := oneOnOneService(t, pool)
	server := rankingServer(t, pool)
	actors := []identity.ActorContext{}
	for range 3 {
		a, _ := oneOnOnePlayer(t, pool, server)
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
	if scalar(t, pool, `SELECT count(*) FROM one_on_one_competitions`) != 1 || scalar(t, pool, `SELECT count(*) FROM one_on_one_players WHERE logical_server_id=$1`, int64(server)) != 3 {
		t.Fatal("concurrent entry")
	}
}

// stalledRounds withholds resolution from START, as if the client vanished.
type stalledRounds struct{ app.Combat }

func (stalledRounds) ResolveDetached(context.Context, operation.Context, ids.UUID) *combat.Flight {
	f := &combat.Flight{Done: make(chan struct{}), Err: cd.ErrResolverRetryable}
	close(f.Done)
	return f
}

// C05: an abandoned match is resolved and settled once by the reconcile provider.
func TestI7C5COneOnOneReconcileAbandonedNative(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	s := oneOnOneService(t, pool)
	a, heroesA := oneOnOnePlayer(t, pool, rankingServer(t, pool))
	b, heroesB := oneOnOnePlayer(t, pool, rankingServer(t, pool))
	if !oneOnOneCatalog(t, pool).Open(time.Now()) {
		t.Skip("1 on 1 START is closed outside 08:00-22:00 GMT+8")
	}
	for _, x := range []struct {
		a      identity.ActorContext
		heroes []int64
	}{{a, heroesA}, {b, heroesB}} {
		if _, err := s.Load(ctx, x.a, op()); err != nil {
			t.Fatal(err)
		}
		if err := s.ChangeTeams(ctx, x.a, teamsOf(x.heroes, 3), op()); err != nil {
			t.Fatal(err)
		}
	}
	exec(t, pool, `UPDATE one_on_one_players SET points=4800,state_version=state_version+1 WHERE player_id=$1`, int64(b.PlayerID))
	pinOneOnOneOffer(t, pool, a, b.PlayerID)
	stalled := s
	stalled.Combat = stalledRounds{s.Combat}
	if _, err := stalled.Start(ctx, a, app.StartCommand{Formations: teamsOf(heroesA, 3), Enemy: b.PlayerID}, op()); err == nil {
		t.Fatal("an unresolved match must not answer a result")
	}
	exec(t, pool, `UPDATE one_on_one_matches SET started_at=started_at-interval '5 minutes' WHERE attacker_id=$1`, int64(a.PlayerID))
	timed, err := gen.Binder{Time: pg.AuthoritativeTime{Queryer: pool}}.Bind(ctx, op())
	if err != nil {
		t.Fatal(err)
	}
	for range 2 {
		if _, err = (app.Reconciler{Service: s}).Reconcile(ctx, timed, 50); err != nil {
			t.Fatal(err)
		}
	}
	if scalar(t, pool, `SELECT count(*) FROM one_on_one_matches WHERE attacker_id=$1 AND status='SETTLED'`, int64(a.PlayerID)) != 1 ||
		scalar(t, pool, `SELECT count(*) FROM one_on_one_records WHERE owner_player_id=$1`, int64(a.PlayerID)) != 1 {
		t.Fatal("abandoned match not settled once")
	}
}

// TestI7C5COneOnOneRivalRegionWireNative runs MATCH_ENEMIES through the production
// dispatcher over a real competition: a rival on another server must carry its own
// band in player_info.region, which ChangeEnemyWindow concatenates into "S"..region.
func TestI7C5COneOnOneRivalRegionWireNative(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	s := oneOnOneService(t, pool)
	a, heroesA := oneOnOnePlayer(t, pool, rankingServer(t, pool))
	b, heroesB := oneOnOnePlayer(t, pool, rankingServer(t, pool))
	if a.LogicalServerID == b.LogicalServerID {
		t.Fatal("fixture needs two logical servers")
	}
	for _, x := range []struct {
		actor  identity.ActorContext
		heroes []int64
	}{{a, heroesA}, {b, heroesB}} {
		if _, err := s.Load(ctx, x.actor, op()); err != nil {
			t.Fatal(err)
		}
		if err := s.ChangeTeams(ctx, x.actor, teamsOf(x.heroes, 3), op()); err != nil {
			t.Fatal(err)
		}
	}
	// The better rival is one row ahead of the requester in the Junior order.
	exec(t, pool, `UPDATE one_on_one_players SET points=3000,state_version=state_version+1 WHERE player_id NOT IN ($1,$2)`, int64(a.PlayerID), int64(b.PlayerID))
	exec(t, pool, `UPDATE one_on_one_players SET points=99999,state_version=state_version+1 WHERE player_id=$1`, int64(b.PlayerID))
	dispatcher := stockruntime.OneOnOneDispatcher{Authority: fixedSocialAuthority{actor: a}, Service: s}
	response := dispatcher.Dispatch(ctx, httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{MID: 2482, Operation: op(), ReceivedAt: time.Now().UTC(),
		Claims: wire.CredentialClaims{Token: "fixture", Region: int64(a.LogicalServerID)}, Params: map[string]any{}}})
	if response.HTTPStatus != http.StatusOK {
		t.Fatalf("MATCH_ENEMIES status=%d body=%v cause=%v", response.HTTPStatus, response.Body, response.Cause)
	}
	offered := response.Body["match_infos"].([]map[string]any)
	found := false
	for _, row := range offered {
		info := row["player_info"].(map[string]any)
		player := identity.PlayerID(info["player_id"].(int64))
		if info["region"] != int64(logicalserver.PlayerRegion(player)) {
			t.Fatalf("rival %d region=%v", player, info["region"])
		}
		if player == b.PlayerID {
			found = true
			if info["region"] != int64(b.LogicalServerID) {
				t.Fatalf("better rival on server %d answered region=%v", b.LogicalServerID, info["region"])
			}
		}
	}
	if !found {
		t.Fatalf("the better rival on server %d was not offered: %v", b.LogicalServerID, offered)
	}
}

// TestI9_10OneOnOneStaleTargetNative proves a target that moved out of the
// better-ranked bands since MATCH is refused with the D488 rank-changed error.
func TestI9_10OneOnOneStaleTargetNative(t *testing.T) {
	p := pool(t)
	defer p.Close()
	s := oneOnOneService(t, p)
	server := rankingServer(t, p)
	a, heroesA := oneOnOnePlayer(t, p, server)
	b, heroesB := oneOnOnePlayer(t, p, server)
	c, heroesC := oneOnOnePlayer(t, p, server)
	for _, actor := range []identity.ActorContext{a, b, c} {
		if _, err := s.Load(ctx, actor, op()); err != nil {
			t.Fatal(err)
		}
	}
	for _, x := range []struct {
		actor  identity.ActorContext
		heroes []int64
	}{{a, heroesA}, {b, heroesB}, {c, heroesC}} {
		if err := s.ChangeTeams(ctx, x.actor, teamsOf(x.heroes, 3), op()); err != nil {
			t.Fatal(err)
		}
	}
	// Both issued lists showed B at a better rank; pin that issued target.
	for _, actor := range []identity.ActorContext{a, c} {
		pinOneOnOneOffer(t, p, actor, b.PlayerID)
	}
	// A concurrent attacker settles and drops B below both challengers.
	exec(t, p, `UPDATE one_on_one_players SET points=3000,state_version=state_version+1 WHERE player_id=$1`, int64(b.PlayerID))
	_, err := s.Start(ctx, c, app.StartCommand{Formations: teamsOf(heroesC, 3), Enemy: b.PlayerID}, op())
	if !errors.Is(err, d.ErrOfferStale) {
		t.Fatalf("moved target START err=%v want ErrOfferStale", err)
	}
}

// TestI9_10OneOnOneTargetDroppedOneRankNative proves D488 parity for a target
// that only drops one rank and stays inside the issued band: the recorded rank,
// not the current band, decides.
func TestI9_10OneOnOneTargetDroppedOneRankNative(t *testing.T) {
	p := pool(t)
	defer p.Close()
	s := oneOnOneService(t, p)
	server := rankingServer(t, p)
	a, heroesA := oneOnOnePlayer(t, p, server)
	b, heroesB := oneOnOnePlayer(t, p, server)
	c, heroesC := oneOnOnePlayer(t, p, server)
	for _, actor := range []identity.ActorContext{a, b, c} {
		if _, err := s.Load(ctx, actor, op()); err != nil {
			t.Fatal(err)
		}
	}
	for _, x := range []struct {
		actor  identity.ActorContext
		heroes []int64
	}{{a, heroesA}, {b, heroesB}, {c, heroesC}} {
		if err := s.ChangeTeams(ctx, x.actor, teamsOf(x.heroes, 3), op()); err != nil {
			t.Fatal(err)
		}
	}
	exec(t, p, `UPDATE one_on_one_players SET points=4310,state_version=state_version+1 WHERE player_id=$1`, int64(b.PlayerID))
	exec(t, p, `UPDATE one_on_one_players SET points=4305,state_version=state_version+1 WHERE player_id=$1`, int64(c.PlayerID))
	pinOneOnOneOffer(t, p, a, b.PlayerID)
	// B and C swap ranks; B is still inside A's better-rank bands.
	exec(t, p, `UPDATE one_on_one_players SET points=4303,state_version=state_version+1 WHERE player_id=$1`, int64(b.PlayerID))
	exec(t, p, `UPDATE one_on_one_players SET points=4312,state_version=state_version+1 WHERE player_id=$1`, int64(c.PlayerID))
	if !inOneOnOneBand(t, p, a.PlayerID, b.PlayerID) {
		t.Fatal("fixture target must stay inside the issued band")
	}
	_, err := s.Start(ctx, a, app.StartCommand{Formations: teamsOf(heroesA, 3), Enemy: b.PlayerID}, op())
	if !errors.Is(err, d.ErrOfferStale) {
		t.Fatalf("target that dropped one rank err=%v want ErrOfferStale", err)
	}
	response := stockruntime.OneOnOneDispatcher{Authority: fixedSocialAuthority{actor: a}, Service: s}.Dispatch(ctx,
		httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{MID: 2484, Operation: op(), ReceivedAt: time.Now().UTC(),
			Claims: wire.CredentialClaims{Token: "fixture", Region: int64(a.LogicalServerID)},
			Params: map[string]any{"formations": []any{"1", "2", "3"}, "enemy_id": json.Number(strconv.FormatInt(int64(b.PlayerID), 10))}}})
	if response.HTTPStatus != http.StatusConflict || response.Body["error_code"] != int64(35026) {
		t.Fatalf("dropped-rank START response=%+v", response)
	}
}

// TestI9_10OneOnOneConcurrentAttackersRankChangedNative proves that when
// several attackers hold an offer for one rank, the first fight moves the
// target and everyone after it receives the stock 409/35026 refusal.
func TestI9_10OneOnOneConcurrentAttackersRankChangedNative(t *testing.T) {
	p := pool(t)
	defer p.Close()
	s := oneOnOneService(t, p)
	server := rankingServer(t, p)
	target, targetHeroes := oneOnOnePlayer(t, p, server)
	type challenger struct {
		actor  identity.ActorContext
		heroes []int64
	}
	challengers := []challenger{}
	for range 3 {
		actor, heroes := oneOnOnePlayer(t, p, server)
		challengers = append(challengers, challenger{actor, heroes})
	}
	if !oneOnOneCatalog(t, p).Open(time.Now()) {
		t.Skip("1 on 1 START is closed outside 08:00-22:00 GMT+8")
	}
	for _, actor := range []identity.ActorContext{target, challengers[0].actor, challengers[1].actor, challengers[2].actor} {
		if _, err := s.Load(ctx, actor, op()); err != nil {
			t.Fatal(err)
		}
	}
	if err := s.ChangeTeams(ctx, target, teamsOf(targetHeroes, 3), op()); err != nil {
		t.Fatal(err)
	}
	for _, x := range challengers {
		if err := s.ChangeTeams(ctx, x.actor, teamsOfFive(x.heroes, 3), op()); err != nil {
			t.Fatal(err)
		}
	}
	// One rank above all three attackers, who each hold an offer for it.
	exec(t, p, `UPDATE one_on_one_players SET points=4305,state_version=state_version+1 WHERE player_id=$1`, int64(target.PlayerID))
	for _, x := range challengers {
		pinOneOnOneOffer(t, p, x.actor, target.PlayerID)
	}
	targetRank := oneOnOneGlobalRank(t, p, target.PlayerID)
	first, err := startSettled(s, challengers[0].actor, app.StartCommand{Formations: teamsOfFive(challengers[0].heroes, 3), Enemy: target.PlayerID})
	if err != nil {
		t.Fatal(err)
	}
	if !first.Win || oneOnOneGlobalRank(t, p, target.PlayerID) == targetRank {
		t.Fatalf("first attacker must win and move the target: win=%v rank=%d", first.Win, targetRank)
	}
	for _, x := range challengers[1:] {
		_, err := s.Start(ctx, x.actor, app.StartCommand{Formations: teamsOfFive(x.heroes, 3), Enemy: target.PlayerID}, op())
		if !errors.Is(err, d.ErrOfferStale) {
			t.Fatalf("later attacker %d err=%v want ErrOfferStale", x.actor.PlayerID, err)
		}
		response := stockruntime.OneOnOneDispatcher{Authority: fixedSocialAuthority{actor: x.actor}, Service: s}.Dispatch(ctx,
			httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{MID: 2484, Operation: op(), ReceivedAt: time.Now().UTC(),
				Claims: wire.CredentialClaims{Token: "fixture", Region: int64(x.actor.LogicalServerID)},
				Params: map[string]any{"formations": []any{"1", "2", "3"}, "enemy_id": json.Number(strconv.FormatInt(int64(target.PlayerID), 10))}}})
		if response.HTTPStatus != http.StatusConflict || response.Body["error_code"] != int64(35026) {
			t.Fatalf("later attacker %d response=%+v", x.actor.PlayerID, response)
		}
	}
}

func sameTeams(left, right []d.Team) bool {
	if len(left) != len(right) {
		return false
	}
	for index := range left {
		if left[index].Pet != right[index].Pet || !slices.Equal(left[index].Heroes, right[index].Heroes) {
			return false
		}
	}
	return true
}

// oneOnOneStartStall stalls resolution while stall is true, keeping a match
// open as a request whose rounds are still resolving does.
type oneOnOneStartStall struct {
	app.Combat
	stall bool
}

func (rounds *oneOnOneStartStall) ResolveDetached(c context.Context, operationContext operation.Context, attempt ids.UUID) *combat.Flight {
	if !rounds.stall {
		return rounds.Combat.ResolveDetached(c, operationContext, attempt)
	}
	flight := &combat.Flight{Done: make(chan struct{}), Err: cd.ErrResolverRetryable}
	close(flight.Done)
	return flight
}

// TestClosureE4OneOnOneStartReplayIdentityNative: a START whose only change is
// the formation replays the open match's frozen START (I8_PARENT_CONTRACT_V1
// generation_supersede), and only an identical formation replays after settlement.
func TestClosureE4OneOnOneStartReplayIdentityNative(t *testing.T) {
	databasePool := pool(t)
	defer databasePool.Close()
	service := oneOnOneService(t, databasePool)
	server := rankingServer(t, databasePool)
	actor, heroes := oneOnOnePlayer(t, databasePool, server)
	enemy, enemyHeroes := oneOnOnePlayer(t, databasePool, server)
	for _, side := range []struct {
		actor  identity.ActorContext
		heroes []int64
	}{{actor, heroes}, {enemy, enemyHeroes}} {
		if _, err := service.Load(ctx, side.actor, op()); err != nil {
			t.Fatal(err)
		}
		if err := service.ChangeTeams(ctx, side.actor, teamsOf(side.heroes, 3), op()); err != nil {
			t.Fatal(err)
		}
	}
	exec(t, databasePool, `UPDATE one_on_one_players SET points=4500,state_version=state_version+1 WHERE player_id=$1`, int64(enemy.PlayerID))
	pinOneOnOneOffer(t, databasePool, actor, enemy.PlayerID)
	if !oneOnOneCatalog(t, databasePool).Open(time.Now()) {
		t.Skip("1 on 1 START is closed outside 08:00-22:00 GMT+8")
	}
	first := app.StartCommand{Formations: teamsOf(heroes, 3), Enemy: enemy.PlayerID}
	stall := &oneOnOneStartStall{Combat: service.Combat, stall: true}
	service.Combat = stall
	if _, err := service.Start(ctx, actor, first, op()); err == nil {
		t.Fatal("an unresolved match must not answer a result")
	}
	open, found, err := (oneononestore.Store{}).LatestMatchTx(ctx, databasePool, actor.PlayerID)
	if err != nil || !found || open.Status != d.StatusStarted || !sameTeams(open.AttackTeams, first.Formations) {
		t.Fatalf("open match %+v found=%v err=%v", open, found, err)
	}
	stall.stall = false
	second := app.StartCommand{Formations: teamsOf(heroes[3:], 3), Enemy: enemy.PlayerID}
	replay, err := startSettled(service, actor, second)
	if err != nil {
		t.Fatal(err)
	}
	if scalar(t, databasePool, `SELECT count(*) FROM one_on_one_matches WHERE attacker_id=$1`, int64(actor.PlayerID)) != 1 ||
		scalar(t, databasePool, `SELECT tries_left FROM one_on_one_players WHERE player_id=$1`, int64(actor.PlayerID)) != 9 {
		t.Fatal("a changed formation must replay the open START: one match, one try")
	}
	frozen := map[string]bool{}
	for _, round := range open.Rounds {
		frozen[round.AttemptID.String()] = true
	}
	if len(replay.ReportKeys) != len(replay.Wins) {
		t.Fatalf("replay %+v", replay)
	}
	for _, key := range replay.ReportKeys {
		if key != "" && !frozen[key] {
			t.Fatalf("replayed report %q is not a frozen attempt of the open match", key)
		}
	}
	// The settled-replay window still requires the same formation: a changed choice starts a new match.
	exec(t, databasePool, `UPDATE one_on_one_players SET last_fight_at=NULL,state_version=state_version+1 WHERE player_id=$1`, int64(actor.PlayerID))
	pinOneOnOneOffer(t, databasePool, actor, enemy.PlayerID)
	third, err := startSettled(service, actor, second)
	if err != nil || len(third.Wins) == 0 ||
		scalar(t, databasePool, `SELECT count(*) FROM one_on_one_matches WHERE attacker_id=$1`, int64(actor.PlayerID)) != 2 {
		t.Fatal("a changed formation after settlement must start a new match")
	}
}

func oneOnOneGlobalRank(t *testing.T, p *pg.Pool, pid identity.PlayerID) int64 {
	t.Helper()
	standings, err := (oneononestore.Store{}).StandingsTx(ctx, p)
	if err != nil {
		t.Fatal(err)
	}
	ranked, ok := d.Find(oneOnOneCatalog(t, p).Rank(standings), pid)
	if !ok {
		t.Fatalf("player %d is not in the standings", pid)
	}
	return ranked.Global
}

// TestI9_10OneOnOneLowPointsRefusalNative proves source message 30003 is
// returned in-band through the production dispatcher and consumes no try.
func TestI9_10OneOnOneLowPointsRefusalNative(t *testing.T) {
	p := pool(t)
	defer p.Close()
	s := oneOnOneService(t, p)
	server := rankingServer(t, p)
	a, heroesA := oneOnOnePlayer(t, p, server)
	b, heroesB := oneOnOnePlayer(t, p, server)
	for _, actor := range []identity.ActorContext{a, b} {
		if _, err := s.Load(ctx, actor, op()); err != nil {
			t.Fatal(err)
		}
	}
	for _, x := range []struct {
		actor  identity.ActorContext
		heroes []int64
	}{{a, heroesA}, {b, heroesB}} {
		if err := s.ChangeTeams(ctx, x.actor, teamsOf(x.heroes, 3), op()); err != nil {
			t.Fatal(err)
		}
	}
	// The revision's floor is 3000, so pin the low-point opponent directly.
	exec(t, p, `UPDATE one_on_one_players SET level=5,slot=NULL,points=999,mode=1,candidates='[]',opponent=NULL,state_version=state_version+1 WHERE player_id=$1`, int64(b.PlayerID))
	pinOneOnOneOffer(t, p, a, b.PlayerID)
	if !oneOnOneCatalog(t, p).Open(time.Now()) {
		t.Skip("1 on 1 START is closed outside 08:00-22:00 GMT+8")
	}
	beforeTries := scalar(t, p, `SELECT tries_left FROM one_on_one_players WHERE player_id=$1`, int64(a.PlayerID))
	response := stockruntime.OneOnOneDispatcher{Authority: fixedSocialAuthority{actor: a}, Service: s}.Dispatch(ctx,
		httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{MID: 2484, Operation: op(), ReceivedAt: time.Now().UTC(),
			Claims: wire.CredentialClaims{Token: "fixture", Region: int64(a.LogicalServerID)},
			Params: map[string]any{"formations": []any{"1", "2", "3"}, "enemy_id": json.Number(strconv.FormatInt(int64(b.PlayerID), 10))}}})
	if response.HTTPStatus != http.StatusOK || response.Body["error_code"] != int64(30003) {
		t.Fatalf("low-point START response=%+v", response)
	}
	if scalar(t, p, `SELECT tries_left FROM one_on_one_players WHERE player_id=$1`, int64(a.PlayerID)) != beforeTries {
		t.Fatal("a refused low-point challenge consumed a try")
	}
	if scalar(t, p, `SELECT count(*) FROM one_on_one_matches WHERE attacker_id=$1`, int64(a.PlayerID)) != 0 {
		t.Fatal("a refused low-point challenge created a match")
	}
}
