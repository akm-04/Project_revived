package archguard

import (
	"go/ast"
	"go/parser"
	"go/token"
	"io/fs"
	"path/filepath"
	"strings"
	"testing"
)

// COMBAT_MODE_REGISTRY_V1: every combat START builder names the mode it
// registers, so an unregistered START cannot be built by accident.
func TestL3CEveryCombatStartBuilderNamesItsMode(t *testing.T) {
	root := repoRoot(t)
	files := token.NewFileSet()
	builders := 0
	err := filepath.WalkDir(filepath.Join(root, "internal", "application"), func(path string, entry fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if entry.IsDir() || !strings.HasSuffix(path, ".go") || strings.HasSuffix(path, "_test.go") {
			return nil
		}
		file, err := parser.ParseFile(files, path, nil, 0)
		if err != nil {
			return err
		}
		relative, _ := filepath.Rel(root, path)
		ast.Inspect(file, func(node ast.Node) bool {
			literal, ok := node.(*ast.CompositeLit)
			if !ok {
				return true
			}
			selector, ok := literal.Type.(*ast.SelectorExpr)
			if !ok || selector.Sel.Name != "StartRequest" {
				return true
			}
			builders++
			if !hasModeField(literal) {
				t.Errorf("%s:%d: combat.StartRequest builder does not name its registered Mode", relative, files.Position(node.Pos()).Line)
			}
			return true
		})
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	if builders != 27 {
		t.Fatalf("%d combat START builders, want the 27 registered by COMBAT_MODE_REGISTRY_V1", builders)
	}
}

func hasModeField(literal *ast.CompositeLit) bool {
	for _, element := range literal.Elts {
		field, ok := element.(*ast.KeyValueExpr)
		if !ok {
			continue
		}
		if identifier, ok := field.Key.(*ast.Ident); ok && identifier.Name == "Mode" {
			return true
		}
	}
	return false
}
