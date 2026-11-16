package workplacestore_test

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	d "gxb.local/backend/v2/internal/domain/workplace"
	"gxb.local/backend/v2/internal/foundation/payload"
)

const workplaceTable = "workplace_players"

func TestPayloadGoldenWorkplaceStore(t *testing.T) {
	directory := filepath.Join("testdata", "payloads", workplaceTable+".payload")
	raw, err := os.ReadFile(filepath.Join(directory, "v0.json"))
	if err != nil {
		t.Fatal(err)
	}
	var state d.State
	if err := payload.Decode(workplaceTable, 0, raw, &state); err != nil {
		t.Fatalf("%s v0: %v", workplaceTable, err)
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
		t.Fatalf("%s v0 decoded value:\n%s\nwant:\n%s", workplaceTable, got, want)
	}
}
