//go:build postgres

package playerdisplay_test

import (
	"context"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/topfloorstore"
	"gxb.local/backend/v2/internal/application/i5"
	application "gxb.local/backend/v2/internal/application/topfloor"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/tx"
	"strings"
	"sync"
	"testing"
	"time"
)

type taskCommitFaultDatabase struct{ tx.Beginner }

func (database taskCommitFaultDatabase) Begin(requestContext context.Context, options tx.Options) (tx.Tx, error) {
	transaction, err := database.Beginner.Begin(requestContext, options)
	if err != nil {
		return nil, err
	}
	return &taskCommitFaultTransaction{Tx: transaction}, nil
}

type taskCommitFaultTransaction struct {
	tx.Tx
	changed bool
}

func (transaction *taskCommitFaultTransaction) Exec(requestContext context.Context, statement string, arguments ...any) (tx.CommandTag, error) {
	result, err := transaction.Tx.Exec(requestContext, statement, arguments...)
	if err == nil && (strings.HasPrefix(statement, "INSERT INTO top_floor_task_fights") || strings.HasPrefix(statement, "UPDATE top_floor_task_fights") || strings.HasPrefix(statement, "INSERT INTO top_floor_task_days")) {
		transaction.changed = true
	}
	return result, err
}
func (transaction *taskCommitFaultTransaction) Commit(requestContext context.Context) error {
	if transaction.changed {
		return (faultTx{Tx: transaction.Tx, commit: true}).Commit(requestContext)
	}
	return transaction.Tx.Commit(requestContext)
}

type taskPrivilegeFixture struct{}

