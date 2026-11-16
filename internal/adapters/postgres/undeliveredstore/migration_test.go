package undeliveredstore

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestR6MigrationsAreForwardOnly(t *testing.T) {
	for _, name := range []string{"00166_r6_undelivered_replies.sql", "00167_r6_request_journal_replay.sql"} {
		raw, err := os.ReadFile(filepath.Join("..", "..", "..", "..", "migrations", name))
		if err != nil {
			t.Fatal(err)
		}
		text := string(raw)
		if !strings.HasPrefix(text, "-- +goose Up\n") || strings.Contains(text, "-- +goose Down") {
			t.Fatalf("%s is not a forward-only goose Up migration", name)
		}
	}
}
