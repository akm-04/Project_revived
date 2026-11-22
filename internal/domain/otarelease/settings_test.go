package otarelease

import (
	"errors"
	"testing"
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

func TestParseSettingsRefusesUnknownFieldAndBadValues(t *testing.T) {
	for _, input := range []string{
		`{"lazy_fetch":"auto","res_path":"","extra":1}`,
		`{"lazy_fetch":"sometimes","res_path":""}`,
		`{"lazy_fetch":"auto","res_path":"relative/res"}`,
		`{}`,
		`{"lazy_fetch":"on","res_path":""} trailing`,
	} {
		if _, err := ParseSettings([]byte(input)); !errors.Is(err, ErrInvalidSettings) {
			t.Fatalf("input %q err=%v", input, err)
		}
	}
}

func TestLazyFetchEnabled(t *testing.T) {
	cases := []struct {
		settings     Settings
		assetsActive bool
		want         bool
	}{
		{Settings{LazyFetchOn, "/res"}, false, true},
		{Settings{LazyFetchAuto, "/res"}, true, true},
		{Settings{LazyFetchAuto, "/res"}, false, false},
		{Settings{LazyFetchOff, "/res"}, true, false},
		{Settings{LazyFetchOn, ""}, true, false},
	}
	for _, test := range cases {
		if got := test.settings.LazyFetchEnabled(test.assetsActive); got != test.want {
			t.Fatalf("%+v assets=%v = %v, want %v", test.settings, test.assetsActive, got, test.want)
		}
	}
}
