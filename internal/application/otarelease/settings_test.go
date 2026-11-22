package otarelease

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"testing"

	"gxb.local/backend/v2/internal/application/operator"
	domain "gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func callSettings(handler operator.Handler, payload string) (any, error) {
	return handler(context.Background(), tx.Scope{}, operator.Command{Payload: []byte(payload)})
}

func TestSettingsFileMissingIsDefaultsAndSaveReloads(t *testing.T) {
	root := t.TempDir()
	file := SettingsFile{Root: root}
	loaded, err := file.Load()
	if err != nil || loaded != domain.DefaultSettings() {
		t.Fatalf("loaded=%+v err=%v", loaded, err)
	}
	res := t.TempDir()
	next := domain.Settings{LazyFetch: domain.LazyFetchOn, ResPath: res}
	if err := file.Save(next); err != nil {
		t.Fatal(err)
	}
	loaded, err = file.Load()
	if err != nil || loaded != next {
		t.Fatalf("loaded=%+v err=%v", loaded, err)
	}
	if leftovers, _ := filepath.Glob(filepath.Join(root, ".settings-*.json")); len(leftovers) != 0 {
		t.Fatalf("atomic write left temp files: %v", leftovers)
	}
}

func TestSettingsFileRefusesUnknownField(t *testing.T) {
	root := t.TempDir()
	if err := os.WriteFile(filepath.Join(root, "settings.json"), []byte(`{"lazy_fetch":"auto","res_path":"","extra":1}`), 0o644); err != nil {
		t.Fatal(err)
	}
	if _, err := (SettingsFile{Root: root}).Load(); !errors.Is(err, domain.ErrInvalidSettings) {
		t.Fatalf("err=%v", err)
	}
}

func TestSettingsSetHandlerValidatesAndChangesNothing(t *testing.T) {
	root := t.TempDir()
	res := t.TempDir()
	file := SettingsFile{Root: root}
	live := NewSettingsValue(domain.DefaultSettings())

	result, err := callSettings(SettingsSetHandler(file, live), `{"lazy_fetch":"on","res_path":"`+res+`"}`)
	if err != nil {
		t.Fatal(err)
	}
	want := SettingsChange{Old: domain.DefaultSettings(), New: domain.Settings{LazyFetch: domain.LazyFetchOn, ResPath: res}}
	if change, ok := result.(SettingsChange); !ok || change != want {
		t.Fatalf("result=%#v", result)
	}
	if live.Get() != domain.DefaultSettings() {
		t.Fatalf("the handler changed the live value before commit: %+v", live.Get())
	}
	if _, statErr := os.Stat(filepath.Join(root, "settings.json")); !errors.Is(statErr, os.ErrNotExist) {
		t.Fatalf("the handler wrote settings.json before commit: %v", statErr)
	}
}

func TestApplySettingsWritesTheCommittedValue(t *testing.T) {
	root := t.TempDir()
	res := t.TempDir()
	file := SettingsFile{Root: root}
	live := NewSettingsValue(domain.DefaultSettings())
	want := domain.Settings{LazyFetch: domain.LazyFetchOn, ResPath: res}
	result, err := json.Marshal(SettingsChange{Old: domain.DefaultSettings(), New: want})
	if err != nil {
		t.Fatal(err)
	}
	if err := ApplySettings(file, live, result); err != nil {
		t.Fatal(err)
	}
	if live.Get() != want {
		t.Fatalf("live=%+v", live.Get())
	}
	reloaded, err := file.Load()
	if err != nil || reloaded != want {
		t.Fatalf("reloaded=%+v err=%v", reloaded, err)
	}

	unwritable := NewSettingsValue(domain.DefaultSettings())
	if err := ApplySettings(SettingsFile{Root: filepath.Join(root, "missing")}, unwritable, result); err == nil {
		t.Fatal("a failed write must be reported")
	}
	if unwritable.Get() != domain.DefaultSettings() {
		t.Fatalf("a failed write changed the live value: %+v", unwritable.Get())
	}
}

func TestSettingsSetHandlerRefusalsAre409(t *testing.T) {
	cases := []string{
		`{"lazy_fetch":"sometimes","res_path":""}`,
		`{"lazy_fetch":"auto","res_path":"relative/res"}`,
		`{"lazy_fetch":"auto","res_path":"/definitely/not/a/folder"}`,
		`{"lazy_fetch":"auto","res_path":"","extra":1}`,
	}
	for _, payload := range cases {
		root := t.TempDir()
		file := SettingsFile{Root: root}
		live := NewSettingsValue(domain.DefaultSettings())
		_, err := callSettings(SettingsSetHandler(file, live), payload)
		var refusal *operator.Refusal
		if !errors.As(err, &refusal) || refusal.Code != operator.CodePayloadInvalid {
			t.Fatalf("payload %s err=%v", payload, err)
		}
		if live.Get() != domain.DefaultSettings() {
			t.Fatalf("refused payload %s changed the live value", payload)
		}
		if _, statErr := os.Stat(filepath.Join(root, "settings.json")); !errors.Is(statErr, os.ErrNotExist) {
			t.Fatalf("refused payload %s wrote settings.json: %v", payload, statErr)
		}
	}
}

func TestSettingsSetHandlerRefusesWithoutAnOTARoot(t *testing.T) {
	_, err := callSettings(SettingsSetHandler(SettingsFile{}, NewSettingsValue(domain.DefaultSettings())), `{"lazy_fetch":"auto","res_path":""}`)
	var refusal *operator.Refusal
	if !errors.As(err, &refusal) || refusal.Code != CodeRootUnavailable {
		t.Fatalf("err=%v", err)
	}
}
