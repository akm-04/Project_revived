//go:build postgres

package main

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
)

type fixedExecutor struct {
	outcome operator.Outcome
	err     error
}

func (executor fixedExecutor) Execute(context.Context, operator.Command) (operator.Outcome, error) {
	return executor.outcome, executor.err
}

func TestPostCommitExecutorMirrorsOnlyAppliedOTAActivations(t *testing.T) {
	activation := json.RawMessage(`{"activation_id":7,"version":"1.631.2","action":"PUBLISH","state":"ACTIVE","at":"2026-11-22T05:00:00Z"}`)
	refusal := json.RawMessage(`{"error_code":"OTA_STATE_INVALID","message":"only a BUILT release can be published"}`)
	cases := []struct {
		name     string
		module   string
		outcome  operator.Outcome
		wantFile bool
	}{
		{"applied publish", "ota.publish", operator.Outcome{State: operator.StateApplied, Result: activation}, true},
		{"applied withdraw", "ota.withdraw", operator.Outcome{State: operator.StateApplied, Result: activation}, true},
		{"replayed publish", "ota.publish", operator.Outcome{State: operator.StateApplied, Result: activation, Replayed: true}, false},
		{"refused publish", "ota.publish", operator.Outcome{State: operator.StateRefused, Result: refusal}, false},
		{"another command", "ota.register_build", operator.Outcome{State: operator.StateApplied, Result: activation}, false},
	}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			root := t.TempDir()
			executor := postCommitExecutor{Next: fixedExecutor{outcome: testCase.outcome}, OTA: otaAfterCommit{Root: root}}
			command := operator.Command{ModuleCommand: testCase.module, Envelope: operator.Envelope{SemanticKey: "key-7"}}
			if _, err := executor.Execute(context.Background(), command); err != nil {
				t.Fatal(err)
			}
			entries, err := os.ReadDir(filepath.Join(root, "updates", "history"))
			if testCase.wantFile {
				if err != nil || len(entries) != 1 || entries[0].Name() != "7.json" {
					t.Fatalf("history entries=%v err=%v", entries, err)
				}
				return
			}
			if err == nil && len(entries) != 0 {
				t.Fatalf("history written for a non-applied command: %v", entries)
			}
		})
	}
}

func TestPostCommitExecutorReconcilesSettingsAfterEveryAppliedCommand(t *testing.T) {
	change := json.RawMessage(`{"old":{"lazy_fetch":"auto","res_path":""},"new":{"lazy_fetch":"off","res_path":""},"revision":1}`)
	cases := []struct {
		name    string
		outcome operator.Outcome
		runs    int
	}{
		{"applied", operator.Outcome{State: operator.StateApplied, Result: change}, 1},
		// A replay is how a committed change whose copy failed gets applied.
		{"replayed", operator.Outcome{State: operator.StateApplied, Result: change, Replayed: true}, 1},
		{"refused", operator.Outcome{State: operator.StateRefused, Result: json.RawMessage(`{"error_code":"PAYLOAD_INVALID"}`)}, 0},
	}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			runs := 0
			reconcile := func(context.Context) error { runs++; return nil }
			executor := postCommitExecutor{Next: fixedExecutor{outcome: testCase.outcome}, OTA: otaAfterCommit{Root: t.TempDir(), ReconcileSettings: reconcile}}
			if _, err := executor.Execute(context.Background(), operator.Command{ModuleCommand: "ota.settings.set"}); err != nil {
				t.Fatal(err)
			}
			if runs != testCase.runs {
				t.Fatalf("reconcile runs=%d want %d", runs, testCase.runs)
			}
		})
	}
}

func TestPostCommitExecutorReportsAFailedSettingsCopy(t *testing.T) {
	executor := postCommitExecutor{
		Next: fixedExecutor{outcome: operator.Outcome{State: operator.StateApplied, Result: json.RawMessage(`{}`)}},
		OTA:  otaAfterCommit{ReconcileSettings: func(context.Context) error { return errors.New("disk full") }},
	}
	if _, err := executor.Execute(context.Background(), operator.Command{ModuleCommand: "ota.settings.set"}); err == nil {
		t.Fatal("a failed settings copy must not report success")
	}
}

func TestPostCommitExecutorReportsAMissingSettingsSync(t *testing.T) {
	executor := postCommitExecutor{
		Next: fixedExecutor{outcome: operator.Outcome{State: operator.StateApplied, Result: json.RawMessage(`{}`)}},
	}
	if _, err := executor.Execute(context.Background(), operator.Command{ModuleCommand: "ota.settings.set"}); err == nil {
		t.Fatal("a committed settings command without a sync must not report success")
	}
}

func TestMirrorActivationWritesTheHistoryFile(t *testing.T) {
	root := t.TempDir()
	at := time.Date(2026, 11, 22, 5, 0, 0, 0, time.UTC)
	result, err := json.Marshal(map[string]any{"activation_id": 7, "version": "1.631.2", "action": "PUBLISH", "state": "ACTIVE", "at": at})
	if err != nil {
		t.Fatal(err)
	}
	if err := mirrorActivation(root, "command-key", result); err != nil {
		t.Fatal(err)
	}
	raw, err := os.ReadFile(filepath.Join(root, "updates", "history", "7.json"))
	if err != nil {
		t.Fatal(err)
	}
	var mirror activationMirror
	if err := json.Unmarshal(raw, &mirror); err != nil {
		t.Fatal(err)
	}
	if mirror.ID != 7 || mirror.Version != "1.631.2" || mirror.Action != "PUBLISH" || mirror.CommandKey != "command-key" || !mirror.At.Equal(at) {
		t.Fatalf("mirror=%+v", mirror)
	}
	if err := mirrorActivation("", "command-key", result); err != nil {
		t.Fatalf("unset root must be a no-op: %v", err)
	}
}
