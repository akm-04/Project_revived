package operatoragent

import (
	"context"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// updateBackendService is newBackupService with an agent.json root, because a
// swap rewrites agent.json.
func updateBackendService(t *testing.T) (*BackupService, *fakeTools, *fakeProcess, string) {
	t.Helper()
	service, tools, process := newBackupService(t)
	root := t.TempDir()
	writeUpdateAgentConfig(t, root, `{"listen":"127.0.0.1:8090","backend":{"operator_addr":"127.0.0.1:1"}}`)
	service.Root = root
	return service, tools, process, root
}

func writeUpdateAgentConfig(t *testing.T, root, contents string) {
	t.Helper()
	if err := os.WriteFile(filepath.Join(root, AgentConfigFileName), []byte(contents), 0o600); err != nil {
		t.Fatal(err)
	}
}

// writeReleaseFolder lays out one complete release folder.
func writeReleaseFolder(t *testing.T, directory, commit string) {
	t.Helper()
	binDirectory := filepath.Join(directory, "bin")
	if err := os.MkdirAll(binDirectory, 0o755); err != nil {
		t.Fatal(err)
	}
	for _, name := range serverBinaryNames {
		writeReleaseExecutable(t, filepath.Join(binDirectory, serverBinaryFileName(name)))
	}
	if err := os.MkdirAll(filepath.Join(directory, "migrations"), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(directory, "migrations", "00001_release.sql"), []byte("-- up\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(directory, "BACKEND_COMMIT"), []byte(commit+"\n"), 0o644); err != nil {
		t.Fatal(err)
	}
}

func writeReleaseExecutable(t *testing.T, path string) {
	t.Helper()
	if err := os.WriteFile(path, []byte("#!/bin/sh\n"), 0o755); err != nil {
		t.Fatal(err)
	}
}

func eventIndex(events []string, event string) int {
	for index, value := range events {
		if value == event {
			return index
		}
	}
	return -1
}

func TestUpdateBackendRefusesAnIncompleteReleaseAndNamesTheFile(t *testing.T) {
	cases := []struct {
		name    string
		prepare func(t *testing.T, directory string)
		message string
	}{
		{name: "missing binary", prepare: func(t *testing.T, directory string) {
			t.Helper()
			if err := os.Remove(filepath.Join(directory, "bin", serverBinaryFileName("gxb-worker"))); err != nil {
				t.Fatal(err)
			}
		}, message: "bin/" + serverBinaryFileName("gxb-worker") + " is missing"},
		{name: "missing migrations", prepare: func(t *testing.T, directory string) {
			t.Helper()
			if err := os.RemoveAll(filepath.Join(directory, "migrations")); err != nil {
				t.Fatal(err)
			}
		}, message: "migrations/ is missing"},
		{name: "missing commit", prepare: func(t *testing.T, directory string) {
			t.Helper()
			if err := os.Remove(filepath.Join(directory, "BACKEND_COMMIT")); err != nil {
				t.Fatal(err)
			}
		}, message: "BACKEND_COMMIT is missing"},
	}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			service, _, process, _ := updateBackendService(t)
			release := filepath.Join(t.TempDir(), "release")
			writeReleaseFolder(t, release, "abc123")
			testCase.prepare(t, release)
			_, err := service.UpdateBackend(context.Background(), release, "upgrade")
			var refusal *Refusal
			if !errors.As(err, &refusal) || refusal.Code != CodeBackupPathInvalid {
				t.Fatalf("error = %v", err)
			}
			if !strings.Contains(refusal.Message, testCase.message) {
				t.Fatalf("message = %q, want %q", refusal.Message, testCase.message)
			}
			if process.stops != 0 || process.starts != 0 {
				t.Fatalf("the backend was touched: %+v", process)
			}
			if list, _ := service.List(context.Background()); len(list.Backups) != 0 {
				t.Fatalf("a snapshot was taken before validation: %+v", list.Backups)
			}
		})
	}
}

func TestUpdateBackendRefusesAFolderThatIsNeitherReleaseNorSource(t *testing.T) {
	service, _, _, _ := updateBackendService(t)
	_, err := service.UpdateBackend(context.Background(), t.TempDir(), "upgrade")
	var refusal *Refusal
	if !errors.As(err, &refusal) || refusal.Code != CodeBackupPathInvalid {
		t.Fatalf("error = %v", err)
	}
	if !strings.Contains(refusal.Message, "bin/gxb-api") || !strings.Contains(refusal.Message, "go.mod") {
		t.Fatalf("message = %q", refusal.Message)
	}
}

