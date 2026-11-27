package operatoragent

import (
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

type runningBackend struct{}

func (runningBackend) Start(bool, string) error { return nil }
func (runningBackend) Stop() error              { return nil }
func (runningBackend) Status() BackendStatus    { return BackendStatus{Running: true} }

func pathsRoot(t *testing.T) string {
	t.Helper()
	return writeAgentConfig(t, `{"listen":"127.0.0.1:8090","backend":{"binary":"","operator_addr":"127.0.0.1:8091"}}`)
}

func TestValidateStoredDirectoryRefusesEveryNonFolderShape(t *testing.T) {
	directory := t.TempDir()
	if err := ValidateStoredDirectory("client_tree", directory); err != nil {
		t.Fatalf("a real folder was refused: %v", err)
	}
	file := filepath.Join(directory, "file")
	if err := os.WriteFile(file, []byte("x"), 0o600); err != nil {
		t.Fatal(err)
	}
	link := filepath.Join(directory, "link")
	if err := os.Symlink(directory, link); err != nil {
		t.Fatal(err)
	}
	interior := filepath.Join(directory, "sub")
	if err := os.MkdirAll(interior, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(file, filepath.Join(interior, "inner")); err != nil {
		t.Fatal(err)
	}

	cases := map[string]string{
		"empty":          "",
		"relative":       "client/ota",
		"file":           file,
		"symlink root":   link,
		"interior link":  interior,
		"windows drive":  `C:\Games\gxb`,
		"windows unc":    `\\server\share\gxb`,
		"windows volume": `C:relative`,
	}
	for name, path := range cases {
		if err := ValidateStoredDirectory("client_tree", path); err == nil {
			t.Fatalf("%s: %q was accepted", name, path)
		}
	}
}

func TestPathsSetSavesAtomicallyAndKeepsTheOldValueOnRefusal(t *testing.T) {
	root := pathsRoot(t)
	clientTree := filepath.Join(t.TempDir(), "client")
	if err := os.MkdirAll(filepath.Join(clientTree, "src"), 0o755); err != nil {
		t.Fatal(err)
	}
	catalogue := t.TempDir()
	service := PathsService{Root: root}

	reply, err := service.Set(PathsChange{Key: "client_tree", Path: clientTree})
	if err != nil {
		t.Fatalf("client_tree: %v", err)
	}
	if reply.RestartRequired {
		t.Fatal("the client tree is read at each build and needs no restart")
	}
	if _, err := service.Set(PathsChange{Key: "stock_catalog", Path: catalogue}); err != nil {
		t.Fatalf("stock_catalog: %v", err)
	}
	config, err := ReadConfig(root)
	if err != nil {
		t.Fatal(err)
	}
	if config.ClientTree != clientTree || config.StockCatalog != catalogue {
		t.Fatalf("saved paths = %q %q", config.ClientTree, config.StockCatalog)
	}

	cases := []PathsChange{
		{Key: "client_tree", Path: "relative/client"},
		{Key: "stock_source", Path: filepath.Join(t.TempDir(), "missing")},
		{Key: "no_such_key", Path: catalogue},
	}
	for _, change := range cases {
		var refusal *Refusal
		if _, err := service.Set(change); !errors.As(err, &refusal) || refusal.Code != CodeSettingsInvalid {
			t.Fatalf("%s: want AGENT_SETTINGS_INVALID, got %v", change.Key, err)
		}
	}
	unchanged, err := ReadConfig(root)
	if err != nil {
		t.Fatal(err)
	}
	if unchanged.ClientTree != clientTree || unchanged.StockCatalog != catalogue {
		t.Fatal("a refused value changed agent.json")
	}

	media := t.TempDir()
	mediaReply, err := service.Set(PathsChange{Key: "media_path", Path: media})
	if err != nil {
		t.Fatal(err)
	}
	if !mediaReply.RestartRequired {
		t.Fatal("the media folder is fixed at agent start and needs a restart")
	}
}

func TestPathsSetRefusesAClientTreeWithoutSourcesOrPatches(t *testing.T) {
	root := pathsRoot(t)
	service := PathsService{Root: root}
	empty := t.TempDir()
	var refusal *Refusal
	_, err := service.Set(PathsChange{Key: "client_tree", Path: empty})
	if !errors.As(err, &refusal) || !strings.Contains(refusal.Message, "src/ or patches/") {
		t.Fatalf("want the client-tree shape refusal, got %v", err)
	}
}

func TestPathsSetRefusesOTARootWhileTheBackendRuns(t *testing.T) {
	root := pathsRoot(t)
	service := PathsService{Root: root, Backend: runningBackend{}}
	otaRoot := t.TempDir()
	var refusal *Refusal
	_, err := service.Set(PathsChange{Key: "ota_root", Path: otaRoot})
	if !errors.As(err, &refusal) || refusal.Code != CodeBackendRunning {
		t.Fatalf("want AGENT_BACKEND_RUNNING, got %v", err)
	}
	config, err := ReadConfig(root)
	if err != nil {
		t.Fatal(err)
	}
	if config.OTARoot != "" {
		t.Fatal("a refused ota_root was written")
	}
}

func TestBuildReadsAgentJSONOnEachBuild(t *testing.T) {
	root := pathsRoot(t)
	first := t.TempDir()
	second := t.TempDir()
	build := Build{Root: root}
	writeLiveConfig(t, root, first)
	config, err := build.config()
	if err != nil {
		t.Fatal(err)
	}
	if config.OTARoot != first {
		t.Fatalf("first ota_root = %q", config.OTARoot)
	}
	writeLiveConfig(t, root, second)
	config, err = build.config()
	if err != nil {
		t.Fatal(err)
	}
	if config.OTARoot != second {
		t.Fatalf("the build kept the captured ota_root %q", config.OTARoot)
	}
}

func TestBackupReadsMigrationsDirectoryOnEachRestore(t *testing.T) {
	root := pathsRoot(t)
	first := t.TempDir()
	second := t.TempDir()
	service := &BackupService{ConfigRoot: root}
	writeMigrationsConfig(t, root, first)
	resolved, err := service.migrationsDirectory()
	if err != nil {
		t.Fatal(err)
	}
	if resolved != first {
		t.Fatalf("first migrations folder = %q", resolved)
	}
	writeMigrationsConfig(t, root, second)
	resolved, err = service.migrationsDirectory()
	if err != nil {
		t.Fatal(err)
	}
	if resolved != second {
		t.Fatalf("the restore kept the captured migrations folder %q", resolved)
	}
}

func writeLiveConfig(t *testing.T, root, otaRoot string) {
	t.Helper()
	contents := `{"listen":"127.0.0.1:8090","ota_root":"` + otaRoot + `","backend":{"operator_addr":"127.0.0.1:8091"}}`
	if err := os.WriteFile(filepath.Join(root, AgentConfigFileName), []byte(contents), 0o600); err != nil {
		t.Fatal(err)
	}
}

func writeMigrationsConfig(t *testing.T, root, migrations string) {
	t.Helper()
	contents := `{"listen":"127.0.0.1:8090","backend":{"operator_addr":"127.0.0.1:8091","migrations_dir":"` + migrations + `"}}`
	if err := os.WriteFile(filepath.Join(root, AgentConfigFileName), []byte(contents), 0o600); err != nil {
		t.Fatal(err)
	}
}
