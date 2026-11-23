package operatoragent

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func writeAgentConfig(t *testing.T, contents string) string {
	t.Helper()
	root := t.TempDir()
	if err := os.WriteFile(filepath.Join(root, AgentConfigFileName), []byte(contents), 0o600); err != nil {
		t.Fatal(err)
	}
	return root
}

func TestLoadConfigRefusesUnknownField(t *testing.T) {
	root := writeAgentConfig(t, `{"listen":"127.0.0.1:8090","backend":{"binary":"/bin/x","operator_addr":"127.0.0.1:8091"},"surprise":1}`)
	_, err := LoadConfig(root)
	if err == nil || !strings.Contains(err.Error(), "unknown field") {
		t.Fatalf("want an unknown-field error, got %v", err)
	}
}

func TestLoadConfigRefusesNonLoopback(t *testing.T) {
	cases := map[string]string{
		"public listen":        `{"listen":"0.0.0.0:8090","backend":{"binary":"/bin/x","operator_addr":"127.0.0.1:8091"}}`,
		"public operator addr": `{"listen":"127.0.0.1:8090","backend":{"binary":"/bin/x","operator_addr":"10.0.0.5:8091"}}`,
	}
	for name, contents := range cases {
		t.Run(name, func(t *testing.T) {
			root := writeAgentConfig(t, contents)
			if _, err := LoadConfig(root); err == nil {
				t.Fatal("want a refusal for a non-loopback address")
			}
		})
	}
}

func TestLoadConfigAcceptsLoopback(t *testing.T) {
	root := writeAgentConfig(t, `{"listen":"127.0.0.1:8090","ota_root":"/srv/ota","backend":{"binary":"/bin/x","env_file":"/srv/env","operator_addr":"[::1]:8091"}}`)
	config, err := LoadConfig(root)
	if err != nil {
		t.Fatal(err)
	}
	if config.OTARoot != "/srv/ota" || config.Backend.OperatorAddr != "[::1]:8091" {
		t.Fatalf("config = %+v", config)
	}
}

func TestConfigMediaPathRoundTrip(t *testing.T) {
	root := writeAgentConfig(t, `{"listen":"127.0.0.1:8090","backend":{"binary":"/bin/x","operator_addr":"127.0.0.1:8091"},"media_path":"/srv/pictures"}`)
	config, err := LoadConfig(root)
	if err != nil {
		t.Fatal(err)
	}
	if config.MediaPath != "/srv/pictures" {
		t.Fatalf("media_path = %q", config.MediaPath)
	}
	if err := SaveConfig(root, config); err != nil {
		t.Fatal(err)
	}
	reloaded, err := LoadConfig(root)
	if err != nil {
		t.Fatal(err)
	}
	if reloaded.MediaPath != "/srv/pictures" {
		t.Fatalf("reloaded media_path = %q", reloaded.MediaPath)
	}
}

func TestLoadConfigStockSource(t *testing.T) {
	root := t.TempDir()
	clientTree := filepath.Join(root, "client")
	if err := os.MkdirAll(filepath.Join(clientTree, "patches", "backend_http_poll"), 0o755); err != nil {
		t.Fatal(err)
	}
	stockSource := filepath.Join(root, "stock")
	if err := os.MkdirAll(stockSource, 0o755); err != nil {
		t.Fatal(err)
	}
	document := map[string]any{
		"listen":      "127.0.0.1:8090",
		"client_tree": clientTree,
		"backend":     map[string]any{"binary": "/bin/x", "operator_addr": "127.0.0.1:8091"},
	}
	load := func(t *testing.T) (Config, error) {
		t.Helper()
		encoded, err := json.Marshal(document)
		if err != nil {
			t.Fatal(err)
		}
		return LoadConfig(writeAgentConfig(t, string(encoded)))
	}

	if _, err := load(t); err == nil || !strings.Contains(err.Error(), "stock_source") {
		t.Fatalf("a patch without stock_source: error = %v", err)
	}

	notDirectory := filepath.Join(root, "not-a-directory")
	if err := os.WriteFile(notDirectory, []byte("x"), 0o600); err != nil {
		t.Fatal(err)
	}
	document["stock_source"] = notDirectory
	if _, err := load(t); err == nil || !strings.Contains(err.Error(), "stock_source") {
		t.Fatalf("stock_source naming a file: error = %v", err)
	}

	document["stock_source"] = stockSource
	config, err := load(t)
	if err != nil {
		t.Fatalf("a readable stock_source was refused: %v", err)
	}
	if config.StockSource != stockSource {
		t.Fatalf("stock_source = %q, want %q", config.StockSource, stockSource)
	}
}

