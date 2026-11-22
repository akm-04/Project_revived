//go:build postgres

package otastore_test

import (
	"context"
	"os"
	"path/filepath"
	"sync"
	"testing"

	"gxb.local/backend/v2/internal/adapters/postgres/operatorstore"
	"gxb.local/backend/v2/internal/adapters/postgres/otastore"
	"gxb.local/backend/v2/internal/application/operator"
	appota "gxb.local/backend/v2/internal/application/otarelease"
	"gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// OA-6: the command writes only the ota_settings row; the sync copies the
// newest committed revision, so concurrent commands end at the last commit.
func TestNativeSettingsRowIsTheRecordAndTheSyncCopiesTheNewest(t *testing.T) {
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
		"ota.settings.set": appota.SettingsSetHandler(file, live, otastore.Store{}),
	}}

	if err := settingsSync.Reconcile(ctx); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(filepath.Join(root, "settings.json")); !os.IsNotExist(err) {
		t.Fatalf("no row yet, yet settings.json exists: %v", err)
	}

	first := l3Execute(t, bus, l3Command(t, "ota.settings.set", nil, map[string]string{"lazy_fetch": "off", "res_path": ""}))
	if first.State != operator.StateApplied {
		t.Fatalf("first=%+v", first)
	}
	if _, err := os.Stat(filepath.Join(root, "settings.json")); !os.IsNotExist(err) {
		t.Fatalf("the command wrote settings.json inside its transaction: %v", err)
	}
	if err := settingsSync.Reconcile(ctx); err != nil {
		t.Fatal(err)
	}
	if loaded, err := file.Load(); err != nil || loaded.LazyFetch != otarelease.LazyFetchOff || live.Get().LazyFetch != otarelease.LazyFetchOff {
		t.Fatalf("file=%+v live=%+v err=%v", loaded, live.Get(), err)
	}

	const writers = 8
	var group sync.WaitGroup
	for index := 0; index < writers; index++ {
		mode := "on"
		if index%2 == 0 {
			mode = "auto"
		}
		command := l3Command(t, "ota.settings.set", nil, map[string]string{"lazy_fetch": mode, "res_path": ""})
		group.Add(1)
		go func() {
			defer group.Done()
			if outcome, err := bus.Execute(ctx, command); err != nil || outcome.State != operator.StateApplied {
				t.Errorf("concurrent settings command: outcome=%+v err=%v", outcome, err)
			}
			_ = settingsSync.Reconcile(ctx)
		}()
	}
	group.Wait()
	if err := settingsSync.Reconcile(ctx); err != nil {
		t.Fatal(err)
	}
	var lastMode string
	var revision int64
	if err := pool.QueryRow(ctx, `SELECT settings->>'lazy_fetch', revision FROM ota_settings`).Scan(&lastMode, &revision); err != nil {
		t.Fatal(err)
	}
	if revision != writers+1 {
		t.Fatalf("revision=%d want %d: a commit was lost", revision, writers+1)
	}
	loaded, err := file.Load()
	if err != nil || string(loaded.LazyFetch) != lastMode || string(live.Get().LazyFetch) != lastMode {
		t.Fatalf("row=%s file=%+v live=%+v err=%v", lastMode, loaded, live.Get(), err)
	}
}