func (taskPrivilegeFixture) SnapshotTx(context.Context, tx.Queryer, identity.PlayerID, time.Time) (i5.PrivilegeSnapshot, error) {
	return i5.PrivilegeSnapshot{VIPLevel: 15, MonthlyPrivilegeActive: true}, nil
}
func TestI97ATaskBattleRecoveryNative(t *testing.T) {
	database := pool(t)
	defer database.Close()
	service := topFloorService(t, database)
	server := rankingServer(t, database)
	actor, revision, hero := topFloorPlayer(t, database, server)
	clock := &workplaceTime{at: time.Now().UTC()}
	service.Timed.Binder.Time = clock
	catalog, err := (contentstore.Store{Queryer: database}).TopFloorCatalogTx(ctx, database, revision)
	if err != nil {
		t.Fatal(err)
	}
	const admissionGap = 301 * time.Second
	walkFrozen := func(start time.Time) bool {
		for challenge := 0; challenge < 10; challenge++ {
			if catalog.Frozen(start.Add(time.Duration(challenge) * admissionGap)) {
				return true
			}
		}
		return false
	}
	for walkFrozen(clock.at) {
		clock.at = clock.at.Add(admissionGap)
	}
	exec(t, database, `UPDATE player_directory_profiles SET lev=60 WHERE player_id=$1`, int64(actor.PlayerID))
	current, err := service.Load(ctx, actor, op())
	if err != nil {
		t.Fatal(err)
	}
	// Rank and available tickets are fixture preconditions; every weekly admission below uses the real START owner.
	transaction, err := database.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	store := topfloorstore.Store{}
	if err = store.SwapTx(ctx, transaction, server, domain.Ranked{Rank: current.Rank, Occupant: domain.Occupant{Player: actor.PlayerID}}, domain.Ranked{Rank: 200, Occupant: domain.Occupant{Robot: domain.RobotTeams + 1 - 200}}); err != nil {
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
		if _, err = service.Start(ctx, actor, application.StartCommand{Formation: []int64{hero.PartnerID}, Enemy: current.Enemies[0].Occupant.TableID()}, op()); err != nil {
			t.Fatalf("normal admission %d: %v", challenge, err)
		}
		clock.at = clock.at.Add(admissionGap)
	}
	count, err := store.WeeklyChallengesTx(ctx, database, actor.PlayerID, clock.at)
	if err != nil || count != 10 {
		t.Fatalf("genuine weekly admissions: %d %v", count, err)
	}
	service.Timed.Runner.DB = taskCommitFaultDatabase{database}
	view, err := service.LoadTask(ctx, actor, op(), false)
	if err != nil {
		t.Fatal("load special", err)
	}
	if len(view.Enemies) != 3 || view.Player.TicketsLeft != 5 {
		t.Fatalf("special load %+v", view)
	}
	if err = service.SaveTaskDefense(ctx, actor, domain.TaskModeDefense{Heroes: []int64{hero.PartnerID + 999999}}, op()); err == nil {
		t.Fatal("unowned special defense accepted")
	}
	if _, err = service.PurchaseTask(ctx, actor, opPinned(revision), false); err == nil {
		t.Fatal("buy before exhaustion accepted")
	}
	if _, err = service.StartTask(ctx, actor, application.TaskStartCommand{StartCommand: application.StartCommand{Formation: []int64{hero.PartnerID}, Enemy: 25000}}, op()); err == nil {
		t.Fatal("unoffered opponent accepted")
	}
	defense := domain.TaskModeDefense{Heroes: []int64{hero.PartnerID}}
	if view.Rotation.Mode == domain.TaskModeLeader {
		defense.Leader = hero.PartnerID
	}
	if err = service.SaveTaskDefense(ctx, actor, defense, op()); err != nil {
		t.Fatal("save special defense", err)
	}

	// A declared historical rules-catalog fixture leaves active actor content unchanged.
	var manifestRaw string
	if err = database.QueryRow(ctx, `SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`, revision).Scan(&manifestRaw); err != nil {
		t.Fatal(err)
	}
	var historicalManifest map[string]json.RawMessage
	if err = json.Unmarshal([]byte(manifestRaw), &historicalManifest); err != nil {
		t.Fatal(err)
	}
	delete(historicalManifest, "revision_id")
	historicalCompiler := fmt.Sprintf("i9-7a-historical-rules-fixture-%d", actor.PlayerID)
	historicalManifest["compiler_version"], err = json.Marshal(historicalCompiler)
	if err != nil {
		t.Fatal(err)
	}
	basis, err := json.Marshal(historicalManifest)
	if err != nil {
		t.Fatal(err)
	}
	historicalRevision := fmt.Sprintf("%x", sha256.Sum256(basis))
	historicalManifest["revision_id"], err = json.Marshal(historicalRevision)
	if err != nil {
		t.Fatal(err)
	}
	historicalPayload, err := json.Marshal(historicalManifest)
	if err != nil {
		t.Fatal(err)
	}
	exec(t, database, `INSERT INTO gxb_content_revisions(revision_id,content_sha256,schema_version,compiler_version,parser_version,manifest) SELECT $2,decode($2,'hex'),schema_version,$3,parser_version,$4::jsonb FROM gxb_content_revisions WHERE revision_id=$1`, revision, historicalRevision, historicalCompiler, string(historicalPayload))
	exec(t, database, `INSERT INTO content_top_floor_catalogs(revision_id,payload) SELECT $2,payload FROM content_top_floor_catalogs WHERE revision_id=$1`, revision, historicalRevision)
	exec(t, database, `UPDATE top_floor_task_periods SET content_revision=$3 WHERE logical_server_id=$1 AND period_number=$2`, int64(server), view.Rotation.Number, historicalRevision)
	exec(t, database, `UPDATE top_floor_task_players SET payload=jsonb_set(payload,'{player,ContentRevision}',to_jsonb($2::text)) WHERE player_id=$1`, int64(actor.PlayerID), historicalRevision)
	normalRecords := scalar(t, database, `SELECT count(*) FROM top_floor_records WHERE owner_player_id=$1`, int64(actor.PlayerID))
	command := application.TaskStartCommand{StartCommand: application.StartCommand{Formation: defense.Heroes, Enemy: view.Enemies[0].Occupant.TableID()}, Leader: defense.Leader}
	result, err := service.StartTask(ctx, actor, command, op())
	if err != nil || len(result.Report) == 0 {
		t.Fatalf("special battle: %v report=%d", err, len(result.Report))
	}
	retry, err := service.StartTask(ctx, actor, command, op())
	if err != nil || string(retry.Report) != string(result.Report) {
		t.Fatal("frozen retry", err)
	}
	lastFight, present, err := store.LatestTaskFightTx(ctx, database, actor.PlayerID)
	if err != nil || !present {
		t.Fatal(err)
	}
	attempt, present, err := service.Combat.AttemptTx(ctx, database, lastFight.Fight.AttemptID)
	if err != nil || !present {
		t.Fatal("active battle content incorrectly tied to historical rotation rules", err)
	}
	var battleContentRevision string
	if err = database.QueryRow(ctx, `SELECT content_revision FROM combat_snapshots WHERE snapshot_hash=$1`, attempt.SnapshotHash).Scan(&battleContentRevision); err != nil || battleContentRevision != revision {
		t.Fatal("active battle content", battleContentRevision, err)
	}
	if result.AwardCrystal != 0 {
		t.Fatal("normal best-rank award leaked")
	}
	period, present, err := store.ReadTaskPeriodTx(ctx, database, server, view.Rotation.Number, false)
	if err != nil || !present {
		t.Fatal("period", err)
	}
	saved, found, err := store.ReadTaskPlayerTx(ctx, database, actor.PlayerID, period, false)
	if err != nil || !found || saved.Player.TicketsLeft != 4 {
		t.Fatalf("single ticket debit: %+v %v", saved, err)
	}
	records, err := store.TaskRecordsTx(ctx, database, actor.PlayerID)
	if err != nil || len(records) != 1 || records[0].Mode != view.Rotation.Mode {
		t.Fatalf("special history: %+v %v", records, err)
	}
	if scalar(t, database, `SELECT count(*) FROM top_floor_records WHERE owner_player_id=$1`, int64(actor.PlayerID)) != normalRecords {
		t.Fatal("normal history contaminated")
	}
	replay, err := service.TaskReport(ctx, actor, records[0].Record.AttemptID.String())
	if err != nil || string(replay) != string(result.Report) {
		t.Fatal("retained replay", err)
	}
	other, _, _ := topFloorPlayer(t, database, server)
	if _, err = service.TaskReport(ctx, other, records[0].Record.AttemptID.String()); err == nil {
		t.Fatal("foreign replay allowed")
	}
	service.Privileges = taskPrivilegeFixture{}
	grantGenuine(t, database, actor, revision, "task purchase fixture", []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "crystal", Amount: 1000}})
	balanceBefore := scalar(t, database, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'`, int64(actor.PlayerID))
	service.Timed.Runner.DB = metricCommitDB{Beginner: database, commit: true}
	resetOperation := opPinned(revision)
	reset, err := service.PurchaseTask(ctx, actor, resetOperation, true)
	if err != nil || reset.LastMatchAt != nil {
		t.Fatal("reset timer", err)
	}
	if _, err = service.PurchaseTask(ctx, actor, resetOperation, true); err != nil {
		t.Fatal("reset receipt retry", err)
	}
	if scalar(t, database, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'`, int64(actor.PlayerID)) != balanceBefore-catalog.ResetCost {
		t.Fatal("duplicate reset debit")
	}
	saved, _, err = store.ReadTaskPlayerTx(ctx, database, actor.PlayerID, period, false)
	if err != nil {
		t.Fatal(err)
	}
	previous := saved.Player.StateVersion
	saved.Player.TicketsLeft = 0
	saved.Player.StateVersion++
	transaction, err = database.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	if err = store.SaveTaskPlayerTx(ctx, transaction, saved, period, previous); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	purchaseOperation := opPinned(revision)
	var buyers sync.WaitGroup
	purchaseResults := make(chan domain.Player, 2)
	purchaseErrors := make(chan error, 2)
	for buyer := 0; buyer < 2; buyer++ {
		buyers.Add(1)
		go func() {
			defer buyers.Done()
			result, err := service.PurchaseTask(ctx, actor, purchaseOperation, false)
			purchaseResults <- result
			purchaseErrors <- err
		}()
	}
	buyers.Wait()
	close(purchaseErrors)
	for err := range purchaseErrors {
		if err != nil {
			t.Fatal("concurrent buy", err)
		}
	}
	bought := <-purchaseResults
	err = nil
	if err != nil || bought.TicketsLeft != catalog.BuyRestore {
		t.Fatal("buy", err)
	}
	if _, err = service.PurchaseTask(ctx, actor, purchaseOperation, false); err != nil {
		t.Fatal("buy receipt retry", err)
	}
	if scalar(t, database, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'`, int64(actor.PlayerID)) != balanceBefore-catalog.ResetCost-catalog.BuyCosts[0] {
		t.Fatal("duplicate buy debit")
	}
	// An admitted purchase replays even when current admission is subsequently lost.
	exec(t, database, `UPDATE player_directory_profiles SET lev=1 WHERE player_id=$1`, int64(actor.PlayerID))
	if _, err = service.PurchaseTask(ctx, actor, purchaseOperation, false); err != nil {
		t.Fatal("frozen purchase after lost admission", err)
	}

	// Put the participant in a source reward band; winning that rank is not this fixture's claim.
	currentRank, ranked, err := store.TaskRankOfTx(ctx, database, server, period.Rotation.Number, domain.Occupant{Player: actor.PlayerID})
	if err != nil || !ranked {
		t.Fatal(err)
	}
	firstRank, err := store.TaskRangeTx(ctx, database, server, period.Rotation.Number, 1, 1)
	if err != nil || len(firstRank) != 1 {
		t.Fatal(err)
	}
	transaction, err = database.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	if err = store.SwapTaskRanksTx(ctx, transaction, server, period.Rotation.Number, domain.Ranked{Rank: currentRank, Occupant: domain.Occupant{Player: actor.PlayerID}}, firstRank[0]); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	service.Timed.Runner.DB = taskCommitFaultDatabase{database}
	clock.at = clock.at.Add(24 * time.Hour)
	due, err := store.TaskDueServersTx(ctx, database, clock.at)
	if err != nil || len(due) == 0 {
		t.Fatal("due special day", due, err)
	}
	var settlementWorkers sync.WaitGroup
	settlementErrors := make(chan error, 2)
	for worker := 0; worker < 2; worker++ {
		settlementWorkers.Add(1)
		go func() { defer settlementWorkers.Done(); settlementErrors <- service.SettleTaskDue(ctx, server, op()) }()
	}
	settlementWorkers.Wait()
	close(settlementErrors)
	for err := range settlementErrors {
		if err != nil {
			t.Fatal("concurrent daily settlement", err)
		}
	}
	if scalar(t, database, `SELECT count(*) FROM top_floor_task_days WHERE logical_server_id=$1 AND period_number=$2`, int64(server), period.Rotation.Number) != 1 {
		t.Fatal("daily receipt duplicated")
	}
	if scalar(t, database, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='TOP_FLOOR_TASK_DAY'`, int64(actor.PlayerID)) != 1 {
		t.Fatal("daily mail missing or duplicated")
	}
	due, err = store.TaskDueServersTx(ctx, database, clock.at)
	for _, candidate := range due {
		if candidate == server {
			t.Fatal("caught-up server starves fight recovery")
		}
	}
	if err != nil {
		t.Fatal(err)
	}

}
