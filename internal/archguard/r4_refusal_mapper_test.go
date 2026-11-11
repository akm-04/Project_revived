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

// r4RefusalMapperRatchet names the dispatchers that still build refusal
// replies outside the shared stockruntime mapper. It may only shrink: delete
// an entry when its dispatcher migrates (R4 parts 2 and 3 empty it).
var r4RefusalMapperRatchet = map[string]bool{
	"achievement_dispatcher.go":    true,
	"activity_dispatcher.go":       true,
	"arena_dispatcher.go":          true,
	"conquer_dispatcher.go":        true,
	"dodgeball_dispatcher.go":      true,
	"dorm_dispatcher.go":           true,
	"eventcentre_dispatcher.go":    true,
	"godstrial_dispatcher.go":      true,
	"guild_campaign_dispatcher.go": true,
	"guild_dispatcher.go":          true,
	"guild_rental_dispatcher.go":   true,
	"guild_tea_dispatcher.go":      true,
	"i5_dispatcher.go":             true,
	"league_dispatcher.go":         true,
	"library_dispatcher.go":        true,
	"library_forum_dispatcher.go":  true,
	"memoir_dispatcher.go":         true,
	"oneonone_dispatcher.go":       true,
	"pet_dispatcher.go":            true,
	"petcampaign_dispatcher.go":    true,
	"practice_auto_dispatcher.go":  true,
	"practice_dispatcher.go":       true,
	"publication_dispatcher.go":    true,
	"saved_preset_dispatcher.go":   true,
	"social_dispatcher.go":         true,
	"topfloor_dispatcher.go":       true,
}

var r4MigratedDispatchers = []string{
	"book_dispatcher.go",
	"hero_dispatcher.go",
	"inactive_dispatcher.go",
}

func TestR4RefusalRepliesGoThroughTheMapper(t *testing.T) {
	root := repoRoot(t)
	base := filepath.Join(root, "internal", "adapters", "stockruntime")
	entries, err := os.ReadDir(base)
	if err != nil {
		t.Fatal(err)
	}
	offenders := map[string]bool{}
	stale := map[string]bool{}
	for _, entry := range entries {
		name := entry.Name()
		if entry.IsDir() || !strings.HasSuffix(name, "_dispatcher.go") || strings.HasSuffix(name, "_test.go") {
			continue
		}
		path := filepath.Join(base, name)
		if fileBuildsRefusalOutsideMapper(t, path) {
			if !r4RefusalMapperRatchet[name] {
				offenders[name] = true
			}
			continue
		}
		if r4RefusalMapperRatchet[name] {
			stale[name] = true
		}
	}
	for name := range offenders {
		t.Errorf("%s builds a 400/409 refusal (or a coded 503) outside the stockruntime mapper; migrate it in parts 2-3 or add it to the ratchet", name)
	}
	for name := range stale {
		t.Errorf("%s no longer builds a refusal outside the mapper; remove it from the ratchet", name)
	}
	for _, name := range r4MigratedDispatchers {
		if r4RefusalMapperRatchet[name] {
			t.Errorf("%s is migrated and must not be on the refusal-mapper ratchet", name)
		}
	}
	for name := range r4RefusalMapperRatchet {
		if _, err := os.Stat(filepath.Join(base, name)); err != nil {
			t.Errorf("ratchet entry %s no longer exists; the ratchet may only shrink to real files", name)
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
