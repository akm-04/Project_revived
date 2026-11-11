package archguard

import (
	"go/ast"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
)

func TestR4RefusalRepliesGoThroughTheMapper(t *testing.T) {
	root := repoRoot(t)
	base := filepath.Join(root, "internal", "adapters", "stockruntime")
	entries, err := os.ReadDir(base)
	if err != nil {
		t.Fatal(err)
	}
	for _, entry := range entries {
		name := entry.Name()
		if entry.IsDir() || !strings.HasSuffix(name, "_dispatcher.go") || strings.HasSuffix(name, "_test.go") {
			continue
		}
		if fileBuildsRefusalOutsideMapper(t, filepath.Join(base, name)) {
			t.Errorf("%s builds a 400/409 refusal (or a coded 503) outside the stockruntime mapper; route it through failureReply", name)
		}
	}
}

func fileBuildsRefusalOutsideMapper(t *testing.T, path string) bool {
	t.Helper()
	file, err := parser.ParseFile(token.NewFileSet(), path, nil, 0)
	if err != nil {
		t.Fatalf("parse %s: %v", path, err)
	}
	found := false
	ast.Inspect(file, func(node ast.Node) bool {
		literal, ok := node.(*ast.CompositeLit)
		if !ok || !isResponseType(literal.Type) {
			return true
		}
		if responseIsRefusal(literal) {
			found = true
		}
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

func responseIsRefusal(literal *ast.CompositeLit) bool {
	var status ast.Expr
	for _, element := range literal.Elts {
		pair, ok := element.(*ast.KeyValueExpr)
		if !ok {
			continue
		}
		key, ok := pair.Key.(*ast.Ident)
		if ok && key.Name == "HTTPStatus" {
			status = pair.Value
		}
	}
	statusKind := responseStatusKind(status)
	if statusKind == "bad_request" || statusKind == "conflict" {
		return true
	}
	if statusKind == "service_unavailable" {
		return responseBodyHasErrorCode(literal)
	}
	if statusKind == "unknown" {
		return responseBodyHasRefusalField(literal)
	}
	return false
}

func responseStatusKind(expr ast.Expr) string {
	selector, ok := expr.(*ast.SelectorExpr)
	if !ok {
		if expr == nil {
			return ""
		}
		return "unknown"
	}
	owner, ok := selector.X.(*ast.Ident)
	if !ok || owner.Name != "http" {
		return "unknown"
	}
	switch selector.Sel.Name {
	case "StatusBadRequest":
		return "bad_request"
	case "StatusConflict":
		return "conflict"
	case "StatusServiceUnavailable":
		return "service_unavailable"
	case "StatusOK":
		return "ok"
	}
	return "other"
}

func responseBodyHasErrorCode(literal *ast.CompositeLit) bool {
	return responseBodyHasField(literal, "error_code")
}

func responseBodyHasRefusalField(literal *ast.CompositeLit) bool {
	return responseBodyHasField(literal, "error_code") || responseBodyHasField(literal, "error")
}

func responseBodyHasField(literal *ast.CompositeLit, wanted string) bool {
	for _, element := range literal.Elts {
		pair, ok := element.(*ast.KeyValueExpr)
		if !ok {
			continue
		}
		key, ok := pair.Key.(*ast.Ident)
		if !ok || key.Name != "Body" {
			continue
		}
		body, ok := pair.Value.(*ast.CompositeLit)
		if !ok {
			return false
		}
		for _, entry := range body.Elts {
			bodyPair, ok := entry.(*ast.KeyValueExpr)
			if !ok {
				continue
			}
			name, err := strconv.Unquote(strings.TrimSpace(expressionText(bodyPair.Key)))
			if err == nil && name == wanted {
				return true
			}
		}
	}
	return false
}

func expressionText(expr ast.Expr) string {
	if literal, ok := expr.(*ast.BasicLit); ok {
		return literal.Value
	}
	return ""
}
