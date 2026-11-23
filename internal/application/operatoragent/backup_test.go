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
	"strings"
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
}

func (tools *fakeTools) Dump(_ context.Context, _ string, destination string) error {
	tools.calls = append(tools.calls, "dump")
	if tools.dumpErr != nil {
		return tools.dumpErr
	}
	return os.WriteFile(destination, []byte(tools.dumpContent), 0o600)
}

func (tools *fakeTools) VerifyDump(context.Context, string) error {
	tools.calls = append(tools.calls, "verify")
	return tools.verifyErr
}

func (tools *fakeTools) Restore(_ context.Context, _ string, _ string) error {
	tools.calls = append(tools.calls, "restore")
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
	running  bool
	starts   int
	stops    int
	startErr error
	stopErr  error
}

func (process *fakeProcess) Start(bool, string) error {
	if process.startErr != nil {
		return process.startErr
	}
	process.starts++
	process.running = true
	return nil
}

func (process *fakeProcess) Stop() error {
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
		ids[index] = "2026010" + string(rune('1'+index)) + "T000000.000000000Z-manual"
		content := "snapshot-" + ids[index]
		manifest := writeSnapshot(t, service.Directory, ids[index], BackupKindManual, base.Add(time.Duration(index)*time.Minute), content)
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
		ids[index] = "2026010" + string(rune('1'+index)) + "T000000.000000000Z-manual"
		writeSnapshot(t, service.Directory, ids[index], BackupKindManual, base.Add(time.Duration(index)*time.Minute), "snapshot")
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

func TestUpdateBackendSnapshotsThenStops(t *testing.T) {
	service, _, process := newBackupService(t)
	operation, err := service.UpdateBackend(context.Background(), "upgrade")
	if err != nil || operation.State != OperationDone {
		t.Fatalf("update backend: %+v %v", operation, err)
	}
	if process.stops != 1 || process.running {
		t.Fatalf("process = %+v", process)
	}
	list, err := service.List(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if len(list.Backups) != 1 || list.Backups[0].Kind != BackupKindPreUpdate {
		t.Fatalf("list = %+v", list.Backups)
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
		ids[index] = "2026010" + string(rune('1'+index)) + "T000000.000000000Z-manual"
		writeSnapshot(t, service.Directory, ids[index], BackupKindManual, base.Add(time.Duration(index)*time.Minute), "snapshot-"+ids[index])
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
