package i5store_test

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/foundation/payload"
)

func TestPayloadGoldenI5Store(t *testing.T) {
	const attachmentTable = "mail_attachments"
	attachmentDirectory := filepath.Join("testdata", "payloads", attachmentTable+".metadata")
	attachmentRaw, err := os.ReadFile(filepath.Join(attachmentDirectory, "v0.json"))
	if err != nil {
		t.Fatal(err)
	}
	var metadata map[string]string
	if err := payload.Decode(attachmentTable, 0, attachmentRaw, &metadata); err != nil {
		t.Fatalf("%s v0: %v", attachmentTable, err)
	}
	assertGolden(t, attachmentTable, attachmentDirectory, metadata)

	const tuningTable = "mail_tuning"
	tuningDirectory := filepath.Join("testdata", "payloads", tuningTable+".payload")
	tuningRaw, err := os.ReadFile(filepath.Join(tuningDirectory, "v0.json"))
	if err != nil {
		t.Fatal(err)
	}
	var tuning mail.Tuning
	if err := payload.Decode(tuningTable, 0, tuningRaw, &tuning); err != nil {
		t.Fatalf("%s v0: %v", tuningTable, err)
	}
	assertGolden(t, tuningTable, tuningDirectory, tuning)
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
