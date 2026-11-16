package achievementstore

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/foundation/payload"
)

func checkPayloadGolden(t *testing.T, table, column string, decode func(raw []byte) any) {
	t.Helper()
	directory := filepath.Join("testdata", "payloads", table+"."+column)
	raw, err := os.ReadFile(filepath.Join(directory, "v0.json"))
	if err != nil {
		t.Fatal(err)
	}
	got, err := json.MarshalIndent(decode(raw), "", "  ")
	if err != nil {
		t.Fatal(err)
	}
	got = append(got, '\n')
	want, err := os.ReadFile(filepath.Join(directory, "v0.expected.json"))
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(got, want) {
		t.Fatalf("%s.%s golden mismatch\n got: %s\nwant: %s", table, column, got, want)
	}
}

func decodeGolden[T any](t *testing.T, table string, raw []byte, value *T) {
	t.Helper()
	if err := payload.Decode(table, 0, raw, value); err != nil {
		t.Fatal(err)
	}
}

func TestPayloadGoldenAchievementStore(t *testing.T) {
	checkPayloadGolden(t, "achievement_roots", "complete_times", func(raw []byte) any {
		var times []*time.Time
		decodeGolden(t, "achievement_roots", raw, &times)
		return times
	})
	checkPayloadGolden(t, "achievement_streaks", "complete_times", func(raw []byte) any {
		var times []*time.Time
		decodeGolden(t, "achievement_streaks", raw, &times)
		return times
	})
}
