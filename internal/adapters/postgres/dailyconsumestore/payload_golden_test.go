package dailyconsumestore_test

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	app "gxb.local/backend/v2/internal/application/dailyconsume"
	"gxb.local/backend/v2/internal/foundation/payload"
)

func TestPayloadGoldenDailyConsumeStore(t *testing.T) {
	directory := filepath.Join("testdata", "payloads", "daily_consumption_players.counts")
	raw, err := os.ReadFile(filepath.Join(directory, "v0.json"))
	if err != nil {
		t.Fatal(err)
	}
	var counts app.Counts
	if err := payload.Decode("daily_consumption_players", 0, raw, &counts); err != nil {
		t.Fatalf("daily_consumption_players v0: %v", err)
	}
	got, err := json.MarshalIndent(counts, "", "  ")
	if err != nil {
		t.Fatal(err)
	}
	want, err := os.ReadFile(filepath.Join(directory, "v0.expected.json"))
	if err != nil {
		t.Fatal(err)
	}
	if strings.TrimSpace(string(got)) != strings.TrimSpace(string(want)) {
		t.Fatalf("daily_consumption_players v0 decoded value:\n%s\nwant:\n%s", got, want)
	}
}
