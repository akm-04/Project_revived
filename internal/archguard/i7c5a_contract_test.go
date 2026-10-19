package archguard

import (
	"go/parser"
	"go/token"
	"io/fs"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"testing"
)

func importsOf(t *testing.T, dir string) map[string][]string {
	t.Helper()
	out := map[string][]string{}
	entries, err := os.ReadDir(dir)
	if err != nil {
		t.Fatal(err)
	}
	for _, e := range entries {
		if e.IsDir() || !strings.HasSuffix(e.Name(), ".go") || strings.HasSuffix(e.Name(), "_test.go") {
			continue
		}
		f, err := parser.ParseFile(token.NewFileSet(), filepath.Join(dir, e.Name()), nil, parser.ImportsOnly)
		if err != nil {
			t.Fatal(err)
		}
		for _, im := range f.Imports {
			path, _ := strconv.Unquote(im.Path.Value)
			out[path] = append(out[path], e.Name())
		}
	}
	return out
}

// C5A rule: the resolver sees only the snapshot and the embedded corpus — no
// database, network, subprocess, filesystem, clock or owner ports.
func TestI7C5AResolverIsolationImports(t *testing.T) {
	root := repoRoot(t)
	banned := func(path string) bool {
		for _, prefix := range []string{"os/exec", "net", "database/", "github.com/jackc/", "github.com/riverqueue/", module + "internal/adapters/postgres", module + "internal/application", module + "internal/adapters/provider"} {
			if path == prefix || strings.HasPrefix(path, prefix+"/") || (strings.HasSuffix(prefix, "/") && strings.HasPrefix(path, prefix)) {
				return true
			}
		}
		return false
	}
	for dir, extra := range map[string][]string{
		"internal/adapters/combatresolver": {"os", "syscall", "time", "path/filepath", "io/fs"},
		"internal/content/combatcorpus":    {"os", "syscall", "time", "path/filepath"},
		"cmd/gxb-combat-worker":            {"time", "path/filepath"},
	} {
		for path, files := range importsOf(t, filepath.Join(root, dir)) {
			denied := banned(path)
			for _, x := range extra {
				denied = denied || path == x
			}
			if denied {
				t.Errorf("%s imports %q (%v)", dir, path, files)
			}
		}
	}
	src, err := os.ReadFile(filepath.Join(root, "internal/adapters/combatresolver/resolver.go"))
	if err != nil {
		t.Fatal(err)
	}
	for _, lib := range []string{"OpenIo", "OpenOs", "OpenDebug", "OpenChannel"} {
		if strings.Contains(string(src), "lua."+lib) {
			t.Errorf("resolver opens Lua library %s", lib)
		}
	}
}

func TestI7C5ALuaVMConfinedToResolver(t *testing.T) {
	root := repoRoot(t)
	err := filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil || d.IsDir() || !strings.HasSuffix(path, ".go") {
			if d != nil && d.IsDir() && d.Name() == ".git" {
				return filepath.SkipDir
			}
			return err
		}
		rel, _ := filepath.Rel(root, path)
		f, err := parser.ParseFile(token.NewFileSet(), path, nil, parser.ImportsOnly)
		if err != nil {
			return err
		}
		for _, im := range f.Imports {
			p, _ := strconv.Unquote(im.Path.Value)
			if strings.HasPrefix(p, "github.com/yuin/gopher-lua") && !strings.HasPrefix(filepath.ToSlash(rel), "internal/adapters/combatresolver/") {
				t.Errorf("%s imports the Lua VM outside the isolated resolver", rel)
			}
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
}

// Combat attempt rank 609 sits after mode roots 601..608 and before I5 610+.
func TestI7C5ACombatLockRankUnique(t *testing.T) {
	root := repoRoot(t)
	rank := regexp.MustCompile(`(?m)^\s*(\w*LockRank\w*)\s*(?:uint16)?\s*=\s*(\d+)\b`)
	owners := []string{}
	err := filepath.WalkDir(filepath.Join(root, "internal"), func(path string, d fs.DirEntry, err error) error {
		if err != nil || d.IsDir() || !strings.HasSuffix(path, ".go") || strings.HasSuffix(path, "_test.go") {
			return err
		}
		b, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		for _, m := range rank.FindAllStringSubmatch(string(b), -1) {
			if m[2] == "609" {
				rel, _ := filepath.Rel(root, path)
				owners = append(owners, filepath.ToSlash(rel)+":"+m[1])
			}
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	if len(owners) != 1 || owners[0] != "internal/domain/combat/snapshot.go:AttemptLockRank" {
		t.Fatalf("lock rank 609 owners: %v", owners)
	}
}
