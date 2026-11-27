package operatoragent

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
)

type fakeTools struct {
	calls       []string
	statements  []string
	dumpContent string
	dumpErr     error
	verifyErr   error
	restoreErr  error
	executeErr  error
	queryAnswer string
	queryErr    error
	migrateErr  error
	migrateDir  string
	// restoreStarted and restoreRelease let a test hold the restore step open
	// long enough to read its live operation status.
	restoreStarted chan struct{}
	restoreRelease chan struct{}
	// events records the order of tool calls when a test installs it.
	events *[]string
}

func (tools *fakeTools) record(event string) {
	if tools.events != nil {
		*tools.events = append(*tools.events, event)
	}
}

func (tools *fakeTools) Dump(_ context.Context, _ string, destination string) error {
	tools.calls = append(tools.calls, "dump")
	tools.record("dump")
	if tools.dumpErr != nil {
		return tools.dumpErr
	}
	return os.WriteFile(destination, []byte(tools.dumpContent), 0o600)
}

func (tools *fakeTools) VerifyDump(context.Context, string) error {
	tools.calls = append(tools.calls, "verify")
	tools.record("verify")
	return tools.verifyErr
}

func (tools *fakeTools) Restore(_ context.Context, _ string, _ string) error {
	tools.calls = append(tools.calls, "restore")
	if tools.restoreStarted != nil {
		close(tools.restoreStarted)
	}
	if tools.restoreRelease != nil {
		<-tools.restoreRelease
	}
	return tools.restoreErr
}

func (tools *fakeTools) Execute(_ context.Context, _ string, statement string) error {
	tools.calls = append(tools.calls, "execute")
	tools.statements = append(tools.statements, statement)
	return tools.executeErr
}

func (tools *fakeTools) Query(context.Context, string, string) (string, error) {
	tools.calls = append(tools.calls, "query")
	return tools.queryAnswer, tools.queryErr
}

func (tools *fakeTools) Migrate(_ context.Context, _ string, directory string) error {
	tools.calls = append(tools.calls, "migrate")
	tools.record("migrate")
	tools.migrateDir = directory
	return tools.migrateErr
}

func (tools *fakeTools) executed(substring string) bool {
	for _, statement := range tools.statements {
		if strings.Contains(statement, substring) {
			return true
		}
	}
	return false
}

type fakeVersionReader struct {
	version    operator.VersionInfo
	versionErr error
}

func (reader fakeVersionReader) Command(context.Context, OperatorRequest) (BackendResponse, error) {
	return BackendResponse{Status: http.StatusOK, Body: []byte(`{}`)}, nil
}

func (reader fakeVersionReader) Read(context.Context, string, string) (BackendResponse, error) {
	return BackendResponse{Status: http.StatusOK, Body: []byte(`{}`)}, nil
}

func (reader fakeVersionReader) Version(context.Context) (operator.VersionInfo, error) {
	return reader.version, reader.versionErr
}

type fakeProcess struct {
	running         bool
	starts          int
	stops           int
	startErr        error
	openErr         error
	stopErr         error
	lastStartClosed bool
	// failStarts fails the next Start calls before they touch the running
	// state, so a test can fail the new release but start the previous one.
	failStarts int
	// events records the order of lifecycle calls when a test installs it.
	events *[]string
}

func (process *fakeProcess) Start(closed bool, _ string) error {
	if process.events != nil {
		*process.events = append(*process.events, "start")
	}
	if process.failStarts > 0 {
		process.failStarts--
		return errors.New("the release exited before it was ready")
	}
	if !closed && process.openErr != nil {
		return process.openErr
	}
	if process.startErr != nil {
		return process.startErr
	}
	process.starts++
	process.lastStartClosed = closed
	process.running = true
	return nil
}

func (process *fakeProcess) Stop() error {
	if process.events != nil {
		*process.events = append(*process.events, "stop")
	}
	if process.stopErr != nil {
		return process.stopErr
	}
	process.stops++
	process.running = false
	return nil
}

func (process *fakeProcess) Status() BackendStatus {
	return BackendStatus{Running: process.running}
}

func newBackupService(t *testing.T) (*BackupService, *fakeTools, *fakeProcess) {
	t.Helper()
	directory := t.TempDir()
	tools := &fakeTools{dumpContent: "dump bytes"}
	process := &fakeProcess{running: true}
	now := time.Date(2026, 11, 22, 12, 0, 0, 123456789, time.UTC)
	service := &BackupService{
		Directory:  directory,
		Keep:       5,
		Tools:      tools,
		Operator:   fakeVersionReader{version: testVersion()},
		Backend:    process,
		Tokens:     &TokenHolder{},
		Operations: NewOperations(filepath.Join(directory, OperationsDirectory), nil, func() time.Time { return now }),
		Guard:      &BackendGuard{},
		Now:        func() time.Time { return now },
	}
	t.Setenv(PostgresDSNVariable, "postgres://postgres@/gxb_bk?host=127.0.0.1&port=55853")
	return service, tools, process
}

