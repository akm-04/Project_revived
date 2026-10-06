package archguard

import (
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestC23SocialProjectionOwnerBoundaries(t *testing.T) {
	root := repoRoot(t)
	for _, rel := range []string{"internal/application/socialprojection", "internal/projection/socialview"} {
		e := filepath.WalkDir(filepath.Join(root, rel), func(p string, d os.DirEntry, e error) error {
			if e != nil {
				return e
			}
			if d.IsDir() || !strings.HasSuffix(p, ".go") || strings.HasSuffix(p, "_test.go") {
				return nil
			}
			node, e := parser.ParseFile(token.NewFileSet(), p, nil, 0)
			if e != nil {
				return e
			}
			for _, i := range node.Imports {
				for _, bad := range []string{"/adapters/", "database/sql", "pgx", "reflect"} {
					if strings.Contains(i.Path.Value, bad) {
						t.Errorf("%s imports %s", p, i.Path.Value)
					}
				}
			}
			b, e := os.ReadFile(p)
			if e != nil {
				return e
			}
			for _, bad := range []string{"SELECT ", "INSERT ", "UPDATE ", "DELETE ", "time.Now(", ".Begin(", ".Commit(", "EnsureRootTx", "ResolutionCommitted"} {
				if strings.Contains(string(b), bad) {
					t.Errorf("%s violates typed composition boundary: %s", p, bad)
				}
			}
			return nil
		})
		if e != nil {
			t.Fatal(e)
		}
	}
}
