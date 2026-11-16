package socialinboxstore_test

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/foundation/payload"
)

func TestPayloadGoldenSocialInboxStore(t *testing.T) {
	const materializationTable = "social_guild_invite_materializations"
	materializationDirectory := filepath.Join("testdata", "payloads", materializationTable+".target_payload")
	materializationRaw, err := os.ReadFile(filepath.Join(materializationDirectory, "v0.json"))
	if err != nil {
		t.Fatal(err)
	}
	var proof gi.TargetProof
	if err := payload.Decode(materializationTable, 0, materializationRaw, &proof); err != nil {
		t.Fatalf("%s v0: %v", materializationTable, err)
	}
	assertGolden(t, materializationTable, materializationDirectory, proof)

	const invalidationTable = "social_guild_invite_invalidations"
	invalidationDirectory := filepath.Join("testdata", "payloads", invalidationTable+".target_payload")
	invalidationRaw, err := os.ReadFile(filepath.Join(invalidationDirectory, "v0.json"))
	if err != nil {
		t.Fatal(err)
	}
	var invalidation gi.InvalidationProof
	if err := payload.Decode(invalidationTable, 0, invalidationRaw, &invalidation); err != nil {
		t.Fatalf("%s v0: %v", invalidationTable, err)
	}
	assertGolden(t, invalidationTable, invalidationDirectory, invalidation)
}

func assertGolden(t *testing.T, table, directory string, value any) {
	t.Helper()
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