func writeSnapshot(t *testing.T, directory, id, kind string, created time.Time, content string) BackupManifest {
	t.Helper()
	digest := sha256.Sum256([]byte(content))
	manifest := BackupManifest{
		ID:        id,
		Kind:      kind,
		CreatedAt: created,
		Database:  "gxb_bk",
		Migration: 183,
		Size:      int64(len(content)),
		SHA256:    hex.EncodeToString(digest[:]),
	}
	if err := os.WriteFile(filepath.Join(directory, id+backupDumpSuffix), []byte(content), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := writeBackupManifest(filepath.Join(directory, id+backupManifestSuffix), manifest); err != nil {
		t.Fatal(err)
	}
	return manifest
}

func TestSnapshotWritesManifestAndVerifiesTheDump(t *testing.T) {
	service, tools, _ := newBackupService(t)
	operation, err := service.Snapshot(context.Background(), SnapshotOptions{Kind: BackupKindManual, Reason: "nightly"})
	if err != nil {
		t.Fatalf("snapshot: %v", err)
	}
	if operation.State != OperationDone {
		t.Fatalf("operation = %+v", operation)
	}
	entries, err := os.ReadDir(service.Directory)
	if err != nil {
		t.Fatal(err)
	}
	var manifestPath string
	for _, entry := range entries {
		if strings.HasSuffix(entry.Name(), backupDumpSuffix+backupPartialSuffix) {
			t.Fatalf("the partial dump was left behind: %s", entry.Name())
		}
		if strings.HasSuffix(entry.Name(), backupManifestSuffix) {
			manifestPath = filepath.Join(service.Directory, entry.Name())
		}
	}
	if manifestPath == "" {
		t.Fatal("no manifest was written")
	}
	manifest, err := readBackupManifest(manifestPath)
	if err != nil {
		t.Fatal(err)
	}
	if manifest.Kind != BackupKindManual || manifest.Database != "gxb_bk" || manifest.Migration != 183 || manifest.BackendCommit != "abc123" {
		t.Fatalf("manifest = %+v", manifest)
	}
	if len(tools.calls) < 2 || tools.calls[0] != "dump" || tools.calls[1] != "verify" {
		t.Fatalf("tool calls = %+v", tools.calls)
	}
	var listed BackupList
	if listed, err = service.List(context.Background()); err != nil {
		t.Fatal(err)
	}
	if len(listed.Backups) != 1 || listed.Backups[0].Damaged || listed.NewestAgeSeconds == nil {
		t.Fatalf("list = %+v", listed)
	}
}

func TestSnapshotRefusesMissingToolchainAndDSN(t *testing.T) {
	service, _, _ := newBackupService(t)
	service.Tools = nil
	service.ToolsError = errors.New("pg_dump is missing")
	if _, err := service.Snapshot(context.Background(), SnapshotOptions{Kind: BackupKindManual, Reason: "r"}); !backupRefusalCode(err, CodeBackupToolsMissing) {
		t.Fatalf("missing tools: %v", err)
	}

	service, _, _ = newBackupService(t)
	t.Setenv(PostgresDSNVariable, "")
	if _, err := service.Snapshot(context.Background(), SnapshotOptions{Kind: BackupKindManual, Reason: "r"}); !backupRefusalCode(err, CodeBackupDSNMissing) {
		t.Fatalf("missing DSN: %v", err)
	}
}

func TestSnapshotRefusesUnknownKind(t *testing.T) {
	service, _, _ := newBackupService(t)
	if _, err := service.Snapshot(context.Background(), SnapshotOptions{Kind: "nonsense", Reason: "r"}); !backupRefusalCode(err, CodeBackupKindInvalid) {
		t.Fatalf("unknown kind: %v", err)
	}
}

func TestListMarksDamagedSnapshots(t *testing.T) {
	service, _, _ := newBackupService(t)
	base := time.Date(2026, 11, 20, 10, 0, 0, 0, time.UTC)
	writeSnapshot(t, service.Directory, "20260101T000000.000000000Z-manual", BackupKindManual, base, "one")
	damaged := damagedManifestForTest("20260102T000000.000000000Z-manual")
	if err := writeBackupManifest(filepath.Join(service.Directory, damaged.ID+backupManifestSuffix), damaged); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(service.Directory, damaged.ID+backupDumpSuffix), []byte("tampered"), 0o600); err != nil {
		t.Fatal(err)
	}
	orphan := "20260103T000000.000000000Z-manual"
	if err := os.WriteFile(filepath.Join(service.Directory, orphan+backupDumpSuffix), []byte("orphan"), 0o600); err != nil {
		t.Fatal(err)
	}
	list, err := service.List(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if len(list.Backups) != 3 {
		t.Fatalf("list = %+v", list)
	}
	damagedCount := 0
	for _, entry := range list.Backups {
		if entry.Damaged {
			damagedCount++
			if entry.DamagedReason == "" {
				t.Fatalf("damaged without a reason: %+v", entry)
			}
		}
	}
	if damagedCount != 2 {
		t.Fatalf("damaged = %d, list = %+v", damagedCount, list.Backups)
	}
}

// damagedManifestForTest builds a manifest whose sha cannot match the written
// dump, so the list has to call it damaged.
func damagedManifestForTest(id string) BackupManifest {
	return BackupManifest{ID: id, Kind: BackupKindManual, CreatedAt: time.Now().UTC(), Database: "gxb_bk", Size: 1, SHA256: strings.Repeat("0", 64)}
}

func TestPruneKeepsNewestKeepAndDamaged(t *testing.T) {
	service, _, _ := newBackupService(t)
	base := time.Date(2026, 11, 20, 10, 0, 0, 0, time.UTC)
	ids := make([]string, 7)
	for index := range 7 {
		ids[index] = "2026010" + string(rune('1'+index)) + "T000000.000000000Z-safety"
		content := "snapshot-" + ids[index]
		manifest := writeSnapshot(t, service.Directory, ids[index], BackupKindSafety, base.Add(time.Duration(index)*time.Minute), content)
		if index == 0 {
			manifest.SHA256 = strings.Repeat("f", 64)
			if err := writeBackupManifest(filepath.Join(service.Directory, ids[index]+backupManifestSuffix), manifest); err != nil {
				t.Fatal(err)
			}
		}
	}
	operation, err := service.Prune(context.Background())
	if err != nil || operation.State != OperationDone {
		t.Fatalf("prune: %+v %v", operation, err)
	}
	var result PruneResult
	if err := json.Unmarshal(operation.Result, &result); err != nil {
		t.Fatal(err)
	}
	if len(result.Damaged) != 1 || result.Damaged[0] != ids[0] {
		t.Fatalf("damaged = %+v", result.Damaged)
	}
	if len(result.Kept) != 6 {
		t.Fatalf("kept = %+v", result.Kept)
	}
	if len(result.Removed) != 1 || result.Removed[0] != ids[1] {
		t.Fatalf("removed = %+v", result.Removed)
	}
	if _, err := os.Stat(filepath.Join(service.Directory, ids[0]+backupDumpSuffix)); err != nil {
		t.Fatalf("the damaged dump was deleted: %v", err)
	}
}

func TestPruneProtectsSnapshotsOfRunningOperations(t *testing.T) {
	service, _, _ := newBackupService(t)
	base := time.Date(2026, 11, 20, 10, 0, 0, 0, time.UTC)
	ids := make([]string, 7)
	for index := range 7 {
		ids[index] = "2026010" + string(rune('1'+index)) + "T000000.000000000Z-safety"
		writeSnapshot(t, service.Directory, ids[index], BackupKindSafety, base.Add(time.Duration(index)*time.Minute), "snapshot")
	}
	opsDirectory := service.Operations.Directory
	if err := os.MkdirAll(opsDirectory, 0o700); err != nil {
		t.Fatal(err)
	}
	running := Operation{ID: strings.Repeat("a", 32), Kind: "backup.restore", State: OperationRunning, Request: json.RawMessage(`{"id":"` + ids[0] + `"}`)}
	encoded, _ := json.Marshal(running)
	if err := os.WriteFile(filepath.Join(opsDirectory, running.ID+".json"), encoded, 0o600); err != nil {
		t.Fatal(err)
	}
	result, err := service.prune(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if len(result.Removed) != 1 || result.Removed[0] != ids[1] {
		t.Fatalf("removed = %+v", result.Removed)
	}
	if _, err := os.Stat(filepath.Join(service.Directory, ids[0]+backupDumpSuffix)); err != nil {
		t.Fatalf("the referenced snapshot is gone: %v", err)
	}
}

func TestRestoreSwapsDatabasesAndRetainsPreRestore(t *testing.T) {
	service, tools, process := newBackupService(t)
	id := "20260101T000000.000000000Z-manual"
	writeSnapshot(t, service.Directory, id, BackupKindManual, time.Date(2026, 11, 20, 10, 0, 0, 0, time.UTC), "restore me")
	operation, err := service.Restore(context.Background(), id, "rollback release")
	if err != nil || operation.State != OperationDone {
		t.Fatalf("restore: %+v %v", operation, err)
	}
	for _, wanted := range []string{`CREATE DATABASE "gxb_bk_restore_`, `ALTER DATABASE "gxb_bk" RENAME TO "gxb_bk_prerestore_`, `ALTER DATABASE "gxb_bk_restore_`} {
		if !tools.executed(wanted) {
			t.Fatalf("missing statement %q in %+v", wanted, tools.statements)
		}
	}
	if !process.running {
		t.Fatal("the backend was not started again")
	}
	contents, err := os.ReadFile(filepath.Join(service.Directory, backupPreRestoreFileName))
	if err != nil {
		t.Fatalf("the prerestore marker is missing: %v", err)
	}
	var retention preRestoreRetention
	if err := json.Unmarshal(contents, &retention); err != nil || !strings.Contains(retention.Database, "_prerestore_") {
		t.Fatalf("marker = %s (%v)", contents, err)
	}
	if _, err := os.Stat(filepath.Join(service.Directory, backupStateFileName)); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("the restore state was not cleared: %v", err)
	}
}

// TestStartRestoreStreamsProgress proves the streaming restore answers while
// the restore is still running and the op status read names the live step, so
// the GUI can follow it.
func TestStartRestoreStreamsProgress(t *testing.T) {
	service, tools, _ := newBackupService(t)
	id := "20260101T000000.000000000Z-manual"
	writeSnapshot(t, service.Directory, id, BackupKindManual, time.Date(2026, 11, 20, 10, 0, 0, 0, time.UTC), "restore me")
	tools.restoreStarted = make(chan struct{})
	tools.restoreRelease = make(chan struct{})
	operation, err := service.StartRestore(context.Background(), id, "watch the log")
	if err != nil {
		t.Fatalf("start restore: %v", err)
	}
	if operation.State != OperationRunning {
		t.Fatalf("start answered %+v, want RUNNING", operation)
	}
	select {
	case <-tools.restoreStarted:
	case <-time.After(5 * time.Second):
		t.Fatal("the restore never reached the restore step")
	}
	status, err := service.Operations.Status(operation.ID)
	if err != nil {
		t.Fatal(err)
	}
	running := false
	for _, step := range status.Steps {
		if step.Name == "restore into new database" && step.State == OperationRunning {
			running = true
		}
	}
	if status.State != OperationRunning || !running {
		t.Fatalf("status during the restore = %+v", status)
	}
	close(tools.restoreRelease)
	deadline := time.Now().Add(5 * time.Second)
	for {
		status, err = service.Operations.Status(operation.ID)
		if err != nil {
			t.Fatal(err)
		}
		if status.State == OperationDone || status.State == OperationFailed {
			break
		}
		if time.Now().After(deadline) {
			t.Fatalf("the restore did not finish: %+v", status)
		}
		time.Sleep(5 * time.Millisecond)
	}
	if status.State != OperationDone {
		t.Fatalf("the restore finished %s: %+v", status.State, status)
	}
}

// TestRestoreCompletesClosedWhenTheOpenStartLacksAnAssetsRelease proves the
// release guard does not turn a good restore into a rolled-back one.
func TestRestoreCompletesClosedWhenTheOpenStartLacksAnAssetsRelease(t *testing.T) {
	service, _, process := newBackupService(t)
	process.openErr = Refuse(CodeBackendNoAssetsRelease, "no ACTIVE assets release is published; start closed, publish an assets release, then open")
	id := "20260101T000000.000000000Z-manual"
	writeSnapshot(t, service.Directory, id, BackupKindManual, time.Date(2026, 11, 20, 10, 0, 0, 0, time.UTC), "restore me")
	operation, err := service.Restore(context.Background(), id, "lost ota state")
	if err != nil || operation.State != OperationDone || operation.FailedStep != "" {
		t.Fatalf("restore: %+v %v", operation, err)
	}
	if process.running {
		t.Fatal("a refused open left the backend running")
	}
	if _, err := os.Stat(filepath.Join(service.Directory, backupPreRestoreFileName)); err != nil {
		t.Fatalf("the prerestore marker is missing: %v", err)
	}
	if _, err := os.Stat(filepath.Join(service.Directory, backupStateFileName)); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("the restore state was not cleared: %v", err)
	}
	var result map[string]any
	if err := json.Unmarshal(operation.Result, &result); err != nil {
		t.Fatal(err)
	}
	if result["error_code"] != CodeBackendNoAssetsRelease || result["backend"] != "closed" {
		t.Fatalf("restore result = %+v", result)
	}
}

