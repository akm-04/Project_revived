package operatoragent

import (
	"context"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

const recoveryTestSnapshotID = "20260101T000000.000000000Z-manual"

func pendingRestoreState() restoreState {
	return restoreState{
		Phase:      "swapping",
		Database:   "gxb_bk",
		Restored:   "gxb_bk_restore_previous",
		PreRestore: "gxb_bk_prerestore_previous",
		Stamp:      "previous",
		UpdatedAt:  time.Now(),
	}
}

// failRestoreRecovery leaves a pending journal and a guard that has seen a
// failed startup recovery, the state cmd/gxb-operator reaches at agent start.
func failRestoreRecovery(t *testing.T) (*BackupService, *fakeTools) {
	t.Helper()
	service, tools, _ := newBackupService(t)
	writeSnapshot(t, service.Directory, recoveryTestSnapshotID, BackupKindManual, time.Now(), "restore me")
	if err := service.writeState(filepath.Join(service.Directory, backupStateFileName), pendingRestoreState()); err != nil {
		t.Fatal(err)
	}
	tools.queryErr = errors.New("synthetic recovery database lookup unavailable")
	if err := service.RecoverRestore(context.Background()); err == nil {
		t.Fatal("expected recovery to fail")
	}
	return service, tools
}

// TestFailedRecoveryMustBlockAnotherRestore is the A-222 regression: a new
// restore after a failed startup recovery was admitted and overwrote the only
// recovery journal.
func TestFailedRecoveryMustBlockAnotherRestore(t *testing.T) {
	service, tools := failRestoreRecovery(t)
	statePath := filepath.Join(service.Directory, backupStateFileName)
	if _, err := os.Stat(statePath); err != nil {
		t.Fatalf("recovery did not preserve its pending journal: %v", err)
	}
	tools.queryErr = nil
	operation, err := service.Restore(context.Background(), recoveryTestSnapshotID, "new restore after failed recovery")
	if err == nil {
		_, journalErr := os.Stat(statePath)
		t.Fatalf("new restore admitted after failed recovery: state=%s; previous recovery journal absent=%t", operation.State, errors.Is(journalErr, os.ErrNotExist))
	}
	if !backupRefusalCode(err, CodeBackupRecoveryRequired) {
		t.Fatalf("refusal = %v", err)
	}
	if !strings.Contains(err.Error(), backupStateFileName) {
		t.Fatalf("the refusal does not name the journal: %v", err)
	}
	stored, readErr := os.ReadFile(statePath)
	if readErr != nil {
		t.Fatalf("the refused restore removed the journal: %v", readErr)
	}
	if !strings.Contains(string(stored), `"swapping"`) {
		t.Fatalf("the refusal overwrote the journal: %s", stored)
	}
}

func TestFailedRecoveryRefusesEveryDestructiveAction(t *testing.T) {
	service, _ := failRestoreRecovery(t)
	service.Keep = 30
	maintenance := Maintenance{Guard: service.Guard}
	actions := map[string]func() error{
		"restore": func() error {
			_, err := service.Restore(context.Background(), recoveryTestSnapshotID, "restore")
			return err
		},
		"start restore": func() error {
			_, err := service.StartRestore(context.Background(), recoveryTestSnapshotID, "restore")
			return err
		},
		"delete": func() error {
			_, err := service.Delete(recoveryTestSnapshotID, "delete")
			return err
		},
		"pin": func() error {
			_, err := service.Pin(recoveryTestSnapshotID, "pin")
			return err
		},
		"unpin": func() error {
			_, err := service.Unpin(recoveryTestSnapshotID)
			return err
		},
		"prune": func() error {
			_, err := service.Prune(context.Background())
			return err
		},
		"set keep": func() error {
			_, err := service.SetKeep(5)
			return err
		},
		"update backend": func() error {
			_, err := service.UpdateBackend(context.Background(), "/srv/backend", "update")
			return err
		},
		"publish": func() error {
			_, err := maintenance.Publish(context.Background(), "1.631.2", "publish", "publish-key")
			return err
		},
		"withdraw": func() error {
			_, err := maintenance.Withdraw(context.Background(), "1.631.2", "withdraw", "withdraw-key")
			return err
		},
	}
	for name, action := range actions {
		if err := action(); !backupRefusalCode(err, CodeBackupRecoveryRequired) {
			t.Errorf("%s during a pending recovery: %v", name, err)
		}
	}
}

func TestPendingRestoreWithoutToolsFailsClosed(t *testing.T) {
	service, _, _ := newBackupService(t)
	if err := service.writeState(filepath.Join(service.Directory, backupStateFileName), pendingRestoreState()); err != nil {
		t.Fatal(err)
	}
	service.Tools = nil
	if err := service.RecoverRestore(context.Background()); !backupRefusalCode(err, CodeBackupToolsMissing) {
		t.Fatalf("recovery without tools = %v", err)
	}
	if err := service.Guard.Acquire(); !backupRefusalCode(err, CodeBackupRecoveryRequired) {
		t.Fatalf("admission after a journal without tools = %v", err)
	}
}

// TestOnlySnapshotAndRecoveryRetryBypassTheRecoveryRefusal is the
// PROVENANCE_AND_COVERAGE_V1 law C completeness check: every destructive entry
// uses Acquire, which honours the refusal. Only the safe snapshot and the
// recovery retry itself take the raw lock.
func TestOnlySnapshotAndRecoveryRetryBypassTheRecoveryRefusal(t *testing.T) {
	entries, err := os.ReadDir(".")
	if err != nil {
		t.Fatal(err)
	}
	bypasses := map[string]int{}
	for _, entry := range entries {
		name := entry.Name()
		if entry.IsDir() || !strings.HasSuffix(name, ".go") || strings.HasSuffix(name, "_test.go") {
			continue
		}
		contents, readErr := os.ReadFile(name)
		if readErr != nil {
			t.Fatal(readErr)
		}
		if count := strings.Count(string(contents), "Guard.TryLock()"); count > 0 {
			bypasses[name] = count
		}
	}
	if len(bypasses) != 1 || bypasses["backup.go"] != 2 {
		t.Fatalf("guard bypasses = %v; only the snapshot and the recovery retry may bypass the refusal", bypasses)
	}
}

func TestRecoverRetryClearsAdmissionOnlyOnSuccess(t *testing.T) {
	service, tools := failRestoreRecovery(t)
	if err := service.RecoverRetry(context.Background()); err == nil {
		t.Fatal("a retry with the database still unavailable reported success")
	}
	if err := service.Guard.Acquire(); !backupRefusalCode(err, CodeBackupRecoveryRequired) {
		t.Fatalf("admission after a failed retry = %v", err)
	}
	tools.queryErr = nil
	if err := service.RecoverRetry(context.Background()); err != nil {
		t.Fatalf("retry: %v", err)
	}
	if err := service.Guard.Acquire(); err != nil {
		t.Fatalf("admission after a successful retry = %v", err)
	}
	service.Guard.Unlock()
	if _, err := os.Stat(filepath.Join(service.Directory, backupStateFileName)); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("the settled journal survived the successful retry: %v", err)
	}
}
