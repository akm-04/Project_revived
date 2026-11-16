//go:build postgres

package socialrecallstore_test

import (
	"context"
	"os"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrecallstore"
	application "gxb.local/backend/v2/internal/application/socialrecall"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/socialrecall"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// seedRecallProjectionPlayers seeds the caller and target rows the recall foreign keys require;
// the enclosing transaction owns them and rolls them back with the fixture.
func seedRecallProjectionPlayers(t *testing.T, ctx context.Context, transaction tx.Tx, players ...identity.PlayerID) {
	t.Helper()
	for _, player := range players {
		account, err := ids.NewUUID()
		if err != nil {
			t.Fatal(err)
		}
		if _, err = transaction.Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES($1::uuid,$2,'ACTIVE',$3)`, account.String(), account.String(), targetAt); err != nil {
			t.Fatal(err)
		}
		if _, err = transaction.Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2::uuid,$3,$4,'recall-projection-native')`, int64(player), account.String(), int64(player)/100000, targetAt); err != nil {
			t.Fatal(err)
		}
	}
}

func TestRecallDoingProjectionOwnerSQLTimeScopeAndOverflow(t *testing.T) {
	databaseURL := os.Getenv("GXB_SOCIAL_RECALL_DSN")
	if databaseURL == "" {
		t.Skip("own migrated PostgreSQL database required")
	}
	ctx := context.Background()
	pool, err := postgres.Open(ctx, databaseURL, postgres.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	seedRecallProjectionPlayers(t, ctx, transaction, 125901, 125902, 125903, 125904, 225901, 225902, 125905, 125906)
	at := targetAt
	for _, entry := range []struct {
		caller, target identity.PlayerID
		duration       time.Duration
	}{
		{125901, 125902, 2 * time.Hour}, {125901, 125903, 2 * time.Hour}, {125901, 125904, time.Hour}, {225901, 225902, 2 * time.Hour}, {125905, 125906, 2 * time.Hour},
	} {
		operationID, err := ids.NewUUID()
		if err != nil {
			t.Fatal(err)
		}
		task, err := domain.NewTask(entry.caller, entry.target, identity.LogicalServerID(int64(entry.caller)/100000), operationID, at.Add(-time.Hour), entry.duration, domain.Baseline{AcademyLevel: 51, OwnedHeroCount: 3})
		if err != nil {
			t.Fatal(err)
		}
		record := application.TaskRecord{Task: task, StateVersion: 1, UpdatedAt: task.StartedAt, ContentRevision: strings.Repeat("a", 64), PolicyVersion: application.RecallPolicyVersion}
		if err := (socialrecallstore.Store{}).InsertTaskTx(ctx, transaction, record); err != nil {
			t.Fatal(err)
		}
	}
	directory := &recallDirectory{}
	projection := socialrecallstore.DoingProjection{Directory: directory}
	rows, err := projection.DoingRecallTx(ctx, transaction, 125901, strings.Repeat("a", 64), at, 3)
	if err != nil || len(rows) != 2 || rows[0].PlayerID != 125902 || rows[1].PlayerID != 125903 || len(directory.players) != 2 || directory.query != transaction {
		t.Fatal(rows, err, directory)
	}
	directory.players = nil
	if _, err := projection.DoingRecallTx(ctx, transaction, 125901, strings.Repeat("a", 64), at, 1); err == nil || len(directory.players) != 0 {
		t.Fatal("overflow did not refuse before directory reads", err, directory)
	}
	if err := transaction.Rollback(ctx); err != nil {
		t.Fatal(err)
	}
	var count int
	if err := pool.QueryRow(ctx, `SELECT count(*) FROM social_recall_tasks WHERE caller_player_id IN (125901,225901,125905)`).Scan(&count); err != nil || count != 0 {
		t.Fatal("projection fixture leaked after rollback", count, err)
	}
}

func TestRecallProjectionAdvertisesOnlyLiveReservations(t *testing.T) {
	pool := openRecallStartPool(t)
	ctx := context.Background()
	world := seedRecallWorld(t, pool, 135071, 135072, [2]string{"Caller135071", "Target135072"})
	liveTarget := identity.PlayerID(135073)
	t.Cleanup(func() {
		_, _ = pool.Raw().Exec(context.Background(), `DELETE FROM social_recall_tasks WHERE caller_player_id=$1 OR target_player_id=ANY($2::bigint[])`, int64(world.caller), []int64{int64(world.target), int64(liveTarget)})
	})
	at := dbClock(t, pool)
	// The expired row stays ACTIVE in the database until a start or login transition sweeps it.
	insertDoingTaskAt(t, pool, world.caller, world.target, at.Add(-2*time.Hour), at, time.Hour, world.revision)
	insertDoingTaskAt(t, pool, world.caller, liveTarget, at.Add(-time.Hour), at, 72*time.Hour, world.revision)

	_, targets := recallClaimHarness(world)
	reader := socialrecallstore.RecallProjectionReader{Current: targets}
	op, err := application.BindRecallPolicies(operationFor(t), world.revision)
	if err != nil {
		t.Fatal(err)
	}
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	base, err := reader.ReadRecallBaseTx(ctx, tx.Scope{Tx: transaction, Operation: op, Attempt: 1, Options: tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}}, world.actor, world.revision, at, []identity.PlayerID{world.target, liveTarget})
	if err != nil {
		t.Fatalf("recall reload read: %v", err)
	}
	if len(base.Recalling) != 1 || base.Recalling[0] != liveTarget {
		t.Fatalf("expired reservation advertised as recalling: %+v", base.Recalling)
	}
	var status string
	if err := pool.Raw().QueryRow(ctx, `SELECT status FROM social_recall_tasks WHERE caller_player_id=$1 AND target_player_id=$2`, int64(world.caller), int64(world.target)).Scan(&status); err != nil || status != "ACTIVE" {
		t.Fatalf("expired fixture status: %q %v", status, err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}
