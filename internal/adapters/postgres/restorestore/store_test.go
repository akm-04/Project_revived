package restorestore

import (
	"os"
	"strings"
	"testing"
)

func TestRestoreEpochsMigrationEnvelopeAndShape(t *testing.T) {
	raw, err := os.ReadFile("../../../../migrations/00171_l3b_restore_epochs.sql")
	if err != nil {
		t.Fatal(err)
	}
	contents := string(raw)
	if !strings.HasPrefix(contents, "-- +goose Up\n") || strings.Contains(contents, "-- +goose Down") {
		t.Fatal("migration violates the forward-only Goose envelope")
	}
	for _, required := range []string{
		"CREATE TABLE restore_epochs",
		"epoch bigserial PRIMARY KEY",
		"restored_at timestamptz NOT NULL",
		"backup_label text NOT NULL",
		"operator text NOT NULL",
		"reconciled_at timestamptz",
		"reconciliation_note text",
		"CHECK(reconciled_at >= restored_at)",
	} {
		if !strings.Contains(contents, required) {
			t.Fatalf("00171 missing %q", required)
		}
	}
}
