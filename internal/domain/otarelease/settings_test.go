package otarelease

import (
	"errors"
	"fmt"
	"testing"
	"time"
)

func TestParseSettingsDefaultsAndValues(t *testing.T) {
	settings, err := ParseSettings([]byte(`{"lazy_fetch":"auto","res_path":""}`))
	if err != nil || settings.LazyFetch != LazyFetchAuto || settings.ResPath != "" {
		t.Fatalf("settings=%+v err=%v", settings, err)
	}
	if got := DefaultSettings(); got.LazyFetch != LazyFetchAuto || got.ResPath != "" {
		t.Fatalf("defaults=%+v", got)
	}
	settings, err = ParseSettings([]byte(`{"lazy_fetch":"on","res_path":"/srv/res"}`))
	if err != nil || settings.LazyFetch != LazyFetchOn || settings.ResPath != "/srv/res" {
		t.Fatalf("settings=%+v err=%v", settings, err)
	}
}

func TestParseSettingsAcceptsOptionalRecoveredResPath(t *testing.T) {
	settings, err := ParseSettings([]byte(`{"lazy_fetch":"auto","res_path":"/srv/res","recovered_res_path":"/srv/recovered"}`))
	if err != nil || settings.RecoveredResPath != "/srv/recovered" {
		t.Fatalf("settings=%+v err=%v", settings, err)
	}
	if got := DefaultSettings(); got.RecoveredResPath != "" {
		t.Fatalf("default recovered_res_path=%q, want empty", got.RecoveredResPath)
	}
	if _, err := ParseSettings([]byte(`{"lazy_fetch":"auto","res_path":"","recovered_res_path":"relative/recovered"}`)); !errors.Is(err, ErrInvalidSettings) {
		t.Fatalf("a relative recovered_res_path was accepted: %v", err)
	}
}

func TestParseSettingsRefusesUnknownFieldAndBadValues(t *testing.T) {
	for _, input := range []string{
		`{"lazy_fetch":"auto","res_path":"","extra":1}`,
		`{"lazy_fetch":"sometimes","res_path":""}`,
		`{"lazy_fetch":"auto","res_path":"relative/res"}`,
		`{"lazy_fetch":"on","res_path":""} trailing`,
	} {
		if _, err := ParseSettings([]byte(input)); !errors.Is(err, ErrInvalidSettings) {
			t.Fatalf("input %q err=%v", input, err)
		}
	}
}

func TestParseSettingsFillsMissingTunablesWithDefaults(t *testing.T) {
	settings, err := ParseSettings([]byte(`{}`))
	if err != nil {
		t.Fatalf("an empty document must mean defaults: %v", err)
	}
	if settings != DefaultSettings() {
		t.Fatalf("empty document=%+v", settings)
	}
	settings, err = ParseSettings([]byte(`{"lazy_fetch":"auto","res_path":""}`))
	if err != nil {
		t.Fatal(err)
	}
	want := DefaultSettings()
	if settings != want {
		t.Fatalf("settings=%+v want=%+v", settings, want)
	}
	if settings.DownloadBaseSeconds != 35 || settings.DownloadMinKiBPerSecond != 32 ||
		settings.CacheMaxAgeSeconds != 31_536_000 || settings.ServingRefreshSeconds != 5 || settings.VolumeMB != 99 {
		t.Fatalf("defaults=%+v", settings)
	}
}

func TestParseSettingsRefusesEveryTunableOutsideItsBounds(t *testing.T) {
	cases := []struct {
		field string
		value int
	}{
		{"download_base_seconds", 4},
		{"download_base_seconds", 601},
		{"download_min_kib_per_second", 0},
		{"download_min_kib_per_second", 102_401},
		{"cache_max_age_seconds", -1},
		{"cache_max_age_seconds", 31_536_001},
		{"serving_refresh_seconds", 0},
		{"serving_refresh_seconds", 301},
		{"volume_mb", 0},
		{"volume_mb", 2_001},
	}
	for _, testCase := range cases {
		payload := fmt.Sprintf(`{"lazy_fetch":"auto","res_path":"","%s":%d}`, testCase.field, testCase.value)
		if _, err := ParseSettings([]byte(payload)); !errors.Is(err, ErrInvalidSettings) {
			t.Fatalf("%s=%d err=%v", testCase.field, testCase.value, err)
		}
	}
}

func TestParseSettingsAcceptsTheTunableBounds(t *testing.T) {
	payload := `{"lazy_fetch":"auto","res_path":"","download_base_seconds":5,"download_min_kib_per_second":1,"cache_max_age_seconds":0,"serving_refresh_seconds":1,"volume_mb":1}`
	settings, err := ParseSettings([]byte(payload))
	if err != nil || settings.DownloadBaseSeconds != 5 || settings.CacheMaxAgeSeconds != 0 || settings.VolumeMB != 1 {
		t.Fatalf("settings=%+v err=%v", settings, err)
	}
	payload = `{"lazy_fetch":"auto","res_path":"","download_base_seconds":600,"download_min_kib_per_second":102400,"cache_max_age_seconds":31536000,"serving_refresh_seconds":300,"volume_mb":2000}`
	if _, err := ParseSettings([]byte(payload)); err != nil {
		t.Fatalf("upper bounds refused: %v", err)
	}
}

func TestTunableUnits(t *testing.T) {
	settings := DefaultSettings()
	now := time.Unix(1_000, 0)
	if got := settings.DownloadWriteDeadline(now, 0).Sub(now); got != 35*time.Second {
		t.Fatalf("empty deadline=%s", got)
	}
	if got := settings.DownloadWriteDeadline(now, 32*1024).Sub(now); got != 36*time.Second {
		t.Fatalf("32 KiB deadline=%s", got)
	}
	if got := settings.ServingRefreshInterval(); got != 5*time.Second {
		t.Fatalf("refresh=%s", got)
	}
	if got := settings.VolumeLimitBytes(); got != 99_000_000 {
		t.Fatalf("volume limit=%d", got)
	}
}

func TestLazyFetchEnabled(t *testing.T) {
	cases := []struct {
		settings     Settings
		assetsActive bool
		want         bool
	}{
		{Settings{LazyFetch: LazyFetchOn, ResPath: "/res"}, false, true},
		{Settings{LazyFetch: LazyFetchAuto, ResPath: "/res"}, true, true},
		{Settings{LazyFetch: LazyFetchAuto, ResPath: "/res"}, false, false},
		{Settings{LazyFetch: LazyFetchOff, ResPath: "/res"}, true, false},
		{Settings{LazyFetch: LazyFetchOn, ResPath: ""}, true, false},
	}
	for _, test := range cases {
		if got := test.settings.LazyFetchEnabled(test.assetsActive); got != test.want {
			t.Fatalf("%+v assets=%v = %v, want %v", test.settings, test.assetsActive, got, test.want)
		}
	}
}