// TestRestoreFailureStartsClosedWhenTheOpenStartLacksAssets proves the rollback
// path keeps the guard semantics instead of leaving the backend stopped.
func TestRestoreFailureStartsClosedWhenTheOpenStartLacksAssets(t *testing.T) {
	service, tools, process := newBackupService(t)
	tools.restoreErr = errors.New("pg_restore: input file does not appear to be a valid archive")
	process.openErr = Refuse(CodeBackendNoAssetsRelease, "no ACTIVE assets release is published")
	id := "20260101T000000.000000000Z-manual"
	writeSnapshot(t, service.Directory, id, BackupKindManual, time.Date(2026, 11, 20, 10, 0, 0, 0, time.UTC), "restore me")
	if _, err := service.Restore(context.Background(), id, "bad archive"); err == nil {
		t.Fatal("the failing restore was not reported")
	}
	if !process.running || !process.lastStartClosed {
		t.Fatalf("original start = running %v closed %v", process.running, process.lastStartClosed)
	}
}

func TestRestoreFailureLeavesTheOriginalDatabaseServing(t *testing.T) {
	service, tools, process := newBackupService(t)
	tools.restoreErr = errors.New("pg_restore: input file does not appear to be a valid archive")
	id := "20260101T000000.000000000Z-manual"
	writeSnapshot(t, service.Directory, id, BackupKindManual, time.Date(2026, 11, 20, 10, 0, 0, 0, time.UTC), "restore me")
	operation, err := service.Restore(context.Background(), id, "bad archive")
	if err == nil {
		t.Fatal("the failing restore was not reported")
	}
	if operation.FailedStep != "restore into new database" {
		t.Fatalf("failed step = %q", operation.FailedStep)
	}
	if tools.executed("RENAME TO") {
		t.Fatalf("a rename ran after the restore failed: %+v", tools.statements)
	}
	if !tools.executed(`DROP DATABASE IF EXISTS "gxb_bk_restore_`) {
		t.Fatalf("the half-restored database was not dropped: %+v", tools.statements)
	}
	if !process.running || process.stops == 0 {
		t.Fatal("the original database was not started again")
	}
	if _, err := os.Stat(filepath.Join(service.Directory, backupStateFileName)); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("the restore state was not cleared: %v", err)
	}
}

