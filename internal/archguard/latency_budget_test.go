package archguard

import (
	"encoding/json"
	"go/ast"
	"go/parser"
	"go/token"
	"io/fs"
	"maps"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"testing"
)

// GATE_LATENCY_SECTION_V1 section 2: a wall-clock budget is asserted only through internal/testsupport/latency.
// The detector follows a measured duration (time.Since, Sub, Elapsed, their Seconds/Milliseconds, append, arithmetic and
// same-call propagation) into an ordering comparison that guards a failing call.

var latencyAllowlist = filepath.Join("internal", "archguard", "latency_budget_allowlist.json")

type latencyAllowRow struct {
	File   string `json:"file"`
	Line   int    `json:"line"`
	Reason string `json:"reason"`
}

func TestLatencyBudgetsUseTheHelper(t *testing.T) {
	root := repoRoot(t)
	allowlist := readLatencyAllowlist(t, filepath.Join(root, latencyAllowlist))
	seen := map[string]bool{}
	var violations []string
	err := filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if outsideProduct(root, path, d) || d.IsDir() || !strings.HasSuffix(path, "_test.go") {
			return nil
		}
		relative, _ := filepath.Rel(root, path)
		relative = filepath.ToSlash(relative)
		lines, parseErr := latencyViolationLines(path)
		if parseErr != nil {
			return parseErr
		}
		for _, line := range lines {
			key := relative + ":" + itoa(line)
			seen[key] = true
			if reason, allowed := allowlist[key]; allowed {
				if reason == "" {
					violations = append(violations, key+": allowlist row has no reason")
				}
				continue
			}
			violations = append(violations, key+": measured duration compared to a budget outside internal/testsupport/latency")
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	for key := range allowlist {
		if !seen[key] {
			violations = append(violations, key+": stale allowlist row")
		}
	}
	if len(violations) > 0 {
		sort.Strings(violations)
		t.Fatalf("latency budget violations:\n%s", strings.Join(violations, "\n"))
	}
}

func readLatencyAllowlist(t *testing.T, path string) map[string]string {
	t.Helper()
	allowlist := map[string]string{}
	raw, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return allowlist
		}
		t.Fatal(err)
	}
	var rows []latencyAllowRow
	if err := json.Unmarshal(raw, &rows); err != nil {
		t.Fatalf("%s: %v", path, err)
	}
	for _, row := range rows {
		if row.File == "" || row.Line < 1 {
			t.Fatalf("%s: a row needs file and line: %+v", path, row)
		}
		allowlist[row.File+":"+itoa(row.Line)] = row.Reason
	}
	return allowlist
}

func itoa(value int) string {
	const digits = "0123456789"
	if value == 0 {
		return "0"
	}
	var out []byte
	for value > 0 {
		out = append([]byte{digits[value%10]}, out...)
		value /= 10
	}
	return string(out)
}

func latencyViolationLines(path string) ([]int, error) {
	fset := token.NewFileSet()
	file, err := parser.ParseFile(fset, path, nil, 0)
	if err != nil {
		return nil, err
	}
	var lines []int
	for _, declaration := range file.Decls {
		function, ok := declaration.(*ast.FuncDecl)
		if !ok || function.Body == nil {
			continue
		}
		lines = append(lines, inspectLatencyBlock(fset, function.Body, map[string]bool{})...)
	}
	return lines, nil
}

