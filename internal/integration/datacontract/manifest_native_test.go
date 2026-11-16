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
	runPythonCheck(t, "player_data_manifest.py", "player data manifest")
}

func TestPlayerRestorePlanMatchesCatalog(t *testing.T) {
	runPythonCheck(t, "player_restore_plan.py", "player restore plan")
}

func runPythonCheck(t *testing.T, tool, label string) {
	t.Helper()
	dsn := os.Getenv("GXB_R8_MANIFEST_DSN")
	if dsn == "" {
		t.Fatal("required GXB_R8_MANIFEST_DSN for a migrated test database is missing")
	}
	root := repositoryRoot(t)
	command := exec.Command("python3", filepath.Join(root, "tools", tool), "--check", "--database", dsn)
	command.Dir = root
	output, err := command.CombinedOutput()
	if err != nil {
		t.Fatalf("%s check failed: %v\n%s", label, err, output)
	}
	t.Logf("%s matches the catalog", label)
}
