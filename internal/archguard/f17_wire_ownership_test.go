package archguard

import (
	"io/fs"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
)

// A key with options (json:"economy_,omitempty") writes the wire key too.
var f17WireKey = regexp.MustCompile(`"(economy_|new_funcs_)[",]`)

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
		wireKey := f17WireKey.FindString(string(body))
		if wireKey == "" {
			return nil
		}
		relative, err := filepath.Rel(root, path)
		if err != nil {
			return err
		}
		if allowed[relative] || allowed[filepath.Dir(relative)] {
			return nil
		}
		t.Errorf("%s writes the F17 wire key %s outside changes and the decorator", relative, wireKey)
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
}
