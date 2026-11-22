//go:build postgres

package clientlogstore_test

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/clientlogstore"
	"gxb.local/backend/v2/internal/adapters/postgres/operatorstore"
	appclientlog "gxb.local/backend/v2/internal/application/clientlog"
	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func lgPool(t *testing.T) *pg.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_I11A_LG_DSN")
	if dsn == "" {
		t.Skip("GXB_I11A_LG_DSN required (ops/testing/fresh_db.sh lg01)")
	}
	pool, err := pg.Open(context.Background(), dsn, pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	return pool
}

// TestJournalTimelineTailAndClearNative proves the operator reads and the
// bounded clear against a fresh database.
func TestJournalTimelineTailAndClearNative(t *testing.T) {
	pool := lgPool(t)
	ctx := context.Background()
	uid := fmt.Sprintf("lg-native-%d", time.Now().UnixNano())
	base := time.Now().UTC().Truncate(time.Second).Add(-time.Hour)
	for index := 0; index < 3; index++ {
		if _, err := pool.Raw().Exec(ctx, `INSERT INTO request_journal(received_at,account_uid,player_id,session_ref,mid,outcome,error_code,http_status,latency_microseconds,request_bytes,response_bytes,retention_class,expires_at)
VALUES($1,$2,$3,'session',$4,$5,0,200,1000,10,10,'ERROR',$6)`,
			base.Add(time.Duration(index)*time.Minute), uid, int64(900000+index), 241, "UNKNOWN_MID", base.Add(30*24*time.Hour)); err != nil {
			t.Fatal(err)
		}
	}
	t.Cleanup(func() {
		_, _ = pool.Raw().Exec(context.Background(), `DELETE FROM request_journal WHERE account_uid=$1`, uid)
	})

	store := clientlogstore.Store{Pool: pool.Raw()}
	service := appclientlog.LogsReadService{Runner: tx.Runner{DB: pool}, Operations: operation.Factory{Clock: clock.System{}}, Reader: store}

	page, err := service.Timeline(ctx, appclientlog.JournalFilter{AccountUID: uid, Limit: 2})
	if err != nil {
		t.Fatal(err)
	}
	if len(page.Entries) != 2 || page.NextCursor == "" {
		t.Fatalf("first page = %+v", page)
	}
	if !page.Entries[0].ReceivedAt.After(page.Entries[1].ReceivedAt) {
		t.Fatalf("page is not newest first: %+v", page.Entries)
	}
	cursor, err := appclientlog.ParseJournalCursor(page.NextCursor)
	if err != nil {
		t.Fatal(err)
	}
	second, err := service.Timeline(ctx, appclientlog.JournalFilter{AccountUID: uid, Limit: 2, Cursor: cursor})
	if err != nil {
		t.Fatal(err)
	}
	if len(second.Entries) != 1 || !second.Entries[0].ReceivedAt.Before(page.Entries[1].ReceivedAt) {
		t.Fatalf("second page = %+v", second.Entries)
	}

	tail, err := service.Tail(ctx, appclientlog.JournalFilter{AccountUID: uid, Limit: 10, Outcomes: []string{"UNKNOWN_MID"}})
	if err != nil {
		t.Fatal(err)
	}
	if len(tail.Entries) != 3 || tail.NextCursor == "" {
		t.Fatalf("tail = %+v", tail)
	}
	if !tail.Entries[0].ReceivedAt.Before(tail.Entries[2].ReceivedAt) {
		t.Fatalf("tail is not oldest first: %+v", tail.Entries)
	}

	transaction, err := pool.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	removed, err := store.ClearJournalTx(ctx, transaction, appclientlog.ClearFilter{AccountUID: uid}, 100)
	if err != nil {
		_ = transaction.Rollback(ctx)
		t.Fatal(err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if removed != 3 {
		t.Fatalf("removed = %d", removed)
	}
	after, err := service.Timeline(ctx, appclientlog.JournalFilter{AccountUID: uid, Limit: 10})
	if err != nil || len(after.Entries) != 0 {
		t.Fatalf("rows survived the clear: %+v err=%v", after.Entries, err)
	}
}

// TestLogsClearCommandThroughTheBusNative proves logs.clear runs as a typed
// command with its audit row in the bus transaction.
func TestLogsClearCommandThroughTheBusNative(t *testing.T) {
	pool := lgPool(t)
	ctx := context.Background()
	uid := fmt.Sprintf("lg-clear-%d", time.Now().UnixNano())
	base := time.Now().UTC().Truncate(time.Second).Add(-time.Hour)
	for index := 0; index < 2; index++ {
		if _, err := pool.Raw().Exec(ctx, `INSERT INTO request_journal(received_at,account_uid,player_id,outcome,http_status,latency_microseconds,request_bytes,response_bytes,retention_class,expires_at)
VALUES($1,$2,$3,'OK',200,10,1,1,'ROUTINE',$4)`, base.Add(time.Duration(index)*time.Minute), uid, int64(800000+index), base.Add(30*24*time.Hour)); err != nil {
			t.Fatal(err)
		}
	}
	t.Cleanup(func() {
		_, _ = pool.Raw().Exec(context.Background(), `DELETE FROM request_journal WHERE account_uid=$1`, uid)
	})
	store := clientlogstore.Store{Pool: pool.Raw()}
	semanticKey := fmt.Sprintf("lg-clear-key-%d", time.Now().UnixNano())
	t.Cleanup(func() {
		_, _ = pool.Raw().Exec(context.Background(), `DELETE FROM operator_commands WHERE semantic_key=$1`, semanticKey)
	})
	bus := operator.Bus{
		Runner:   tx.Runner{DB: pool},
		Clock:    clock.System{},
		Store:    operatorstore.Store{},
		Handlers: appclientlog.LogsCommands{Clearer: store}.Handlers(),
	}
	payload, err := json.Marshal(map[string]any{"source": "client", "scope": "player", "uid": uid})
	if err != nil {
		t.Fatal(err)
	}
	command, err := operator.NewCommand("logs.clear", operator.Envelope{
		Principal: "root", Role: operator.RoleRoot, Scope: "global", Reason: "native clear", SemanticKey: semanticKey,
	}, payload)
	if err != nil {
		t.Fatal(err)
	}
	outcome, err := bus.Execute(ctx, command)
	if err != nil {
		t.Fatal(err)
	}
	if outcome.State != operator.StateApplied {
		t.Fatalf("state = %s result = %s", outcome.State, outcome.Result)
	}
	var result appclientlog.ClearResult
	if err := json.Unmarshal(outcome.Result, &result); err != nil {
		t.Fatal(err)
	}
	if result.Removed != 2 || result.Source != "client" || result.Scope != "player" {
		t.Fatalf("result = %+v", result)
	}
	var remaining int
	if err := pool.Raw().QueryRow(ctx, `SELECT count(*) FROM request_journal WHERE account_uid=$1`, uid).Scan(&remaining); err != nil {
		t.Fatal(err)
	}
	if remaining != 0 {
		t.Fatalf("remaining rows = %d", remaining)
	}
}
