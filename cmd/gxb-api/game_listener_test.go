//go:build postgres

package main

import (
	"os"
	"testing"

	appotarelease "gxb.local/backend/v2/internal/application/otarelease"
	domain "gxb.local/backend/v2/internal/domain/otarelease"
)

func TestRefuseOpenWithoutAssets(t *testing.T) {
	state := appotarelease.NewStateFile(t.TempDir())
	if !refuseOpenWithoutAssets(true, state) {
		t.Fatal("an open start without assets was allowed")
	}
	if refuseOpenWithoutAssets(false, state) {
		t.Fatal("a closed start was refused")
	}
	document := appotarelease.StateDocument{Releases: []appotarelease.StoredRelease{{
		RawRelease: domain.RawRelease{Version: "1.631.1", Lane: string(domain.LaneCode), State: string(domain.StateActive)},
	}}}
	if err := state.Save(document); err != nil {
		t.Fatal(err)
	}
	if !refuseOpenWithoutAssets(true, state) {
		t.Fatal("an ACTIVE code release was taken for an assets release")
	}
	document.Releases[0].Lane = string(domain.LaneAssets)
	if err := state.Save(document); err != nil {
		t.Fatal(err)
	}
	if refuseOpenWithoutAssets(true, state) {
		t.Fatal("an open start with an ACTIVE assets release was refused")
	}
}

func TestRefuseOpenWithoutAssetsFailsClosedOnACorruptRecord(t *testing.T) {
	state := appotarelease.NewStateFile(t.TempDir())
	if err := os.WriteFile(state.Path(), []byte("{"), 0o644); err != nil {
		t.Fatal(err)
	}
	if !refuseOpenWithoutAssets(true, state) {
		t.Fatal("an unreadable release record did not refuse the open start")
	}
}

func TestParseGameListener(t *testing.T) {
	cases := []struct {
		value string
		open  bool
		fails bool
	}{
		{"", true, false},
		{"open", true, false},
		{"closed", false, false},
		{"CLOSED", false, true},
		{"shut", false, true},
	}
	for _, testCase := range cases {
		t.Run(testCase.value, func(t *testing.T) {
			open, err := parseGameListener(testCase.value)
			if (err != nil) != testCase.fails {
				t.Fatalf("fails = %v, err = %v", testCase.fails, err)
			}
			if err == nil && open != testCase.open {
				t.Fatalf("open = %v, want %v", open, testCase.open)
			}
		})
	}
}
