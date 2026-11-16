package marchstore_test

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"gxb.local/backend/v2/internal/domain/march"
	"gxb.local/backend/v2/internal/foundation/payload"
)

func TestPayloadGoldenMarchStore(t *testing.T) {
	directory := filepath.Join("testdata", "payloads", "march_players.payload")
	raw, err := os.ReadFile(filepath.Join(directory, "v0.json"))
	if err != nil {
		t.Fatal(err)
	}
	var run march.Run
	if err := payload.Decode("march_players", 0, raw, &run); err != nil {
		t.Fatalf("march_players v0: %v", err)
	}
	got, err := json.MarshalIndent(run, "", "  ")
	if err != nil {
		t.Fatal(err)
	}
	want, err := os.ReadFile(filepath.Join(directory, "v0.expected.json"))
	if err != nil {
		t.Fatal(err)
	}
	if strings.TrimSpace(string(got)) != strings.TrimSpace(string(want)) {
		t.Fatalf("march_players v0 decoded value:\n%s\nwant:\n%s", got, want)
	}
}
