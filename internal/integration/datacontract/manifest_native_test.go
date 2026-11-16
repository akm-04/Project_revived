//go:build postgres

package datacontract_test

import (
	"os"
	"os/exec"
	"path/filepath"
	"testing"
)

func repositoryRoot(t *testing.T) string {
	t.Helper()
	directory, err := os.Getwd()
	if err != nil {
		t.Fatal(err)
	}
	for {
		if _, err := os.Stat(filepath.Join(directory, "tools", "player_data_manifest.py")); err == nil {
			return directory
		}
		parent := filepath.Dir(directory)
		if parent == directory {
			t.Fatal("backend root with tools/player_data_manifest.py not found")
		}
		directory = parent
	}
}

func TestPlayerDataManifestMatchesCatalog(t *testing.T) {
	dsn := os.Getenv("GXB_R8_MANIFEST_DSN")
	if dsn == "" {
		t.Fatal("required GXB_R8_MANIFEST_DSN for a migrated test database is missing")
	}
	root := repositoryRoot(t)
	command := exec.Command("python3", filepath.Join(root, "tools", "player_data_manifest.py"), "--check", "--database", dsn)
	command.Dir = root
	output, err := command.CombinedOutput()
	if err != nil {
		t.Fatalf("player data manifest check failed: %v\n%s", err, output)
	}
	t.Logf("player data manifest matches the catalog")
}
