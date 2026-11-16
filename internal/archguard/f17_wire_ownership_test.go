package archguard

import (
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// I9_MODE_FRAMEWORK_V2 F17: stockruntime.Decorated (live replies) and foundation/changes (stored replies) are the only
// owners of the economy_/new_funcs_ keys. No dispatcher or application owner assembles them.
func TestF17WireKeysHaveOneOwner(t *testing.T) {
	root := repoRoot(t)
	allowed := map[string]bool{
		filepath.Join("internal", "foundation", "changes"):                    true,
		filepath.Join("internal", "adapters", "stockruntime", "decorated.go"): true,
	}
	err := filepath.WalkDir(root, func(path string, entry fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if outsideProduct(root, path, entry) {
			return filepath.SkipDir
		}
		if entry.IsDir() || !strings.HasSuffix(path, ".go") || strings.HasSuffix(path, "_test.go") {
			return nil
		}
		body, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		for _, wireKey := range []string{`"economy_"`, `"new_funcs_"`} {
			if !strings.Contains(string(body), wireKey) {
				continue
			}
			relative, err := filepath.Rel(root, path)
			if err != nil {
				return err
			}
			owner := filepath.Dir(relative)
			if allowed[relative] || allowed[owner] {
				continue
			}
			t.Errorf("%s writes the F17 wire key %s outside changes and the decorator", relative, wireKey)
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
}
