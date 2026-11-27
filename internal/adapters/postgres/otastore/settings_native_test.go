//go:build postgres

package otastore_test

import (
	"context"
	"os"
	"path/filepath"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/operatorstore"
	"gxb.local/backend/v2/internal/adapters/postgres/otastore"
	"gxb.local/backend/v2/internal/application/operator"
	appota "gxb.local/backend/v2/internal/application/otarelease"
	"gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// S1 item 1: the command writes settings.json and the live value; the
// ota_settings row is audit telemetry for the same change.
func TestNativeSettingsSetWritesFileLiveAndAuditRow(t *testing.T) {
	pool := l3Pool(t)
	ctx := context.Background()
	if _, err := pool.Raw().Exec(ctx, `DELETE FROM ota_settings`); err != nil {
		t.Fatal(err)
	}
	root := t.TempDir()
	file := appota.SettingsFile{Root: root}
	live := appota.NewSettingsValue(otarelease.DefaultSettings())
	runner := tx.Runner{DB: pool}
	settingsSync := &appota.SettingsSync{Runner: runner, Operations: operation.Factory{Clock: clock.System{}}, Store: otastore.Store{}, File: file, Live: live}
	bus := operator.Bus{Runner: runner, Clock: clock.System{}, Store: operatorstore.Store{}, Handlers: map[string]operator.Handler{
		"ota.settings.set": appota.SettingsSetHandler(file, live),
	}}
	if err := settingsSync.Start(ctx); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(filepath.Join(root, "settings.json")); !os.IsNotExist(err) {
		t.Fatalf("no row yet, yet settings.json exists: %v", err)
	}

	recoveredPath := t.TempDir()
	payload := map[string]any{
		"lazy_fetch":                  "on",
		"res_path":                    "",
		"recovered_res_path":          recoveredPath,
		"download_base_seconds":       10,
		"download_min_kib_per_second": 64,
		"cache_max_age_seconds":       0,
		"serving_refresh_seconds":     2,
		"volume_mb":                   120,
	}
	command := l3Command(t, "ota.settings.set", nil, payload)
	if outcome := l3Execute(t, bus, command); outcome.State != operator.StateApplied {
		t.Fatalf("outcome=%+v", outcome)
	}
	if err := settingsSync.Record(ctx, command.Envelope.SemanticKey); err != nil {
		t.Fatal(err)
	}
	loaded, err := file.Load()
	if err != nil {
		t.Fatal(err)
	}
	if loaded.DownloadBaseSeconds != 10 || loaded.DownloadMinKiBPerSecond != 64 || loaded.CacheMaxAgeSeconds != 0 ||
		loaded.ServingRefreshSeconds != 2 || loaded.VolumeMB != 120 || loaded.RecoveredResPath != recoveredPath {
		t.Fatalf("file=%+v", loaded)
	}
	if live.Get() != loaded {
		t.Fatalf("live=%+v file=%+v", live.Get(), loaded)
	}
	var volumeMB, baseSeconds int
	var revision int64
	if err := pool.QueryRow(ctx, `SELECT (settings->>'volume_mb')::int, (settings->>'download_base_seconds')::int, revision FROM ota_settings`).Scan(&volumeMB, &baseSeconds, &revision); err != nil {
		t.Fatal(err)
	}
	if volumeMB != 120 || baseSeconds != 10 || revision != 1 {
		t.Fatalf("row volume_mb=%d download_base_seconds=%d revision=%d", volumeMB, baseSeconds, revision)
	}
}

// S1 item 1: the database row is imported once, into a missing file only.
func TestNativeSettingsStartImportsTheLegacyRowOnce(t *testing.T) {
	pool := l3Pool(t)
	ctx := context.Background()
	if _, err := pool.Raw().Exec(ctx, `DELETE FROM ota_settings`); err != nil {
		t.Fatal(err)
	}
	root := t.TempDir()
	file := appota.SettingsFile{Root: root}
	live := appota.NewSettingsValue(otarelease.DefaultSettings())
	runner := tx.Runner{DB: pool}
	settingsSync := &appota.SettingsSync{Runner: runner, Operations: operation.Factory{Clock: clock.System{}}, Store: otastore.Store{}, File: file, Live: live}
	bus := operator.Bus{Runner: runner, Clock: clock.System{}, Store: operatorstore.Store{}, Handlers: map[string]operator.Handler{
		"ota.settings.set": appota.SettingsSetHandler(file, live),
	}}
	command := l3Command(t, "ota.settings.set", nil, map[string]string{"lazy_fetch": "off", "res_path": ""})
	if outcome := l3Execute(t, bus, command); outcome.State != operator.StateApplied {
		t.Fatalf("outcome=%+v", outcome)
	}
	if err := settingsSync.Record(ctx, command.Envelope.SemanticKey); err != nil {
		t.Fatal(err)
	}
	if err := os.Remove(filepath.Join(root, "settings.json")); err != nil {
		t.Fatal(err)
	}
	if err := settingsSync.Start(ctx); err != nil {
		t.Fatal(err)
	}
	imported, err := file.Load()
	if err != nil || imported.LazyFetch != otarelease.LazyFetchOff {
		t.Fatalf("legacy row was not imported: file=%+v err=%v", imported, err)
	}

	// A later row change must not reach an existing file.
	if _, err := pool.Raw().Exec(ctx, `UPDATE ota_settings SET settings='{"lazy_fetch":"on"}'::jsonb`); err != nil {
		t.Fatal(err)
	}
	if err := settingsSync.Start(ctx); err != nil {
		t.Fatal(err)
	}
	if loaded, err := file.Load(); err != nil || loaded.LazyFetch != otarelease.LazyFetchOff || live.Get().LazyFetch != otarelease.LazyFetchOff {
		t.Fatalf("an existing file was replaced from the row: file=%+v live=%+v err=%v", loaded, live.Get(), err)
	}
}

// S1 item 4: a database restore (an older ota_settings row) never changes
// settings.json, releases.json or the live value.
func TestNativeRestoreDoesNotChangeOTASettingsOrReleases(t *testing.T) {
	pool := l3Pool(t)
	ctx := context.Background()
	root := t.TempDir()
	at := atTime()
	fileSettings := otarelease.DefaultSettings()
	fileSettings.LazyFetch = otarelease.LazyFetchOff
	file := appota.SettingsFile{Root: root}
	if err := file.Save(fileSettings); err != nil {
		t.Fatal(err)
	}
	state := appota.NewStateFile(root)
	publishStateReleaseNative(t, state, "1.631.2", at)
	beforeReleases, err := os.ReadFile(state.Path())
	if err != nil {
		t.Fatal(err)
	}

	if _, err := pool.Raw().Exec(ctx, `DELETE FROM ota_settings`); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO ota_settings (settings, revision, updated_at) VALUES ('{"lazy_fetch":"on"}'::jsonb, 0, now())`); err != nil {
		t.Fatal(err)
	}
	live := appota.NewSettingsValue(otarelease.DefaultSettings())
	runner := tx.Runner{DB: pool}
	settingsSync := &appota.SettingsSync{Runner: runner, Operations: operation.Factory{Clock: clock.System{}}, Store: otastore.Store{}, File: file, Live: live}
	if err := settingsSync.Start(ctx); err != nil {
		t.Fatal(err)
	}
	if live.Get() != fileSettings || live.Invalid() {
		t.Fatalf("the restored row changed the live settings: %+v", live.Get())
	}
	loaded, err := file.Load()
	if err != nil || loaded != fileSettings {
		t.Fatalf("the restored row changed settings.json: %+v err=%v", loaded, err)
	}

	exporter := &countingExporter{}
	seeded, err := state.Seed(ctx, runner, exporter)
	if err != nil || seeded || exporter.calls != 0 {
		t.Fatalf("seed = %v err=%v calls=%d", seeded, err, exporter.calls)
	}
	afterReleases, err := os.ReadFile(state.Path())
	if err != nil {
		t.Fatal(err)
	}
	if string(afterReleases) != string(beforeReleases) {
		t.Fatal("the restore changed releases.json")
	}
}

type countingExporter struct {
	calls int
}

func (exporter *countingExporter) ExportStateTx(context.Context, tx.Queryer) (appota.StateDocument, error) {
	exporter.calls++
	return appota.StateDocument{}, nil
}

func atTime() time.Time {
	return time.Now().UTC().Truncate(time.Microsecond)
}

const (
	nativeStateSHA = "1111111111111111111111111111111111111111111111111111111111111111"
	nativeStateMD5 = "22222222222222222222222222222222"
)

func publishStateReleaseNative(t *testing.T, store *appota.StateFile, version string, at time.Time) {
	t.Helper()
	parsed, err := otarelease.ParseVersion(version)
	if err != nil {
		t.Fatal(err)
	}
	release := otarelease.Release{
		Version: parsed, Lane: otarelease.LaneCode, State: otarelease.StateBuilt,
		Volumes:   []otarelease.PackageVolume{{Name: version + "-" + nativeStateSHA[:12] + ".zip.001", Size: 1000, MD5: nativeStateMD5, SHA256: nativeStateSHA}},
		TotalSize: 1000, MD5: nativeStateMD5, SHA256: nativeStateSHA,
		Manifest: []otarelease.ManifestEntry{{Path: "src_64/a.lua", Size: 1, MD5: nativeStateMD5}},
	}
	if err := store.InsertBuildTx(context.Background(), nil, release, "command-"+version, at); err != nil {
		t.Fatal(err)
	}
	if _, err := store.SupersedeLaneTx(context.Background(), nil, otarelease.LaneCode, at); err != nil {
		t.Fatal(err)
	}
	if err := store.ActivateTx(context.Background(), nil, version, "command-"+version, at); err != nil {
		t.Fatal(err)
	}
	row, err := store.ReleaseTx(context.Background(), nil, version)
	if err != nil || row == nil {
		t.Fatalf("release %s missing: %v", version, err)
	}
	if _, err := store.InsertActivationTx(context.Background(), nil, appota.ActivationRow{ReleaseID: row.ID, Version: version, Action: "PUBLISH", CommandKey: "command-" + version, At: at}); err != nil {
		t.Fatal(err)
	}
}
