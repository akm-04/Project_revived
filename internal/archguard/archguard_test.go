package archguard

import (
	"bufio"
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"io/fs"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
)

const module = "gxb.local/backend/v2/"

// allowedLayerImports is the executable I0 dependency contract. New top-level
// internal layers are denied until deliberately registered here. The matrix is
// intentionally directional: mechanisms live at the edge, orchestration points
// inward, and canonical domains never point back to application/edge layers.
var allowedLayerImports = map[string]map[string]bool{
	"foundation": {
		"foundation": true,
	},
	"content": {
		"content":    true,
		"foundation": true,
	},
	"domain": {
		"domain":     true,
		"foundation": true,
	},
	"protocol": {
		"protocol":   true,
		"foundation": true,
	},
	"projection": {
		"projection": true,
		"domain":     true,
		"foundation": true,
	},
	"application": {
		"application": true,
		"domain":      true,
		"foundation":  true,
	},
	// Adapters are the composition edge. They may depend on any registered
	// inward layer and on sibling adapters. The reverse direction is forbidden.
	"adapters": {
		"adapters":    true,
		"content":     true,
		"application": true,
		"domain":      true,
		"foundation":  true,
		"projection":  true,
		"protocol":    true,
	},
}

func TestImportOwnershipRules(t *testing.T) {
	root := repoRoot(t)
	var errs []string
	err := filepath.WalkDir(filepath.Join(root, "internal"), func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() || !strings.HasSuffix(path, ".go") || strings.HasSuffix(path, "_test.go") {
			return nil
		}
		f, err := parser.ParseFile(token.NewFileSet(), path, nil, parser.ImportsOnly)
		if err != nil {
			return err
		}
		rel, _ := filepath.Rel(root, path)
		owner := ownerGroup(filepath.ToSlash(rel))
		for _, im := range f.Imports {
			imp, _ := strconv.Unquote(im.Path.Value)
			if msg := violation(owner, imp); msg != "" {
				errs = append(errs, fmt.Sprintf("%s: %s", rel, msg))
			}
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	if len(errs) > 0 {
		t.Fatalf("architecture import violations:\n%s", strings.Join(errs, "\n"))
	}
}

func TestLayerMatrixNegativeFixtures(t *testing.T) {
	fixtures := []struct {
		owner string
		imp   string
	}{
		{"domain", module + "internal/application/bootstrap"},
		{"domain", module + "internal/adapters/postgres/i5store"},
		{"protocol", module + "internal/domain/player"},
		{"projection", module + "internal/adapters/stockruntime"},
		{"projection", module + "internal/protocol/wire"},
		{"application", module + "internal/adapters/postgres/i4store"},
		{"foundation", module + "internal/domain/player"},
		{"content", module + "internal/application/i5"},
		{"newlayer", module + "internal/foundation/clock"},
	}
	for _, tc := range fixtures {
		if got := violation(tc.owner, tc.imp); got == "" {
			t.Errorf("expected %s -> %s to be rejected", tc.owner, tc.imp)
		}
	}
}

func TestLayerMatrixPositiveFixtures(t *testing.T) {
	fixtures := []struct {
		owner string
		imp   string
	}{
		{"foundation", module + "internal/foundation/clock"},
		{"content", module + "internal/content/builtin"},
		{"content", module + "internal/foundation/tx"},
		{"domain", module + "internal/foundation/id"},
		{"domain", module + "internal/domain/mail"},
		{"protocol", module + "internal/foundation/operation"},
		{"projection", module + "internal/domain/player"},
		{"application", module + "internal/domain/grant"},
		{"adapters", module + "internal/application/i5"},
		{"adapters", module + "internal/protocol/amf3"},
	}
	for _, tc := range fixtures {
		if got := violation(tc.owner, tc.imp); got != "" {
			t.Errorf("expected %s -> %s to be allowed, got %q", tc.owner, tc.imp, got)
		}
	}
}

func TestNoDirectTableOrRiverBypassMarkers(t *testing.T) {
	root := repoRoot(t)
	var errs []string
	forbidden := []string{"github.com/jackc/pgx", "github.com/riverqueue/river", "database/sql"}
	for _, group := range []string{"domain", "protocol", "projection", "content"} {
		base := filepath.Join(root, "internal", group)
		err := filepath.WalkDir(base, func(path string, d fs.DirEntry, err error) error {
			if err != nil {
				return err
			}
			if d.IsDir() || !strings.HasSuffix(path, ".go") {
				return nil
			}
			f, err := os.Open(path)
			if err != nil {
				return err
			}
			defer f.Close()
			sc := bufio.NewScanner(f)
			line := 0
			for sc.Scan() {
				line++
				txt := sc.Text()
				for _, x := range forbidden {
					if strings.Contains(txt, "\""+x) {
						rel, _ := filepath.Rel(root, path)
						errs = append(errs, fmt.Sprintf("%s:%d imports %s outside adapter", rel, line, x))
					}
				}
			}
			return sc.Err()
		})
		if err != nil {
			t.Fatal(err)
		}
	}
	if len(errs) > 0 {
		t.Fatalf("direct persistence/job bypass:\n%s", strings.Join(errs, "\n"))
	}
}

func violation(owner, imp string) string {
	if !strings.HasPrefix(imp, module+"internal/") {
		return ""
	}
	target := strings.TrimPrefix(imp, module+"internal/")
	targetGroup := strings.SplitN(target, "/", 2)[0]
	allowed, registered := allowedLayerImports[owner]
	if !registered {
		return fmt.Sprintf("unregistered internal source layer %q importing %q", owner, targetGroup)
	}
	if !allowed[targetGroup] {
		return fmt.Sprintf("layer %q may not depend on internal layer %q", owner, targetGroup)
	}
	return ""
}

func ownerGroup(rel string) string {
	p := strings.Split(rel, "/")
	if len(p) >= 3 && p[0] == "internal" {
		return p[1]
	}
	return ""
}

func repoRoot(t *testing.T) string {
	t.Helper()
	d, err := os.Getwd()
	if err != nil {
		t.Fatal(err)
	}
	return filepath.Clean(filepath.Join(d, "../.."))
}

func TestNoExternalNetworkInsideTransactionOrDomain(t *testing.T) {
	root := repoRoot(t)
	for _, base := range []string{filepath.Join(root, "internal", "foundation", "tx"), filepath.Join(root, "internal", "domain"), filepath.Join(root, "internal", "content")} {
		err := filepath.WalkDir(base, func(path string, d fs.DirEntry, err error) error {
			if err != nil {
				return err
			}
			if d.IsDir() || !strings.HasSuffix(path, ".go") {
				return nil
			}
			f, err := parser.ParseFile(token.NewFileSet(), path, nil, parser.ImportsOnly)
			if err != nil {
				return err
			}
			for _, im := range f.Imports {
				imp, _ := strconv.Unquote(im.Path.Value)
				if imp == "net" || strings.HasPrefix(imp, "net/") || strings.Contains(imp, "/internal/adapters/provider") {
					rel, _ := filepath.Rel(root, path)
					t.Errorf("%s imports outbound network/provider package %q inside transaction/domain boundary", rel, imp)
				}
			}
			return nil
		})
		if err != nil {
			t.Fatal(err)
		}
	}
}

func TestPgxAndRiverRemainAdapterOnly(t *testing.T) {
	root := repoRoot(t)
	err := filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			if d.Name() == ".git" {
				return filepath.SkipDir
			}
			return nil
		}
		if !strings.HasSuffix(path, ".go") {
			return nil
		}
		f, err := parser.ParseFile(token.NewFileSet(), path, nil, parser.ImportsOnly)
		if err != nil {
			return err
		}
		rel, _ := filepath.Rel(root, path)
		rel = filepath.ToSlash(rel)
		allowed := strings.HasPrefix(rel, "internal/adapters/postgres/") || strings.HasPrefix(rel, "internal/adapters/river/")
		for _, im := range f.Imports {
			imp, _ := strconv.Unquote(im.Path.Value)
			if strings.HasPrefix(imp, "github.com/jackc/pgx") || strings.HasPrefix(imp, "github.com/riverqueue/river") {
				if !allowed {
					t.Errorf("%s imports mechanism package %q outside adapter", rel, imp)
				}
			}
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
}

func TestDomainCannotReadWallClockDirectly(t *testing.T) {
	root := repoRoot(t)
	err := filepath.WalkDir(filepath.Join(root, "internal", "domain"), func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() || !strings.HasSuffix(path, ".go") {
			return nil
		}
		b, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		if strings.Contains(string(b), "time.Now(") {
			rel, _ := filepath.Rel(root, path)
			t.Errorf("%s calls time.Now directly; use foundation/clock", rel)
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
}

func TestNoGenericAMFRuntimeAuthority(t *testing.T) {
	root := repoRoot(t)
	err := filepath.WalkDir(filepath.Join(root, "internal"), func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() || !strings.HasSuffix(path, ".go") {
			return nil
		}
		f, err := parser.ParseFile(token.NewFileSet(), path, nil, parser.ImportsOnly)
		if err != nil {
			return err
		}
		for _, im := range f.Imports {
			imp, _ := strconv.Unquote(im.Path.Value)
			if imp == "github.com/breign/goAMF3" || strings.HasPrefix(imp, "github.com/breign/goAMF3/") {
				rel, _ := filepath.Rel(root, path)
				t.Errorf("%s imports goAMF3 into runtime authority; it is differential-only", rel)
			}
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
}

func TestI6AGenerationApplicationCannotReadWallClockOrMechanismPackages(t *testing.T) {
	root := repoRoot(t)
	base := filepath.Join(root, "internal", "application", "generation")
	err := filepath.WalkDir(base, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() || !strings.HasSuffix(path, ".go") {
			return nil
		}
		b, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		if strings.Contains(string(b), "time.Now(") {
			rel, _ := filepath.Rel(root, path)
			t.Errorf("%s reads process wall clock inside I6A durable decision layer", rel)
		}
		f, err := parser.ParseFile(token.NewFileSet(), path, nil, parser.ImportsOnly)
		if err != nil {
			return err
		}
		for _, im := range f.Imports {
			imp, _ := strconv.Unquote(im.Path.Value)
			if strings.HasPrefix(imp, "github.com/jackc/pgx") || strings.HasPrefix(imp, "github.com/riverqueue/river") || imp == "database/sql" {
				rel, _ := filepath.Rel(root, path)
				t.Errorf("%s imports mechanism package %q", rel, imp)
			}
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
}

func TestGenerationCoreDefinesNoUniversalPhaseType(t *testing.T) {
	root := repoRoot(t)
	base := filepath.Join(root, "internal", "domain", "generation")
	err := filepath.WalkDir(base, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() || !strings.HasSuffix(path, ".go") || strings.HasSuffix(path, "_test.go") {
			return nil
		}
		f, err := parser.ParseFile(token.NewFileSet(), path, nil, 0)
		if err != nil {
			return err
		}
		for _, decl := range f.Decls {
			gen, ok := decl.(*ast.GenDecl)
			if !ok || gen.Tok != token.TYPE {
				continue
			}
			for _, spec := range gen.Specs {
				ts, ok := spec.(*ast.TypeSpec)
				if ok && strings.Contains(strings.ToLower(ts.Name.Name), "phase") {
					t.Errorf("%s defines universal-looking phase type %q; feature owners must define phases", path, ts.Name.Name)
				}
			}
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
}

func TestObligationQueueExposesOnlyTransactionalInsert(t *testing.T) {
	root := repoRoot(t)
	path := filepath.Join(root, "internal", "foundation", "obligation", "obligation.go")
	f, err := parser.ParseFile(token.NewFileSet(), path, nil, 0)
	if err != nil {
		t.Fatal(err)
	}
	for _, decl := range f.Decls {
		gen, ok := decl.(*ast.GenDecl)
		if !ok || gen.Tok != token.TYPE {
			continue
		}
		for _, spec := range gen.Specs {
			ts, ok := spec.(*ast.TypeSpec)
			if !ok || ts.Name.Name != "Queue" {
				continue
			}
			iface, ok := ts.Type.(*ast.InterfaceType)
			if !ok || len(iface.Methods.List) != 1 || len(iface.Methods.List[0].Names) != 1 || iface.Methods.List[0].Names[0].Name != "InsertTx" {
				t.Fatal("obligation.Queue must expose only same-transaction InsertTx; post-commit fire-and-forget enqueue is not authorized")
			}
			return
		}
	}
	t.Fatal("obligation.Queue interface not found")
}
