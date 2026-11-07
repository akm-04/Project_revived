//go:build postgres

package socialrecallstore_test

import (
	"context"
	"errors"
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
	"gxb.local/backend/v2/internal/foundation/tx"
)

type recallDoingFixture struct {
	pool    *postgres.Pool
	at      time.Time
	caller  identity.PlayerID
	names   map[identity.PlayerID]string
	records map[identity.PlayerID]application.TaskRecord
}

func seedDoingPlayers(t *testing.T, pool *postgres.Pool, players ...identity.PlayerID) map[identity.PlayerID]string {
	t.Helper()
	ctx := context.Background()
	names := make(map[identity.PlayerID]string, len(players))
	for _, player := range players {
		account := mustUUID(t)
		name := "Doing" + stringifyPlayer(player)
		if _, err := pool.Raw().Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1,$2,'ACTIVE',now()-interval '12 days')`, account.String(), "social40-doing-"+account.String()); err != nil {
			t.Fatal(err)
		}
		if _, err := pool.Raw().Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2,$3,now()-interval '12 days','social40-native')`, int64(player), account.String(), int64(player)/100000); err != nil {
			t.Fatal(err)
		}
		if _, err := pool.Raw().Exec(ctx, `INSERT INTO player_directory_profiles(player_id,name,lev,created_at,updated_at) VALUES($1,$2,51,now()-interval '1 hour',now()-interval '1 hour')`, int64(player), name); err != nil {
			t.Fatal(err)
		}
		names[player] = name
	}
	t.Cleanup(func() {
		for _, player := range players {
			_, _ = pool.Raw().Exec(context.Background(), `DELETE FROM player_directory_profiles WHERE player_id=$1`, int64(player))
			_, _ = pool.Raw().Exec(context.Background(), `DELETE FROM players WHERE player_id=$1`, int64(player))
		}
		_, _ = pool.Raw().Exec(context.Background(), `DELETE FROM accounts WHERE account_uid LIKE 'social40-doing-%'`)
	})
	return names
}

func insertDoingTask(t *testing.T, pool *postgres.Pool, caller, target identity.PlayerID, at time.Time, duration time.Duration, revision string) application.TaskRecord {
	t.Helper()
	return insertDoingTaskAt(t, pool, caller, target, at, at, duration, revision)
}

