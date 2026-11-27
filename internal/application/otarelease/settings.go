package otarelease

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"sync/atomic"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
	domain "gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const settingsFileName = "settings.json"

// SettingsFile owns <ota_root>/settings.json (I11A_OTA_RELEASE_V1 "OTA root").
type SettingsFile struct {
	Root string
}

func (f SettingsFile) path() string {
	return filepath.Join(f.Root, settingsFileName)
}

// Path is the settings file this SettingsFile owns.
func (f SettingsFile) Path() string {
	return f.path()
}

// Load reads the file; a missing file is the documented default. An empty Root
// has no file and therefore the same default.
func (f SettingsFile) Load() (domain.Settings, error) {
	settings, _, err := f.LoadExisting()
	return settings, err
}

// LoadExisting reads the file and reports whether it exists. A missing file or
// an empty Root is not an error; an unreadable or invalid file is.
func (f SettingsFile) LoadExisting() (domain.Settings, bool, error) {
	if f.Root == "" {
		return domain.DefaultSettings(), false, nil
	}
	data, err := os.ReadFile(f.path())
	if errors.Is(err, os.ErrNotExist) {
		return domain.DefaultSettings(), false, nil
	}
	if err != nil {
		return domain.Settings{}, false, err
	}
	settings, err := domain.ParseSettings(data)
	if err != nil {
		return domain.Settings{}, true, err
	}
	if settings.ResPath != "" && !readableDirectory(settings.ResPath) {
		log.Printf("ota settings res_path %s is not a readable folder", settings.ResPath)
	}
	if settings.ApkResPath != "" && !readableDirectory(settings.ApkResPath) {
		log.Printf("ota settings apk_res_path %s is not a readable folder", settings.ApkResPath)
	}
	if settings.RecoveredResPath != "" && !readableDirectory(settings.RecoveredResPath) {
		log.Printf("ota settings recovered_res_path %s is not a readable folder", settings.RecoveredResPath)
	}
	return settings, true, nil
}

// Save replaces the file atomically: a temp file in the same folder, fsynced,
// then a rename and a folder fsync, so a reader never sees a half-written
// settings.json.
func (f SettingsFile) Save(settings domain.Settings) error {
	if f.Root == "" {
		return errors.New("otarelease: OTA root is not configured")
	}
	if err := settings.Validate(); err != nil {
		return err
	}
	data, err := json.Marshal(settings)
	if err != nil {
		return err
	}
	return writeFileAtomically(f.path(), append(data, '\n'))
}

// SettingsValue is the live in-memory copy of the committed settings.
type SettingsValue struct {
	current atomic.Pointer[domain.Settings]
	invalid atomic.Bool
}

func NewSettingsValue(initial domain.Settings) *SettingsValue {
	value := &SettingsValue{}
	value.current.Store(&initial)
	return value
}

func (v *SettingsValue) Get() domain.Settings {
	if v == nil || v.current.Load() == nil {
		return domain.DefaultSettings()
	}
	return *v.current.Load()
}

func (v *SettingsValue) Set(next domain.Settings) {
	v.current.Store(&next)
	v.invalid.Store(false)
}

// MarkInvalid records that settings.json could not be used at boot. The file is
// left untouched and ota.status reports settings_invalid.
func (v *SettingsValue) MarkInvalid() {
	if v != nil {
		v.invalid.Store(true)
	}
}

func (v *SettingsValue) Invalid() bool {
	return v != nil && v.invalid.Load()
}

// SettingsRecord is the ota_settings row: the committed settings and the
// revision that orders the commits (OA-6). Revision 0 is the seed copied from
// settings.json before the first command.
type SettingsRecord struct {
	Settings domain.Settings
	Revision int64
}

// SettingsStore is the ota_settings row.
type SettingsStore interface {
	// LockSettingsTx inserts the seed when the row is missing, then locks the row.
	LockSettingsTx(ctx context.Context, transaction tx.Tx, seed domain.Settings, at time.Time) (SettingsRecord, error)
	SaveSettingsTx(ctx context.Context, transaction tx.Tx, record SettingsRecord, commandKey string, at time.Time) error
	// ReadSettingsTx returns nil when no command has seeded the row yet.
	ReadSettingsTx(ctx context.Context, query tx.Queryer) (*SettingsRecord, error)
}

// SettingsChange is the recorded result of `ota.settings.set`. The file has no
// revision, so Revision stays 0; it remains in the reply shape for the operator
// client.
type SettingsChange struct {
	Old      domain.Settings `json:"old"`
	New      domain.Settings `json:"new"`
	Revision int64           `json:"revision"`
}

