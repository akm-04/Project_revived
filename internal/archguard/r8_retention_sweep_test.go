package archguard

import (
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// TestCanonicalMigrationsAreForwardOnly is the PASS628 preventive rule: every
// canonical migration starts with the literal -- +goose Up and has no Down section.
func TestCanonicalMigrationsAreForwardOnly(t *testing.T) {
	root := repoRoot(t)
	entries, err := os.ReadDir(filepath.Join(root, "migrations"))
	if err != nil {
		t.Fatal(err)
	}
	for _, entry := range entries {
		if entry.IsDir() || !strings.HasSuffix(entry.Name(), ".sql") {
			continue
		}
		content, err := os.ReadFile(filepath.Join(root, "migrations", entry.Name()))
		if err != nil {
			t.Fatal(err)
		}
		text := string(content)
		if !strings.HasPrefix(text, "-- +goose Up\n") {
			t.Errorf("migrations/%s does not begin with -- +goose Up", entry.Name())
		}
		if strings.Contains(text, "-- +goose Down") {
			t.Errorf("migrations/%s contains a Down section", entry.Name())
		}
	}
}

// TestRetentionSweepSettingOnlyInRetentionstoreAndMigration keeps the combat
// append-only bypass inside the retention sweep: the setting is written by
// retentionstore rules and accepted by migration 00165, nowhere else.
func TestRetentionSweepSettingOnlyInRetentionstoreAndMigration(t *testing.T) {
	const setting = "gxb.retention_sweep"
	root := repoRoot(t)
	allowedDirectory := filepath.ToSlash(filepath.Join("internal", "adapters", "postgres", "retentionstore")) + "/"
	allowedMigration := filepath.ToSlash(filepath.Join("migrations", "00165_r8_4_combat_retention_sweep.sql"))
	guardSource := filepath.ToSlash(filepath.Join("internal", "archguard", "r8_retention_sweep_test.go"))
	foundAllowedMigration := false
	foundAllowedDirectory := false
	var errs []string
	err := filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if outsideProduct(root, path, d) {
			return filepath.SkipDir
		}
		if d.IsDir() || (!strings.HasSuffix(path, ".go") && !strings.HasSuffix(path, ".sql")) {
			return nil
		}
		content, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		if !strings.Contains(string(content), setting) {
			return nil
		}
		rel, err := filepath.Rel(root, path)
		if err != nil {
			return err
		}
		rel = filepath.ToSlash(rel)
		switch {
		case rel == guardSource:
		case strings.HasPrefix(rel, allowedDirectory):
			foundAllowedDirectory = true
		case rel == allowedMigration:
			foundAllowedMigration = true
		default:
			errs = append(errs, rel)
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	if !foundAllowedMigration {
		t.Fatalf("%s is absent or does not set %s", allowedMigration, setting)
	}
	if !foundAllowedDirectory {
		t.Fatalf("%s does not set %s", allowedDirectory, setting)
	}
	if len(errs) > 0 {
		t.Fatalf("%s appears outside retentionstore and %s:\n%s", setting, allowedMigration, strings.Join(errs, "\n"))
	}
}
