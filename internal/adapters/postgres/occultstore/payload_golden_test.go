package occultstore_test

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"gxb.local/backend/v2/internal/domain/occult"
	"gxb.local/backend/v2/internal/foundation/payload"
)

func TestPayloadGoldenOccultStore(t *testing.T) {
	directory := filepath.Join("testdata", "payloads", "occult_players.scores")
	raw, err := os.ReadFile(filepath.Join(directory, "v0.json"))
	if err != nil {
		t.Fatal(err)
	}
	var scores occult.Scores
	if err := payload.Decode("occult_players", 0, raw, &scores); err != nil {
		t.Fatalf("occult_players v0: %v", err)
	}
	got, err := json.MarshalIndent(scores, "", "  ")
	if err != nil {
		t.Fatal(err)
	}
	want, err := os.ReadFile(filepath.Join(directory, "v0.expected.json"))
	if err != nil {
		t.Fatal(err)
	}
	if strings.TrimSpace(string(got)) != strings.TrimSpace(string(want)) {
		t.Fatalf("occult_players v0 decoded value:\n%s\nwant:\n%s", got, want)
	}
}
