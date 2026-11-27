package otarelease

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"path/filepath"
	"time"
)

// Defaults and bounds of the operator-tunable OTA values (I11A_1_PLAN "L4h OTA
// tunables"). The defaults are today's constants.
const (
	DefaultDownloadBaseSeconds     = 35
	DefaultDownloadMinKiBPerSecond = 32
	DefaultCacheMaxAgeSeconds      = 31_536_000
	DefaultServingRefreshSeconds   = 5
	DefaultVolumeMB                = 99

	MinDownloadBaseSeconds     = 5
	MaxDownloadBaseSeconds     = 600
	MinDownloadMinKiBPerSecond = 1
	MaxDownloadMinKiBPerSecond = 102_400
	MinCacheMaxAgeSeconds      = 0
	MaxCacheMaxAgeSeconds      = 31_536_000
	MinServingRefreshSeconds   = 1
	MaxServingRefreshSeconds   = 300
	MinVolumeMB                = 1
	MaxVolumeMB                = 2_000

	kibibyteBytes = 1024
	megabyteBytes = 1_000_000
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
	// ApkResPath is the optional second picture root: the APK res tree that
	// holds icons the OTA res_path does not ship (the GUI tries it second).
	ApkResPath              string `json:"apk_res_path"`
	RecoveredResPath        string `json:"recovered_res_path"`
	DownloadBaseSeconds     int    `json:"download_base_seconds"`
	DownloadMinKiBPerSecond int    `json:"download_min_kib_per_second"`
	CacheMaxAgeSeconds      int    `json:"cache_max_age_seconds"`
	ServingRefreshSeconds   int    `json:"serving_refresh_seconds"`
	VolumeMB                int    `json:"volume_mb"`
}

// DefaultSettings is the value of a missing settings.json and the starting
// point for a JSON document that omits a field.
func DefaultSettings() Settings {
	return Settings{
		LazyFetch:               LazyFetchAuto,
		ResPath:                 "",
		ApkResPath:              "",
		RecoveredResPath:        "",
		DownloadBaseSeconds:     DefaultDownloadBaseSeconds,
		DownloadMinKiBPerSecond: DefaultDownloadMinKiBPerSecond,
		CacheMaxAgeSeconds:      DefaultCacheMaxAgeSeconds,
		ServingRefreshSeconds:   DefaultServingRefreshSeconds,
		VolumeMB:                DefaultVolumeMB,
	}
}

// ErrInvalidSettings marks a settings file this process must not use.
var ErrInvalidSettings = errors.New("otarelease: invalid OTA settings")

// ParseSettings refuses unknown fields and any value outside the plan.
func ParseSettings(data []byte) (Settings, error) {
	settings := DefaultSettings()
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

// Validate accepts the values the plan defines; a relative res_path or
// recovered_res_path would resolve against the process working directory, so it
// is refused.
func (s Settings) Validate() error {
	switch s.LazyFetch {
	case LazyFetchAuto, LazyFetchOn, LazyFetchOff:
	default:
		return fmt.Errorf("%w: lazy_fetch %q is not auto, on or off", ErrInvalidSettings, s.LazyFetch)
	}
	if s.ResPath != "" && !filepath.IsAbs(s.ResPath) {
		return fmt.Errorf("%w: res_path %q is not absolute", ErrInvalidSettings, s.ResPath)
	}
	if s.ApkResPath != "" && !filepath.IsAbs(s.ApkResPath) {
		return fmt.Errorf("%w: apk_res_path %q is not absolute", ErrInvalidSettings, s.ApkResPath)
	}
	if s.RecoveredResPath != "" && !filepath.IsAbs(s.RecoveredResPath) {
		return fmt.Errorf("%w: recovered_res_path %q is not absolute", ErrInvalidSettings, s.RecoveredResPath)
	}
	for _, bound := range []struct {
		name             string
		value            int
		minimum, maximum int
	}{
		{"download_base_seconds", s.DownloadBaseSeconds, MinDownloadBaseSeconds, MaxDownloadBaseSeconds},
		{"download_min_kib_per_second", s.DownloadMinKiBPerSecond, MinDownloadMinKiBPerSecond, MaxDownloadMinKiBPerSecond},
		{"cache_max_age_seconds", s.CacheMaxAgeSeconds, MinCacheMaxAgeSeconds, MaxCacheMaxAgeSeconds},
		{"serving_refresh_seconds", s.ServingRefreshSeconds, MinServingRefreshSeconds, MaxServingRefreshSeconds},
		{"volume_mb", s.VolumeMB, MinVolumeMB, MaxVolumeMB},
	} {
		if bound.value < bound.minimum || bound.value > bound.maximum {
			return fmt.Errorf("%w: %s %d is outside %d..%d", ErrInvalidSettings, bound.name, bound.value, bound.minimum, bound.maximum)
		}
	}
	return nil
}

// DownloadWriteDeadline is the write deadline of one OTA body: the base window
// plus the size at the slowest allowed client rate (OA-4).
func (s Settings) DownloadWriteDeadline(now time.Time, size int64) time.Time {
	if size < 0 {
		size = 0
	}
	rate := int64(s.DownloadMinKiBPerSecond) * kibibyteBytes
	if rate <= 0 {
		rate = DefaultDownloadMinKiBPerSecond * kibibyteBytes
	}
	return now.Add(time.Duration(s.DownloadBaseSeconds)*time.Second + time.Duration(size)*time.Second/time.Duration(rate))
}

// ServingRefreshInterval is how long a servable snapshot stays fresh.
func (s Settings) ServingRefreshInterval() time.Duration {
	return time.Duration(s.ServingRefreshSeconds) * time.Second
}

// VolumeLimitBytes is the per-volume cap of `ota build` in bytes.
func (s Settings) VolumeLimitBytes() int64 {
	return int64(s.VolumeMB) * megabyteBytes
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
