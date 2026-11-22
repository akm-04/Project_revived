//go:build postgres

package socialrecallstore_test

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strconv"
	"strings"
	"sync"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	ps "gxb.local/backend/v2/internal/adapters/postgres/commerceprivilegestore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrecallstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrelationstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/application/commerceprivilege"
	"gxb.local/backend/v2/internal/application/generation"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/socialrecall"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/socialrecall"
	"gxb.local/backend/v2/internal/foundation/changes"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/limits"
)

func recallClaimHarness(world *recallWorld) (socialrecall.ClaimService, socialrecallstore.TargetReader) {
	progression := i5store.Store{Queryer: world.pool}
	content := contentstore.Store{Queryer: world.pool}
	privileges := commerceprivilege.Provider{Store: ps.Store{}, Content: content}
	targets := socialrecallstore.TargetReader{
		Activity:    i4store.PlayerLoginActivity{},
		Progression: progression,
		Roster:      characterstore.RosterMetricReader{Store: characterstore.Store{Queryer: world.pool}, Content: content},
		Privilege:   privileges,
		Relations:   socialrelationstore.Store{},
	}
	i5svc := appi5.Service{Runner: tx.Runner{DB: world.pool}, Store: progression, Content: content, Privileges: privileges, Functions: appi5.PetStarterFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{}, Backpack: progression, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: world.pool}}
	awarder := socialrecall.Awarder{Players: i4store.PlayerRootLocker{}, Owner: world.store, Content: content, Current: targets, Grants: i5svc}
	claim := socialrecall.ClaimService{
		Timed:         generation.TimedRunner{Binder: generation.Binder{Time: postgres.AuthoritativeTime{Queryer: world.pool}}, Runner: tx.Runner{DB: world.pool}},
		Fence:         progression,
		Players:       i4store.PlayerRootLocker{},
		Content:       content,
		Awarder:       awarder,
		Receipts:      kernelstore.Store{},
		ReceiptReader: kernelstore.Reader{Queryer: world.pool},
	}
	return claim, targets
}

