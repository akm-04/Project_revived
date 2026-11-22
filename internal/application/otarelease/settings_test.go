package otarelease

import (
	"context"
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

func TestSettingsSetHandlerAppliesAndRecordsOldAndNew(t *testing.T) {
	root := t.TempDir()
	res := t.TempDir()
	file := SettingsFile{Root: root}
	live := NewSettingsValue(domain.DefaultSettings())
	handler := SettingsSetHandler(file, live)

	result, err := callSettings(handler, `{"lazy_fetch":"on","res_path":"`+res+`"}`)
	if err != nil {
		t.Fatal(err)
	}
	values, ok := result.(map[string]any)
	if !ok {
		t.Fatalf("result=%#v", result)
	}
	if old, ok := values["old"].(domain.Settings); !ok || old != domain.DefaultSettings() {
		t.Fatalf("old=%#v", values["old"])
	}
	want := domain.Settings{LazyFetch: domain.LazyFetchOn, ResPath: res}
	if next, ok := values["new"].(domain.Settings); !ok || next != want {
		t.Fatalf("new=%#v", values["new"])
	}
	if live.Get() != want {
		t.Fatalf("live=%+v", live.Get())
	}
	reloaded, err := file.Load()
	if err != nil || reloaded != want {
		t.Fatalf("reloaded=%+v err=%v", reloaded, err)
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
