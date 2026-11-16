package i5store

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"

	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/payload"
)

func assertPayloadGolden[T any](t *testing.T, table, column string) {
	t.Helper()
	dir := filepath.Join("testdata", "payloads", table+"."+column)
	raw, err := os.ReadFile(filepath.Join(dir, "v0.json"))
	if err != nil {
		t.Fatal(err)
	}
	expected, err := os.ReadFile(filepath.Join(dir, "v0.expected.json"))
	if err != nil {
		t.Fatal(err)
	}
	var value T
	if err = payload.Decode(table, 0, raw, &value); err != nil {
		t.Fatalf("%s.%s: %v", table, column, err)
	}
	stored, err := json.MarshalIndent(value, "", "  ")
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(stored, expected) {
		t.Fatalf("%s.%s: re-marshalled value differs\n got: %s\nwant: %s", table, column, stored, expected)
	}
}

func TestPayloadGoldenI5Store(t *testing.T) {
	assertPayloadGolden[objective.AwakeRoot](t, "player_awakening_roots", "payload")
}