func TestRestoreRefusesDamagedUnknownAndNewerMigration(t *testing.T) {
	service, _, _ := newBackupService(t)
	if _, err := service.Restore(context.Background(), "missing", "r"); !backupRefusalCode(err, CodeBackupUnknown) {
		t.Fatalf("unknown: %v", err)
	}
	id := "20260101T000000.000000000Z-manual"
	writeSnapshot(t, service.Directory, id, BackupKindManual, time.Now().UTC(), "content")
	if err := os.WriteFile(filepath.Join(service.Directory, id+backupDumpSuffix), []byte("tampered content"), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := service.Restore(context.Background(), id, "r"); !backupRefusalCode(err, CodeBackupDamaged) {
		t.Fatalf("damaged: %v", err)
	}

	service, _, _ = newBackupService(t)
	service.Operator = fakeVersionReader{version: operator.VersionInfo{Migration: 100}}
	writeSnapshot(t, service.Directory, id, BackupKindManual, time.Now().UTC(), "content")
	if _, err := service.Restore(context.Background(), id, "r"); !backupRefusalCode(err, CodeBackupMigrationTooNew) {
		t.Fatalf("migration: %v", err)
	} else if !strings.Contains(err.Error(), "183") || !strings.Contains(err.Error(), "100") {
		t.Fatalf("the refusal does not name both migrations: %v", err)
	}
}

func TestRecoverRestoreLeavesAKnownState(t *testing.T) {
	cases := []struct {
		name       string
		phase      string
		restored   string
		wantRename string
		wantDrop   bool
		wantMarker bool
	}{
		{name: "keep the original when the swap never renamed it", phase: "swapping", restored: "1", wantDrop: true},
		{name: "roll the original back after the first rename", phase: "swapping", restored: "", wantRename: `ALTER DATABASE "gxb_bk_prerestore_`, wantDrop: true},
		{name: "drop the half restore before the swap", phase: "restoring", wantDrop: true},
		{name: "keep the prerestore after a swap", phase: "swapped", restored: "1", wantMarker: true},
		{name: "roll the original back when the restored database is gone", phase: "swapped", restored: "", wantRename: `ALTER DATABASE "gxb_bk_prerestore_`},
	}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			service, tools, _ := newBackupService(t)
			tools.queryAnswer = testCase.restored
			state := restoreState{Phase: testCase.phase, Database: "gxb_bk", Restored: "gxb_bk_restore_1", PreRestore: "gxb_bk_prerestore_1", Stamp: "20260101T000000"}
			if err := service.writeState(filepath.Join(service.Directory, backupStateFileName), state); err != nil {
				t.Fatal(err)
			}
			if err := service.RecoverRestore(context.Background()); err != nil {
				t.Fatalf("recover: %v", err)
			}
			if testCase.wantRename != "" && !tools.executed(testCase.wantRename) {
				t.Fatalf("missing rename %q in %+v", testCase.wantRename, tools.statements)
			}
			if testCase.wantDrop && !tools.executed(`DROP DATABASE IF EXISTS "gxb_bk_restore_1"`) {
				t.Fatalf("missing drop in %+v", tools.statements)
			}
			_, markerErr := os.Stat(filepath.Join(service.Directory, backupPreRestoreFileName))
			if testCase.wantMarker && markerErr != nil {
				t.Fatalf("marker missing: %v", markerErr)
			}
			if !testCase.wantMarker && markerErr == nil {
				t.Fatal("an unexpected prerestore marker was written")
			}
			if _, err := os.Stat(filepath.Join(service.Directory, backupStateFileName)); !errors.Is(err, os.ErrNotExist) {
				t.Fatalf("the state file survived recovery: %v", err)
			}
		})
	}
}

func TestRecoverMarksAHalfDoneRestoreFailed(t *testing.T) {
	service, _, _ := newBackupService(t)
	operation := Operation{ID: strings.Repeat("b", 32), Kind: "backup.restore", State: OperationRunning, StartedAt: time.Now(), Steps: []OperationStep{{Name: "verify snapshot", State: OperationDone, At: time.Now()}}}
	if err := service.Operations.write(operation); err != nil {
		t.Fatal(err)
	}
	if err := service.Operations.Recover(); err != nil {
		t.Fatal(err)
	}
	recovered, err := service.Operations.Status(operation.ID)
	if err != nil {
		t.Fatal(err)
	}
	if recovered.State != OperationFailed || recovered.Error != "agent restarted" || recovered.FailedStep != "" {
		t.Fatalf("recovered = %+v", recovered)
	}
	if len(recovered.Steps) != 1 || recovered.Steps[0].Name != "verify snapshot" {
		t.Fatalf("the completed steps were lost: %+v", recovered.Steps)
	}
}

func TestDatabaseDSNRoundTrip(t *testing.T) {
	urlDSN := "postgres://postgres@/gxb_bk?host=127.0.0.1&port=55853"
	name, err := DatabaseNameFromDSN(urlDSN)
	if err != nil || name != "gxb_bk" {
		t.Fatalf("name = %q (%v)", name, err)
	}
	changed, err := DSNWithDatabase(urlDSN, "gxb_bk_restore_1")
	if err != nil || !strings.Contains(changed, "/gxb_bk_restore_1?") {
		t.Fatalf("changed = %q (%v)", changed, err)
	}
	admin, err := AdminDSN(urlDSN)
	if err != nil || !strings.Contains(admin, "/postgres?") {
		t.Fatalf("admin = %q (%v)", admin, err)
	}
	keyword := "host=127.0.0.1 port=55853 dbname=gxb_bk user=postgres"
	if name, err := DatabaseNameFromDSN(keyword); err != nil || name != "gxb_bk" {
		t.Fatalf("keyword name = %q (%v)", name, err)
	}
	if _, err := DatabaseNameFromDSN("host=127.0.0.1"); err == nil || strings.Contains(err.Error(), "127.0.0.1") {
		t.Fatalf("a DSN without a database leaked: %v", err)
	}
}

func TestSnapshotStoresNameAndPin(t *testing.T) {
	service, _, _ := newBackupService(t)
	operation, err := service.Snapshot(context.Background(), SnapshotOptions{Kind: BackupKindManual, Reason: "named", Name: "  before awakening  ", Pinned: true})
	if err != nil || operation.State != OperationDone {
		t.Fatalf("snapshot: %+v %v", operation, err)
	}
	list, err := service.List(context.Background())
	if err != nil || len(list.Backups) != 1 {
		t.Fatalf("list: %+v %v", list, err)
	}
	entry := list.Backups[0]
	if entry.Name != "before awakening" || !entry.Pinned {
		t.Fatalf("entry = %+v", entry)
	}
}

func TestSnapshotPinRequiresAName(t *testing.T) {
	service, _, _ := newBackupService(t)
	if _, err := service.Snapshot(context.Background(), SnapshotOptions{Kind: BackupKindManual, Reason: "r", Pinned: true}); !backupRefusalCode(err, CodeBackupNameInvalid) {
		t.Fatalf("pin without a name: %v", err)
	}
}

