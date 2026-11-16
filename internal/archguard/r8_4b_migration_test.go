package archguard

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestR84BRetentionMigrationsKeepForwardOnlyEnvelope(t *testing.T) {
	root := repoRoot(t)
	for _, name := range []string{"00164_r8_receipt_operation_id.sql", "00165_r8_validate_attempt_foreign_keys.sql"} {
		raw, err := os.ReadFile(filepath.Join(root, "migrations", name))
		if err != nil {
			t.Fatal(err)
		}
		text := string(raw)
		if !strings.HasPrefix(text, "-- +goose Up\n") || strings.Contains(text, "-- +goose Down") {
			t.Fatalf("%s violates the forward-only Goose envelope", name)
		}
	}
}
