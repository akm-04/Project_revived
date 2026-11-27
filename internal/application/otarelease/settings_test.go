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
	recovered := t.TempDir()
	next := domain.DefaultSettings()
	next.LazyFetch = domain.LazyFetchOn
	next.ResPath = res
	next.RecoveredResPath = recovered
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
	record  *SettingsRecord
	saved   []string
	reads   int
	saveErr error
}

func (store *fakeSettingsStore) LockSettingsTx(_ context.Context, _ tx.Tx, seed domain.Settings, _ time.Time) (SettingsRecord, error) {
	if store.record == nil {
		store.record = &SettingsRecord{Settings: seed}
	}
	return *store.record, nil
}

func (store *fakeSettingsStore) SaveSettingsTx(_ context.Context, _ tx.Tx, record SettingsRecord, commandKey string, _ time.Time) error {
	if store.saveErr != nil {
		return store.saveErr
	}
	if record.Revision != store.record.Revision+1 {
		return errors.New("revision moved")
	}
	store.record = &record
	store.saved = append(store.saved, commandKey)
	return nil
}

func (store *fakeSettingsStore) ReadSettingsTx(context.Context, tx.Queryer) (*SettingsRecord, error) {
	store.reads++
	return store.record, nil
}

func TestSettingsSetHandlerWritesTheFileAndLiveValue(t *testing.T) {
	root := t.TempDir()
	res := t.TempDir()
	live := NewSettingsValue(domain.DefaultSettings())
	handler := SettingsSetHandler(SettingsFile{Root: root}, live)

	result, err := handler(context.Background(), tx.Scope{}, operator.Command{Envelope: operator.Envelope{SemanticKey: "first"}, Payload: []byte(`{"lazy_fetch":"on","res_path":"` + res + `"}`)})
	if err != nil {
		t.Fatal(err)
	}
	first := domain.DefaultSettings()
	first.LazyFetch = domain.LazyFetchOn
	first.ResPath = res
	if change, ok := result.(SettingsChange); !ok || change.Old != domain.DefaultSettings() || change.New != first || change.Revision != 0 {
		t.Fatalf("result=%#v", result)
	}
	if live.Get() != first {
		t.Fatalf("the handler did not update the live value: %+v", live.Get())
	}
	loaded, err := (SettingsFile{Root: root}).Load()
	if err != nil || loaded != first {
		t.Fatalf("settings.json=%+v err=%v", loaded, err)
	}

	result, err = handler(context.Background(), tx.Scope{}, operator.Command{Envelope: operator.Envelope{SemanticKey: "second"}, Payload: []byte(`{"lazy_fetch":"off","res_path":""}`)})
	if err != nil {
		t.Fatal(err)
	}
	if change := result.(SettingsChange); change.Old != first {
		t.Fatalf("second change=%+v", change)
	}
}

// S1 item 1: the history row is written after commit and its failure is
// reported so the caller can log it; the file is already in force.
func TestSettingsRecordWritesTheAuditRowAndReportsAFailure(t *testing.T) {
	live := NewSettingsValue(domain.DefaultSettings())
	store := &fakeSettingsStore{}
	sync := &SettingsSync{Runner: tx.Runner{DB: fakeDB{}}, Operations: operation.Factory{Clock: clock.System{}}, Store: store, Live: live}
	if err := sync.Record(context.Background(), "key"); err != nil {
		t.Fatal(err)
	}
	if store.record == nil || store.record.Revision != 1 || len(store.saved) != 1 || store.saved[0] != "key" {
		t.Fatalf("record=%+v saved=%v", store.record, store.saved)
	}
	sync.Store = &fakeSettingsStore{record: store.record, saveErr: errors.New("database restored")}
	if err := sync.Record(context.Background(), "again"); err == nil {
		t.Fatal("a failed audit row must be reported to the caller")
	}
}

func newStartupSync(root string, live *SettingsValue, store SettingsStore) *SettingsSync {
	return &SettingsSync{Runner: tx.Runner{DB: fakeDB{}}, Operations: operation.Factory{Clock: clock.System{}}, Store: store, File: SettingsFile{Root: root}, Live: live}
}

// S1 item 1: an unusable file is reported, left untouched, and the defaults are
// served; the legacy row is never read to replace it.
func TestSettingsStartKeepsAnInvalidFileAndServesDefaults(t *testing.T) {
	root := t.TempDir()
	bogus := []byte(`{"lazy_fetch":"nope"}`)
	if err := os.WriteFile(filepath.Join(root, settingsFileName), bogus, 0o644); err != nil {
		t.Fatal(err)
	}
	committed := domain.DefaultSettings()
	committed.LazyFetch = domain.LazyFetchOff
	live := NewSettingsValue(committed)
	store := &fakeSettingsStore{record: &SettingsRecord{Settings: committed, Revision: 1}}
	sync := newStartupSync(root, live, store)
	if err := sync.Start(context.Background()); err != nil {
		t.Fatal(err)
	}
	if live.Get() != domain.DefaultSettings() {
		t.Fatalf("live=%+v", live.Get())
	}
	if !live.Invalid() {
		t.Fatal("an invalid file must report settings_invalid")
	}
	if store.reads != 0 {
		t.Fatalf("the database was read for an existing file: reads=%d", store.reads)
	}
	if raw, readErr := os.ReadFile(filepath.Join(root, settingsFileName)); readErr != nil || string(raw) != string(bogus) {
		t.Fatalf("startup changed the invalid file: %q err=%v", raw, readErr)
	}
}

