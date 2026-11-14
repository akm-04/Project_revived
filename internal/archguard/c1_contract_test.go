package archguard

import (
	"io/fs"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
)

// C1-2: a request holds at most one connection. postgres.Pool.Begin and QueryRow refuse a nested acquisition in strict
// mode; a query through Pool.Raw() would skip that check, so product code outside the composition roots must not use
// the raw pool for statements.
var rawPoolStatement = regexp.MustCompile(`\.Raw\(\)\.(Exec|Query|QueryRow|Begin|BeginTx|Acquire|SendBatch|CopyFrom)\(`)

// nativebirth seeds native-test databases outside any request.
var rawPoolAllowed = map[string]bool{"internal/adapters/postgres/nativebirth/birth.go": true}

func TestC1NoStatementsThroughTheRawPool(t *testing.T) {
	root := repoRoot(t)
	err := filepath.WalkDir(filepath.Join(root, "internal"), func(path string, d fs.DirEntry, err error) error {
		if err != nil || outsideProduct(root, path, d) {
			return err
		}
		if d.IsDir() || !strings.HasSuffix(path, ".go") || strings.HasSuffix(path, "_test.go") {
			return nil
		}
		rel, _ := filepath.Rel(root, path)
		if rawPoolAllowed[filepath.ToSlash(rel)] {
			return nil
		}
		src, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		for number, line := range strings.Split(string(src), "\n") {
			if rawPoolStatement.MatchString(line) {
				t.Errorf("%s:%d runs a statement on the raw pool, bypassing the one-connection check: %s", rel, number+1, strings.TrimSpace(line))
			}
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
}
