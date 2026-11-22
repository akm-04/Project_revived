//go:build postgres

package main

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
	"time"
)

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
