package socialgiftstore_test

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	sg "gxb.local/backend/v2/internal/application/socialgift"
	"gxb.local/backend/v2/internal/foundation/payload"
)

func TestPayloadGoldenSocialGiftStore(t *testing.T) {
	const table = "social_gift_claim_operations"
	directory := filepath.Join("testdata", "payloads", table+".semantic_result")
	raw, err := os.ReadFile(filepath.Join(directory, "v0.json"))
	if err != nil {
		t.Fatal(err)
	}
	var value sg.Result
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
