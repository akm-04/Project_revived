package archguard

import (
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// TestGirlsLogHasOneWriter pins A-125 G1 step 1: no caller writes a Girls Log
// row directly, so every insert reaches the one wakeup-emitting writer.
func TestGirlsLogHasOneWriter(t *testing.T) {
	root := repoRoot(t)
	writers := []string{}
	err := filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			if outsideProduct(root, path, d) || strings.Contains(filepath.ToSlash(path), "/vendor/") {
				return filepath.SkipDir
			}
			return nil
		}
		if !strings.HasSuffix(path, ".go") || strings.HasSuffix(path, "_test.go") {
			return nil
		}
		raw, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		if strings.Contains(string(raw), "INSERT INTO player_library_hero_logs") {
			rel, _ := filepath.Rel(root, path)
			writers = append(writers, filepath.ToSlash(rel))
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	if len(writers) != 1 || writers[0] != "internal/adapters/postgres/librarystore/logs.go" {
		t.Fatalf("Girls Log writers %v, want only librarystore/logs.go", writers)
	}
}

// TestAwakeningMilestoneUsesTheGirlsLogWriter keeps the awakening milestone on
// the one wakeup-emitting journal path.
func TestAwakeningMilestoneUsesTheGirlsLogWriter(t *testing.T) {
	raw, err := os.ReadFile(filepath.Join(repoRoot(t), "internal/application/characterhero/awakening.go"))
	if err != nil {
		t.Fatal(err)
	}
	text := string(raw)
	if !strings.Contains(text, "lib.LogAwakened") || !strings.Contains(text, "s.recordHeroJournalTx(") {
		t.Fatal("awakening milestone does not use the shared Girls Log journal")
	}
}
