package otarelease

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"path/filepath"
)

// LazyFetch is the operator switch for lazy asset serving (I11A_OTA_RELEASE_V1
// ruling 6): "auto" turns it on once an ACTIVE assets release exists.
type LazyFetch string

const (
	LazyFetchAuto LazyFetch = "auto"
	LazyFetchOn   LazyFetch = "on"
	LazyFetchOff  LazyFetch = "off"
)

// Settings is <ota_root>/settings.json (I11A_1_PLAN "OTA root and serving
// inputs"). Later phases add fields in code, never by hand.
type Settings struct {
	LazyFetch LazyFetch `json:"lazy_fetch"`
	ResPath   string    `json:"res_path"`
}

// DefaultSettings is the value of a missing settings.json.
func DefaultSettings() Settings {
	return Settings{LazyFetch: LazyFetchAuto, ResPath: ""}
}

// ErrInvalidSettings marks a settings file this process must not use.
var ErrInvalidSettings = errors.New("otarelease: invalid OTA settings")

// ParseSettings refuses unknown fields and any value outside the plan.
func ParseSettings(data []byte) (Settings, error) {
	var settings Settings
	decoder := json.NewDecoder(bytes.NewReader(data))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&settings); err != nil {
		return Settings{}, fmt.Errorf("%w: %v", ErrInvalidSettings, err)
	}
	var trailing any
	if err := decoder.Decode(&trailing); !errors.Is(err, io.EOF) {
		return Settings{}, fmt.Errorf("%w: trailing data", ErrInvalidSettings)
	}
	if err := settings.Validate(); err != nil {
		return Settings{}, err
	}
	return settings, nil
}

// Validate accepts the two values the plan defines; a relative res_path would
// resolve against the process working directory, so it is refused.
func (s Settings) Validate() error {
	switch s.LazyFetch {
	case LazyFetchAuto, LazyFetchOn, LazyFetchOff:
	default:
		return fmt.Errorf("%w: lazy_fetch %q is not auto, on or off", ErrInvalidSettings, s.LazyFetch)
	}
	if s.ResPath != "" && !filepath.IsAbs(s.ResPath) {
		return fmt.Errorf("%w: res_path %q is not absolute", ErrInvalidSettings, s.ResPath)
	}
	return nil
}

// LazyFetchEnabled reports whether discovery may advertise /res/ (ruling 6 and
// the plan's discovery rule): "on", or "auto" with an ACTIVE assets release,
// and a res_path to serve from.
func (s Settings) LazyFetchEnabled(assetsActive bool) bool {
	if s.ResPath == "" {
		return false
	}
	switch s.LazyFetch {
	case LazyFetchOn:
		return true
	case LazyFetchAuto:
		return assetsActive
	}
	return false
}