func TestLoadConfigBackendTimeoutsDefaultAndBounds(t *testing.T) {
	base := `{"listen":"127.0.0.1:8090","backend":{"binary":"/bin/x","operator_addr":"127.0.0.1:8091"}}`
	config, err := LoadConfig(writeAgentConfig(t, base))
	if err != nil {
		t.Fatal(err)
	}
	if config.Backend.ReadyTimeout() != 60*time.Second || config.Backend.StopGrace() != 15*time.Second {
		t.Fatalf("defaults = %s/%s", config.Backend.ReadyTimeout(), config.Backend.StopGrace())
	}

	for _, values := range []string{
		`"ready_timeout_seconds":4`,
		`"ready_timeout_seconds":601`,
		`"stop_grace_seconds":0`,
		`"stop_grace_seconds":301`,
	} {
		contents := `{"listen":"127.0.0.1:8090","backend":{"binary":"/bin/x","operator_addr":"127.0.0.1:8091",` + values + `}}`
		if _, err := LoadConfig(writeAgentConfig(t, contents)); err == nil {
			t.Fatalf("%s was accepted", values)
		}
	}

	contents := `{"listen":"127.0.0.1:8090","backend":{"binary":"/bin/x","operator_addr":"127.0.0.1:8091","ready_timeout_seconds":5,"stop_grace_seconds":1}}`
	config, err = LoadConfig(writeAgentConfig(t, contents))
	if err != nil || config.Backend.ReadyTimeout() != 5*time.Second || config.Backend.StopGrace() != time.Second {
		t.Fatalf("lower bounds: %+v err=%v", config.Backend, err)
	}
	contents = `{"listen":"127.0.0.1:8090","backend":{"binary":"/bin/x","operator_addr":"127.0.0.1:8091","ready_timeout_seconds":600,"stop_grace_seconds":300}}`
	config, err = LoadConfig(writeAgentConfig(t, contents))
	if err != nil || config.Backend.ReadyTimeout() != 600*time.Second || config.Backend.StopGrace() != 300*time.Second {
		t.Fatalf("upper bounds: %+v err=%v", config.Backend, err)
	}
}

func TestLoadConfigErrorCarriesNoValue(t *testing.T) {
	root := writeAgentConfig(t, `{"listen":5,"ota_root":"postgres://alice:hunter2@db/x","backend":{"binary":"/bin/x","operator_addr":"127.0.0.1:8091"}}`)
	_, err := LoadConfig(root)
	if err == nil {
		t.Fatal("want a decode error")
	}
	for _, secret := range []string{"alice", "hunter2", "db/x"} {
		if strings.Contains(err.Error(), secret) {
			t.Fatalf("error text leaked %q: %v", secret, err)
		}
	}
}

func TestReadEnvFile(t *testing.T) {
	path := filepath.Join(t.TempDir(), "backend.env")
	contents := "# comment\n\nGXB_POSTGRES_DSN=postgres://user:pass@host/db?sslmode=disable\nGXB_PLAIN=a=b=c\n# trailing comment\n"
	if err := os.WriteFile(path, []byte(contents), 0o600); err != nil {
		t.Fatal(err)
	}
	entries, err := ReadEnvFile(path)
	if err != nil {
		t.Fatal(err)
	}
	want := []string{"GXB_POSTGRES_DSN=postgres://user:pass@host/db?sslmode=disable", "GXB_PLAIN=a=b=c"}
	if len(entries) != len(want) {
		t.Fatalf("entries = %v", entries)
	}
	for index, entry := range want {
		if entries[index] != entry {
			t.Fatalf("entry %d = %q, want %q", index, entries[index], entry)
		}
	}
}

