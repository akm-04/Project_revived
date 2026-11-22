package archguard

import (
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// R7: the ranking application package must never enumerate all players. The
// I4 enumeration lives at the adapter edge, which passes roots to the jobs.
func TestRankingApplicationDoesNotEnumerateAllPlayers(t *testing.T) {
	root := repoRoot(t)
	base := filepath.Join(root, "internal", "application", "ranking")
	forbidden := []string{"ListPlayerRootsTx", "ListAllPlayers", "ListPlayersTx", "AllPlayersTx"}
	var errs []string
	e := filepath.WalkDir(base, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() || !strings.HasSuffix(path, ".go") || strings.HasSuffix(path, "_test.go") {
			return nil
		}
		b, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		rel, _ := filepath.Rel(root, path)
		for _, name := range forbidden {
			if strings.Contains(string(b), name) {
				errs = append(errs, rel+" mentions "+name)
			}
		}
		return nil
	})
	if e != nil {
		t.Fatal(e)
	}
	if len(errs) > 0 {
		t.Fatalf("ranking application enumerates all players:\n%s", strings.Join(errs, "\n"))
	}
}