func TestPinAndUnpinRewriteTheManifest(t *testing.T) {
	service, _, _ := newBackupService(t)
	id := "20260101T000000.000000000Z-manual"
	writeSnapshot(t, service.Directory, id, BackupKindManual, time.Date(2026, 11, 20, 10, 0, 0, 0, time.UTC), "content")
	pinned, err := service.Pin(id, "  baseline  ")
	if err != nil || !pinned.Pinned || pinned.Name != "baseline" {
		t.Fatalf("pin = %+v (%v)", pinned, err)
	}
	stored, err := readBackupManifest(filepath.Join(service.Directory, id+backupManifestSuffix))
	if err != nil || !stored.Pinned || stored.Name != "baseline" {
		t.Fatalf("stored manifest = %+v (%v)", stored, err)
	}
	unpinned, err := service.Unpin(id)
	if err != nil || unpinned.Pinned || unpinned.Name != "baseline" {
		t.Fatalf("unpin = %+v (%v)", unpinned, err)
	}
}

func TestPinRefusesUnknownIDAndInvalidName(t *testing.T) {
	service, _, _ := newBackupService(t)
	id := "20260101T000000.000000000Z-manual"
	writeSnapshot(t, service.Directory, id, BackupKindManual, time.Date(2026, 11, 20, 10, 0, 0, 0, time.UTC), "content")
	for name, testCase := range map[string]struct {
		id   string
		name string
		code string
	}{
		"unknown id":    {id: "20260102T000000.000000000Z-manual", name: "x", code: CodeBackupUnknown},
		"blank name":    {id: id, name: "   ", code: CodeBackupNameInvalid},
		"too long":      {id: id, name: strings.Repeat("x", 81), code: CodeBackupNameInvalid},
		"not printable": {id: id, name: "bad\nname", code: CodeBackupNameInvalid},
	} {
		t.Run(name, func(t *testing.T) {
			if _, err := service.Pin(testCase.id, testCase.name); !backupRefusalCode(err, testCase.code) {
				t.Fatalf("pin: %v", err)
			}
		})
	}
	if _, err := service.Unpin("20260102T000000.000000000Z-manual"); !backupRefusalCode(err, CodeBackupUnknown) {
		t.Fatalf("unpin unknown: %v", err)
	}
}

func TestPruneNeverRemovesPinnedSnapshots(t *testing.T) {
	service, _, _ := newBackupService(t)
	service.Keep = 1
	base := time.Date(2026, 11, 20, 10, 0, 0, 0, time.UTC)
	ids := make([]string, 6)
	for index := range 6 {
		ids[index] = "2026010" + string(rune('1'+index)) + "T000000.000000000Z-safety"
		writeSnapshot(t, service.Directory, ids[index], BackupKindSafety, base.Add(time.Duration(index)*time.Minute), "snapshot-"+ids[index])
	}
	for _, pinned := range []string{ids[0], ids[2], ids[4]} {
		if _, err := service.Pin(pinned, "keep "+pinned); err != nil {
			t.Fatalf("pin %s: %v", pinned, err)
		}
	}
	result, err := service.prune(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	for _, pinned := range []string{ids[0], ids[2], ids[4], ids[5]} {
		if _, err := os.Stat(filepath.Join(service.Directory, pinned+backupDumpSuffix)); err != nil {
			t.Fatalf("snapshot %s was removed: %v", pinned, err)
		}
	}
	wantRemoved := map[string]bool{ids[1]: true, ids[3]: true}
	if len(result.Removed) != 2 {
		t.Fatalf("removed = %+v", result.Removed)
	}
	for _, removed := range result.Removed {
		if !wantRemoved[removed] {
			t.Fatalf("removed %q, want only %v", removed, wantRemoved)
		}
	}
}

func TestPinUnpinAndDeleteShareTheBackendGuard(t *testing.T) {
	service, _, _ := newBackupService(t)
	id := "20260101T000000.000000000Z-manual"
	writeSnapshot(t, service.Directory, id, BackupKindManual, time.Date(2026, 11, 20, 10, 0, 0, 0, time.UTC), "content")
	if !service.Guard.TryLock() {
		t.Fatal("the guard was already held")
	}
	_, pinErr := service.Pin(id, "keep me")
	_, unpinErr := service.Unpin(id)
	_, deleteErr := service.Delete(id, "cleanup")
	service.Guard.Unlock()
	for name, err := range map[string]error{"pin": pinErr, "unpin": unpinErr, "delete": deleteErr} {
		if !backupRefusalCode(err, CodeBackendBusy) {
			t.Fatalf("%s while the guard is held: %v", name, err)
		}
	}
	for _, suffix := range []string{backupDumpSuffix, backupManifestSuffix} {
		if _, err := os.Stat(filepath.Join(service.Directory, id+suffix)); err != nil {
			t.Fatalf("the %s file was touched: %v", suffix, err)
		}
	}
}

func TestRestoreMigratesAnOlderSnapshotForward(t *testing.T) {
	service, tools, process := newBackupService(t)
	service.MigrationsDirectory = "/tmp/gxb-migrations"
	id := "20260101T000000.000000000Z-manual"
	manifest := writeSnapshot(t, service.Directory, id, BackupKindManual, time.Date(2026, 11, 20, 10, 0, 0, 0, time.UTC), "older")
	manifest.Migration = 182
	if err := writeBackupManifest(filepath.Join(service.Directory, id+backupManifestSuffix), manifest); err != nil {
		t.Fatal(err)
	}
	operation, err := service.Restore(context.Background(), id, "older snapshot")
	if err != nil || operation.State != OperationDone {
		t.Fatalf("restore: %+v %v", operation, err)
	}
	if tools.migrateDir != "/tmp/gxb-migrations" {
		t.Fatalf("migrate folder = %q, calls = %+v", tools.migrateDir, tools.calls)
	}
	if !process.running {
		t.Fatal("the backend was not started again")
	}
}

func TestRestoreRefusesAnOlderSnapshotWithoutAMigrationsFolder(t *testing.T) {
	service, _, process := newBackupService(t)
	id := "20260101T000000.000000000Z-manual"
	manifest := writeSnapshot(t, service.Directory, id, BackupKindManual, time.Date(2026, 11, 20, 10, 0, 0, 0, time.UTC), "older")
	manifest.Migration = 182
	if err := writeBackupManifest(filepath.Join(service.Directory, id+backupManifestSuffix), manifest); err != nil {
		t.Fatal(err)
	}
	if _, err := service.Restore(context.Background(), id, "older snapshot"); !backupRefusalCode(err, CodeBackupToolsMissing) {
		t.Fatalf("restore: %v", err)
	}
	if process.stops != 0 {
		t.Fatal("the backend was stopped before the migration check")
	}
}

func testVersion() operator.VersionInfo {
	backendVersion := "v0.167.0"
	gitCommit := "abc123"
	return operator.VersionInfo{BackendVersion: &backendVersion, GitCommit: &gitCommit, Migration: 183}
}

func backupRefusalCode(err error, code string) bool {
	var refusal *Refusal
	return errors.As(err, &refusal) && refusal.Code == code
}

func TestPruneNeverRemovesManualSnapshots(t *testing.T) {
	service, _, _ := newBackupService(t)
	service.Keep = 1
	base := time.Date(2026, 11, 20, 10, 0, 0, 0, time.UTC)
	for index := range 6 {
		id := "2026010" + string(rune('1'+index)) + "T000000.000000000Z-manual"
		writeSnapshot(t, service.Directory, id, BackupKindManual, base.Add(time.Duration(index)*time.Minute), "snapshot-"+id)
	}
	result, err := service.prune(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if len(result.Removed) != 0 {
		t.Fatalf("manual snapshots were pruned: %+v", result.Removed)
	}
}

func TestManualSnapshotRefusesAtTheTotalCap(t *testing.T) {
	service, _, _ := newBackupService(t)
	service.Max = 2
	base := time.Date(2026, 11, 20, 10, 0, 0, 0, time.UTC)
	for index := range 2 {
		id := "2026010" + string(rune('1'+index)) + "T000000.000000000Z-manual"
		writeSnapshot(t, service.Directory, id, BackupKindManual, base.Add(time.Duration(index)*time.Minute), "snapshot-"+id)
	}
	if _, err := service.Snapshot(context.Background(), SnapshotOptions{Kind: BackupKindManual, Reason: "cap"}); !backupRefusalCode(err, CodeBackupCap) {
		t.Fatalf("snapshot at the cap: %v", err)
	} else if !strings.Contains(err.Error(), "2 snapshots kept; delete or unpin one first") {
		t.Fatalf("cap message = %v", err)
	}
}

func TestDeleteRefusesPinnedAndDamagedAndRemovesAnySnapshot(t *testing.T) {
	service, _, _ := newBackupService(t)
	base := time.Date(2026, 11, 20, 10, 0, 0, 0, time.UTC)
	manualID := "20260101T000000.000000000Z-manual"
	writeSnapshot(t, service.Directory, manualID, BackupKindManual, base, "manual")
	if _, err := service.Pin(manualID, "keep me"); err != nil {
		t.Fatal(err)
	}
	if _, err := service.Delete(manualID, "pinned"); !backupRefusalCode(err, CodeBackupPinned) {
		t.Fatalf("delete pinned: %v", err)
	}
	if _, err := service.Unpin(manualID); err != nil {
		t.Fatal(err)
	}
	if _, err := service.Delete(manualID, "no longer needed"); err != nil {
		t.Fatalf("delete manual: %v", err)
	}
	if _, err := os.Stat(filepath.Join(service.Directory, manualID+backupDumpSuffix)); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("the deleted dump still exists: %v", err)
	}

	safetyID := "20260102T000000.000000000Z-safety"
	writeSnapshot(t, service.Directory, safetyID, BackupKindSafety, base.Add(time.Minute), "automatic")
	if _, err := service.Delete(safetyID, "automatic"); err != nil {
		t.Fatalf("delete automatic: %v", err)
	}
	if _, err := os.Stat(filepath.Join(service.Directory, safetyID+backupDumpSuffix)); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("the deleted automatic dump still exists: %v", err)
	}

	damagedID := "20260103T000000.000000000Z-manual"
	damaged := writeSnapshot(t, service.Directory, damagedID, BackupKindManual, base.Add(2*time.Minute), "damaged")
	damaged.SHA256 = strings.Repeat("f", 64)
	if err := writeBackupManifest(filepath.Join(service.Directory, damagedID+backupManifestSuffix), damaged); err != nil {
		t.Fatal(err)
	}
	if _, err := service.Delete(damagedID, "damaged"); !backupRefusalCode(err, CodeBackupDamaged) {
		t.Fatalf("delete damaged: %v", err)
	}
	if _, err := os.Stat(filepath.Join(service.Directory, damagedID+backupDumpSuffix)); err != nil {
		t.Fatalf("the damaged dump was deleted: %v", err)
	}
}

