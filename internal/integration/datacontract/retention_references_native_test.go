//go:build postgres

package datacontract_test

import (
	"os"
	"os/exec"
	"path/filepath"
	"testing"
)

func TestRetentionReferencesMatchCatalog(t *testing.T) {
	dsn := os.Getenv("GXB_R8_RETENTION_DSN")
	if dsn == "" {
		t.Fatal("required GXB_R8_RETENTION_DSN for a migrated test database is missing")
	}
	root := repositoryRoot(t)
	command := exec.Command("python3", filepath.Join(root, "tools", "retention_references.py"), "--check", "--database", dsn)
	command.Dir = root
	output, err := command.CombinedOutput()
	if err != nil {
		t.Fatalf("retention references check failed: %v\n%s", err, output)
	}
	t.Logf("retention reference lists match the catalog")
}