func insertDoingTaskAt(t *testing.T, pool *postgres.Pool, caller, target identity.PlayerID, started, at time.Time, duration time.Duration, revision string) application.TaskRecord {
	t.Helper()
	operation, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	task, err := domain.NewTask(caller, target, identity.LogicalServerID(int64(caller)/100000), operation, started, duration, domain.Baseline{})
	if err != nil {
		t.Fatal(err)
	}
	record := application.TaskRecord{Task: task, StateVersion: 1, UpdatedAt: started, ContentRevision: revision, PolicyVersion: application.RecallPolicyVersion}
	transaction, err := pool.Begin(context.Background(), tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if err := (socialrecallstore.Store{}).InsertTaskTx(context.Background(), transaction, record); err != nil {
		_ = transaction.Rollback(context.Background())
		t.Fatal(err)
	}
	if err := transaction.Commit(context.Background()); err != nil {
		t.Fatal(err)
	}
	return record
}

func transitionDoingTask(t *testing.T, pool *postgres.Pool, previous application.TaskRecord, complete bool, at time.Time) {
	t.Helper()
	next := previous
	var changed bool
	var err error
	if complete {
		next.Task, changed, err = previous.Task.Complete(at)
	} else {
		next.Task, changed, err = previous.Task.Expire(at)
	}
	if err != nil || !changed {
		t.Fatalf("transition changed=%v err=%v", changed, err)
	}
	next.StateVersion++
	next.UpdatedAt = at
	transaction, err := pool.Begin(context.Background(), tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if err := (socialrecallstore.Store{}).SaveRecallLoginTransitionTx(context.Background(), transaction, previous, next); err != nil {
		_ = transaction.Rollback(context.Background())
		t.Fatal(err)
	}
	if err := transaction.Commit(context.Background()); err != nil {
		t.Fatal(err)
	}
}

func TestRecallDoingProjectionNativeBoundedCallerScope(t *testing.T) {
	pool := openRecallStartPool(t)
	ctx := context.Background()
	at := dbClock(t, pool)
	revision := strings.Repeat("a", 64)
	oldRevision := strings.Repeat("b", 64)
	caller := identity.PlayerID(132001)
	targets := []identity.PlayerID{132002, 132003, 132004, 132005, 132006, 132007, 132101, 132102, 232001, 232002}
	for _, player := range append([]identity.PlayerID{caller}, targets...) {
		_, _ = pool.Raw().Exec(ctx, `DELETE FROM social_recall_tasks WHERE caller_player_id=$1 OR target_player_id=$1`, int64(player))
	}
	names := seedDoingPlayers(t, pool, append([]identity.PlayerID{caller}, targets...)...)
	t.Cleanup(func() {
		for _, player := range append([]identity.PlayerID{caller}, targets...) {
			_, _ = pool.Raw().Exec(context.Background(), `DELETE FROM social_recall_tasks WHERE caller_player_id=$1 OR target_player_id=$1`, int64(player))
		}
	})

	records := map[identity.PlayerID]application.TaskRecord{}
	records[132002] = insertDoingTaskAt(t, pool, caller, 132002, at.Add(-2*time.Hour), at, 72*time.Hour, revision)
	records[132003] = insertDoingTaskAt(t, pool, caller, 132003, at.Add(-time.Hour), at, 72*time.Hour, oldRevision)
	records[132004] = insertDoingTaskAt(t, pool, caller, 132004, at.Add(-2*time.Hour), at, time.Hour, revision)
	transitionDoingTask(t, pool, records[132004], false, at)
	records[132005] = insertDoingTaskAt(t, pool, caller, 132005, at.Add(-2*time.Hour), at, 72*time.Hour, revision)
	transitionDoingTask(t, pool, records[132005], true, at.Add(-time.Hour))
	records[132006] = insertDoingTaskAt(t, pool, caller, 132006, at.Add(-time.Hour), at, time.Hour, revision)
	records[132007] = insertDoingTask(t, pool, caller, 132007, at, 72*time.Hour, revision)
	insertDoingTaskAt(t, pool, 132101, 132102, at.Add(-30*time.Minute), at, 72*time.Hour, revision)
	insertDoingTaskAt(t, pool, 232001, 232002, at.Add(-30*time.Minute), at, 72*time.Hour, revision)

	projection := socialrecallstore.DoingProjection{Directory: i4store.TransactionDiscoveryReader{}}
	var readTransaction tx.Tx
	readTransaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	rows, err := projection.DoingRecallTx(ctx, readTransaction, caller, revision, at, 3)
	if err != nil {
		_ = readTransaction.Rollback(ctx)
		t.Fatal(err)
	}
	if len(rows) != 3 {
		_ = readTransaction.Rollback(ctx)
		t.Fatalf("bounded doing rows: %d %+v", len(rows), rows)
	}
	wantOrder := []identity.PlayerID{132007, 132003, 132002}
	for index, want := range wantOrder {
		row := rows[index]
		if row.PlayerID != want || row.PlayerName != names[want] || row.RecallingTime != records[want].Task.StartedAt.Unix() {
			_ = readTransaction.Rollback(ctx)
			t.Fatalf("row %d: %+v want id=%d name=%q time=%d", index, row, want, names[want], records[want].Task.StartedAt.Unix())
		}
	}
	for _, excluded := range []identity.PlayerID{132004, 132005, 132006, 132102, 232002} {
		for _, row := range rows {
			if row.PlayerID == excluded {
				_ = readTransaction.Rollback(ctx)
				t.Fatalf("excluded task %d leaked into doing rows", excluded)
			}
		}
	}
	state, err := (socialrecallstore.Store{}).PrepareStartStateTx(ctx, readTransaction, caller, 132009, at)
	if err != nil {
		_ = readTransaction.Rollback(ctx)
		t.Fatal(err)
	}
	if state.ActiveTasks != int64(len(rows)) || state.TargetReserved || state.AlreadyCompleted {
		_ = readTransaction.Rollback(ctx)
		t.Fatalf("doing count and start owner disagree: state=%+v rows=%d", state, len(rows))
	}
	if err := readTransaction.Rollback(ctx); err != nil {
		t.Fatal(err)
	}

	second, err := pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer second.Rollback(ctx)
	if _, err := projection.DoingRecallTx(ctx, second, caller, revision, at, 2); !errors.Is(err, application.ErrStartFacts) {
		t.Fatalf("overflow over the caller budget was not refused: %v", err)
	}
	foreign, err := projection.DoingRecallTx(ctx, second, 132101, revision, at, 3)
	if err != nil || len(foreign) != 1 || foreign[0].PlayerID != 132102 || foreign[0].PlayerName != names[132102] {
		t.Fatalf("foreign caller rows: %+v %v", foreign, err)
	}
	serverTwo, err := projection.DoingRecallTx(ctx, second, 232001, revision, at, 3)
	if err != nil || len(serverTwo) != 1 || serverTwo[0].PlayerID != 232002 {
		t.Fatalf("server-two caller rows: %+v %v", serverTwo, err)
	}
	var rawStatus string
	if err := pool.Raw().QueryRow(ctx, `SELECT status FROM social_recall_tasks WHERE operation_id=$1::uuid`, records[132004].Task.OperationID.String()).Scan(&rawStatus); err != nil || rawStatus != "EXPIRED" {
		t.Fatalf("expired fixture status: %s %v", rawStatus, err)
	}
}
