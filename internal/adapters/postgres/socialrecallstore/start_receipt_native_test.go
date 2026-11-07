//go:build postgres

package socialrecallstore_test

import (
	"context"
	"errors"
	"fmt"
	"reflect"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/application/socialrecall"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/socialrecall"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type recallActivation struct {
	revision    string
	version     int64
	activatedAt time.Time
	activatedBy string
}

func readRecallActivation(t *testing.T, pool *postgres.Pool) recallActivation {
	t.Helper()
	var out recallActivation
	if err := pool.Raw().QueryRow(context.Background(), `SELECT revision_id,activation_version,activated_at,activated_by FROM gxb_content_activation WHERE slot='content'`).Scan(&out.revision, &out.version, &out.activatedAt, &out.activatedBy); err != nil {
		t.Fatal(err)
	}
	return out
}

func restoreRecallActivation(t *testing.T, pool *postgres.Pool, activation recallActivation) {
	t.Helper()
	if _, err := pool.Raw().Exec(context.Background(), `INSERT INTO gxb_content_activation(slot,revision_id,activation_version,activated_at,activated_by) VALUES('content',$1,$2,$3,$4) ON CONFLICT(slot) DO UPDATE SET revision_id=EXCLUDED.revision_id,activation_version=EXCLUDED.activation_version,activated_at=EXCLUDED.activated_at,activated_by=EXCLUDED.activated_by`, activation.revision, activation.version, activation.activatedAt, activation.activatedBy); err != nil {
		t.Fatal(err)
	}
}

func removeRecallActivation(t *testing.T, pool *postgres.Pool) {
	t.Helper()
	if _, err := pool.Raw().Exec(context.Background(), `DELETE FROM gxb_content_activation WHERE slot='content'`); err != nil {
		t.Fatal(err)
	}
}

func TestRecallStartReceiptReplayAndUnknownCommitNative(t *testing.T) {
	pool := openRecallStartPool(t)
	ctx := context.Background()
	world := seedRecallWorld(t, pool, 130011, 130012, [2]string{"Caller130011", "Target130012"})
	current := operationFor(t)
	first, err := world.service.Start(ctx, world.actor, world.target, current)
	if err != nil {
		t.Fatal(err)
	}
	var taskCount, receiptCount int
	if err := pool.Raw().QueryRow(ctx, `SELECT (SELECT count(*) FROM social_recall_tasks WHERE caller_player_id=$1),(SELECT count(*) FROM gxb_operation_receipts WHERE owner_key=$2)`, int64(world.caller), stringifyPlayer(world.caller)).Scan(&taskCount, &receiptCount); err != nil {
		t.Fatal(err)
	}
	if taskCount != 1 || receiptCount != 1 {
		t.Fatalf("success did not commit task+reply together: %d %d", taskCount, receiptCount)
	}

	activation := readRecallActivation(t, pool)
	removeRecallActivation(t, pool)
	replayed, err := world.service.Start(ctx, world.actor, world.target, current)
	if err != nil {
		t.Fatalf("retry after content removal did not recover terminal receipt: %v", err)
	}
	if !reflect.DeepEqual(first, replayed) {
		t.Fatalf("replay changed terminal reply: %#v vs %#v", first, replayed)
	}
	var conflict *receipt.ConflictError
	if _, err := world.service.Start(ctx, world.actor, 130013, current); !errors.As(err, &conflict) {
		t.Fatalf("changed target under one semantic operation was not a conflict: %v", err)
	}
	restoreRecallActivation(t, pool, activation)

	commitWorld := seedRecallWorld(t, pool, 130021, 130022, [2]string{"Caller130021", "Target130022"})
	if err := assertRecallUnknownCommitRecovery(t, commitWorld); err != nil {
		t.Fatal(err)
	}
	absentWorld := seedRecallWorld(t, pool, 130031, 130032, [2]string{"Caller130031", "Target130032"})
	if err := assertRecallUnknownCommitAbsence(t, absentWorld); err != nil {
		t.Fatal(err)
	}
}

func assertRecallUnknownCommitRecovery(t *testing.T, world *recallWorld) error {
	t.Helper()
	ctx := context.Background()
	database := &recallCommitFault{inner: world.pool, deliverCommit: true}
	world.service.Timed.Runner.DB = database
	current := operationFor(t)
	body, err := world.service.Start(ctx, world.actor, world.target, current)
	if err != nil {
		return err
	}
	if rows, ok := body["doing_recall"].([]any); !ok || len(rows) != 1 {
		return errors.New("reconciled commit returned no doing_recall")
	}
	var tasks, receipts int
	if err := world.pool.Raw().QueryRow(ctx, `SELECT (SELECT count(*) FROM social_recall_tasks WHERE operation_id=$1::uuid),(SELECT count(*) FROM gxb_operation_receipts WHERE semantic_key=$2)`, current.ID.String(), current.ID.String()).Scan(&tasks, &receipts); err != nil {
		return err
	}
	if tasks != 1 || receipts != 1 || database.begins.Load() != 1 {
		return errors.New("unknown-commit recovery duplicated or lost the terminal effect")
	}
	return nil
}

func assertRecallUnknownCommitAbsence(t *testing.T, world *recallWorld) error {
	t.Helper()
	ctx := context.Background()
	database := &recallCommitFault{inner: world.pool, deliverCommit: false}
	world.service.Timed.Runner.DB = database
	current := operationFor(t)
	_, err := world.service.Start(ctx, world.actor, world.target, current)
	if err == nil {
		return errors.New("absent receipt was treated as replay permission")
	}
	var unknown *tx.UnknownCommitError
	if !errors.As(err, &unknown) {
		return fmt.Errorf("absent receipt did not stay UNKNOWN: %w", err)
	}
	var tasks, receipts int
	if err := world.pool.Raw().QueryRow(ctx, `SELECT (SELECT count(*) FROM social_recall_tasks WHERE operation_id=$1::uuid),(SELECT count(*) FROM gxb_operation_receipts WHERE semantic_key=$2)`, current.ID.String(), current.ID.String()).Scan(&tasks, &receipts); err != nil {
		return err
	}
	if tasks != 0 || receipts != 0 {
		return errors.New("ambiguous rollback left task or receipt")
	}
	if database.begins.Load() != 1 {
		return errors.New("unknown commit body was replayed without evidence")
	}
	return nil
}

// recallCommitFault wraps the real PostgreSQL beginner. It injects only the
// ambiguous COMMIT outcome; every statement still runs on a real transaction.
type recallCommitFault struct {
	inner          tx.Beginner
	deliverCommit  bool
	commitError    error
	begins         atomic.Int32
	deliveredError error
}

func (fault *recallCommitFault) Begin(ctx context.Context, options tx.Options) (tx.Tx, error) {
	fault.begins.Add(1)
	inner, err := fault.inner.Begin(ctx, options)
	if err != nil {
		return nil, err
	}
	if fault.commitError == nil {
		fault.commitError = errors.New("injected unknown commit outcome")
	}
	return &recallCommitFaultTx{Tx: inner, deliverCommit: fault.deliverCommit, commitError: fault.commitError}, nil
}

type recallCommitFaultTx struct {
	tx.Tx
	deliverCommit bool
	commitError   error
}

func (transaction *recallCommitFaultTx) Commit(ctx context.Context) error {
	if !transaction.deliverCommit {
		return transaction.commitError
	}
	if err := transaction.Tx.Commit(ctx); err != nil {
		return err
	}
	return transaction.commitError
}

type recallFailingReceipts struct {
	inner   kernelstore.Store
	failPut bool
}

func (store recallFailingReceipts) FindTx(ctx context.Context, query tx.Queryer, id receipt.Identity) (receipt.Receipt, bool, error) {
	return store.inner.FindTx(ctx, query, id)
}

func (store recallFailingReceipts) PutTx(ctx context.Context, transaction tx.Tx, value receipt.Receipt) (receipt.PutResult, error) {
	if store.failPut {
		return receipt.PutResult{}, errors.New("injected receipt put failure")
	}
	return store.inner.PutTx(ctx, transaction, value)
}

func TestRecallStartProjectionFailureRollsBackTaskAndReply(t *testing.T) {
	pool := openRecallStartPool(t)
	ctx := context.Background()
	world := seedRecallWorld(t, pool, 130041, 130042, [2]string{"Caller130041", "Target130042"})

	blockedTarget := identity.PlayerID(130043)
	for _, cleanup := range []string{
		`DELETE FROM player_directory_profiles WHERE player_id=130043`,
		`DELETE FROM players WHERE player_id=130043`,
		`DELETE FROM accounts WHERE account_uid LIKE 'social40-blocked-%'`,
	} {
		if _, err := pool.Raw().Exec(ctx, cleanup); err != nil {
			t.Fatal(err)
		}
	}
	blockedAccount := mustUUID(t)
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1,$2,'ACTIVE',now()-interval '1 hour')`, blockedAccount.String(), "social40-blocked-"+blockedAccount.String()); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2,1,now()-interval '1 hour','social40-native')`, int64(blockedTarget), blockedAccount.String()); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		_, _ = pool.Raw().Exec(context.Background(), `DELETE FROM player_directory_profiles WHERE player_id=$1`, int64(blockedTarget))
		_, _ = pool.Raw().Exec(context.Background(), `DELETE FROM players WHERE player_id=$1`, int64(blockedTarget))
		_, _ = pool.Raw().Exec(context.Background(), `DELETE FROM accounts WHERE account_id=$1`, blockedAccount.String())
	})
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO player_directory_profiles(player_id,name,lev,created_at,updated_at) VALUES($1,'',51,now()-interval '1 hour',now()-interval '1 hour')`, int64(blockedTarget)); err != nil {
		t.Fatal(err)
	}
	blockedOperation, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	startedAt := dbClock(t, pool).Add(-2 * time.Hour)
	blockedTask, err := domain.NewTask(world.caller, blockedTarget, 1, blockedOperation, startedAt, 72*time.Hour, domain.Baseline{})
	if err != nil {
		t.Fatal(err)
	}
	blockedRecord := socialrecall.TaskRecord{Task: blockedTask, StateVersion: 1, UpdatedAt: startedAt, ContentRevision: strings.Repeat("a", 64), PolicyVersion: socialrecall.RecallPolicyVersion}
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if err := world.store.InsertTaskTx(ctx, transaction, blockedRecord); err != nil {
		_ = transaction.Rollback(ctx)
		t.Fatal(err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		_, _ = pool.Raw().Exec(context.Background(), `DELETE FROM social_recall_tasks WHERE operation_id=$1::uuid`, blockedOperation.String())
	})

	current := operationFor(t)
	if _, err := world.service.Start(ctx, world.actor, world.target, current); !errors.Is(err, socialrecall.ErrStartFacts) {
		t.Fatalf("real projection failure did not roll back the command: %v", err)
	}
	var tasks, receipts int
	if err := pool.Raw().QueryRow(ctx, `SELECT (SELECT count(*) FROM social_recall_tasks WHERE operation_id=$1::uuid),(SELECT count(*) FROM gxb_operation_receipts WHERE semantic_key=$2)`, current.ID.String(), current.ID.String()).Scan(&tasks, &receipts); err != nil {
		t.Fatal(err)
	}
	if tasks != 0 || receipts != 0 {
		t.Fatalf("projection failure left terminal effects: %d %d", tasks, receipts)
	}
	var retained int
	if err := pool.Raw().QueryRow(ctx, `SELECT count(*) FROM social_recall_tasks WHERE operation_id=$1::uuid AND status='ACTIVE'`, blockedOperation.String()).Scan(&retained); err != nil || retained != 1 {
		t.Fatalf("pre-existing active task was not preserved: %d %v", retained, err)
	}
}

func TestRecallStartReceiptPutFailureRollsBackTaskAndReply(t *testing.T) {
	pool := openRecallStartPool(t)
	ctx := context.Background()
	world := seedRecallWorld(t, pool, 130051, 130052, [2]string{"Caller130051", "Target130052"})
	world.service.Receipts = recallFailingReceipts{inner: kernelstore.Store{}, failPut: true}
	current := operationFor(t)
	if _, err := world.service.Start(ctx, world.actor, world.target, current); err == nil {
		t.Fatal("terminal receipt write failure was accepted")
	}
	var tasks, receipts int
	if err := pool.Raw().QueryRow(ctx, `SELECT (SELECT count(*) FROM social_recall_tasks WHERE operation_id=$1::uuid),(SELECT count(*) FROM gxb_operation_receipts WHERE semantic_key=$2)`, current.ID.String(), current.ID.String()).Scan(&tasks, &receipts); err != nil {
		t.Fatal(err)
	}
	if tasks != 0 || receipts != 0 {
		t.Fatalf("failed receipt write left task or reply: %d %d", tasks, receipts)
	}
}

func TestRecallStartCountingBeginMatchesSuccessfulCommand(t *testing.T) {
	pool := openRecallStartPool(t)
	ctx := context.Background()
	world := seedRecallWorld(t, pool, 130061, 130062, [2]string{"Caller130061", "Target130062"})
	database := &recallBeginCounter{inner: pool}
	world.service.Timed.Runner.DB = database
	current := operationFor(t)
	if _, err := world.service.Start(ctx, world.actor, world.target, current); err != nil {
		t.Fatal(err)
	}
	if database.begins.Load() != 1 {
		t.Fatalf("successful start did not begin exactly one transaction: %d", database.begins.Load())
	}
	var status string
	if err := pool.Raw().QueryRow(ctx, `SELECT status FROM social_recall_tasks WHERE operation_id=$1::uuid`, current.ID.String()).Scan(&status); err != nil || status != "ACTIVE" {
		t.Fatalf("counted transaction did not commit the task: %s %v", status, err)
	}
}

type recallBeginCounter struct {
	inner  tx.Beginner
	begins atomic.Int32
}

func (counter *recallBeginCounter) Begin(ctx context.Context, options tx.Options) (tx.Tx, error) {
	counter.begins.Add(1)
	return counter.inner.Begin(ctx, options)
}