func TestEnvFileErrorAndLogCarryNoValue(t *testing.T) {
	directory := t.TempDir()
	path := filepath.Join(directory, "backend.env")
	contents := "GXB_POSTGRES_DSN=postgres://alice:hunter2@db/x\nnot-a-pair\n"
	if err := os.WriteFile(path, []byte(contents), 0o600); err != nil {
		t.Fatal(err)
	}
	_, err := ReadEnvFile(path)
	if err == nil {
		t.Fatal("want a parse error")
	}
	for _, secret := range []string{"alice", "hunter2", "postgres://"} {
		if strings.Contains(err.Error(), secret) {
			t.Fatalf("error text leaked %q: %v", secret, err)
		}
	}

	good := filepath.Join(directory, "good.env")
	if err := os.WriteFile(good, []byte("GXB_POSTGRES_DSN=postgres://alice:hunter2@db/x\nGXB_API_PASSWORD=swordfish\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	entries, err := ReadEnvFile(good)
	if err != nil {
		t.Fatal(err)
	}
	detail := map[string]any{}
	for _, entry := range entries {
		key, value, _ := strings.Cut(entry, "=")
		detail[key] = value
	}
	var buffer bytes.Buffer
	NewToolLog(&buffer, func() time.Time { return time.Unix(0, 0) }).Write("backend.start", "env", "ok", detail)
	line := buffer.String()
	for _, secret := range []string{"alice", "hunter2", "swordfish"} {
		if strings.Contains(line, secret) {
			t.Fatalf("tool log leaked %q: %s", secret, line)
		}
	}
	var parsed map[string]any
	if err := json.Unmarshal(bytes.TrimSpace(buffer.Bytes()), &parsed); err != nil {
		t.Fatalf("log line is not JSON: %v", err)
	}
}

func TestBackupSettingsDefaultsAndValidation(t *testing.T) {
	base := `{"listen":"127.0.0.1:8090","backend":{"binary":"/bin/x","operator_addr":"127.0.0.1:8091"}}`
	root := writeAgentConfig(t, base)
	config, err := LoadConfig(root)
	if err != nil {
		t.Fatal(err)
	}
	if config.BackupKeepValue() != DefaultBackupKeep {
		t.Fatalf("backup_keep default = %d", config.BackupKeepValue())
	}
	if config.BackupDirectory(root) != filepath.Join(root, BackupDirectoryName) {
		t.Fatalf("backup directory = %q", config.BackupDirectory(root))
	}

	for name, contents := range map[string]string{
		"zero keep":     `{"listen":"127.0.0.1:8090","backup_keep":0,"backend":{"binary":"/bin/x","operator_addr":"127.0.0.1:8091"}}`,
		"negative keep": `{"listen":"127.0.0.1:8090","backup_keep":-1,"backend":{"binary":"/bin/x","operator_addr":"127.0.0.1:8091"}}`,
		"relative path": `{"listen":"127.0.0.1:8090","backup_path":"backups","backend":{"binary":"/bin/x","operator_addr":"127.0.0.1:8091"}}`,
		"unknown keep":  `{"listen":"127.0.0.1:8090","backup_keep":"five","backend":{"binary":"/bin/x","operator_addr":"127.0.0.1:8091"}}`,
	} {
		t.Run(name, func(t *testing.T) {
			if _, err := LoadConfig(writeAgentConfig(t, contents)); err == nil {
				t.Fatal("want a refusal")
			}
		})
	}
}

func TestBackupPathMustBeWritableAndOutsideTheTrees(t *testing.T) {
	otaRoot := t.TempDir()
	inside := filepath.Join(otaRoot, "backups")
	contents := `{"listen":"127.0.0.1:8090","ota_root":"` + otaRoot + `","backup_path":"` + inside + `","backend":{"binary":"/bin/x","operator_addr":"127.0.0.1:8091"}}`
	if _, err := LoadConfig(writeAgentConfig(t, contents)); err == nil || !strings.Contains(err.Error(), "ota_root") {
		t.Fatalf("inside ota_root: %v", err)
	}

	notDirectory := filepath.Join(t.TempDir(), "file")
	if err := os.WriteFile(notDirectory, []byte("x"), 0o600); err != nil {
		t.Fatal(err)
	}
	contents = `{"listen":"127.0.0.1:8090","backup_path":"` + notDirectory + `","backend":{"binary":"/bin/x","operator_addr":"127.0.0.1:8091"}}`
	if _, err := LoadConfig(writeAgentConfig(t, contents)); err == nil || !strings.Contains(err.Error(), "writable") {
		t.Fatalf("file backup_path: %v", err)
	}

	writable := filepath.Join(t.TempDir(), "snapshots")
	contents = `{"listen":"127.0.0.1:8090","backup_path":"` + writable + `","backend":{"binary":"/bin/x","operator_addr":"127.0.0.1:8091"}}`
	config, err := LoadConfig(writeAgentConfig(t, contents))
	if err != nil {
		t.Fatalf("a writable backup_path was refused: %v", err)
	}
	if config.BackupDirectory("/elsewhere") != writable {
		t.Fatalf("backup directory = %q", config.BackupDirectory("/elsewhere"))
	}
}

func TestToolchainPathMustBeADirectory(t *testing.T) {
	notDirectory := filepath.Join(t.TempDir(), "file")
	if err := os.WriteFile(notDirectory, []byte("x"), 0o600); err != nil {
		t.Fatal(err)
	}
	contents := `{"listen":"127.0.0.1:8090","toolchain_path":"` + notDirectory + `","backend":{"binary":"/bin/x","operator_addr":"127.0.0.1:8091"}}`
	if _, err := LoadConfig(writeAgentConfig(t, contents)); err == nil {
		t.Fatal("a file toolchain_path was accepted")
	}
	directory := t.TempDir()
	contents = `{"listen":"127.0.0.1:8090","toolchain_path":"` + directory + `","backend":{"binary":"/bin/x","operator_addr":"127.0.0.1:8091"}}`
	if _, err := LoadConfig(writeAgentConfig(t, contents)); err != nil {
		t.Fatalf("a directory toolchain_path was refused: %v", err)
	}
}

func TestMigrationsDirectoryResolvesConfiguredAndBinaryRelative(t *testing.T) {
	configured := t.TempDir()
	config := Config{Backend: BackendConfig{MigrationsDir: configured}}
	if config.MigrationsDirectory() != configured {
		t.Fatalf("configured folder = %q", config.MigrationsDirectory())
	}
	binaryDirectory := t.TempDir()
	migrations := filepath.Join(binaryDirectory, "migrations")
	if err := os.MkdirAll(migrations, 0o755); err != nil {
		t.Fatal(err)
	}
	config = Config{Backend: BackendConfig{Binary: filepath.Join(binaryDirectory, "gxb-api")}}
	if config.MigrationsDirectory() != migrations {
		t.Fatalf("binary-relative folder = %q", config.MigrationsDirectory())
	}
	if (Config{Backend: BackendConfig{Binary: filepath.Join(t.TempDir(), "gxb-api")}}).MigrationsDirectory() != "" {
		t.Fatal("a missing migrations folder was not empty")
	}
}

func TestMigrationsDirectoryMustBeADirectory(t *testing.T) {
	notDirectory := filepath.Join(t.TempDir(), "file")
	if err := os.WriteFile(notDirectory, []byte("x"), 0o600); err != nil {
		t.Fatal(err)
	}
	contents := `{"listen":"127.0.0.1:8090","backend":{"binary":"/bin/x","operator_addr":"127.0.0.1:8091","migrations_dir":"` + notDirectory + `"}}`
	if _, err := LoadConfig(writeAgentConfig(t, contents)); err == nil {
		t.Fatal("a file migrations_dir was accepted")
	}
	directory := t.TempDir()
	contents = `{"listen":"127.0.0.1:8090","backend":{"binary":"/bin/x","operator_addr":"127.0.0.1:8091","migrations_dir":"` + directory + `"}}`
	if _, err := LoadConfig(writeAgentConfig(t, contents)); err != nil {
		t.Fatalf("a directory migrations_dir was refused: %v", err)
	}
}

func TestLoadConfigToolLogDaysDefaultAndBounds(t *testing.T) {
	root := writeAgentConfig(t, `{"listen":"127.0.0.1:8090","backend":{"operator_addr":"127.0.0.1:8091"}}`)
	config, err := LoadConfig(root)
	if err != nil {
		t.Fatal(err)
	}
	if config.ToolLogRetentionDays() != DefaultToolLogDays {
		t.Fatalf("default tool_log_days = %d", config.ToolLogRetentionDays())
	}
	root = writeAgentConfig(t, `{"listen":"127.0.0.1:8090","backend":{"operator_addr":"127.0.0.1:8091"},"tool_log_days":0}`)
	if _, err := LoadConfig(root); err == nil {
		t.Fatal("zero tool_log_days was accepted")
	}
	root = writeAgentConfig(t, `{"listen":"127.0.0.1:8090","backend":{"operator_addr":"127.0.0.1:8091"},"tool_log_days":7,"database_log":"/var/log/postgresql/postgresql.log"}`)
	config, err = LoadConfig(root)
	if err != nil {
		t.Fatal(err)
	}
	if config.ToolLogRetentionDays() != 7 || config.DatabaseLog != "/var/log/postgresql/postgresql.log" {
		t.Fatalf("config = %+v", config)
	}
}
