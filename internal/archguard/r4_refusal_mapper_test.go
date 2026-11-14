package archguard

import (
	"go/ast"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// TestR4RefusalRepliesGoThroughTheMapper guards every stockruntime production
// file, not only the dispatchers: failure.go is the only place allowed to build
// a non-200 httpedge.Response. It sees a literal whose HTTPStatus is not
// statically http.StatusOK (or the literal 200/0) and any status expression it
// cannot resolve, such as an identifier, variable or call. It cannot see a
// status chosen inside a helper that returns failureReply, nor a response built
// away from a composite literal.
func TestR4RefusalRepliesGoThroughTheMapper(t *testing.T) {
	root := repoRoot(t)
	base := filepath.Join(root, "internal", "adapters", "stockruntime")
	for _, name := range productionGoFiles(t, base) {
		if name == "failure.go" {
			continue
		}
		for _, literal := range responseLiterals(t, filepath.Join(base, name)) {
			status, found := responseStatus(t, literal)
			if !found || statusIsOK(status) {
				continue
			}
			t.Errorf("%s:%d builds an httpedge.Response with status %s outside the stockruntime mapper; route it through failureReply", name, literal.line, statusLabel(status))
		}
	}
}

// TestR4EdgeNonOKRepliesGoThroughEdgeFailure guards the protocol edge: every
// writeJSON call must sit in edgeFailure, and the response writer's
// writeJSONValue is allowed only in the builder, the helper and the dispatcher
// write path. It cannot see a non-200 status chosen inside an allowed function,
// nor a different writer function that bypasses these two names.
func TestR4EdgeNonOKRepliesGoThroughEdgeFailure(t *testing.T) {
	root := repoRoot(t)
	base := filepath.Join(root, "internal", "protocol", "httpedge")
	for _, name := range productionGoFiles(t, base) {
		path := filepath.Join(base, name)
		file, err := parser.ParseFile(token.NewFileSet(), path, nil, 0)
		if err != nil {
			t.Fatalf("parse %s: %v", path, err)
		}
		for _, declaration := range file.Decls {
			function, ok := declaration.(*ast.FuncDecl)
			if !ok || function.Body == nil {
				continue
			}
			ast.Inspect(function.Body, func(node ast.Node) bool {
				call, ok := node.(*ast.CallExpr)
				if !ok {
					return true
				}
				writer := calledName(call.Fun)
				if !writerAllowed(writer, function.Name.Name) {
					t.Errorf("%s: %s called from %s (want edgeFailure)", name, writer, function.Name.Name)
				}
				return true
			})
		}
	}
}

type responseLiteral struct {
	literal *ast.CompositeLit
	line    int
}

func responseLiterals(t *testing.T, path string) []responseLiteral {
	t.Helper()
	files := token.NewFileSet()
	file, err := parser.ParseFile(files, path, nil, 0)
	if err != nil {
		t.Fatalf("parse %s: %v", path, err)
	}
	var found []responseLiteral
	ast.Inspect(file, func(node ast.Node) bool {
		literal, ok := node.(*ast.CompositeLit)
		if !ok || !isResponseType(literal.Type) {
			return true
		}
		found = append(found, responseLiteral{literal: literal, line: files.Position(literal.Pos()).Line})
		return true
	})
	return found
}

func isResponseType(expr ast.Expr) bool {
	selector, ok := expr.(*ast.SelectorExpr)
	if !ok {
		return false
	}
	owner, ok := selector.X.(*ast.Ident)
	return ok && owner.Name == "httpedge" && selector.Sel.Name == "Response"
}

func responseStatus(t *testing.T, literal responseLiteral) (ast.Expr, bool) {
	t.Helper()
	for _, element := range literal.literal.Elts {
		pair, ok := element.(*ast.KeyValueExpr)
		if !ok {
			continue
		}
		key, ok := pair.Key.(*ast.Ident)
		if ok && key.Name == "HTTPStatus" {
			return pair.Value, true
		}
	}
	return nil, false
}

func statusIsOK(expr ast.Expr) bool {
	switch value := expr.(type) {
	case *ast.SelectorExpr:
		owner, ok := value.X.(*ast.Ident)
		return ok && owner.Name == "http" && value.Sel.Name == "StatusOK"
	case *ast.BasicLit:
		return value.Kind == token.INT && (value.Value == "200" || value.Value == "0")
	}
	return false
}

func statusLabel(expr ast.Expr) string {
	switch value := expr.(type) {
	case *ast.SelectorExpr:
		if owner, ok := value.X.(*ast.Ident); ok {
			return owner.Name + "." + value.Sel.Name
		}
	case *ast.Ident:
		return value.Name
	case *ast.BasicLit:
		return value.Value
	}
	return "a computed expression"
}

func calledName(expr ast.Expr) string {
	switch value := expr.(type) {
	case *ast.Ident:
		return value.Name
	case *ast.SelectorExpr:
		return value.Sel.Name
	}
	return ""
}

func writerAllowed(writer, function string) bool {
	switch writer {
	case "writeJSON":
		return function == "edgeFailure"
	case "writeJSONValue":
		return function == "edgeFailure" || function == "serve" || function == "writeJSON"
	}
	return true
}

func productionGoFiles(t *testing.T, base string) []string {
	t.Helper()
	entries, err := os.ReadDir(base)
	if err != nil {
		t.Fatal(err)
	}
	var names []string
	for _, entry := range entries {
		name := entry.Name()
		if entry.IsDir() || !strings.HasSuffix(name, ".go") || strings.HasSuffix(name, "_test.go") {
			continue
		}
		names = append(names, name)
	}
	return names
}
