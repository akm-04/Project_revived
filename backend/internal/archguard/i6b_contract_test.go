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

func TestI6BActivityDirectoryStaysReadOnlyAndOwnerNeutral(t *testing.T) {
	root := repoRoot(t)
	base := filepath.Join(root, "internal", "application", "activitydirectory")
	forbidden := []string{
		module + "internal/domain/economy", module + "internal/domain/grant", module + "internal/foundation/tx",
		module + "internal/adapters", "github.com/riverqueue/river", "github.com/jackc/pgx", "database/sql",
	}
	err := filepath.WalkDir(base, func(path string, d os.DirEntry, err error) error {
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
			for _, x := range forbidden {
				if imp == x || strings.HasPrefix(imp, x+"/") {
					t.Errorf("%s imports forbidden I6B owner/mechanism %s", path, imp)
				}
			}
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
}

func TestI6BActivityDirectoryAddsNoWallClockOrUniversalPhase(t *testing.T) {
	root := repoRoot(t)
	for _, rel := range []string{"internal/application/activitydirectory", "internal/domain/activity"} {
		err := filepath.WalkDir(filepath.Join(root, rel), func(path string, d os.DirEntry, err error) error {
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
			s := string(b)
			for _, bad := range []string{"time.Now(", "type Phase ", "all_server", "05:00", "UTC+8"} {
				if strings.Contains(s, bad) {
					t.Errorf("%s contains forbidden universal Activity policy marker %q", path, bad)
				}
			}
			return nil
		})
		if err != nil {
			t.Fatal(err)
		}
	}
}

func TestI6BProductionRoutesOnlyReadDirectoryMIDs(t *testing.T) {
	root := repoRoot(t)
	b, err := os.ReadFile(filepath.Join(root, "cmd", "gxb-api", "main_postgres.go"))
	if err != nil {
		t.Fatal(err)
	}
	s := string(b)
	if !strings.Contains(s, "[]uint16{229, 234}") {
		t.Fatal("I6B MID229/MID234 composition missing")
	}
	if strings.Contains(s, "mustRegister(231") || strings.Contains(s, "[]uint16{229, 231") || strings.Contains(s, "[]uint16{231,") {
		t.Fatal("MID231 must remain unregistered in I6B")
	}
}

func TestI6BAddsNoActivityOwnedMigration(t *testing.T) {
	root := repoRoot(t)
	entries, err := os.ReadDir(filepath.Join(root, "migrations"))
	if err != nil {
		t.Fatal(err)
	}
	for _, e := range entries {
		name := e.Name()
		if strings.Contains(strings.ToLower(name), "activity") {
			t.Fatalf("I6B unexpectedly owns migration %s", name)
		}
		if strings.HasPrefix(name, "00012") && name != "00012_i6c_guild_core.sql" {
			t.Fatalf("unexpected migration 00012 owner %s", name)
		}
	}
}

func TestI6BNoTimeNowASTBackstop(t *testing.T) {
	root := repoRoot(t)
	base := filepath.Join(root, "internal", "application", "activitydirectory")
	err := filepath.WalkDir(base, func(path string, d os.DirEntry, err error) error {
		if err != nil || d.IsDir() || !strings.HasSuffix(path, ".go") {
			return err
		}
		f, e := parser.ParseFile(token.NewFileSet(), path, nil, 0)
		if e != nil {
			return e
		}
		ast.Inspect(f, func(n ast.Node) bool {
			call, ok := n.(*ast.CallExpr)
			if !ok {
				return true
			}
			sel, ok := call.Fun.(*ast.SelectorExpr)
			if !ok || sel.Sel.Name != "Now" {
				return true
			}
			if id, ok := sel.X.(*ast.Ident); ok && id.Name == "time" {
				t.Errorf("%s calls time.Now", path)
			}
			return true
		})
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
}
