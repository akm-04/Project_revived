package archguard

import (
	"go/parser"
	"go/token"
	"io/fs"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
)

// S1 item 5: the login and session edge stays independent of the OTA owner, so
// an OTA file fault can never reach the path that serves a login.
var otaIsolatedPackages = []string{
	"internal/adapters/sdkapi",
	"internal/adapters/postgres/identitystore",
	"internal/application/bootstrap",
	"internal/application/identitylifecycle",
	"internal/application/realtimeauth",
}

var otaForbiddenImports = []string{
	module + "internal/application/otarelease",
	module + "internal/adapters/postgres/otastore",
	module + "internal/application/otabuild",
}

func TestLoginAndSessionNeverImportOTA(t *testing.T) {
	root := repoRoot(t)
	var violations []string
	for _, relative := range otaIsolatedPackages {
		base := filepath.Join(root, relative)
		err := filepath.WalkDir(base, func(path string, d fs.DirEntry, err error) error {
			if err != nil {
				return err
			}
			if d.IsDir() || !strings.HasSuffix(path, ".go") || strings.HasSuffix(path, "_test.go") {
				return nil
			}
			file, err := parser.ParseFile(token.NewFileSet(), path, nil, parser.ImportsOnly)
			if err != nil {
				return err
			}
			for _, imported := range file.Imports {
				name, _ := strconv.Unquote(imported.Path.Value)
				if otaImportViolation(name) != "" {
					rel, _ := filepath.Rel(root, path)
					violations = append(violations, rel+" imports "+name)
				}
			}
			return nil
		})
		if err != nil {
			t.Fatal(err)
		}
	}
	if len(violations) > 0 {
		t.Fatalf("login/session packages import the OTA owner:\n%s", strings.Join(violations, "\n"))
	}
}

func TestOTAFaultGuardNegativeFixture(t *testing.T) {
	for _, forbidden := range []string{
		module + "internal/application/otarelease",
		module + "internal/adapters/postgres/otastore",
		module + "internal/application/otabuild",
		module + "internal/adapters/postgres/otastore/sub",
	} {
		if otaImportViolation(forbidden) == "" {
			t.Errorf("an import of %q was not rejected", forbidden)
		}
	}
	for _, allowed := range []string{
		module + "internal/domain/otarelease",
		module + "internal/application/identitylifecycle",
	} {
		if got := otaImportViolation(allowed); got != "" {
			t.Errorf("an allowed import %q was rejected: %s", allowed, got)
		}
	}
}

func otaImportViolation(imported string) string {
	for _, prefix := range otaForbiddenImports {
		if imported == prefix || strings.HasPrefix(imported, prefix+"/") {
			return imported
		}
	}
	return ""
}
