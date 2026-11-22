//go:build postgres

package playerdisplay_test

import (
	"go/ast"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"testing"

	d "gxb.local/backend/v2/internal/domain/itemsenergy"
)

// Shared namespace bands, not row ranks: one is a lower bound for the whole
// Character asset band and one reserves the mail grant namespace.
var sharedRankNamespaces = map[string]bool{
	"CharacterAssetLockRankMin":  true,
	"grantLockRankMailNamespace": true,
}

// TestI911BLockRanksAreUnique is the seam section 2 uniqueness proof over every
// exported lock-rank constant in the tree.
func TestI911BLockRanksAreUnique(t *testing.T) {
	if d.LockRankDailyConsume != 450 {
		t.Fatalf("daily-consume rank %d, want 450", d.LockRankDailyConsume)
	}
	root := filepath.Join("..", "..", "..")
	seen := map[int64]string{}
	err := filepath.Walk(filepath.Join(root, "internal"), func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() || !strings.HasSuffix(path, ".go") || strings.HasSuffix(path, "_test.go") {
			return nil
		}
		file, err := parser.ParseFile(token.NewFileSet(), path, nil, 0)
		if err != nil {
			return err
		}
		for _, declaration := range file.Decls {
			gen, ok := declaration.(*ast.GenDecl)
			if !ok || gen.Tok != token.CONST {
				continue
			}
			for _, spec := range gen.Specs {
				value, ok := spec.(*ast.ValueSpec)
				if !ok || len(value.Names) != len(value.Values) {
					continue
				}
				for index, name := range value.Names {
					if !strings.Contains(name.Name, "LockRank") || sharedRankNamespaces[name.Name] {
						continue
					}
					number, ok := value.Values[index].(*ast.BasicLit)
					if !ok || number.Kind != token.INT {
						continue
					}
					rank, err := strconv.ParseInt(number.Value, 10, 64)
					if err != nil {
						continue
					}
					if prior, exists := seen[rank]; exists {
						t.Fatalf("rank %d used by %s and %s (%s)", rank, prior, name.Name, path)
					}
					seen[rank] = name.Name
				}
			}
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
}