// S1 item 1: the legacy import runs once, only for a missing file.
func TestSettingsStartImportsTheLegacyRowOnlyWhenTheFileIsMissing(t *testing.T) {
	root := t.TempDir()
	committed := domain.DefaultSettings()
	committed.LazyFetch = domain.LazyFetchOff
	live := NewSettingsValue(domain.DefaultSettings())
	sync := newStartupSync(root, live, &fakeSettingsStore{record: &SettingsRecord{Settings: committed, Revision: 3}})
	if err := sync.Start(context.Background()); err != nil {
		t.Fatal(err)
	}
	if live.Get() != committed || live.Invalid() {
		t.Fatalf("live=%+v invalid=%v", live.Get(), live.Invalid())
	}
	loaded, err := (SettingsFile{Root: root}).Load()
	if err != nil || loaded != committed {
		t.Fatalf("file=%+v err=%v", loaded, err)
	}
}

func TestSettingsStartIgnoresTheUnseededRow(t *testing.T) {
	root := t.TempDir()
	seeded := domain.DefaultSettings()
	seeded.LazyFetch = domain.LazyFetchOff
	live := NewSettingsValue(domain.DefaultSettings())
	sync := newStartupSync(root, live, &fakeSettingsStore{record: &SettingsRecord{Settings: seeded, Revision: 0}})
	if err := sync.Start(context.Background()); err != nil {
		t.Fatal(err)
	}
	if live.Get() != domain.DefaultSettings() {
		t.Fatalf("the revision-0 row was imported: %+v", live.Get())
	}
	if _, err := os.Stat(filepath.Join(root, settingsFileName)); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("the revision-0 row was written to the file: %v", err)
	}
}

func TestSettingsStartTrustsAValidFileOverTheDatabase(t *testing.T) {
	root := t.TempDir()
	fileSettings := domain.DefaultSettings()
	fileSettings.LazyFetch = domain.LazyFetchOff
	if err := (SettingsFile{Root: root}).Save(fileSettings); err != nil {
		t.Fatal(err)
	}
	other := domain.DefaultSettings()
	other.LazyFetch = domain.LazyFetchOn
	live := NewSettingsValue(domain.DefaultSettings())
	store := &fakeSettingsStore{record: &SettingsRecord{Settings: other, Revision: 9}}
	sync := newStartupSync(root, live, store)
	if err := sync.Start(context.Background()); err != nil {
		t.Fatal(err)
	}
	if live.Get() != fileSettings {
		t.Fatalf("live=%+v", live.Get())
	}
	if store.reads != 0 {
		t.Fatalf("the database was read for an existing file: reads=%d", store.reads)
	}
}

func TestSettingsSetHandlerRefusalsAre409(t *testing.T) {
	cases := []string{
		`{"lazy_fetch":"sometimes","res_path":""}`,
		`{"lazy_fetch":"auto","res_path":"relative/res"}`,
		`{"lazy_fetch":"auto","res_path":"/definitely/not/a/folder"}`,
		`{"lazy_fetch":"auto","res_path":"","recovered_res_path":"relative/recovered"}`,
		`{"lazy_fetch":"auto","res_path":"","recovered_res_path":"/definitely/not/a/folder"}`,
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

func TestSettingsSetHandlerAppliesTunables(t *testing.T) {
	live := NewSettingsValue(domain.DefaultSettings())
	recovered := t.TempDir()
	payload := `{"lazy_fetch":"auto","res_path":"","recovered_res_path":"` + recovered + `","download_base_seconds":10,"download_min_kib_per_second":64,"cache_max_age_seconds":0,"serving_refresh_seconds":2,"volume_mb":120}`
	result, err := callSettings(SettingsSetHandler(SettingsFile{Root: t.TempDir()}, live), payload)
	if err != nil {
		t.Fatal(err)
	}
	want := domain.DefaultSettings()
	want.RecoveredResPath = recovered
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
		_, err := callSettings(SettingsSetHandler(SettingsFile{Root: t.TempDir()}, live), payload)
		var refusal *operator.Refusal
		if !errors.As(err, &refusal) || refusal.Code != operator.CodePayloadInvalid {
			t.Fatalf("payload %s err=%v", payload, err)
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
