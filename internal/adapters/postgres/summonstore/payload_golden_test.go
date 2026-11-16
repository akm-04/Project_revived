package summonstore_test

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	d "gxb.local/backend/v2/internal/domain/summon"
	"gxb.local/backend/v2/internal/foundation/payload"
)

func TestPayloadGoldenSummonStore(t *testing.T) {
	countersDirectory := filepath.Join("testdata", "payloads", "summon_players.counters")
	countersRaw, err := os.ReadFile(filepath.Join(countersDirectory, "v0.json"))
	if err != nil {
		t.Fatal(err)
	}
	var counters map[string]int64
	if err := payload.Decode("summon_players", 0, countersRaw, &counters); err != nil {
		t.Fatalf("summon_players v0: %v", err)
	}
	assertGolden(t, "summon_players", countersDirectory, counters)

	tuningDirectory := filepath.Join("testdata", "payloads", "summon_tuning.payload")
	tuningRaw, err := os.ReadFile(filepath.Join(tuningDirectory, "v0.json"))
	if err != nil {
		t.Fatal(err)
	}
	var tuning d.Tuning
	if err := payload.Decode("summon_tuning", 0, tuningRaw, &tuning); err != nil {
		t.Fatalf("summon_tuning v0: %v", err)
	}
	assertGolden(t, "summon_tuning", tuningDirectory, tuning)
}

func assertGolden(t *testing.T, table, directory string, value any) {
	t.Helper()
	got, err := json.MarshalIndent(value, "", "  ")
	if err != nil {
		t.Fatal(err)
	}
	want, err := os.ReadFile(filepath.Join(directory, "v0.expected.json"))
	if err != nil {
		t.Fatal(err)
	}
	if strings.TrimSpace(string(got)) != strings.TrimSpace(string(want)) {
		t.Fatalf("%s v0 decoded value:\n%s\nwant:\n%s", table, got, want)
	}
}
