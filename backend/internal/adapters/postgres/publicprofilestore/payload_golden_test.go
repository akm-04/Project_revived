package publicprofilestore_test

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	app "gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/foundation/payload"
)

const mediaHistoryTable = "player_public_profile_media_history"
const mediaHistoryColumn = "reference"

func TestPayloadGoldenPublicProfileStore(t *testing.T) {
	directory := filepath.Join("testdata", "payloads", mediaHistoryTable+"."+mediaHistoryColumn)
	raw, err := os.ReadFile(filepath.Join(directory, "v0.json"))
	if err != nil {
		t.Fatal(err)
	}
	var reference app.MediaReference
	if err := payload.Decode(mediaHistoryTable, 0, raw, &reference); err != nil {
		t.Fatalf("%s v0: %v", mediaHistoryTable, err)
	}
	got, err := json.MarshalIndent(reference, "", "  ")
	if err != nil {
		t.Fatal(err)
	}
	want, err := os.ReadFile(filepath.Join(directory, "v0.expected.json"))
	if err != nil {
		t.Fatal(err)
	}
	if strings.TrimSpace(string(got)) != strings.TrimSpace(string(want)) {
		t.Fatalf("%s v0 decoded value:\n%s\nwant:\n%s", mediaHistoryTable, got, want)
	}
}
