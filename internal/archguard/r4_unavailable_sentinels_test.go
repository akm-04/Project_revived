package archguard

import (
	"go/ast"
	"go/parser"
	"go/token"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
)

const modulePrefix = "gxb.local/backend/v2/"

// TestR4UnavailableSentinelsCoverEveryImportedOwner keeps the hand-kept
// unavailableSentinels list complete: an owner package that stockruntime
// imports and that declares ErrUnavailable must be listed, or its
// "unavailable" answers 500 instead of the contracted 503.
func TestR4UnavailableSentinelsCoverEveryImportedOwner(t *testing.T) {
	root := repoRoot(t)
	base := filepath.Join(root, "internal", "adapters", "stockruntime")
	listed := importPaths(t, filepath.Join(base, "unavailable_sentinels.go"))
	owners := map[string]bool{}
	for _, name := range productionGoFiles(t, base) {
		if name == "unavailable_sentinels.go" {
			continue
		}
		for path := range importPaths(t, filepath.Join(base, name)) {
			isOwner := strings.HasPrefix(path, modulePrefix+"internal/application/") || strings.HasPrefix(path, modulePrefix+"internal/domain/")
			if isOwner && declaresErrUnavailable(t, filepath.Join(root, strings.TrimPrefix(path, modulePrefix))) {
				owners[path] = true
			}
		}
	}
	for path := range owners {
		if !listed[path] {
			t.Errorf("%s declares ErrUnavailable but is missing from unavailableSentinels", path)
		}
	}
	for path := range listed {
		if !owners[path] {
			t.Errorf("unavailableSentinels lists %s, which stockruntime no longer imports or which no longer declares ErrUnavailable", path)
		}
	}
}

func importPaths(t *testing.T, path string) map[string]bool {
	t.Helper()
	file, err := parser.ParseFile(token.NewFileSet(), path, nil, parser.ImportsOnly)
	if err != nil {
		t.Fatalf("parse %s: %v", path, err)
	}
	paths := map[string]bool{}
	for _, spec := range file.Imports {
		value, err := strconv.Unquote(spec.Path.Value)
		if err != nil {
			t.Fatalf("import in %s: %v", path, err)
		}
		paths[value] = true
	}
	return paths
}

func declaresErrUnavailable(t *testing.T, directory string) bool {
	t.Helper()
	for _, name := range productionGoFiles(t, directory) {
		file, err := parser.ParseFile(token.NewFileSet(), filepath.Join(directory, name), nil, 0)
		if err != nil {
			t.Fatalf("parse %s: %v", name, err)
		}
		for _, declaration := range file.Decls {
			general, ok := declaration.(*ast.GenDecl)
			if !ok || general.Tok != token.VAR {
				continue
			}
			for _, spec := range general.Specs {
				for _, identifier := range spec.(*ast.ValueSpec).Names {
					if identifier.Name == "ErrUnavailable" {
						return true
					}
				}
			}
		}
	}
	return false
}
