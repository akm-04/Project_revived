//go:build postgres

package socialrecallstore_test

import (
	"context"
	"errors"
	"os"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrecallstore"
	application "gxb.local/backend/v2/internal/application/socialrecall"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/socialrecall"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestRecallOwnerTerminalReleaseRollbackAndCAS(t *testing.T) {
	dsn := os.Getenv("GXB_SOCIAL_RECALL_DSN")
	if dsn == "" {
		t.Skip("explicit own migrated PostgreSQL database required; skip is not native proof")
	}
	ctx := context.Background()
	pool, err := postgres.Open(ctx, dsn, postgres.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	seedRecallLoginPlayer(t, pool, 125001)
	seedRecallLoginPlayer(t, pool, 125002)
	seedRecallLoginPlayer(t, pool, 125003)
	store := socialrecallstore.Store{}
	at := time.Date(2026, 11, 5, 12, 0, 0, 0, time.UTC)
	record := func(caller identity.PlayerID) application.TaskRecord {
		operationID, err := ids.NewUUID()
		if err != nil {
			t.Fatal(err)
		}
		cleanupRecallTask(t, pool, operationID)
		task, err := domain.NewTask(caller, 125001, 1, operationID, at, time.Hour, domain.Baseline{AcademyLevel: 51, OwnedHeroCount: 3})
		if err != nil {
			t.Fatal(err)
		}
		return application.TaskRecord{Task: task, StateVersion: 1, UpdatedAt: at, ContentRevision: strings.Repeat("a", 64), PolicyVersion: "test-qualified-policy"}
	}
	begin := func() tx.Tx {
		transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
		if err != nil {
			t.Fatal(err)
		}
		t.Cleanup(func() { _ = transaction.Rollback(ctx) })
		return transaction
	}
	original := record(125002)
	transaction := begin()
	if err := store.InsertTaskTx(ctx, transaction, original); err != nil {
		t.Fatal(err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	competing := record(125003)
	transaction = begin()
	if err := store.InsertTaskTx(ctx, transaction, competing); err == nil {
		t.Fatal("two active callers reserved same target")
	}
	_ = transaction.Rollback(ctx)

	transaction = begin()
	loaded, exists, err := store.ReadActiveRecallForTargetTx(ctx, transaction, original.Task.Target)
	if err != nil || !exists || loaded.ContentRevision != original.ContentRevision {
		t.Fatal(loaded, exists, err)
	}
	next := loaded
	next.Task, _, err = loaded.Task.Complete(at.Add(time.Minute))
	if err != nil {
		t.Fatal(err)
	}
	next.StateVersion++
	next.UpdatedAt = at.Add(time.Minute)
	tampered := next
	tampered.Task.Baseline.OwnedHeroCount++
	if err := store.SaveRecallLoginTransitionTx(ctx, transaction, loaded, tampered); !errors.Is(err, application.ErrLoginFacts) {
		t.Fatal("baseline mutation accepted", err)
	}
	if err := store.SaveRecallLoginTransitionTx(ctx, transaction, loaded, next); err != nil {
		t.Fatal(err)
	}
	_ = transaction.Rollback(ctx)

	transaction = begin()
	if _, exists, err := store.ReadActiveRecallForTargetTx(ctx, transaction, original.Task.Target); err != nil || !exists {
		t.Fatal("rollback lost reservation", exists, err)
	}
	actor := identity.ActorContext{PlayerID: original.Task.Target, LogicalServerID: 1}
	current := operation.Context{ID: original.Task.OperationID, StartedAt: at.Add(time.Minute)}
	if err := (application.LoginReconciler{Owner: store, Players: i4store.PlayerRootLocker{}}).ReconcileCharacterLogin(ctx, transaction, actor, current, at.Add(time.Minute)); err != nil {
		t.Fatal(err)
	}
	if err := store.SaveRecallLoginTransitionTx(ctx, transaction, loaded, next); !errors.Is(err, socialrecallstore.ErrStateConflict) {
		t.Fatal("stale writer accepted", err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}

	transaction = begin()
	if err := store.SaveRecallLoginTransitionTx(ctx, transaction, loaded, next); !errors.Is(err, socialrecallstore.ErrStateConflict) {
		t.Fatal("committed stale writer accepted", err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}

	transaction = begin()
	if _, exists, err := store.ReadActiveRecallForTargetTx(ctx, transaction, original.Task.Target); err != nil || exists {
		t.Fatal("terminal task retained reservation", exists, err)
	}
	if err := store.InsertTaskTx(ctx, transaction, competing); err != nil {
		t.Fatal("reservation not released", err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	transaction = begin()
	if err := (application.LoginReconciler{Owner: store, Players: i4store.PlayerRootLocker{}}).ReconcileCharacterLogin(ctx, transaction, actor, current, at.Add(time.Hour)); err != nil {
		t.Fatal(err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var completed, expired int
	if err := pool.Raw().QueryRow(ctx, "SELECT count(*) FILTER (WHERE status='COMPLETED'),count(*) FILTER (WHERE status='EXPIRED') FROM social_recall_tasks WHERE target_player_id=$1", int64(original.Task.Target)).Scan(&completed, &expired); err != nil || completed != 1 || expired != 1 {
		t.Fatal(completed, expired, err)
	}
}

func TestRecallOwnerConcurrentReservationAndLogin(t *testing.T) {
	dsn := os.Getenv("GXB_SOCIAL_RECALL_DSN")
	if dsn == "" {
		t.Skip("explicit own migrated PostgreSQL database required; skip is not native proof")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	pool, err := postgres.Open(ctx, dsn, postgres.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	at := time.Date(2026, 11, 5, 12, 0, 0, 0, time.UTC)
	seedRecallLoginPlayer(t, pool, 125101)
	seedRecallLoginPlayer(t, pool, 125102)
	seedRecallLoginPlayer(t, pool, 125103)
	var records []application.TaskRecord
	for _, caller := range []identity.PlayerID{125102, 125103} {
		operationID, err := ids.NewUUID()
		if err != nil {
			t.Fatal(err)
		}
		cleanupRecallTask(t, pool, operationID)
		task, err := domain.NewTask(caller, 125101, 1, operationID, at, time.Hour, domain.Baseline{AcademyLevel: 51})
		if err != nil {
			t.Fatal(err)
		}
		records = append(records, application.TaskRecord{Task: task, StateVersion: 1, UpdatedAt: at, ContentRevision: strings.Repeat("b", 64), PolicyVersion: "test-qualified-policy"})
	}
	store := socialrecallstore.Store{}
	start := make(chan struct{})
	results := make(chan error, 2)
	for _, record := range records {
		go func(record application.TaskRecord) {
			<-start
			transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
			if err != nil {
				results <- err
				return
			}
			defer transaction.Rollback(ctx)
			if err = store.InsertTaskTx(ctx, transaction, record); err == nil {
				err = transaction.Commit(ctx)
			}
			results <- err
		}(record)
	}
	close(start)
	successes, conflicts := 0, 0
	for range records {
		err := <-results
		if err == nil {
			successes++
			continue
		}
		var postgresState interface{ SQLState() string }
		if !errors.As(err, &postgresState) || postgresState.SQLState() != "23505" {
			t.Fatal("reservation failed for unrelated reason", err)
		}
		conflicts++
	}
	if successes != 1 || conflicts != 1 {
		t.Fatal("reservation did not select exactly one caller", successes, conflicts)
	}
	start = make(chan struct{})
	for _, record := range records {
		go func(record application.TaskRecord) {
			<-start
			transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
			if err != nil {
				results <- err
				return
			}
			defer transaction.Rollback(ctx)
			actor := identity.ActorContext{PlayerID: 125101, LogicalServerID: 1}
			current := operation.Context{ID: record.Task.OperationID, StartedAt: at.Add(time.Minute)}
			err = (application.LoginReconciler{Owner: store, Players: i4store.PlayerRootLocker{}}).ReconcileCharacterLogin(ctx, transaction, actor, current, at.Add(time.Minute))
			if err == nil {
				err = transaction.Commit(ctx)
			}
			results <- err
		}(record)
	}
	close(start)
	for range records {
		if err := <-results; err != nil {
			t.Fatal("concurrent login failed", err)
		}
	}
	var completed int
	var stateVersion int64
	if err := pool.Raw().QueryRow(ctx, "SELECT count(*),max(state_version) FROM social_recall_tasks WHERE target_player_id=125101 AND status='COMPLETED'").Scan(&completed, &stateVersion); err != nil || completed != 1 || stateVersion != 2 {
		t.Fatal("completion was not exactly once", completed, stateVersion, err)
	}
}

func cleanupRecallTask(t *testing.T, pool *postgres.Pool, operationID ids.UUID) {
	t.Helper()
	t.Cleanup(func() {
		cleanupContext, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		if _, err := pool.Raw().Exec(cleanupContext, "DELETE FROM social_recall_tasks WHERE operation_id=$1", operationID.String()); err != nil {
			t.Error("remove test-owned task", err)
		}
	})
}

func TestRecallOwnerSerializableLoginRetries(t *testing.T) {
	databaseURL := os.Getenv("GXB_SOCIAL_RECALL_DSN")
	if databaseURL == "" {
		t.Skip("explicit own migrated PostgreSQL database required; skip is not native proof")
	}
	requestContext, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	pool, err := postgres.Open(requestContext, databaseURL, postgres.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	seedRecallLoginPlayer(t, pool, 125201)
	seedRecallLoginPlayer(t, pool, 125202)
	operationID, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	cleanupRecallTask(t, pool, operationID)
	at := time.Date(2026, 11, 5, 12, 0, 0, 0, time.UTC)
	task, err := domain.NewTask(125202, 125201, 1, operationID, at, time.Hour, domain.Baseline{})
	if err != nil {
		t.Fatal(err)
	}
	store := socialrecallstore.Store{}
	transaction, err := pool.Begin(requestContext, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(context.Background())
	record := application.TaskRecord{Task: task, StateVersion: 1, UpdatedAt: at, ContentRevision: strings.Repeat("c", 64), PolicyVersion: "test-qualified-policy"}
	if err = store.InsertTaskTx(requestContext, transaction, record); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(requestContext); err != nil {
		t.Fatal(err)
	}
	ready := make(chan struct{}, 2)
	release := make(chan struct{})
	type outcome struct {
		result  tx.Result
		failure error
	}
	results := make(chan outcome, 2)
	for range 2 {
		loginID, err := ids.NewUUID()
		if err != nil {
			t.Fatal(err)
		}
		go func(loginID ids.UUID) {
			current := operation.Context{ID: loginID, StartedAt: at.Add(time.Minute)}
			result, failure := (tx.Runner{DB: pool}).Run(requestContext, current, i4store.DefaultI4Profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, AllowReplayAfterAuthoritativeNegative: true}, nil, func(callContext context.Context, scope tx.Scope) error {
				if scope.Attempt == 1 {
					var count int
					if err := scope.Tx.QueryRow(callContext, "SELECT count(*) FROM social_recall_tasks WHERE target_player_id=$1", int64(task.Target)).Scan(&count); err != nil {
						return err
					}
					ready <- struct{}{}
					select {
					case <-release:
					case <-callContext.Done():
						return callContext.Err()
					}
				}
				actor := identity.ActorContext{PlayerID: task.Target, LogicalServerID: 1}
				return (application.LoginReconciler{Owner: store, Players: i4store.PlayerRootLocker{}}).ReconcileCharacterLogin(callContext, scope.Tx, actor, current, current.StartedAt)
			})
			results <- outcome{result: result, failure: failure}
		}(loginID)
	}
	for range 2 {
		select {
		case <-ready:
		case <-requestContext.Done():
			t.Fatal(requestContext.Err())
		}
	}
	close(release)
	attempts := 0
	for range 2 {
		result := <-results
		if result.failure != nil {
			t.Fatal(result.failure)
		}
		attempts += result.result.Attempts
	}
	if attempts < 3 {
		t.Fatal("Serializable retry path was not exercised", attempts)
	}
	t.Logf("Serializable concurrent logins: total attempts=%d, one completion/version2 required", attempts)
	var stateVersion int64
	var status string
	if err := pool.Raw().QueryRow(requestContext, "SELECT status,state_version FROM social_recall_tasks WHERE operation_id=$1", operationID.String()).Scan(&status, &stateVersion); err != nil || status != "COMPLETED" || stateVersion != 2 {
		t.Fatal(status, stateVersion, err)
	}
}

func TestRecallOwnerStartPreparationExpiresReservationWithoutLogin(t *testing.T) {
	databaseURL := os.Getenv("GXB_SOCIAL_RECALL_DSN")
	if databaseURL == "" {
		t.Skip("explicit own migrated PostgreSQL database required; skip is not native proof")
	}
	requestContext := context.Background()
	pool, err := postgres.Open(requestContext, databaseURL, postgres.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	at := time.Date(2026, 11, 5, 12, 0, 0, 0, time.UTC)
	seedRecallLoginPlayer(t, pool, 125301)
	seedRecallLoginPlayer(t, pool, 125302)
	seedRecallLoginPlayer(t, pool, 125303)
	store := socialrecallstore.Store{}
	makeRecord := func(caller identity.PlayerID, started time.Time) application.TaskRecord {
		operationID, err := ids.NewUUID()
		if err != nil {
			t.Fatal(err)
		}
		cleanupRecallTask(t, pool, operationID)
		task, err := domain.NewTask(caller, 125301, 1, operationID, started, time.Hour, domain.Baseline{})
		if err != nil {
			t.Fatal(err)
		}
		return application.TaskRecord{Task: task, StateVersion: 1, UpdatedAt: started, ContentRevision: strings.Repeat("d", 64), PolicyVersion: "test-qualified-policy"}
	}
	begin := func() tx.Tx {
		transaction, err := pool.Begin(requestContext, tx.Options{Isolation: tx.Serializable})
		if err != nil {
			t.Fatal(err)
		}
		t.Cleanup(func() { _ = transaction.Rollback(context.Background()) })
		return transaction
	}
	previous := makeRecord(125302, at)
	transaction := begin()
	if err := store.InsertTaskTx(requestContext, transaction, previous); err != nil {
		t.Fatal(err)
	}
	if err := transaction.Commit(requestContext); err != nil {
		t.Fatal(err)
	}
	transaction = begin()
	state, err := store.PrepareStartStateTx(requestContext, transaction, 125302, 125301, at)
	if err != nil || state.ActiveTasks != 1 || !state.TargetReserved || state.AlreadyCompleted {
		t.Fatal(state, err)
	}
	if err := transaction.Commit(requestContext); err != nil {
		t.Fatal(err)
	}
	transaction = begin()
	state, err = store.PrepareStartStateTx(requestContext, transaction, 125302, 125301, at.Add(time.Hour))
	if err != nil || state.ActiveTasks != 0 || state.TargetReserved || state.AlreadyCompleted {
		t.Fatal("expired task retained slot or reservation", state, err)
	}
	next := makeRecord(125303, at.Add(time.Hour))
	if err := store.InsertTaskTx(requestContext, transaction, next); err != nil {
		t.Fatal(err)
	}
	if err := transaction.Commit(requestContext); err != nil {
		t.Fatal(err)
	}
	transaction = begin()
	actor := identity.ActorContext{PlayerID: 125301, LogicalServerID: 1}
	current := operation.Context{ID: next.Task.OperationID, StartedAt: at.Add(time.Hour + time.Minute)}
	if err := (application.LoginReconciler{Owner: store, Players: i4store.PlayerRootLocker{}}).ReconcileCharacterLogin(requestContext, transaction, actor, current, current.StartedAt); err != nil {
		t.Fatal(err)
	}
	state, err = store.PrepareStartStateTx(requestContext, transaction, 125303, 125301, current.StartedAt)
	if err != nil || state.ActiveTasks != 0 || state.TargetReserved || !state.AlreadyCompleted {
		t.Fatal("completed pair lost lifetime fact", state, err)
	}
	if err := transaction.Commit(requestContext); err != nil {
		t.Fatal(err)
	}
}

func seedRecallLoginPlayer(t *testing.T, pool *postgres.Pool, player identity.PlayerID) {
	t.Helper()
	ctx := context.Background()
	account, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	at := time.Date(2026, 11, 5, 12, 0, 0, 0, time.UTC)
	if _, err = pool.Raw().Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1::uuid,$2,'ACTIVE',$3)`, account.String(), account.String(), at); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		_, _ = pool.Raw().Exec(context.Background(), `DELETE FROM accounts WHERE account_id=$1::uuid`, account.String())
	})
	if _, err = pool.Raw().Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2::uuid,1,$3,'recall-login-root-native')`, int64(player), account.String(), at); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		_, _ = pool.Raw().Exec(context.Background(), `DELETE FROM players WHERE player_id=$1 AND account_id=$2::uuid`, int64(player), account.String())
	})
}