// SettingsSetHandler is `ota.settings.set` (OTA ruling 6, live class): the
// payload is the full settings object, no expected_revision, last writer wins.
// settings.json and the live value are the authority. The ota_settings history
// row is written after commit by SettingsSync.Record, so a database fault there
// is a logged warning and never undoes the file (S1 item 1). A bad payload is a
// 409 refusal.
func SettingsSetHandler(file SettingsFile, live *SettingsValue) operator.Handler {
	return func(ctx context.Context, scope tx.Scope, command operator.Command) (any, error) {
		if file.Root == "" {
			return nil, operator.Refuse(CodeRootUnavailable, "the OTA root is not configured", nil)
		}
		next := domain.DefaultSettings()
		decoder := json.NewDecoder(bytes.NewReader(command.Payload))
		decoder.DisallowUnknownFields()
		if err := decoder.Decode(&next); err != nil {
			return nil, operator.Refuse(operator.CodePayloadInvalid, "the payload must be {lazy_fetch, res_path, apk_res_path, recovered_res_path, download_base_seconds, download_min_kib_per_second, cache_max_age_seconds, serving_refresh_seconds, volume_mb}", nil)
		}
		var trailing any
		if err := decoder.Decode(&trailing); !errors.Is(err, io.EOF) {
			return nil, operator.Refuse(operator.CodePayloadInvalid, "the payload has trailing data", nil)
		}
		if err := next.Validate(); err != nil {
			return nil, operator.Refuse(operator.CodePayloadInvalid, err.Error(), nil)
		}
		if next.ResPath != "" && !readableDirectory(next.ResPath) {
			return nil, operator.Refuse(operator.CodePayloadInvalid, fmt.Sprintf("res_path %q is not a readable folder", next.ResPath), nil)
		}
		if next.ApkResPath != "" && !readableDirectory(next.ApkResPath) {
			return nil, operator.Refuse(operator.CodePayloadInvalid, fmt.Sprintf("apk_res_path %q is not a readable folder", next.ApkResPath), nil)
		}
		if next.RecoveredResPath != "" && !readableDirectory(next.RecoveredResPath) {
			return nil, operator.Refuse(operator.CodePayloadInvalid, fmt.Sprintf("recovered_res_path %q is not a readable folder", next.RecoveredResPath), nil)
		}
		current := live.Get()
		if err := file.Save(next); err != nil {
			return nil, err
		}
		live.Set(next)
		return SettingsChange{Old: current, New: next}, nil
	}
}

// SettingsSync imports settings.json once from the legacy ota_settings row. The
// file is the authority: after the import the database is never read for
// settings (S1 item 1).
type SettingsSync struct {
	Runner     tx.Runner
	Operations operation.Factory
	Store      SettingsStore
	File       SettingsFile
	Live       *SettingsValue
}

// Start boots settings.json. A missing file imports the legacy database row
// when one exists; a present file is used as it is. An unusable file is logged
// loudly, left untouched, and the defaults are served with settings_invalid.
func (s *SettingsSync) Start(ctx context.Context) error {
	settings, found, err := s.File.LoadExisting()
	if err != nil {
		log.Printf("ota settings: %s is unusable, serving the defaults and leaving the file untouched: %v", s.File.Path(), err)
		s.Live.Set(domain.DefaultSettings())
		s.Live.MarkInvalid()
		return nil
	}
	if found {
		s.Live.Set(settings)
		return nil
	}
	s.Live.Set(domain.DefaultSettings())
	imported, err := s.legacyImport(ctx)
	if err != nil {
		log.Printf("ota settings: legacy import from ota_settings skipped: %v", err)
		return nil
	}
	if imported != nil {
		s.Live.Set(*imported)
	}
	return nil
}

// legacyImport copies the committed ota_settings row into a missing settings.json
// once. Revision 0 is the unseeded default row, so only a command-written row
// (revision >= 1) is imported.
func (s *SettingsSync) legacyImport(ctx context.Context) (*domain.Settings, error) {
	if s.Store == nil || s.Runner.DB == nil {
		return nil, nil
	}
	current, err := s.Operations.New(policy.Set{})
	if err != nil {
		return nil, err
	}
	var record *SettingsRecord
	_, err = s.Runner.Run(ctx, current, ReadProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		loaded, readErr := s.Store.ReadSettingsTx(ctx, scope.Tx)
		record = loaded
		return readErr
	})
	if err != nil {
		return nil, err
	}
	if record == nil || record.Revision < 1 {
		return nil, nil
	}
	if err := s.File.Save(record.Settings); err != nil {
		return nil, err
	}
	return &record.Settings, nil
}

// Record writes the ota_settings history row for one applied settings command,
// in its own transaction after the command committed. settings.json is already
// in force, so a failure here is telemetry loss only (S1 item 1).
func (s *SettingsSync) Record(ctx context.Context, commandKey string) error {
	if s == nil || s.Store == nil || s.Runner.DB == nil || s.Live == nil {
		return nil
	}
	next := s.Live.Get()
	currentOperation, err := s.Operations.New(policy.Set{})
	if err != nil {
		return err
	}
	profile := tx.Profile{Name: "ota-settings-audit", AcquireTimeout: time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 10 * time.Second, CleanupTimeout: time.Second, ReconcileTimeout: time.Second, OperationTimeout: 15 * time.Second}
	_, err = s.Runner.Run(ctx, currentOperation, profile, tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 2}, nil, func(ctx context.Context, scope tx.Scope) error {
		record, readErr := s.Store.LockSettingsTx(ctx, scope.Tx, next, scope.Operation.StartedAt)
		if readErr != nil {
			return readErr
		}
		return s.Store.SaveSettingsTx(ctx, scope.Tx, SettingsRecord{Settings: next, Revision: record.Revision + 1}, commandKey, scope.Operation.StartedAt)
	})
	return err
}

func readableDirectory(path string) bool {
	directory, err := os.Open(path)
	if err != nil {
		return false
	}
	defer directory.Close()
	info, err := directory.Stat()
	if err != nil || !info.IsDir() {
		return false
	}
	if _, err := directory.Readdirnames(1); err != nil && !errors.Is(err, io.EOF) {
		return false
	}
	return true
}
