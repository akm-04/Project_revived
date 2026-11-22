package operatoragent

import (
	"context"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/pgtoolchain"
	"gxb.local/backend/v2/internal/application/operator"
)

// TestBackupSnapshotRestoreRenameNative proves B4/B5 on a fresh database:
// snapshot, change, restore by rename, and an injected failing restore that
// leaves the original database serving. GXB_I11A_BK_DSN names the fresh DB.
func TestBackupSnapshotRestoreRenameNative(t *testing.T) {
	dsn := os.Getenv("GXB_I11A_BK_DSN")
	if dsn == "" {
		t.Skip("GXB_I11A_BK_DSN is not set")
	}
	tools, err := pgtoolchain.Resolve(os.Getenv("GXB_PG_TOOLCHAIN"))
	if err != nil {
		t.Skip("pg toolchain unavailable: " + err.Error())
	}
	database, err := DatabaseNameFromDSN(dsn)
	if err != nil {
		t.Fatalf("DSN: %v", err)
	}
	adminDSN, err := AdminDSN(dsn)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		cleanupNativeDatabases(context.Background(), tools, adminDSN, database)
	})
	ctx := context.Background()
	if err := tools.Execute(ctx, dsn, "DROP TABLE IF EXISTS backup_native_probe"); err != nil {
		t.Fatal(err)
	}
	if err := tools.Execute(ctx, dsn, "CREATE TABLE backup_native_probe (value text)"); err != nil {
		t.Fatal(err)
	}
	if err := tools.Execute(ctx, dsn, "INSERT INTO backup_native_probe VALUES ('original')"); err != nil {
		t.Fatal(err)
	}

	now := time.Now
	service := &BackupService{
		Directory:  t.TempDir(),
		Keep:       5,
		Tools:      tools,
		Operator:   fakeVersionReader{version: operator.VersionInfo{Migration: 100000}},
		Backend:    &fakeProcess{running: true},
		Tokens:     &TokenHolder{},
		Operations: NewOperations(filepath.Join(t.TempDir(), OperationsDirectory), nil, now),
		Guard:      &BackendGuard{},
		Now:        now,
	}
	t.Setenv(PostgresDSNVariable, dsn)

	snapshot, err := service.Snapshot(ctx, BackupKindManual, "native snapshot")
	if err != nil || snapshot.State != OperationDone {
		t.Fatalf("snapshot: %+v %v", snapshot, err)
	}
	list, err := service.List(ctx)
	if err != nil || len(list.Backups) != 1 {
		t.Fatalf("list = %+v (%v)", list, err)
	}
	id := list.Backups[0].ID

	if err := tools.Execute(ctx, dsn, "UPDATE backup_native_probe SET value = 'changed'"); err != nil {
		t.Fatal(err)
	}
	restored, err := service.Restore(ctx, id, "native restore")
	if err != nil || restored.State != OperationDone {
		t.Fatalf("restore: %+v %v", restored, err)
	}
	assertProbeValue(t, tools, dsn, "original")

	retentionPath := filepath.Join(service.Directory, backupPreRestoreFileName)
	contents, err := os.ReadFile(retentionPath)
	if err != nil {
		t.Fatalf("the prerestore marker is missing: %v", err)
	}
	if !strings.Contains(string(contents), "_prerestore_") {
		t.Fatalf("marker = %s", contents)
	}

	failing := &failingRestoreTools{DatabaseTools: tools, err: errors.New("injected restore failure")}
	service.Tools = failing
	if err := tools.Execute(ctx, dsn, "UPDATE backup_native_probe SET value = 'before failed restore'"); err != nil {
		t.Fatal(err)
	}
	operation, err := service.Restore(ctx, id, "injected failing restore")
	if err == nil {
		t.Fatal("the injected restore failure was not reported")
	}
	if operation.FailedStep != "restore into new database" {
		t.Fatalf("failed step = %q", operation.FailedStep)
	}
	assertProbeValue(t, tools, dsn, "before failed restore")

	if err := os.Remove(retentionPath); err != nil && !errors.Is(err, os.ErrNotExist) {
		t.Fatal(err)
	}
}

func assertProbeValue(t *testing.T, tools DatabaseTools, dsn, wanted string) {
	t.Helper()
	value, err := tools.Query(context.Background(), dsn, "SELECT value FROM backup_native_probe")
	if err != nil {
		t.Fatalf("probe query: %v", err)
	}
	if got := strings.TrimSpace(value); got != wanted {
		t.Fatalf("probe = %q, want %q", got, wanted)
	}
}

// cleanupNativeDatabases drops the restore and prerestore databases this test
// created, so a rerun on the same fresh database starts clean.
func cleanupNativeDatabases(ctx context.Context, tools DatabaseTools, adminDSN, database string) {
	entries, err := tools.Query(ctx, adminDSN, `SELECT datname FROM pg_database WHERE datname LIKE '`+database+`\\_%'`)
	if err != nil {
		return
	}
	for _, name := range strings.Fields(entries) {
		_ = tools.Execute(ctx, adminDSN, `DROP DATABASE IF EXISTS "`+name+`"`)
	}
}

type failingRestoreTools struct {
	DatabaseTools
	err error
}

func (tools *failingRestoreTools) Restore(context.Context, string, string) error {
	return tools.err
}
