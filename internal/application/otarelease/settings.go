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

	"gxb.local/backend/v2/internal/application/operator"
	domain "gxb.local/backend/v2/internal/domain/otarelease"
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

// SettingsValue is the live in-memory copy swapped on every successful write.
type SettingsValue struct {
	mu      sync.Mutex
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

// Set swaps the value; callers that must serialize a read-modify-write (the
// settings command) hold Lock for the old value and this call.
func (v *SettingsValue) Set(next domain.Settings) {
	v.current.Store(&next)
}

func (v *SettingsValue) Lock()   { v.mu.Lock() }
func (v *SettingsValue) Unlock() { v.mu.Unlock() }

// SettingsSetHandler is `ota.settings.set` (OTA ruling 6, live class): the
// payload is the full settings object, no expected_revision, last writer wins.
// A permanent bad payload is a 409 refusal; an I/O failure is a fault.
func SettingsSetHandler(file SettingsFile, live *SettingsValue) operator.Handler {
	return func(_ context.Context, _ tx.Scope, command operator.Command) (any, error) {
		var next domain.Settings
		decoder := json.NewDecoder(bytes.NewReader(command.Payload))
		decoder.DisallowUnknownFields()
		if err := decoder.Decode(&next); err != nil {
			return nil, operator.Refuse(operator.CodePayloadInvalid, "the payload must be {lazy_fetch, res_path}", nil)
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
		live.Lock()
		defer live.Unlock()
		old := live.Get()
		if err := file.Save(next); err != nil {
			return nil, err
		}
		live.Set(next)
		return map[string]any{"old": old, "new": next}, nil
	}
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
