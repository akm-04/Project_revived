package generaldmstore_test

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	dm "gxb.local/backend/v2/internal/application/generaldm"
	"gxb.local/backend/v2/internal/foundation/payload"
)

func TestPayloadGoldenGeneralDMStore(t *testing.T) {
	const table = "personal_dm_payloads"
	directory := filepath.Join("testdata", "payloads", table+".payload")
	raw, err := os.ReadFile(filepath.Join(directory, "v0.json"))
	if err != nil {
		t.Fatal(err)
	}
	var value dm.Intent
	if err := payload.Decode(table, 0, raw, &value); err != nil {
		t.Fatalf("%s v0: %v", table, err)
	}
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
