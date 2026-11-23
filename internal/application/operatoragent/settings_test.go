package operatoragent

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func writeExecutable(t *testing.T, directory, name string) string {
	t.Helper()
	path := filepath.Join(directory, name)
	if err := os.WriteFile(path, []byte("#!/bin/sh\n"), 0o755); err != nil {
		t.Fatal(err)
	}
	return path
}

func writeSettingsRoot(t *testing.T) (string, string) {
	t.Helper()
	root := t.TempDir()
	envPath := filepath.Join(root, "backend.env")
	contents := "# backend environment\nGXB_POSTGRES_DSN=postgres://user:pass@host/db\n"
	if err := os.WriteFile(envPath, []byte(contents), 0o600); err != nil {
		t.Fatal(err)
	}
	config := `{"listen":"127.0.0.1:8090","backend":{"binary":"` + writeExecutable(t, root, "gxb-api") + `","env_file":"` + envPath + `","operator_addr":"127.0.0.1:8091"}}`
	if err := os.WriteFile(filepath.Join(root, AgentConfigFileName), []byte(config), 0o600); err != nil {
		t.Fatal(err)
	}
	return root, envPath
}

func TestSettingsValuesReadBothSettingsFiles(t *testing.T) {
	root, envPath := writeSettingsRoot(t)
	if err := WriteEnvValue(envPath, PublicEngineURLKey, "https://game.example"); err != nil {
		t.Fatal(err)
	}
	otaRoot := t.TempDir()
	resPath := t.TempDir()
	apkPath := t.TempDir()
	document := `{"lazy_fetch":"auto","res_path":"` + resPath + `","apk_res_path":"` + apkPath + `","recovered_res_path":""}`
	if err := os.WriteFile(filepath.Join(otaRoot, "settings.json"), []byte(document), 0o600); err != nil {
		t.Fatal(err)
	}
	values, err := SettingsService{Root: root, OTARoot: otaRoot}.Values()
	if err != nil {
		t.Fatal(err)
	}
	if values.ServerURL != "https://game.example" || values.ResPath != resPath || values.ApkResPath != apkPath {
		t.Fatalf("values = %+v", values)
	}
	if values.BackendPath == "" || values.EnvFile != envPath || values.BackupPath != filepath.Join(root, BackupDirectoryName) {
		t.Fatalf("agent values = %+v", values)
	}
	if values.AppRepackPath != "" || values.ToolchainPath != "" {
		t.Fatalf("unset paths = %+v", values)
	}
	if values.OTASettings.LazyFetch != "auto" {
		t.Fatalf("ota settings = %+v", values.OTASettings)
	}
}

func TestSetAgentWritesValidatedPathsAndKeepsOldOnRefusal(t *testing.T) {
	root, _ := writeSettingsRoot(t)
	service := SettingsService{Root: root}
	appRepack := t.TempDir()
	backup := filepath.Join(t.TempDir(), "snapshots")
	toolchain := t.TempDir()
	newBackend := writeExecutable(t, t.TempDir(), "gxb-api")
	reply, err := service.SetAgent(AgentSettingsChange{
		BackendPath:   &newBackend,
		BackupPath:    &backup,
		AppRepackPath: &appRepack,
		ToolchainPath: &toolchain,
	})
	if err != nil {
		t.Fatal(err)
	}
	if !reply.RestartRequired || reply.Message == "" {
		t.Fatalf("reply = %+v", reply)
	}
	config, err := LoadConfig(root)
	if err != nil {
		t.Fatal(err)
	}
	if config.Backend.Binary != newBackend || config.BackupPath != backup || config.AppRepackPath != appRepack || config.ToolchainPath != toolchain {
		t.Fatalf("config = %+v", config)
	}

	before, err := os.ReadFile(filepath.Join(root, AgentConfigFileName))
	if err != nil {
		t.Fatal(err)
	}
	relative := "bin/gxb-api"
	if _, err := service.SetAgent(AgentSettingsChange{BackendPath: &relative}); err == nil {
		t.Fatal("a relative backend path was accepted")
	}
	missing := filepath.Join(t.TempDir(), "missing")
	if _, err := service.SetAgent(AgentSettingsChange{AppRepackPath: &missing}); err == nil {
		t.Fatal("a missing app_repack folder was accepted")
	}
	after, err := os.ReadFile(filepath.Join(root, AgentConfigFileName))
	if err != nil {
		t.Fatal(err)
	}
	if string(before) != string(after) {
		t.Fatal("a refused value changed agent.json")
	}

	empty := ""
	if _, err := service.SetAgent(AgentSettingsChange{ToolchainPath: &empty, BackupPath: &empty}); err != nil {
		t.Fatal(err)
	}
	config, err = LoadConfig(root)
	if err != nil {
		t.Fatal(err)
	}
	if config.ToolchainPath != "" || config.BackupPath != "" {
		t.Fatalf("cleared paths = %+v", config)
	}
	if config.BackupDirectory(root) != filepath.Join(root, BackupDirectoryName) {
		t.Fatalf("backup default = %q", config.BackupDirectory(root))
	}
}

