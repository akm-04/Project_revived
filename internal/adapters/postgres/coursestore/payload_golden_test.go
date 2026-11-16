package coursestore

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"

	app "gxb.local/backend/v2/internal/application/course"
	"gxb.local/backend/v2/internal/domain/course"
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

func TestPayloadGoldenCourseStore(t *testing.T) {
	assertPayloadGolden[course.State](t, "player_course_roots", "facts")
	assertPayloadGolden[course.HeroFacts](t, "player_course_heroes", "facts")
	assertPayloadGolden[app.Admission](t, "player_course_admissions", "operation_context")
}
