package characterstore

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"

	app "gxb.local/backend/v2/internal/application/heroevolution"
	"gxb.local/backend/v2/internal/domain/heroevolution"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/policy"
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

func TestPayloadGoldenCharacterStore(t *testing.T) {
	assertPayloadGolden[heroevolution.Facts](t, "player_hero_evolution", "facts")
	assertPayloadGolden[app.Admission](t, "player_hero_evolution_admissions", "operation_context")
	assertPayloadGolden[policy.Set](t, "player_hero_practice_candidates", "generation_policy_refs")
	assertPayloadGolden[policy.Set](t, "player_pet_practice_candidates", "generation_policy_refs")
}