func TestSetServerURLWritesTheEnvFileAndRefusesInvalidValues(t *testing.T) {
	root, envPath := writeSettingsRoot(t)
	service := SettingsService{Root: root}
	reply, err := service.SetServerURL("https://game.example/")
	if err != nil {
		t.Fatal(err)
	}
	if reply.URL != "https://game.example" || !reply.RestartRequired || !reply.APKRebuildRequired || !strings.Contains(reply.Message, "APK") {
		t.Fatalf("reply = %+v", reply)
	}
	contents, err := os.ReadFile(envPath)
	if err != nil {
		t.Fatal(err)
	}
	text := string(contents)
	if !strings.Contains(text, PublicEngineURLKey+"=https://game.example\n") {
		t.Fatalf("env file = %q", text)
	}
	if !strings.Contains(text, "# backend environment") || !strings.Contains(text, "GXB_POSTGRES_DSN=postgres://user:pass@host/db") {
		t.Fatalf("env file lost a line: %q", text)
	}
	entries, err := ReadEnvFile(envPath)
	if err != nil {
		t.Fatal(err)
	}
	if len(entries) != 2 {
		t.Fatalf("entries = %v", entries)
	}

	before := text
	for _, invalid := range []string{"", "game.example", "ftp://game.example", "https://user:pass@game.example", "https://game.example/?x=1"} {
		if _, err := service.SetServerURL(invalid); err == nil {
			t.Fatalf("%q was accepted", invalid)
		}
	}
	after, err := os.ReadFile(envPath)
	if err != nil {
		t.Fatal(err)
	}
	if string(after) != before {
		t.Fatal("a refused URL changed the env file")
	}
}

func TestSetServerURLNeedsAConfiguredEnvFile(t *testing.T) {
	root := t.TempDir()
	config := `{"listen":"127.0.0.1:8090","backend":{"binary":"/bin/x","operator_addr":"127.0.0.1:8091"}}`
	if err := os.WriteFile(filepath.Join(root, AgentConfigFileName), []byte(config), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := (SettingsService{Root: root}).SetServerURL("https://game.example"); err == nil {
		t.Fatal("a missing env file was accepted")
	}
}

func TestWriteEnvValueAppendsAMissingKey(t *testing.T) {
	path := filepath.Join(t.TempDir(), "backend.env")
	if err := os.WriteFile(path, []byte("GXB_PLAIN=1\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := WriteEnvValue(path, PublicEngineURLKey, "http://127.0.0.1:8080"); err != nil {
		t.Fatal(err)
	}
	value, err := ReadEnvValue(path, PublicEngineURLKey)
	if err != nil {
		t.Fatal(err)
	}
	if value != "http://127.0.0.1:8080" {
		t.Fatalf("value = %q", value)
	}
	entries, err := ReadEnvFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if len(entries) != 2 || entries[0] != "GXB_PLAIN=1" {
		t.Fatalf("entries = %v", entries)
	}
}
