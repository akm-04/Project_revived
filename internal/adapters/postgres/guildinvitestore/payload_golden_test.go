package guildinvitestore_test

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/foundation/payload"
)

func TestPayloadGoldenGuildInviteStore(t *testing.T) {
	goldens := []struct {
		table   string
		column  string
		decoded func([]byte) (any, error)
	}{
		{"guild_invite_projection_sources", "source_payload", func(raw []byte) (any, error) {
			var value gi.Issue
			err := payload.Decode("guild_invite_projection_sources", 0, raw, &value)
			return value, err
		}},
		{"guild_invite_projection_markers", "source_payload", func(raw []byte) (any, error) {
			var value gi.Marker
			err := payload.Decode("guild_invite_projection_markers", 0, raw, &value)
			return value, err
		}},
		{"guild_invite_projection_markers", "cursor_proof", func(raw []byte) (any, error) {
			var value gi.CursorProof
			err := payload.Decode("guild_invite_projection_markers", 0, raw, &value)
			return value, err
		}},
	}
	for _, golden := range goldens {
		directory := filepath.Join("testdata", "payloads", golden.table+"."+golden.column)
		raw, err := os.ReadFile(filepath.Join(directory, "v0.json"))
		if err != nil {
			t.Fatal(err)
		}
		value, err := golden.decoded(raw)
		if err != nil {
			t.Fatalf("%s.%s v0: %v", golden.table, golden.column, err)
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
			t.Fatalf("%s.%s v0 decoded value:\n%s\nwant:\n%s", golden.table, golden.column, got, want)
		}
	}
}