func finishRecallTask(t *testing.T, world *recallWorld) {
	t.Helper()
	ctx := context.Background()
	transaction, err := world.pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	previous, exists, err := world.store.ReadActiveRecallForTargetTx(ctx, transaction, world.target)
	if err != nil || !exists {
		t.Fatalf("active task missing: %v %v", exists, err)
	}
	at := dbClock(t, world.pool)
	next := previous
	next.Task, _, err = previous.Task.Complete(at)
	if err != nil || next.Task.Status != domain.StatusCompleted {
		t.Fatalf("complete task: %v %v", next.Task.Status, err)
	}
	next.StateVersion++
	next.UpdatedAt = at.UTC()
	if err := world.store.SaveRecallLoginTransitionTx(ctx, transaction, previous, next); err != nil {
		t.Fatal(err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}

// ensureClaimEconomy writes the caller's canonical I5 roots the grant owner
// requires. The recall owner itself never creates economy state.
func ensureClaimEconomy(t *testing.T, world *recallWorld) {
	t.Helper()
	ctx := context.Background()
	for _, statement := range []string{
		`INSERT INTO player_economy_owners(player_id,state_version,created_at) VALUES($1,1,clock_timestamp()) ON CONFLICT(player_id) DO NOTHING`,
		`INSERT INTO player_progression(player_id,level,exp,state_version,updated_at) VALUES($1,1,0,1,clock_timestamp()) ON CONFLICT(player_id) DO NOTHING`,
		`INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at) VALUES($1,'crystal',1000,1,clock_timestamp()) ON CONFLICT(player_id,resource_key) DO NOTHING`,
	} {
		if _, err := world.pool.Raw().Exec(ctx, statement, int64(world.caller)); err != nil {
			t.Fatal(err)
		}
	}
}

func startRecallTask(t *testing.T, world *recallWorld) {
	t.Helper()
	if _, err := world.service.Start(context.Background(), world.actor, world.target, operationFor(t)); err != nil {
		t.Fatal(err)
	}
}

func bodyInteger(t *testing.T, value any) int64 {
	t.Helper()
	number, ok := value.(json.Number)
	if !ok {
		t.Fatalf("body value is not a JSON number: %#v", value)
	}
	result, err := number.Int64()
	if err != nil {
		t.Fatal(err)
	}
	return result
}

func countRecallRows(t *testing.T, world *recallWorld, awardID int64) (markers, receipts int) {
	t.Helper()
	if err := world.pool.Raw().QueryRow(context.Background(), `SELECT (SELECT count(*) FROM social_recall_awards WHERE player_id=$1 AND award_id=$2),(SELECT count(*) FROM gxb_operation_receipts WHERE owner_kind='player' AND owner_key=$3 AND domain='socialrecall' AND operation='award' AND semantic_key=$4)`, int64(world.caller), awardID, strconv.FormatInt(int64(world.caller), 10), strconv.FormatInt(awardID, 10)).Scan(&markers, &receipts); err != nil {
		t.Fatal(err)
	}
	return markers, receipts
}

func crystalAmount(t *testing.T, world *recallWorld) int64 {
	t.Helper()
	var amount int64
	if err := world.pool.Raw().QueryRow(context.Background(), `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'`, int64(world.caller)).Scan(&amount); err != nil {
		t.Fatal(err)
	}
	return amount
}

func itemAmount(t *testing.T, world *recallWorld, itemID int64) int64 {
	t.Helper()
	var amount int64
	if err := world.pool.Raw().QueryRow(context.Background(), `SELECT COALESCE((SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=$2),0)`, int64(world.caller), itemID).Scan(&amount); err != nil {
		t.Fatal(err)
	}
	return amount
}

func TestRecallClaimReceiptReplayCorruptionAndRefusalNative(t *testing.T) {
	pool := openRecallStartPool(t)
	ctx, _ := changes.Track(context.Background())
	world := seedRecallWorld(t, pool, 131001, 131002, [2]string{"Claimer131001", "Target131002"})
	ensureClaimEconomy(t, world)
	startRecallTask(t, world)
	finishRecallTask(t, world)
	claim, _ := recallClaimHarness(world)
	initial := crystalAmount(t, world)

	first, err := claim.Claim(ctx, world.actor, 100001, operationFor(t))
	if err != nil {
		t.Fatalf("first claim: %v", err)
	}
	awarded, ok := first["recall_awarded"].([]any)
	if !ok || len(awarded) != 1 || bodyInteger(t, awarded[0]) != 100001 {
		t.Fatalf("recall_awarded shape: %#v", first)
	}
	rows, ok := first["awards"].([]any)
	if !ok || len(rows) != 1 {
		t.Fatalf("awards shape: %#v", first)
	}
	row := rows[0].(map[string]any)
	if bodyInteger(t, row["table_id"]) != -1 || bodyInteger(t, row["item_num"]) != 50 || bodyInteger(t, row["crystal"]) != 50 {
		t.Fatalf("crystal row: %#v", row)
	}
	if bodyInteger(t, first["economy_"].(map[string]any)["crystal"]) != initial+50 || crystalAmount(t, world) != initial+50 {
		t.Fatalf("frozen/actual crystal mismatch: %#v %d", first["economy_"], crystalAmount(t, world))
	}
	markers, receipts := countRecallRows(t, world, 100001)
	if markers != 1 || receipts != 1 {
		t.Fatalf("claim effects: %d %d", markers, receipts)
	}

	activation := readRecallActivation(t, pool)
	removeRecallActivation(t, pool)
	replayed, err := claim.Claim(ctx, world.actor, 100001, operationFor(t))
	if err != nil {
		t.Fatalf("retry after content removal did not recover receipt: %v", err)
	}
	firstJSON, _ := json.Marshal(first)
	replayJSON, _ := json.Marshal(replayed)
	if string(firstJSON) != string(replayJSON) {
		t.Fatalf("replay changed frozen reply: %s vs %s", firstJSON, replayJSON)
	}
	restoreRecallActivation(t, pool, activation)

	if _, err := pool.Raw().Exec(ctx, `DELETE FROM gxb_operation_receipts WHERE owner_kind='player' AND owner_key=$1 AND domain='socialrecall' AND operation='award' AND semantic_key='100001'`, strconv.FormatInt(int64(world.caller), 10)); err != nil {
		t.Fatal(err)
	}
	if _, err := claim.Claim(ctx, world.actor, 100001, operationFor(t)); !errors.Is(err, socialrecall.ErrAwardProof) {
		t.Fatalf("marker without receipt was not proof corruption: %v", err)
	}

	refusedWorld := seedRecallWorld(t, pool, 131011, 131012, [2]string{"Claimer131011", "Target131012"})
	ensureClaimEconomy(t, refusedWorld)
	startRecallTask(t, refusedWorld)
	refusedClaim, _ := recallClaimHarness(refusedWorld)
	refusedBalance := crystalAmount(t, refusedWorld)
	if _, err := refusedClaim.Claim(ctx, refusedWorld.actor, 100001, operationFor(t)); !errors.Is(err, socialrecall.ErrAwardRefused) {
		t.Fatalf("premature claim was not refused: %v", err)
	}
	if markers, receipts := countRecallRows(t, refusedWorld, 100001); markers != 0 || receipts != 0 {
		t.Fatalf("refusal consumed the success key: %d %d", markers, receipts)
	}
	finishRecallTask(t, refusedWorld)
	if _, err := refusedClaim.Claim(ctx, refusedWorld.actor, 100001, operationFor(t)); err != nil {
		t.Fatalf("later eligibility was blocked: %v", err)
	}
	if crystalAmount(t, refusedWorld) != refusedBalance+50 {
		t.Fatalf("later claim did not grant once: %d", crystalAmount(t, refusedWorld))
	}

	failureWorld := seedRecallWorld(t, pool, 131091, 131092, [2]string{"Claimer131091", "Target131092"})
	ensureClaimEconomy(t, failureWorld)
	startRecallTask(t, failureWorld)
	finishRecallTask(t, failureWorld)
	failureClaim, _ := recallClaimHarness(failureWorld)
	failureClaim.Receipts = recallFailingReceipts{inner: kernelstore.Store{}, failPut: true}
	failureBalance := crystalAmount(t, failureWorld)
	if _, err := failureClaim.Claim(ctx, failureWorld.actor, 100001, operationFor(t)); err == nil {
		t.Fatal("receipt write failure was accepted")
	}
	if markers, receipts := countRecallRows(t, failureWorld, 100001); markers != 0 || receipts != 0 {
		t.Fatalf("failed receipt write left marker or receipt: %d %d", markers, receipts)
	}
	if crystalAmount(t, failureWorld) != failureBalance {
		t.Fatal("failed receipt write left the I5 grant")
	}
}

func TestRecallClaimScalarItemAndConcurrentOnceGrantNative(t *testing.T) {
	pool := openRecallStartPool(t)
	ctx := context.Background()
	world := seedRecallWorld(t, pool, 131021, 131022, [2]string{"Claimer131021", "Target131022"})
	ensureClaimEconomy(t, world)
	startRecallTask(t, world)
	finishRecallTask(t, world)
	claim, _ := recallClaimHarness(world)
	if _, err := pool.Raw().Exec(ctx, `UPDATE player_progression SET level=95,state_version=state_version+1,updated_at=clock_timestamp() WHERE player_id=$1`, int64(world.target)); err != nil {
		t.Fatal(err)
	}
	crystalBefore, firstItemBefore, secondItemBefore := crystalAmount(t, world), itemAmount(t, world, 50001011), itemAmount(t, world, 50001173)
	body, err := claim.Claim(ctx, world.actor, 100005, operationFor(t))
	if err != nil {
		t.Fatalf("scalar+item claim: %v", err)
	}
	if len(body["awards"].([]any)) != 3 || crystalAmount(t, world) != crystalBefore+100 || itemAmount(t, world, 50001011) != firstItemBefore+5 || itemAmount(t, world, 50001173) != secondItemBefore+1 {
		t.Fatalf("scalar+item effect: %#v %d %d %d", body["awards"], crystalAmount(t, world), itemAmount(t, world, 50001011), itemAmount(t, world, 50001173))
	}

	competing := seedRecallWorld(t, pool, 131031, 131032, [2]string{"Claimer131031", "Target131032"})
	ensureClaimEconomy(t, competing)
	startRecallTask(t, competing)
	finishRecallTask(t, competing)
	competingClaim, _ := recallClaimHarness(competing)
	competingBalance := crystalAmount(t, competing)
	var wait sync.WaitGroup
	outcomes := make(chan error, 2)
	for index := 0; index < 2; index++ {
		wait.Add(1)
		go func() {
			defer wait.Done()
			_, err := competingClaim.Claim(ctx, competing.actor, 100001, operationFor(t))
			outcomes <- err
		}()
	}
	wait.Wait()
	close(outcomes)
	successes, refusals := 0, 0
	for err := range outcomes {
		switch {
		case err == nil:
			successes++
		case errors.Is(err, socialrecall.ErrAwardRefused):
			refusals++
		default:
			t.Fatalf("competing claim: %v", err)
		}
	}
	if successes < 1 || successes+refusals != 2 {
		t.Fatalf("competing outcomes: %d %d", successes, refusals)
	}
	if markers, receipts := countRecallRows(t, competing, 100001); markers != 1 || receipts != 1 {
		t.Fatalf("concurrent marker/receipt: %d %d", markers, receipts)
	}
	if crystalAmount(t, competing) != competingBalance+50 {
		t.Fatalf("concurrent grant was not once-only: %d", crystalAmount(t, competing))
	}
}

func TestRecallClaimRootLockWaitAndUnknownCommitNative(t *testing.T) {
	pool := openRecallStartPool(t)
	ctx := context.Background()
	world := seedRecallWorld(t, pool, 131041, 131042, [2]string{"Claimer131041", "Target131042"})
	ensureClaimEconomy(t, world)
	startRecallTask(t, world)
	finishRecallTask(t, world)
	claim, _ := recallClaimHarness(world)

	holder, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer holder.Rollback(ctx)
	var holderPID int32
	if err := holder.QueryRow(ctx, `SELECT pg_backend_pid()`).Scan(&holderPID); err != nil {
		t.Fatal(err)
	}
	var locked int64
	if err := holder.QueryRow(ctx, `SELECT player_id FROM players WHERE player_id=$1 FOR UPDATE`, int64(world.caller)).Scan(&locked); err != nil {
		t.Fatal(err)
	}
	done := make(chan error, 1)
	go func() {
		_, err := claim.Claim(context.Background(), world.actor, 100001, operationFor(t))
		done <- err
	}()
	waitClaimBlocked(t, pool, holderPID, 10*time.Second)
	if err := holder.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if err := <-done; err != nil {
		t.Fatalf("claim after lock release: %v", err)
	}
	if markers, receipts := countRecallRows(t, world, 100001); markers != 1 || receipts != 1 {
		t.Fatalf("locked claim effects: %d %d", markers, receipts)
	}

	recoveryWorld := seedRecallWorld(t, pool, 131051, 131052, [2]string{"Claimer131051", "Target131052"})
	ensureClaimEconomy(t, recoveryWorld)
	startRecallTask(t, recoveryWorld)
	finishRecallTask(t, recoveryWorld)
	recoveryClaim, _ := recallClaimHarness(recoveryWorld)
	recoveryBalance := crystalAmount(t, recoveryWorld)
	fault := &recallCommitFault{inner: recoveryWorld.pool, deliverCommit: true}
	recoveryClaim.Timed.Runner.DB = fault
	if _, err := recoveryClaim.Claim(ctx, recoveryWorld.actor, 100001, operationFor(t)); err != nil {
		t.Fatalf("unknown-commit recovery: %v", err)
	}
	if markers, receipts := countRecallRows(t, recoveryWorld, 100001); markers != 1 || receipts != 1 || fault.begins.Load() != 1 {
		t.Fatalf("unknown-commit recovery duplicated effects: %d %d %d", markers, receipts, fault.begins.Load())
	}
	if crystalAmount(t, recoveryWorld) != recoveryBalance+50 {
		t.Fatal("unknown-commit recovery did not pay exactly once")
	}

	absentWorld := seedRecallWorld(t, pool, 131061, 131062, [2]string{"Claimer131061", "Target131062"})
	ensureClaimEconomy(t, absentWorld)
	startRecallTask(t, absentWorld)
	finishRecallTask(t, absentWorld)
	absentClaim, _ := recallClaimHarness(absentWorld)
	absentBalance := crystalAmount(t, absentWorld)
	absentFault := &recallCommitFault{inner: absentWorld.pool, deliverCommit: false}
	absentClaim.Timed.Runner.DB = absentFault
	if _, err := absentClaim.Claim(ctx, absentWorld.actor, 100001, operationFor(t)); !errors.As(err, new(*tx.UnknownCommitError)) {
		t.Fatalf("absent receipt did not stay UNKNOWN: %v", err)
	}
	if markers, receipts := countRecallRows(t, absentWorld, 100001); markers != 0 || receipts != 0 {
		t.Fatalf("ambiguous commit left effects: %d %d", markers, receipts)
	}
	if crystalAmount(t, absentWorld) != absentBalance {
		t.Fatal("ambiguous commit paid value")
	}
}

func waitClaimBlocked(t *testing.T, pool *postgres.Pool, holderPID int32, timeout time.Duration) {
	t.Helper()
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		var blocked int32
		err := pool.Raw().QueryRow(context.Background(), `SELECT pid FROM pg_stat_activity WHERE wait_event_type='Lock' AND $1=ANY(pg_blocking_pids(pid)) LIMIT 1`, holderPID).Scan(&blocked)
		if err == nil && blocked != 0 {
			t.Logf("observed PostgreSQL row-lock contention: holder=%d blocked=%d", holderPID, blocked)
			return
		}
		time.Sleep(10 * time.Millisecond)
	}
	t.Fatalf("bounded wait graph did not show holder=%d blocking a claim", holderPID)
}

func TestRecallProjectionReaderNative(t *testing.T) {
	pool := openRecallStartPool(t)
	ctx := context.Background()
	world := seedRecallWorld(t, pool, 131071, 131072, [2]string{"Claimer131071", "Target131072"})
	ensureClaimEconomy(t, world)
	startRecallTask(t, world)
	finishRecallTask(t, world)
	claim, targets := recallClaimHarness(world)
	if _, err := claim.Claim(ctx, world.actor, 100001, operationFor(t)); err != nil {
		t.Fatal(err)
	}
	reader := socialrecallstore.RecallProjectionReader{Current: targets}
	op, err := socialrecall.BindRecallPolicies(operationFor(t), world.revision)
	if err != nil {
		t.Fatal(err)
	}
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	at := dbClock(t, pool)
	// The completed target's current facts must be observable at a re-read time.
	base, err := reader.ReadRecallBaseTx(ctx, tx.Scope{Tx: transaction, Operation: op, Attempt: 1, Options: tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}}, world.actor, world.revision, at, []identity.PlayerID{world.target})
	if err != nil {
		t.Fatalf("recall reload read: %v", err)
	}
	if len(base.Got) != 1 || base.Got[0] != world.target || len(base.Awarded) != 1 || base.Awarded[0] != 100001 {
		t.Fatalf("got/awarded: %+v", base)
	}
	if len(base.Recalling) != 0 || len(base.Doing) != 0 {
		t.Fatalf("terminal task leaked into active view: %+v", base)
	}
	if len(base.Done) != 1 || base.Done[0].PlayerID != world.target || base.Done[0].Baseline.AcademyLevel != 51 || base.Done[0].Current.AcademyLevel != 51 || base.Done[0].Baseline.ChargeTotal != 100 {
		t.Fatalf("done row: %+v", base.Done)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}

func TestRecallMID194HTTPThroughProductionDispatcher(t *testing.T) {
	pool := openRecallStartPool(t)
	ctx := context.Background()
	world := seedRecallWorld(t, pool, 134011, 134012, [2]string{"Caller134011", "Target134012"})
	ensureClaimEconomy(t, world)
	startRecallTask(t, world)
	finishRecallTask(t, world)
	claim, _ := recallClaimHarness(world)
	secret := []byte("social62-native-http-secret-0123456789")
	gameplayContext := identity.GameplayContext{ID: world.actor.ContextID, SessionID: world.actor.SessionID, AccountID: world.actor.AccountID, LogicalServerID: 1, PlayerID: world.caller, ContextGeneration: 1}
	bearer, err := identity.DeriveGameplayBearer(secret, gameplayContext)
	if err != nil {
		t.Fatal(err)
	}
	digest, err := identity.DigestGameplayBearer(secret, bearer)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO gameplay_context_credentials(credential_id,context_id,session_id,digest,credential_generation,derivation_key_id,issued_at) VALUES($1,$2,$3,$4,1,'social62-v1',now())`, mustUUID(t).String(), world.actor.ContextID.UUID().String(), world.actor.SessionID.UUID().String(), digest[:]); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		_, _ = pool.Raw().Exec(context.Background(), `DELETE FROM gameplay_context_credentials WHERE context_id=$1::uuid`, world.actor.ContextID.UUID().String())
	})
	authority := i4store.RealtimeAuthority{Queryer: pool, DigestSecret: secret, BearerSecret: secret, DerivationKeyID: "social62-v1"}
	router := httpedge.NewRouter()
	if err := router.Register(194, stockruntime.SocialRecallAwardDispatcher{Authority: authority, Service: claim}); err != nil {
		t.Fatal(err)
	}
	admission, err := httpedge.NewAdmission(8)
	if err != nil {
		t.Fatal(err)
	}
	handler := httpedge.Handler{Limits: limits.Default(), Admission: admission, Operations: operation.Factory{Clock: clock.System{}}, Router: router}
	post := func(parameters map[string]any) (*httptest.ResponseRecorder, map[string]any) {
		parameters["mid"] = 194
		parameters["token"] = bearer
		parameters["region"] = int64(1)
		payload, err := json.Marshal(parameters)
		if err != nil {
			t.Fatal(err)
		}
		request := httptest.NewRequest(http.MethodPost, "/", strings.NewReader("payload="+url.QueryEscape(string(payload))))
		request.Header.Set("Content-Type", "application/x-www-form-urlencoded")
		response := httptest.NewRecorder()
		handler.ServeHTTP(response, request)
		var body map[string]any
		if response.Body.Len() > 0 {
			if err := json.Unmarshal(response.Body.Bytes(), &body); err != nil {
				t.Fatalf("decode HTTP body %q: %v", response.Body.String(), err)
			}
		}
		return response, body
	}
	response, body := post(map[string]any{"award_id": int64(100001)})
	if response.Code != http.StatusOK || body["error_code"] != nil || body["recall_awarded"] == nil || body["awards"] == nil {
		t.Fatalf("MID194 success: %d %s", response.Code, response.Body.String())
	}
	firstJSON, _ := json.Marshal(body)
	activation := readRecallActivation(t, pool)
	removeRecallActivation(t, pool)
	replayed, replayBody := post(map[string]any{"award_id": int64(100001)})
	restoreRecallActivation(t, pool, activation)
	secondJSON, _ := json.Marshal(replayBody)
	if replayed.Code != http.StatusOK || string(firstJSON) != string(secondJSON) {
		t.Fatalf("MID194 replay changed reply: %d %s vs %s", replayed.Code, firstJSON, secondJSON)
	}
	malformed, _ := post(map[string]any{"award_id": 1.5})
	if malformed.Code != http.StatusBadRequest {
		t.Fatalf("MID194 malformed award: %d", malformed.Code)
	}
	refused, refusedBody := post(map[string]any{"award_id": int64(100025)})
	if refused.Code != http.StatusConflict || refusedBody["awards"] != nil || refusedBody["error_code"] == nil {
		t.Fatalf("MID194 business refusal: %d %s", refused.Code, refused.Body.String())
	}
}
