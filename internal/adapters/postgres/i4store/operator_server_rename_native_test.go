//go:build postgres

package i4store_test

import (
	"context"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const renameServerID = 2_000_001

func TestOperatorServerRenameNative(t *testing.T) {
	pool := o2DirectoryPool(t)
	ctx := context.Background()
	now := time.Now().UTC().Truncate(time.Second)
	_, err := pool.Raw().Exec(ctx, `INSERT INTO logical_servers(logical_server_id,name,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,created_at) VALUES($1,'Before',true,true,true,$2,$3,$4) ON CONFLICT (logical_server_id) DO UPDATE SET name='Before'`, renameServerID, renameServerID*100000+25001, (renameServerID+1)*100000-1, now)
	if err != nil {
		t.Fatal(err)
	}
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	result, err := i4store.ServerDirectoryReader{}.RenameServerTx(ctx, transaction, renameServerID, "Sakura")
	if err != nil {
		_ = transaction.Rollback(ctx)
		t.Fatal(err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if result.OldName != "Before" || result.NewName != "Sakura" {
		t.Fatalf("result = %+v", result)
	}
	var stored string
	if err := pool.Raw().QueryRow(ctx, `SELECT name FROM logical_servers WHERE logical_server_id=$1`, renameServerID).Scan(&stored); err != nil {
		t.Fatal(err)
	}
	if stored != "Sakura" {
		t.Fatalf("stored name = %q", stored)
	}

	missing, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = missing.Rollback(ctx) }()
	if _, err := (i4store.ServerDirectoryReader{}).RenameServerTx(ctx, missing, renameServerID+1, "Nowhere"); !errors.Is(err, operator.ErrServerNotFound) {
		t.Fatalf("missing server err = %v", err)
	}
}
