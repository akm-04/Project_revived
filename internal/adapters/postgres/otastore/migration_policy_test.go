package otastore

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// TestMigrationsAreForwardOnlyGooseFiles is the PASS628 preventive rule: every
// canonical migration begins with the literal -- +goose Up and carries no Down.
func TestMigrationsAreForwardOnlyGooseFiles(t *testing.T) {
	directory := filepath.Join("..", "..", "..", "..", "migrations")
	entries, err := os.ReadDir(directory)
	if err != nil {
		t.Fatal(err)
	}
	checked := 0
	for _, entry := range entries {
		if entry.IsDir() || !strings.HasSuffix(entry.Name(), ".sql") {
			continue
		}
		contents, err := os.ReadFile(filepath.Join(directory, entry.Name()))
		if err != nil {
			t.Fatal(err)
		}
		text := string(contents)
		firstLine, _, _ := strings.Cut(text, "\n")
		if strings.TrimSpace(firstLine) != "-- +goose Up" {
			t.Fatalf("%s does not begin with -- +goose Up", entry.Name())
		}
		if strings.Contains(text, "-- +goose Down") {
			t.Fatalf("%s carries a goose Down section", entry.Name())
		}
		checked++
	}
	if checked == 0 {
		t.Fatal("no migration file was checked")
	}
}
