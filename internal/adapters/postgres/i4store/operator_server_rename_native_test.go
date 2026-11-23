//go:build postgres

package i4store_test

import (
	"context"
	"errors"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	renameServerFirst  = 2_000_001
	renameServerSecond = 2_000_002
	renameServerThird  = 2_000_003
	renameServerFourth = 2_000_004
	renameServerAbsent = 2_000_099
)

func insertRenameServer(t *testing.T, pool *pg.Pool, serverID int64, name string) {
	t.Helper()
	now := time.Now().UTC().Truncate(time.Second)
	_, err := pool.Raw().Exec(context.Background(), `INSERT INTO logical_servers(logical_server_id,name,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,created_at) VALUES($1,$2,true,true,true,$3,$4,$5) ON CONFLICT (logical_server_id) DO UPDATE SET name=EXCLUDED.name`, serverID, name, serverID*100000+25001, (serverID+1)*100000-1, now)
	if err != nil {
		t.Fatal(err)
	}
}

func storedServerName(t *testing.T, pool *pg.Pool, serverID int64) string {
	t.Helper()
	var name string
	if err := pool.Raw().QueryRow(context.Background(), `SELECT name FROM logical_servers WHERE logical_server_id=$1`, serverID).Scan(&name); err != nil {
		t.Fatal(err)
	}
	return name
}

func TestOperatorServerRenameBatchCommitsBothNative(t *testing.T) {
	pool := o2DirectoryPool(t)
	ctx := context.Background()
	insertRenameServer(t, pool, renameServerFirst, "Before One")
	insertRenameServer(t, pool, renameServerSecond, "Before Two")
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	results, err := i4store.ServerDirectoryReader{}.RenameServersTx(ctx, transaction, []operator.ServerNameChange{
		{ServerID: renameServerSecond, Name: "Maple"},
		{ServerID: renameServerFirst, Name: "Sakura"},
	})
	if err != nil {
		_ = transaction.Rollback(ctx)
		t.Fatal(err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if len(results) != 2 || results[0].ServerID != renameServerSecond || results[0].OldName != "Before Two" || results[0].NewName != "Maple" {
		t.Fatalf("results = %+v", results)
	}
	if results[1].ServerID != renameServerFirst || results[1].OldName != "Before One" || results[1].NewName != "Sakura" {
		t.Fatalf("results = %+v", results)
	}
	if got := storedServerName(t, pool, renameServerFirst); got != "Sakura" {
		t.Fatalf("first stored name = %q", got)
	}
	if got := storedServerName(t, pool, renameServerSecond); got != "Maple" {
		t.Fatalf("second stored name = %q", got)
	}
}

func TestOperatorServerRenameBatchWithMissingServerChangesNeitherNative(t *testing.T) {
	pool := o2DirectoryPool(t)
	ctx := context.Background()
	insertRenameServer(t, pool, renameServerThird, "Before Three")
	insertRenameServer(t, pool, renameServerFourth, "Before Four")
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	_, err = i4store.ServerDirectoryReader{}.RenameServersTx(ctx, transaction, []operator.ServerNameChange{
		{ServerID: renameServerThird, Name: "After Three"},
		{ServerID: renameServerAbsent, Name: "Nowhere"},
	})
	var missing *operator.ServerNotFoundError
	if !errors.As(err, &missing) || missing.ServerID != renameServerAbsent {
		_ = transaction.Rollback(ctx)
		t.Fatalf("err = %v", err)
	}
	if !errors.Is(err, operator.ErrServerNotFound) {
		t.Fatalf("err does not match ErrServerNotFound: %v", err)
	}
	if err := transaction.Rollback(ctx); err != nil {
		t.Fatal(err)
	}
	if got := storedServerName(t, pool, renameServerThird); got != "Before Three" {
		t.Fatalf("third stored name = %q", got)
	}
	if got := storedServerName(t, pool, renameServerFourth); got != "Before Four" {
		t.Fatalf("fourth stored name = %q", got)
	}
}