func TestDeleteManyReportsPartialFailurePerSnapshot(t *testing.T) {
	service, _, _ := newBackupService(t)
	base := time.Date(2026, 11, 20, 10, 0, 0, 0, time.UTC)
	pinnedID := "20260101T000000.000000000Z-manual"
	firstID := "20260102T000000.000000000Z-manual"
	secondID := "20260103T000000.000000000Z-safety"
	writeSnapshot(t, service.Directory, pinnedID, BackupKindManual, base, "pinned")
	writeSnapshot(t, service.Directory, firstID, BackupKindManual, base.Add(time.Minute), "first")
	writeSnapshot(t, service.Directory, secondID, BackupKindSafety, base.Add(2*time.Minute), "second")
	if _, err := service.Pin(pinnedID, "keep me"); err != nil {
		t.Fatal(err)
	}
	result := service.DeleteMany([]string{pinnedID, firstID, secondID, firstID}, "cleanup")
	if len(result.Deleted) != 2 || result.Deleted[0] != firstID || result.Deleted[1] != secondID {
		t.Fatalf("deleted = %+v", result.Deleted)
	}
	if len(result.Failed) != 1 || result.Failed[0].ID != pinnedID || result.Failed[0].ErrorCode != CodeBackupPinned || result.Failed[0].Message == "" {
		t.Fatalf("failed = %+v", result.Failed)
	}
	for _, id := range []string{firstID, secondID} {
		if _, err := os.Stat(filepath.Join(service.Directory, id+backupDumpSuffix)); !errors.Is(err, os.ErrNotExist) {
			t.Fatalf("snapshot %s was not deleted: %v", id, err)
		}
	}
	if _, err := os.Stat(filepath.Join(service.Directory, pinnedID+backupDumpSuffix)); err != nil {
		t.Fatalf("the pinned snapshot was deleted: %v", err)
	}
}

func TestEmptyBackupPathRefusesSnapshotAndRestore(t *testing.T) {
	service, _, _ := newBackupService(t)
	service.Directory = ""
	if _, err := service.Snapshot(context.Background(), SnapshotOptions{Kind: BackupKindManual, Reason: "no folder"}); !backupRefusalCode(err, CodeBackupPathMissing) {
		t.Fatalf("snapshot without a folder: %v", err)
	}
	if _, err := service.Restore(context.Background(), "20260101T000000.000000000Z-manual", "no folder"); !backupRefusalCode(err, CodeBackupPathMissing) {
		t.Fatalf("restore without a folder: %v", err)
	}
	list, err := service.List(context.Background())
	if err != nil || list.Directory != "" || len(list.Backups) != 0 {
		t.Fatalf("list without a folder: %+v %v", list, err)
	}
}