func inspectLatencyBlock(fset *token.FileSet, block *ast.BlockStmt, tainted map[string]bool) []int {
	var found []int
	for _, statement := range block.List {
		switch current := statement.(type) {
		case *ast.AssignStmt:
			for index, left := range current.Lhs {
				name, ok := left.(*ast.Ident)
				if !ok {
					continue
				}
				var value ast.Expr
				if len(current.Rhs) == len(current.Lhs) {
					value = current.Rhs[index]
				} else if len(current.Rhs) == 1 {
					value = current.Rhs[0]
				}
				tainted[name.Name] = latencyDerived(value, tainted)
			}
			for _, right := range current.Rhs {
				found = append(found, inspectLatencyExpression(fset, right, tainted)...)
			}
		case *ast.DeclStmt:
			declaration, ok := current.Decl.(*ast.GenDecl)
			if !ok {
				continue
			}
			for _, spec := range declaration.Specs {
				value, ok := spec.(*ast.ValueSpec)
				if !ok {
					continue
				}
				for index, name := range value.Names {
					var expression ast.Expr
					if len(value.Values) == len(value.Names) {
						expression = value.Values[index]
					} else if len(value.Values) == 1 {
						expression = value.Values[0]
					}
					tainted[name.Name] = latencyDerived(expression, tainted) || durationSlice(value.Type)
				}
			}
		case *ast.IfStmt:
			if current.Init != nil {
				assignments, ok := current.Init.(*ast.AssignStmt)
				if ok {
					for index, left := range assignments.Lhs {
						name, ok := left.(*ast.Ident)
						if !ok || index >= len(assignments.Rhs) {
							continue
						}
						tainted[name.Name] = latencyDerived(assignments.Rhs[index], tainted)
					}
				}
			}
			found = append(found, latencyConditionViolation(fset, current.Cond, current.Body, tainted)...)
			found = append(found, inspectLatencyBlock(fset, current.Body, tainted)...)
			if current.Else != nil {
				found = append(found, inspectLatencyStatement(fset, current.Else, tainted)...)
			}
		case *ast.ForStmt:
			found = append(found, latencyConditionViolation(fset, current.Cond, current.Body, tainted)...)
			found = append(found, inspectLatencyBlock(fset, current.Body, tainted)...)
		case *ast.RangeStmt:
			found = append(found, inspectLatencyBlock(fset, current.Body, tainted)...)
		case *ast.SwitchStmt:
			found = append(found, inspectLatencyBlock(fset, current.Body, tainted)...)
		case *ast.TypeSwitchStmt:
			found = append(found, inspectLatencyBlock(fset, current.Body, tainted)...)
		case *ast.SelectStmt:
			found = append(found, inspectLatencyBlock(fset, current.Body, tainted)...)
		case *ast.BlockStmt:
			found = append(found, inspectLatencyBlock(fset, current, tainted)...)
		case *ast.ExprStmt:
			found = append(found, inspectLatencyExpression(fset, current.X, tainted)...)
		case *ast.ReturnStmt:
			for _, result := range current.Results {
				found = append(found, inspectLatencyExpression(fset, result, tainted)...)
			}
		}
	}
	return found
}

func inspectLatencyStatement(fset *token.FileSet, statement ast.Stmt, tainted map[string]bool) []int {
	switch current := statement.(type) {
	case *ast.BlockStmt:
		return inspectLatencyBlock(fset, current, tainted)
	case *ast.IfStmt:
		return inspectLatencyBlock(fset, &ast.BlockStmt{List: []ast.Stmt{current}}, tainted)
	}
	return nil
}

func latencyConditionViolation(fset *token.FileSet, condition ast.Expr, body *ast.BlockStmt, tainted map[string]bool) []int {
	if condition == nil || !failsTheTest(body) {
		return nil
	}
	var found []int
	ast.Inspect(condition, func(node ast.Node) bool {
		comparison, ok := node.(*ast.BinaryExpr)
		if !ok || !isOrdering(comparison.Op) {
			return true
		}
		if latencyDerived(comparison.X, tainted) || latencyDerived(comparison.Y, tainted) {
			found = append(found, fset.Position(comparison.OpPos).Line)
		}
		return true
	})
	return found
}

func inspectLatencyExpression(fset *token.FileSet, expression ast.Expr, tainted map[string]bool) []int {
	if expression == nil {
		return nil
	}
	var found []int
	if literal, ok := expression.(*ast.FuncLit); ok && literal.Body != nil {
		inner := map[string]bool{}
		maps.Copy(inner, tainted)
		found = append(found, inspectLatencyBlock(fset, literal.Body, inner)...)
	}
	return found
}

func latencyDerived(expression ast.Expr, tainted map[string]bool) bool {
	switch current := expression.(type) {
	case nil:
		return false
	case *ast.Ident:
		return tainted[current.Name]
	case *ast.ParenExpr:
		return latencyDerived(current.X, tainted)
	case *ast.StarExpr:
		return latencyDerived(current.X, tainted)
	case *ast.IndexExpr:
		return latencyDerived(current.X, tainted) || latencyDerived(current.Index, tainted)
	case *ast.SliceExpr:
		return latencyDerived(current.X, tainted)
	case *ast.CompositeLit:
		if durationSlice(current.Type) {
			return true
		}
		for _, element := range current.Elts {
			if latencyDerived(element, tainted) {
				return true
			}
		}
		return false
	case *ast.BinaryExpr:
		return latencyDerived(current.X, tainted) || latencyDerived(current.Y, tainted)
	case *ast.CallExpr:
		if selector, ok := current.Fun.(*ast.SelectorExpr); ok {
			switch selector.Sel.Name {
			case "Since", "Elapsed", "Sub", "Seconds", "Milliseconds":
				return true
			}
			if owner, ok := selector.X.(*ast.Ident); ok && owner.Name == "time" && selector.Sel.Name == "Duration" {
				return true
			}
		}
		if identifier, ok := current.Fun.(*ast.Ident); ok && identifier.Name == "append" && len(current.Args) == 2 {
			return latencyDerived(current.Args[1], tainted)
		}
		for _, argument := range current.Args {
			if latencyDerived(argument, tainted) {
				return true
			}
		}
	}
	return false
}

