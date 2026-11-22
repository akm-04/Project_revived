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
	"sync"
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
	if f.Root == "" {
		return domain.DefaultSettings(), nil
	}
	data, err := os.ReadFile(f.path())
	if errors.Is(err, os.ErrNotExist) {
		return domain.DefaultSettings(), nil
	}
	if err != nil {
		return domain.Settings{}, err
	}
	settings, err := domain.ParseSettings(data)
	if err != nil {
		return domain.Settings{}, err
	}
	if settings.ResPath != "" && !readableDirectory(settings.ResPath) {
		log.Printf("ota settings res_path %s is not a readable folder", settings.ResPath)
	}
	return settings, nil
}

// Save replaces the file atomically: a temp file in the same folder then a
// rename, so a reader never sees a half-written settings.json.
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
	temporary, err := os.CreateTemp(f.Root, ".settings-*.json")
	if err != nil {
		return err
	}
	temporaryName := temporary.Name()
	cleanup := func() {
		_ = temporary.Close()
		_ = os.Remove(temporaryName)
	}
	if _, err := temporary.Write(append(data, '\n')); err != nil {
		cleanup()
		return err
	}
	if err := temporary.Close(); err != nil {
		_ = os.Remove(temporaryName)
		return err
	}
	if err := os.Rename(temporaryName, f.path()); err != nil {
		_ = os.Remove(temporaryName)
		return err
	}
	return nil
}

// SettingsValue is the live in-memory copy of the committed settings.
type SettingsValue struct {
	current atomic.Pointer[domain.Settings]
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

// SettingsChange is the recorded result of `ota.settings.set`.
type SettingsChange struct {
	Old      domain.Settings `json:"old"`
	New      domain.Settings `json:"new"`
	Revision int64           `json:"revision"`
}

// SettingsSetHandler is `ota.settings.set` (OTA ruling 6, live class): the
// payload is the full settings object, no expected_revision, last writer wins.
// It writes only the ota_settings row; settings.json and the live value follow
// after commit through SettingsSync (OTA_AMENDMENTS OA-6). A bad payload is a
// 409 refusal.
func SettingsSetHandler(file SettingsFile, live *SettingsValue, store SettingsStore) operator.Handler {
	return func(ctx context.Context, scope tx.Scope, command operator.Command) (any, error) {
		if file.Root == "" {
			return nil, operator.Refuse(CodeRootUnavailable, "the OTA root is not configured", nil)
		}
		next := domain.DefaultSettings()
		decoder := json.NewDecoder(bytes.NewReader(command.Payload))
		decoder.DisallowUnknownFields()
		if err := decoder.Decode(&next); err != nil {
			return nil, operator.Refuse(operator.CodePayloadInvalid, "the payload must be {lazy_fetch, res_path, download_base_seconds, download_min_kib_per_second, cache_max_age_seconds, serving_refresh_seconds, volume_mb}", nil)
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
		current, err := store.LockSettingsTx(ctx, scope.Tx, live.Get(), scope.Operation.StartedAt)
		if err != nil {
			return nil, err
		}
		saved := SettingsRecord{Settings: next, Revision: current.Revision + 1}
		if err := store.SaveSettingsTx(ctx, scope.Tx, saved, command.Envelope.SemanticKey, scope.Operation.StartedAt); err != nil {
			return nil, err
		}
		return SettingsChange{Old: current.Settings, New: next, Revision: saved.Revision}, nil
	}
}

// SettingsSync copies the committed ota_settings row to settings.json and the
// live value (OA-6). It runs at startup and after every applied settings
// command, replays included, so a copy that failed or was cut by a crash is
// made by the next run, and a run never installs an older revision.
type SettingsSync struct {
	Runner     tx.Runner
	Operations operation.Factory
	Store      SettingsStore
	File       SettingsFile
	Live       *SettingsValue

	mu      sync.Mutex
	applied int64
}

func (s *SettingsSync) Reconcile(ctx context.Context) error {
	_, err := s.reconcile(ctx)
	return err
}

// Start is the startup copy. settings.json is only a copy of the committed row,
// so an invalid file is replaced from the row instead of stopping startup. The
// bool is false only when the file is invalid and no committed revision (>= 1)
// exists to replace it.
func (s *SettingsSync) Start(ctx context.Context) (bool, error) {
	settings, err := s.File.Load()
	invalidFile := errors.Is(err, domain.ErrInvalidSettings)
	if invalidFile {
		log.Printf("ota settings: %s is invalid, replacing it from the committed row: %v", s.File.Path(), err)
		settings = domain.DefaultSettings()
	} else if err != nil {
		return false, err
	}
	s.Live.Set(settings)
	installed, err := s.reconcile(ctx)
	if err != nil {
		return false, err
	}
	return installed || !invalidFile, nil
}

// reconcile is Reconcile reporting whether it installed a committed revision.
func (s *SettingsSync) reconcile(ctx context.Context) (bool, error) {
	if s.Store == nil || s.Runner.DB == nil {
		return false, ErrUnavailable
	}
	current, err := s.Operations.New(policy.Set{})
	if err != nil {
		return false, err
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	before := s.applied
	var record *SettingsRecord
	_, err = s.Runner.Run(ctx, current, ReadProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		loaded, readErr := s.Store.ReadSettingsTx(ctx, scope.Tx)
		record = loaded
		return readErr
	})
	if err != nil {
		return false, err
	}
	if err := s.install(record); err != nil {
		return false, err
	}
	return s.applied != before, nil
}

// install is Reconcile after the read; the caller holds mu.
func (s *SettingsSync) install(record *SettingsRecord) error {
	if record == nil || record.Revision <= s.applied {
		return nil
	}
	if err := s.File.Save(record.Settings); err != nil {
		return err
	}
	s.Live.Set(record.Settings)
	s.applied = record.Revision
	return nil
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
