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
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
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
	next := domain.DefaultSettings()
	next.LazyFetch = domain.LazyFetchOn
	next.ResPath = res
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
	first := domain.DefaultSettings()
	first.LazyFetch = domain.LazyFetchOn
	first.ResPath = res
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
	on := domain.DefaultSettings()
	on.LazyFetch = domain.LazyFetchOn
	off := domain.DefaultSettings()
	off.LazyFetch = domain.LazyFetchOff

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
	offSettings := domain.DefaultSettings()
	offSettings.LazyFetch = domain.LazyFetchOff
	record := &SettingsRecord{Settings: offSettings, Revision: 1}

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

func newStartupSync(root string, live *SettingsValue, store SettingsStore) *SettingsSync {
	return &SettingsSync{Runner: tx.Runner{DB: fakeDB{}}, Operations: operation.Factory{Clock: clock.System{}}, Store: store, File: SettingsFile{Root: root}, Live: live}
}

func TestSettingsStartReplacesAnInvalidFileFromTheCommittedRow(t *testing.T) {
	root := t.TempDir()
	if err := os.WriteFile(filepath.Join(root, settingsFileName), []byte(`{"lazy_fetch":"nope"}`), 0o644); err != nil {
		t.Fatal(err)
	}
	committed := domain.DefaultSettings()
	committed.LazyFetch = domain.LazyFetchOff
	live := NewSettingsValue(domain.DefaultSettings())
	sync := newStartupSync(root, live, &fakeSettingsStore{record: &SettingsRecord{Settings: committed, Revision: 1}})
	usable, err := sync.Start(context.Background())
	if err != nil || !usable {
		t.Fatalf("usable=%v err=%v", usable, err)
	}
	loaded, err := sync.File.Load()
	if err != nil || loaded != committed || live.Get() != committed {
		t.Fatalf("file=%+v live=%+v err=%v", loaded, live.Get(), err)
	}
}

func TestSettingsStartRefusesAnInvalidFileWithoutACommittedRow(t *testing.T) {
	root := t.TempDir()
	bogus := []byte(`{"lazy_fetch":"nope"}`)
	if err := os.WriteFile(filepath.Join(root, settingsFileName), bogus, 0o644); err != nil {
		t.Fatal(err)
	}
	offSettings := domain.DefaultSettings()
	offSettings.LazyFetch = domain.LazyFetchOff
	live := NewSettingsValue(offSettings)
	sync := newStartupSync(root, live, &fakeSettingsStore{})
	usable, err := sync.Start(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if usable {
		t.Fatal("an invalid file without a committed row must not be usable")
	}
	if live.Get() != domain.DefaultSettings() {
		t.Fatalf("live=%+v", live.Get())
	}
	if raw, readErr := os.ReadFile(filepath.Join(root, settingsFileName)); readErr != nil || string(raw) != string(bogus) {
		t.Fatalf("the startup copy changed the invalid file: %q err=%v", raw, readErr)
	}
}

func TestSettingsStartTrustsAValidFileWithoutACommittedRow(t *testing.T) {
	root := t.TempDir()
	fileSettings := domain.DefaultSettings()
	fileSettings.LazyFetch = domain.LazyFetchOff
	if err := (SettingsFile{Root: root}).Save(fileSettings); err != nil {
		t.Fatal(err)
	}
	live := NewSettingsValue(domain.DefaultSettings())
	sync := newStartupSync(root, live, &fakeSettingsStore{})
	usable, err := sync.Start(context.Background())
	if err != nil || !usable {
		t.Fatalf("usable=%v err=%v", usable, err)
	}
	if live.Get() != fileSettings {
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

func TestSettingsSetHandlerAppliesTunables(t *testing.T) {
	live := NewSettingsValue(domain.DefaultSettings())
	store := &fakeSettingsStore{}
	payload := `{"lazy_fetch":"auto","res_path":"","download_base_seconds":10,"download_min_kib_per_second":64,"cache_max_age_seconds":0,"serving_refresh_seconds":2,"volume_mb":120}`
	result, err := callSettings(SettingsSetHandler(SettingsFile{Root: t.TempDir()}, live, store), payload)
	if err != nil {
		t.Fatal(err)
	}
	want := domain.DefaultSettings()
	want.DownloadBaseSeconds = 10
	want.DownloadMinKiBPerSecond = 64
	want.CacheMaxAgeSeconds = 0
	want.ServingRefreshSeconds = 2
	want.VolumeMB = 120
	if change, ok := result.(SettingsChange); !ok || change.New != want {
		t.Fatalf("result=%#v", result)
	}
}

func TestSettingsSetHandlerRefusesOutOfBoundsTunables(t *testing.T) {
	for _, payload := range []string{
		`{"lazy_fetch":"auto","res_path":"","download_base_seconds":4}`,
		`{"lazy_fetch":"auto","res_path":"","download_min_kib_per_second":102401}`,
		`{"lazy_fetch":"auto","res_path":"","cache_max_age_seconds":-1}`,
		`{"lazy_fetch":"auto","res_path":"","serving_refresh_seconds":301}`,
		`{"lazy_fetch":"auto","res_path":"","volume_mb":0}`,
	} {
		live := NewSettingsValue(domain.DefaultSettings())
		_, err := callSettings(SettingsSetHandler(SettingsFile{Root: t.TempDir()}, live, &fakeSettingsStore{}), payload)
		var refusal *operator.Refusal
		if !errors.As(err, &refusal) || refusal.Code != operator.CodePayloadInvalid {
			t.Fatalf("payload %s err=%v", payload, err)
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
