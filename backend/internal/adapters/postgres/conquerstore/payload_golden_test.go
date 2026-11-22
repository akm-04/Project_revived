package conquerstore

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"

	d "gxb.local/backend/v2/internal/domain/conquerschool"
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

func TestPayloadGoldenConquerStore(t *testing.T) {
	assertPayloadGolden[d.Mode](t, "conquer_school_players", "state")
	assertPayloadGolden[d.ReportProfile](t, "conquer_school_reports", "profile")
	assertPayloadGolden[d.Payload](t, "player_conquer_facts", "payload")
}
