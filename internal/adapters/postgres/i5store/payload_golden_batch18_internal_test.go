package i5store

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"gxb.local/backend/v2/internal/foundation/payload"
)

func TestPayloadGoldenI5StoreBatch18Audience(t *testing.T) {
	const table = "redeem_campaigns"
	directory := filepath.Join("testdata", "payloads", table+".audience_policy")
	raw, err := os.ReadFile(filepath.Join(directory, "v0.json"))
	if err != nil {
		t.Fatal(err)
	}
	var audience audienceJSON
	if err := payload.Decode(table, 0, raw, &audience); err != nil {
		t.Fatalf("%s v0: %v", table, err)
	}
	got, err := json.MarshalIndent(audience, "", "  ")
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
