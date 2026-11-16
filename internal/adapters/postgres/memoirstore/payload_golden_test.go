package memoirstore_test

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"gxb.local/backend/v2/internal/domain/memoir"
	"gxb.local/backend/v2/internal/foundation/payload"
)

func TestPayloadGoldenMemoirStore(t *testing.T) {
	directory := filepath.Join("testdata", "payloads", "memoir_players.payload")
	raw, err := os.ReadFile(filepath.Join(directory, "v0.json"))
	if err != nil {
		t.Fatal(err)
	}
	var state memoir.State
	if err := payload.Decode("memoir_players", 0, raw, &state); err != nil {
		t.Fatalf("memoir_players v0: %v", err)
	}
	got, err := json.MarshalIndent(state, "", "  ")
	if err != nil {
		t.Fatal(err)
	}
	want, err := os.ReadFile(filepath.Join(directory, "v0.expected.json"))
	if err != nil {
		t.Fatal(err)
	}
	if strings.TrimSpace(string(got)) != strings.TrimSpace(string(want)) {
		t.Fatalf("memoir_players v0 decoded value:\n%s\nwant:\n%s", got, want)
	}
}
