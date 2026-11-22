package otarelease

import (
	"context"
	"errors"
	"os"
	"path/filepath"
	"testing"
	"time"

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

// fakeSettingsStore is the ota_settings row in memory.
type fakeSettingsStore struct {
	record *SettingsRecord
	saved  []string
}

func (store *fakeSettingsStore) LockSettingsTx(_ context.Context, _ tx.Tx, seed domain.Settings, _ time.Time) (SettingsRecord, error) {
	if store.record == nil {
		store.record = &SettingsRecord{Settings: seed}
	}
	return *store.record, nil
}

func (store *fakeSettingsStore) SaveSettingsTx(_ context.Context, _ tx.Tx, record SettingsRecord, commandKey string, _ time.Time) error {
	if record.Revision != store.record.Revision+1 {
		return errors.New("revision moved")
	}
	store.record = &record
	store.saved = append(store.saved, commandKey)
	return nil
}

func (store *fakeSettingsStore) ReadSettingsTx(context.Context, tx.Queryer) (*SettingsRecord, error) {
	return store.record, nil
}

func TestSettingsSetHandlerWritesOnlyTheRow(t *testing.T) {
	root := t.TempDir()
	res := t.TempDir()
	live := NewSettingsValue(domain.DefaultSettings())
	store := &fakeSettingsStore{}
	handler := SettingsSetHandler(SettingsFile{Root: root}, live, store)

	result, err := handler(context.Background(), tx.Scope{}, operator.Command{Envelope: operator.Envelope{SemanticKey: "first"}, Payload: []byte(`{"lazy_fetch":"on","res_path":"` + res + `"}`)})
	if err != nil {
		t.Fatal(err)
	}
	first := domain.Settings{LazyFetch: domain.LazyFetchOn, ResPath: res}
	if change, ok := result.(SettingsChange); !ok || change != (SettingsChange{Old: domain.DefaultSettings(), New: first, Revision: 1}) {
		t.Fatalf("result=%#v", result)
	}
	if live.Get() != domain.DefaultSettings() {
		t.Fatalf("the handler changed the live value before commit: %+v", live.Get())
	}
	if _, statErr := os.Stat(filepath.Join(root, "settings.json")); !errors.Is(statErr, os.ErrNotExist) {
		t.Fatalf("the handler wrote settings.json before commit: %v", statErr)
	}

	// Old comes from the row, not from a live value that no copy has updated yet.
	result, err = handler(context.Background(), tx.Scope{}, operator.Command{Envelope: operator.Envelope{SemanticKey: "second"}, Payload: []byte(`{"lazy_fetch":"off","res_path":""}`)})
	if err != nil {
		t.Fatal(err)
	}
	if change := result.(SettingsChange); change.Old != first || change.Revision != 2 {
		t.Fatalf("second change=%+v", change)
	}
	if len(store.saved) != 2 || store.saved[1] != "second" {
		t.Fatalf("saved=%v", store.saved)
	}
}

func TestSettingsSyncInstallsOnlyNewerRevisions(t *testing.T) {
	root := t.TempDir()
	live := NewSettingsValue(domain.DefaultSettings())
	sync := &SettingsSync{File: SettingsFile{Root: root}, Live: live}
	on := domain.Settings{LazyFetch: domain.LazyFetchOn}
	off := domain.Settings{LazyFetch: domain.LazyFetchOff}

	if err := sync.install(&SettingsRecord{Settings: on, Revision: 0}); err != nil || live.Get() != domain.DefaultSettings() {
		t.Fatalf("the seed row was installed: live=%+v err=%v", live.Get(), err)
	}
	if err := sync.install(&SettingsRecord{Settings: off, Revision: 2}); err != nil {
		t.Fatal(err)
	}
	// A late copy of an older commit must not undo the newer one.
	if err := sync.install(&SettingsRecord{Settings: on, Revision: 1}); err != nil {
		t.Fatal(err)
	}
	reloaded, err := sync.File.Load()
	if err != nil || reloaded != off || live.Get() != off {
		t.Fatalf("file=%+v live=%+v err=%v", reloaded, live.Get(), err)
	}
}

func TestSettingsSyncRetriesAFailedCopy(t *testing.T) {
	root := t.TempDir()
	missing := filepath.Join(root, "missing")
	live := NewSettingsValue(domain.DefaultSettings())
	sync := &SettingsSync{File: SettingsFile{Root: missing}, Live: live}
	record := &SettingsRecord{Settings: domain.Settings{LazyFetch: domain.LazyFetchOff}, Revision: 1}

	if err := sync.install(record); err == nil {
		t.Fatal("a failed write must be reported")
	}
	if live.Get() != domain.DefaultSettings() {
		t.Fatalf("a failed write changed the live value: %+v", live.Get())
	}
	if err := os.Mkdir(missing, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := sync.install(record); err != nil {
		t.Fatalf("the next run must make the copy: %v", err)
	}
	if live.Get() != record.Settings {
		t.Fatalf("live=%+v", live.Get())
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
		_, err := callSettings(SettingsSetHandler(file, live, &fakeSettingsStore{}), payload)
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
	_, err := callSettings(SettingsSetHandler(SettingsFile{}, NewSettingsValue(domain.DefaultSettings()), &fakeSettingsStore{}), `{"lazy_fetch":"auto","res_path":""}`)
	var refusal *operator.Refusal
	if !errors.As(err, &refusal) || refusal.Code != CodeRootUnavailable {
		t.Fatalf("err=%v", err)
	}
}