func durationSlice(expression ast.Expr) bool {
	array, ok := expression.(*ast.ArrayType)
	if !ok {
		return false
	}
	element, ok := array.Elt.(*ast.SelectorExpr)
	if !ok {
		return false
	}
	owner, ok := element.X.(*ast.Ident)
	return ok && owner.Name == "time" && element.Sel.Name == "Duration"
}

func isOrdering(operator token.Token) bool {
	return operator == token.LSS || operator == token.LEQ || operator == token.GTR || operator == token.GEQ
}

func failsTheTest(body *ast.BlockStmt) bool {
	failed := false
	ast.Inspect(body, func(node ast.Node) bool {
		if failed {
			return false
		}
		call, ok := node.(*ast.CallExpr)
		if !ok {
			return true
		}
		switch function := call.Fun.(type) {
		case *ast.SelectorExpr:
			switch function.Sel.Name {
			case "Fatal", "Fatalf", "Error", "Errorf":
				failed = true
			}
		case *ast.Ident:
			if function.Name == "panic" {
				failed = true
			}
		}
		return !failed
	})
	return failed
}

func TestLatencyDetectorCatchesEveryShape(t *testing.T) {
	shapes := map[string]string{
		"time.Since": `package planted
import ("testing"; "time")
func TestPlanted(t *testing.T) {
	started := time.Now()
	if elapsed := time.Since(started); elapsed > 2*time.Second {
		t.Fatalf("slow %v", elapsed)
	}
}`,
		"Sub": `package planted
import ("testing"; "time")
func TestPlanted(t *testing.T) {
	at := time.Now()
	var now time.Time
	if now.Sub(at) > time.Second {
		t.Fatal("db clock drift")
	}
}`,
		"p95 over samples": `package planted
import ("testing"; "time")
func TestPlanted(t *testing.T) {
	samples := []time.Duration{}
	p95 := percentile95(samples)
	if p95 > 6500*time.Millisecond {
		t.Fatalf("p95 %v", p95)
	}
}`,
		"best of N": `package planted
import ("testing"; "time")
func TestPlanted(t *testing.T) {
	best := time.Duration(0)
	elapsed := time.Since(time.Now())
	if best == 0 || elapsed < best {
		best = elapsed
	}
	if best > time.Second {
		t.Fatalf("best %v", best)
	}
}`,
		"throughput": `package planted
import ("testing"; "time")
func TestPlanted(t *testing.T) {
	started := time.Now()
	deleted := 50000
	elapsed := time.Since(started)
	seconds := elapsed.Seconds()
	rate := float64(deleted) / seconds
	if rate < 400 {
		t.Fatalf("rate %.0f", rate)
	}
}`,
		"Elapsed": `package planted
import ("testing"; "time")
func TestPlanted(t *testing.T) {
	var b testing.B
	if b.Elapsed() > time.Second {
		t.Fatal("too slow")
	}
}`,
	}
	for name, source := range shapes {
		path := filepath.Join(t.TempDir(), "planted_test.go")
		if err := os.WriteFile(path, []byte(source), 0o600); err != nil {
			t.Fatal(err)
		}
		lines, err := latencyViolationLines(path)
		if err != nil {
			t.Fatalf("%s: %v", name, err)
		}
		if len(lines) == 0 {
			t.Errorf("%s: detector missed the planted shape", name)
		}
	}
	allowed := `package planted
import ("testing"; "time"; "gxb.local/backend/v2/internal/testsupport/latency")
func TestPlanted(t *testing.T) {
	if !latency.Within(t, latency.Incidental, time.Since(time.Now()), time.Second) {
		t.Fatal("outside the helper")
	}
}`
	path := filepath.Join(t.TempDir(), "allowed_test.go")
	if err := os.WriteFile(path, []byte(allowed), 0o600); err != nil {
		t.Fatal(err)
	}
	lines, err := latencyViolationLines(path)
	if err != nil {
		t.Fatal(err)
	}
	if len(lines) != 0 {
		t.Fatalf("a helper call must be the allowed form, got %v", lines)
	}
}
