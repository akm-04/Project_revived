//go:build postgres

package main

import (
	"context"
	"errors"
	"fmt"
	"log"
	"os"
	"path/filepath"

	"gxb.local/backend/v2/internal/adapters/postgres/otastore"
	appotarelease "gxb.local/backend/v2/internal/application/otarelease"
	domain "gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// otaBoot is the file-only OTA state the backend serves from.
type otaBoot struct {
	State        *appotarelease.StateFile
	Release      appotarelease.Service
	File         appotarelease.SettingsFile
	Settings     *appotarelease.SettingsValue
	SettingsSync *appotarelease.SettingsSync
}

// prepareOTAFiles boots OTA from settings.json and releases.json. Only a
// non-absolute GXB_OTA_ROOT is a configuration error: a missing or corrupt file
// is logged and the backend continues with the defaults and whatever the file
// holds. The database is never read for OTA state (S1 items 1-3).
func prepareOTAFiles(ctx context.Context, root, publicEngineURL string, runner tx.Runner) (otaBoot, error) {
	if root != "" && !filepath.IsAbs(root) {
		return otaBoot{}, fmt.Errorf("GXB_OTA_ROOT must be an absolute path, got %q", root)
	}
	state := appotarelease.NewStateFile(root)
	if root != "" {
		if _, err := os.Stat(state.Path()); errors.Is(err, os.ErrNotExist) {
			log.Printf("OTA release state: %s is missing, serving an empty release state", state.Path())
		}
	}
	settingsFile := appotarelease.SettingsFile{Root: root}
	settings := appotarelease.NewSettingsValue(domain.DefaultSettings())
	settingsSync := &appotarelease.SettingsSync{Runner: runner, Operations: operation.Factory{Clock: clock.System{}}, Store: otastore.Store{}, File: settingsFile, Live: settings}
	if root != "" {
		settingsSync.Start()
	}
	release := appotarelease.Service{Store: state, PublicEngineURL: publicEngineURL}
	if err := release.StartupCheck(ctx, root); err != nil {
		log.Printf("OTA startup check: %v", err)
	}
	return otaBoot{State: state, Release: release, File: settingsFile, Settings: settings, SettingsSync: settingsSync}, nil
}
