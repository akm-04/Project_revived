//go:build postgres

package main

import (
	"context"
	"errors"
	"os"
	"path/filepath"
	"testing"

	appotarelease "gxb.local/backend/v2/internal/application/otarelease"
	domain "gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type brokenDB struct{}

func (brokenDB) Begin(context.Context, tx.Options) (tx.Tx, error) {
	return nil, errors.New("database unreachable")
}

// S1 item 3: a missing or corrupt file and an unreadable database are logged
// and the backend still boots with the defaults and the file's own state.
func TestPrepareOTAFilesSurvivesOTAFaults(t *testing.T) {
	cases := []struct {
		name      string
		runner    tx.Runner
		corrupt   string
		invalid   bool
		unwritten bool
	}{
		{name: "missing files", runner: tx.Runner{}, unwritten: true},
		{name: "corrupt releases.json", runner: tx.Runner{}, corrupt: "releases"},
		{name: "invalid settings.json", runner: tx.Runner{}, corrupt: "settings", invalid: true},
		{name: "unreadable database", runner: tx.Runner{DB: brokenDB{}}, unwritten: true},
	}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			root := t.TempDir()
			switch testCase.corrupt {
			case "releases":
				if err := os.WriteFile(filepath.Join(root, "releases.json"), []byte("{"), 0o644); err != nil {
					t.Fatal(err)
				}
			case "settings":
				if err := os.WriteFile(filepath.Join(root, "settings.json"), []byte(`{"lazy_fetch":"nope"}`), 0o644); err != nil {
					t.Fatal(err)
				}
			}
			boot, err := prepareOTAFiles(context.Background(), root, "https://engine.example", testCase.runner)
			if err != nil {
				t.Fatalf("an OTA fault stopped boot: %v", err)
			}
			if boot.Settings.Get() != domain.DefaultSettings() {
				t.Fatalf("settings=%+v", boot.Settings.Get())
			}
			if boot.Settings.Invalid() != testCase.invalid {
				t.Fatalf("settings_invalid=%v want %v", boot.Settings.Invalid(), testCase.invalid)
			}
			if testCase.unwritten {
				if _, statErr := os.Stat(filepath.Join(root, "settings.json")); !errors.Is(statErr, os.ErrNotExist) {
					t.Fatalf("boot created settings.json: %v", statErr)
				}
			}
			if testCase.corrupt == "settings" {
				if raw, readErr := os.ReadFile(filepath.Join(root, "settings.json")); readErr != nil || string(raw) != `{"lazy_fetch":"nope"}` {
					t.Fatalf("boot changed the invalid file: %q err=%v", raw, readErr)
				}
			}
		})
	}
}

func TestPrepareOTAFilesRefusesARelativeRoot(t *testing.T) {
	if _, err := prepareOTAFiles(context.Background(), "relative/ota", "https://engine.example", tx.Runner{}); err == nil {
		t.Fatal("a non-absolute GXB_OTA_ROOT must be a configuration error")
	}
}

func TestPrepareOTAFilesKeepsTheFileAuthority(t *testing.T) {
	root := t.TempDir()
	settings := domain.DefaultSettings()
	settings.LazyFetch = domain.LazyFetchOff
	if err := (appotarelease.SettingsFile{Root: root}).Save(settings); err != nil {
		t.Fatal(err)
	}
	boot, err := prepareOTAFiles(context.Background(), root, "https://engine.example", tx.Runner{})
	if err != nil {
		t.Fatal(err)
	}
	if boot.Settings.Get() != settings || boot.Settings.Invalid() {
		t.Fatalf("settings=%+v invalid=%v", boot.Settings.Get(), boot.Settings.Invalid())
	}
}