func TestForeignDumpIsListedDamagedAndNeverRestoredOrDeleted(t *testing.T) {
	service, _, _ := newBackupService(t)
	foreign := filepath.Join(service.Directory, "foreign.dump")
	if err := os.WriteFile(foreign, []byte("not ours"), 0o600); err != nil {
		t.Fatal(err)
	}
	list, err := service.List(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if len(list.Backups) != 1 || !list.Backups[0].Damaged || list.Backups[0].ID != "foreign" {
		t.Fatalf("foreign dump list = %+v", list.Backups)
	}
	if _, err := service.Delete("foreign", "foreign"); !backupRefusalCode(err, CodeBackupUnknown) {
		t.Fatalf("delete foreign: %v", err)
	}
	if _, err := service.Restore(context.Background(), "foreign", "foreign"); !backupRefusalCode(err, CodeBackupUnknown) {
		t.Fatalf("restore foreign: %v", err)
	}
	if _, err := os.Stat(foreign); err != nil {
		t.Fatalf("the foreign dump was deleted: %v", err)
	}
}

func TestSetBackupPathRescansAndRestores(t *testing.T) {
	root := t.TempDir()
	config := `{"listen":"127.0.0.1:8090","backend":{"operator_addr":"127.0.0.1:8091"}}`
	if err := os.WriteFile(filepath.Join(root, AgentConfigFileName), []byte(config), 0o600); err != nil {
		t.Fatal(err)
	}
	target := t.TempDir()
	id := "20260101T000000.000000000Z-manual"
	writeSnapshot(t, target, id, BackupKindManual, time.Date(2026, 11, 20, 10, 0, 0, 0, time.UTC), "existing")
	service, _, _ := newBackupService(t)
	service.Directory = ""
	service.Root = root

	list, err := service.SetPath(target)
	if err != nil {
		t.Fatalf("set path: %v", err)
	}
	if list.Directory != target || len(list.Backups) != 1 || list.Backups[0].ID != id {
		t.Fatalf("rescanned list = %+v", list)
	}
	stored, err := LoadConfig(root)
	if err != nil || stored.BackupPath != target {
		t.Fatalf("stored path = %+v (%v)", stored.BackupPath, err)
	}
	operation, err := service.Restore(context.Background(), id, "restore from the configured folder")
	if err != nil || operation.State != OperationDone {
		t.Fatalf("restore: %+v %v", operation, err)
	}
}

func TestSetBackupPathRefusesAFolderInsideTheOTARoot(t *testing.T) {
	root := t.TempDir()
	otaRoot := t.TempDir()
	config := `{"listen":"127.0.0.1:8090","ota_root":"` + otaRoot + `","backend":{"operator_addr":"127.0.0.1:8091"}}`
	if err := os.WriteFile(filepath.Join(root, AgentConfigFileName), []byte(config), 0o600); err != nil {
		t.Fatal(err)
	}
	service, _, _ := newBackupService(t)
	service.Directory = ""
	service.Root = root
	if _, err := service.SetPath(filepath.Join(otaRoot, "backups")); !backupRefusalCode(err, CodeBackupPathInvalid) {
		t.Fatalf("inside ota_root: %v", err)
	}
}

func TestSetScheduleAcceptsEachChoice(t *testing.T) {
	base := `{"listen":"127.0.0.1:8090","backend":{"operator_addr":"127.0.0.1:8091"}}`
	for _, testCase := range []struct {
		value string
		hours int
	}{
		{value: "1d", hours: 24},
		{value: "7d", hours: 168},
		{value: "15d", hours: 360},
		{value: "30d", hours: 720},
		{value: "off", hours: 0},
	} {
		t.Run(testCase.value, func(t *testing.T) {
			service := newBackupServiceWithConfig(t, base)
			list, err := service.SetSchedule(testCase.value)
			if err != nil || list.Schedule != testCase.value {
				t.Fatalf("set schedule: %+v %v", list, err)
			}
			stored, err := LoadConfig(service.Root)
			if err != nil || stored.BackupEveryHours == nil || *stored.BackupEveryHours != testCase.hours {
				t.Fatalf("stored schedule = %+v (%v)", stored.BackupEveryHours, err)
			}
			if service.scheduleInterval() != time.Duration(testCase.hours)*time.Hour {
				t.Fatalf("running interval = %v", service.scheduleInterval())
			}
		})
	}
	service := newBackupServiceWithConfig(t, base)
	if _, err := service.SetSchedule("2d"); !backupRefusalCode(err, CodeSettingsInvalid) {
		t.Fatalf("invalid schedule: %v", err)
	}
}

func TestSetKeepAcceptsEachChoice(t *testing.T) {
	base := `{"listen":"127.0.0.1:8090","backend":{"operator_addr":"127.0.0.1:8091"}}`
	for _, value := range []int{5, 10, 15, 30} {
		t.Run(strconv.Itoa(value), func(t *testing.T) {
			service := newBackupServiceWithConfig(t, base)
			result, err := service.SetKeep(value)
			if err != nil || result.Keep != value || len(result.Removed) != 0 {
				t.Fatalf("set keep: %+v %v", result, err)
			}
			stored, err := LoadConfig(service.Root)
			if err != nil || stored.BackupKeepValue() != value {
				t.Fatalf("stored keep = %d (%v)", stored.BackupKeepValue(), err)
			}
			if service.keep() != value {
				t.Fatalf("running keep = %d", service.keep())
			}
		})
	}
	service := newBackupServiceWithConfig(t, base)
	if _, err := service.SetKeep(7); !backupRefusalCode(err, CodeSettingsInvalid) {
		t.Fatalf("invalid keep: %v", err)
	}
}

func TestSetKeepLoweringPrunesTheExcessAutomaticSnapshots(t *testing.T) {
	service := newBackupServiceWithConfig(t, `{"listen":"127.0.0.1:8090","backup_keep":30,"backend":{"operator_addr":"127.0.0.1:8091"}}`)
	service.Keep = 30
	base := time.Date(2026, 11, 20, 10, 0, 0, 0, time.UTC)
	ids := make([]string, 8)
	for index := range 8 {
		ids[index] = "2026010" + string(rune('1'+index)) + "T000000.000000000Z-safety"
		writeSnapshot(t, service.Directory, ids[index], BackupKindSafety, base.Add(time.Duration(index)*time.Minute), "snapshot-"+ids[index])
	}
	result, err := service.SetKeep(5)
	if err != nil {
		t.Fatalf("set keep: %v", err)
	}
	if result.Keep != 5 || len(result.Removed) != 3 {
		t.Fatalf("result = %+v", result)
	}
	for _, id := range ids[:3] {
		if _, err := os.Stat(filepath.Join(service.Directory, id+backupDumpSuffix)); !errors.Is(err, os.ErrNotExist) {
			t.Fatalf("snapshot %s was not pruned: %v", id, err)
		}
	}
	for _, id := range ids[3:] {
		if _, err := os.Stat(filepath.Join(service.Directory, id+backupDumpSuffix)); err != nil {
			t.Fatalf("snapshot %s was pruned: %v", id, err)
		}
	}
	stored, err := LoadConfig(service.Root)
	if err != nil || stored.BackupKeepValue() != 5 {
		t.Fatalf("stored keep = %d (%v)", stored.BackupKeepValue(), err)
	}
}

// newBackupServiceWithConfig is newBackupService with a writable agent.json, so
// the setting commands have a root to persist into.
func newBackupServiceWithConfig(t *testing.T, contents string) *BackupService {
	t.Helper()
	root := t.TempDir()
	if err := os.WriteFile(filepath.Join(root, AgentConfigFileName), []byte(contents), 0o600); err != nil {
		t.Fatal(err)
	}
	service, _, _ := newBackupService(t)
	service.Root = root
	return service
}

func TestAutomaticBackupDue(t *testing.T) {
	now := time.Date(2026, 11, 23, 12, 0, 0, 0, time.UTC)
	for name, testCase := range map[string]struct {
		last    time.Time
		hours   int
		running bool
		want    bool
	}{
		"no automatic snapshot": {last: time.Time{}, hours: 24, running: true, want: true},
		"too soon":              {last: now.Add(-23 * time.Hour), hours: 24, running: true, want: false},
		"due":                   {last: now.Add(-24 * time.Hour), hours: 24, running: true, want: true},
		"backend stopped":       {last: now.Add(-48 * time.Hour), hours: 24, running: false, want: false},
		"schedule off":          {last: now.Add(-48 * time.Hour), hours: 0, running: true, want: false},
	} {
		t.Run(name, func(t *testing.T) {
			got := AutomaticBackupDue(now, testCase.last, time.Duration(testCase.hours)*time.Hour, testCase.running)
			if got != testCase.want {
				t.Fatalf("due = %v, want %v", got, testCase.want)
			}
		})
	}
	for _, interval := range []time.Duration{24 * time.Hour, 7 * 24 * time.Hour, 15 * 24 * time.Hour, 30 * 24 * time.Hour} {
		if !AutomaticBackupDue(now, now.Add(-interval), interval, true) {
			t.Fatalf("not due after %v", interval)
		}
		if AutomaticBackupDue(now, now.Add(-interval+time.Second), interval, true) {
			t.Fatalf("due one second before %v", interval)
		}
	}
}

func TestNewestAutomaticTimeIgnoresManualSnapshots(t *testing.T) {
	newest := time.Date(2026, 11, 20, 10, 0, 0, 0, time.UTC)
	entries := []BackupEntry{
		{BackupManifest: BackupManifest{Kind: BackupKindManual, CreatedAt: newest.Add(time.Hour)}},
		{BackupManifest: BackupManifest{Kind: BackupKindScheduled, CreatedAt: newest}},
	}
	if got := newestAutomaticTime(entries); !got.Equal(newest) {
		t.Fatalf("newest automatic = %v", got)
	}
}

// TestSettingsSettersRaceWithTheScheduleReader is the finding-1 regression: the
// schedule goroutine reads Directory, Keep and Schedule while the HTTP handlers
// write them. Run with -race.
func TestSettingsSettersRaceWithTheScheduleReader(t *testing.T) {
	root := t.TempDir()
	config := `{"listen":"127.0.0.1:8090","backend":{"operator_addr":"127.0.0.1:8091"}}`
	if err := os.WriteFile(filepath.Join(root, AgentConfigFileName), []byte(config), 0o600); err != nil {
		t.Fatal(err)
	}
	service, _, process := newBackupService(t)
	process.running = false
	service.Root = root
	service.writeSchedule(time.Hour)
	other := t.TempDir()

	stop := make(chan struct{})
	var reader sync.WaitGroup
	reader.Add(1)
	go func() {
		defer reader.Done()
		for {
			select {
			case <-stop:
				return
			default:
			}
			service.snapshotScheduled(context.Background())
			_ = service.Settings()
			_, _ = service.prune(context.Background())
		}
	}()

	var setters sync.WaitGroup
	for index := range 20 {
		setters.Add(1)
		go func(index int) {
			defer setters.Done()
			if index%2 == 0 {
				_, _ = service.SetPath(other)
				_, _ = service.SetSchedule("1d")
				return
			}
			_, _ = service.SetPath(service.directory())
			_, _ = service.SetSchedule("off")
			_, _ = service.SetKeep(10)
			_, _ = service.SetKeep(5)
		}(index)
	}
	setters.Wait()
	close(stop)
	reader.Wait()
}

// TestSetKeepLoweringWhileBusyKeepsTheStoredValue is the finding-2 regression:
// the guard is taken before the new value is saved, so a refusal changes
// neither agent.json nor the live retention.
func TestSetKeepLoweringWhileBusyKeepsTheStoredValue(t *testing.T) {
	service := newBackupServiceWithConfig(t, `{"listen":"127.0.0.1:8090","backup_keep":10,"backend":{"operator_addr":"127.0.0.1:8091"}}`)
	service.writeKeep(10)
	if !service.Guard.TryLock() {
		t.Fatal("the guard was already held")
	}
	defer service.Guard.Unlock()
	if _, err := service.SetKeep(5); !backupRefusalCode(err, CodeBackendBusy) {
		t.Fatalf("set keep while busy: %v", err)
	}
	stored, err := LoadConfig(service.Root)
	if err != nil || stored.BackupKeepValue() != 10 {
		t.Fatalf("a busy lowering changed agent.json: keep = %d (%v)", stored.BackupKeepValue(), err)
	}
	if service.keep() != 10 {
		t.Fatalf("a busy lowering changed the live keep: %d", service.keep())
	}
}

// TestKeepPruneCountsProtectedAutomaticSnapshots is the finding-4 regression:
// pinned and damaged automatic snapshots consume keep slots, so the preview the
// GUI shows must count the same snapshots the agent's prune does.
func TestKeepPruneCountsProtectedAutomaticSnapshots(t *testing.T) {
	base := time.Date(2026, 11, 20, 10, 0, 0, 0, time.UTC)
	entries := make([]BackupEntry, 0, 9)
	for index := range 8 {
		entries = append(entries, BackupEntry{BackupManifest: BackupManifest{
			ID:        "id" + strconv.Itoa(index),
			Kind:      BackupKindScheduled,
			CreatedAt: base.Add(-time.Duration(index) * time.Minute),
		}})
	}
	entries[1].Pinned = true
	entries[2].Damaged = true
	entries = append(entries, BackupEntry{BackupManifest: BackupManifest{
		ID:        "manual",
		Kind:      BackupKindManual,
		CreatedAt: base.Add(-time.Hour),
	}})
	counts := keepPruneCounts(entries, "")
	if counts["5"] != 3 {
		t.Fatalf("keep 5 removes %d automatic snapshots, want 3", counts["5"])
	}
	if counts["10"] != 0 {
		t.Fatalf("keep 10 removes %d automatic snapshots, want 0", counts["10"])
	}
}

// TestSetPathRefusesWhileAnOperationRuns covers the other half of finding 1: a
// folder change must not land in the middle of a snapshot or restore.
func TestSetPathRefusesWhileAnOperationRuns(t *testing.T) {
	root := t.TempDir()
	config := `{"listen":"127.0.0.1:8090","backend":{"operator_addr":"127.0.0.1:8091"}}`
	if err := os.WriteFile(filepath.Join(root, AgentConfigFileName), []byte(config), 0o600); err != nil {
		t.Fatal(err)
	}
	service, _, _ := newBackupService(t)
	service.Root = root
	if !service.Guard.TryLock() {
		t.Fatal("the guard was already held")
	}
	defer service.Guard.Unlock()
	if _, err := service.SetPath(t.TempDir()); !backupRefusalCode(err, CodeBackendBusy) {
		t.Fatalf("set path while busy: %v", err)
	}
	stored, err := LoadConfig(root)
	if err != nil || stored.BackupPath != "" {
		t.Fatalf("a busy set path changed agent.json: %q (%v)", stored.BackupPath, err)
	}
}