func TestUpdateBackendSnapshotsBeforeStopAndMigratesBeforeSwitch(t *testing.T) {
	events := []string{}
	service, tools, process, root := updateBackendService(t)
	tools.events = &events
	process.events = &events
	release := filepath.Join(t.TempDir(), "release")
	writeReleaseFolder(t, release, "abc123")

	operation, err := service.UpdateBackend(context.Background(), release, "upgrade")
	if err != nil || operation.State != OperationDone {
		t.Fatalf("update = %+v %v", operation, err)
	}
	if !process.running || process.lastStartClosed {
		t.Fatalf("the new release was not started open: %+v", process)
	}
	if tools.migrateDir != filepath.Join(release, "migrations") {
		t.Fatalf("migrated %q", tools.migrateDir)
	}
	if index, stop, migrate, start := eventIndex(events, "dump"), eventIndex(events, "stop"), eventIndex(events, "migrate"), eventIndex(events, "start"); index < 0 || stop < index || migrate < stop || start < migrate {
		t.Fatalf("step order = %v", events)
	}
	config, err := LoadConfig(root)
	if err != nil {
		t.Fatal(err)
	}
	if config.Backend.Binary != filepath.Join(release, "bin", serverBinaryFileName("gxb-api")) || config.Backend.MigrationsDir != filepath.Join(release, "migrations") {
		t.Fatalf("agent.json backend = %+v", config.Backend)
	}
	list, err := service.List(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if len(list.Backups) != 1 || list.Backups[0].Kind != BackupKindPreUpdate {
		t.Fatalf("snapshots = %+v", list.Backups)
	}
}

func TestUpdateBackendBuildsASourceTreeIntoReleases(t *testing.T) {
	service, _, process, root := updateBackendService(t)
	toolchain := t.TempDir()
	writeUpdateAgentConfig(t, root, fmt.Sprintf(`{"listen":"127.0.0.1:8090","toolchain_path":%q,"backend":{"operator_addr":"127.0.0.1:1"}}`, toolchain))
	source := t.TempDir()
	if err := os.WriteFile(filepath.Join(source, "go.mod"), []byte("module example\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(filepath.Join(source, "migrations"), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(source, "migrations", "00001_source.sql"), []byte("-- up\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(source, "BACKEND_COMMIT"), []byte("def456\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	var builtSource, builtToolchain, builtBin string
	service.BuildRelease = func(_ context.Context, sourceDirectory, toolchainDirectory, binDirectory string) error {
		builtSource, builtToolchain, builtBin = sourceDirectory, toolchainDirectory, binDirectory
		for _, name := range serverBinaryNames {
			if err := os.WriteFile(filepath.Join(binDirectory, serverBinaryFileName(name)), []byte("#!/bin/sh\n"), 0o755); err != nil {
				return err
			}
		}
		return nil
	}

	operation, err := service.UpdateBackend(context.Background(), source, "build and swap")
	if err != nil || operation.State != OperationDone {
		t.Fatalf("update = %+v %v", operation, err)
	}
	release := filepath.Join(root, "releases", "def456")
	if builtSource != source || builtToolchain != toolchain || filepath.Base(builtBin) != "bin" || !strings.HasPrefix(builtBin, filepath.Join(root, "releases")) {
		t.Fatalf("builder saw %q %q %q", builtSource, builtToolchain, builtBin)
	}
	if _, err := os.Stat(filepath.Join(release, "bin", serverBinaryFileName("gxb-api"))); err != nil {
		t.Fatalf("the built binaries were not moved into the release: %v", err)
	}
	if _, err := os.Stat(filepath.Join(source, "bin")); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("the source tree was modified: %v", err)
	}
	if _, err := os.Stat(filepath.Join(release, "migrations", "00001_source.sql")); err != nil {
		t.Fatalf("migrations were not copied: %v", err)
	}
	commit, err := os.ReadFile(filepath.Join(release, "BACKEND_COMMIT"))
	if err != nil || strings.TrimSpace(string(commit)) != "def456" {
		t.Fatalf("BACKEND_COMMIT = %q (%v)", commit, err)
	}
	config, err := LoadConfig(root)
	if err != nil {
		t.Fatal(err)
	}
	if config.Backend.Binary != filepath.Join(release, "bin", serverBinaryFileName("gxb-api")) {
		t.Fatalf("binary = %q", config.Backend.Binary)
	}
	if !process.running {
		t.Fatal("the built release was not started")
	}
}

func TestUpdateBackendFailedStartSwitchesBackToThePreviousFolder(t *testing.T) {
	service, tools, process, root := updateBackendService(t)
	previous := filepath.Join(t.TempDir(), "previous")
	writeReleaseFolder(t, previous, "prev")
	writeUpdateAgentConfig(t, root, fmt.Sprintf(`{"listen":"127.0.0.1:8090","backend":{"binary":%q,"operator_addr":"127.0.0.1:1","migrations_dir":%q}}`, filepath.Join(previous, "bin", serverBinaryFileName("gxb-api")), filepath.Join(previous, "migrations")))
	release := filepath.Join(t.TempDir(), "release")
	writeReleaseFolder(t, release, "new789")
	process.failStarts = 1

	operation, err := service.UpdateBackend(context.Background(), release, "upgrade")
	if err == nil {
		t.Fatal("the failed start was not reported")
	}
	if operation.State != OperationFailed || operation.FailedStep != "start backend and wait" {
		t.Fatalf("operation = %+v", operation)
	}
	if !strings.Contains(err.Error(), "schema may be newer") {
		t.Fatalf("message = %q", err.Error())
	}
	if tools.migrateDir != filepath.Join(release, "migrations") {
		t.Fatalf("migrated %q", tools.migrateDir)
	}
	config, err := LoadConfig(root)
	if err != nil {
		t.Fatal(err)
	}
	if config.Backend.Binary != filepath.Join(previous, "bin", serverBinaryFileName("gxb-api")) || config.Backend.MigrationsDir != filepath.Join(previous, "migrations") {
		t.Fatalf("agent.json did not return to the previous folder: %+v", config.Backend)
	}
	if !process.running || process.starts != 1 {
		t.Fatalf("the previous folder was not started: %+v", process)
	}
}

func TestUpdateBackendSourceTreeWithoutCommitNamesTheFile(t *testing.T) {
	service, _, _, _ := updateBackendService(t)
	source := t.TempDir()
	if err := os.WriteFile(filepath.Join(source, "go.mod"), []byte("module example\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	_, err := service.UpdateBackend(context.Background(), source, "build")
	var refusal *Refusal
	if !errors.As(err, &refusal) || refusal.Code != CodeBackupPathInvalid || !strings.Contains(refusal.Message, "BACKEND_COMMIT") {
		t.Fatalf("error = %v", err)
	}
}
