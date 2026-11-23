package operatoragent

import (
	"errors"
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
	service := SettingsService{Root: root, OTARoot: otaRoot, MediaPath: "/srv/pictures", LookupEnvironment: func(string) string {
		return "https://environment.example"
	}}
	values, err := service.Values()
	if err != nil {
		t.Fatal(err)
	}
	if values.ServerURL != "https://game.example" || values.ServerURLSource != ServerURLSourceEnvFile || values.ResPath != resPath || values.ApkResPath != apkPath {
		t.Fatalf("values = %+v", values)
	}
	if values.BackendPath == "" || values.EnvFile != envPath || values.BackupPath != "" {
		t.Fatalf("agent values = %+v", values)
	}
	if values.AppRepackPath != "" || values.ToolchainPath != "" {
		t.Fatalf("unset paths = %+v", values)
	}
	if values.MediaPath != "/srv/pictures" {
		t.Fatalf("media path = %q", values.MediaPath)
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
	if config.BackupDirectory(root) != "" {
		t.Fatalf("a fresh install has a backup directory: %q", config.BackupDirectory(root))
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

// TestSettingsValuesFallBackToTheAgentEnvironment proves an install that
// passes env_file "" still shows the URL the backend inherits from the agent
// process, with its source (G32).
func TestSettingsValuesFallBackToTheAgentEnvironment(t *testing.T) {
	root := t.TempDir()
	config := `{"listen":"127.0.0.1:8090","backend":{"binary":"/bin/x","operator_addr":"127.0.0.1:8091"}}`
	if err := os.WriteFile(filepath.Join(root, AgentConfigFileName), []byte(config), 0o600); err != nil {
		t.Fatal(err)
	}
	service := SettingsService{Root: root, LookupEnvironment: func(key string) string {
		if key == PublicEngineURLKey {
			return "https://environment.example"
		}
		return ""
	}}
	values, err := service.Values()
	if err != nil {
		t.Fatal(err)
	}
	if values.ServerURL != "https://environment.example" || values.ServerURLSource != ServerURLSourceAgentEnvironment {
		t.Fatalf("values = %+v", values)
	}
}

func TestSettingsValuesReportNoServerURLSourceWhenBothAreEmpty(t *testing.T) {
	root := t.TempDir()
	config := `{"listen":"127.0.0.1:8090","backend":{"binary":"/bin/x","operator_addr":"127.0.0.1:8091"}}`
	if err := os.WriteFile(filepath.Join(root, AgentConfigFileName), []byte(config), 0o600); err != nil {
		t.Fatal(err)
	}
	values, err := (SettingsService{Root: root, LookupEnvironment: func(string) string { return "" }}).Values()
	if err != nil {
		t.Fatal(err)
	}
	if values.ServerURL != "" || values.ServerURLSource != "" {
		t.Fatalf("values = %+v", values)
	}
}

func TestSetPublicURLsStoresRolesAndWritesTheGameAPIURLToTheEnvFile(t *testing.T) {
	root, envPath := writeSettingsRoot(t)
	reply, err := (SettingsService{Root: root}).SetPublicURLs(map[string]string{
		PublicRoleSDK:    "https://sdk.example",
		PublicRoleAPI:    "https://api.example",
		PublicRoleAssets: "https://assets.example",
	})
	if err != nil {
		t.Fatal(err)
	}
	if reply.Message == "" || reply.Values.PublicURLs[PublicRoleAssets] != "https://assets.example" {
		t.Fatalf("reply = %+v", reply)
	}
	config, err := LoadConfig(root)
	if err != nil {
		t.Fatal(err)
	}
	if config.PublicURLs[PublicRoleSDK] != "https://sdk.example" || config.PublicURLs[PublicRoleAPI] != "https://api.example" {
		t.Fatalf("config = %+v", config.PublicURLs)
	}
	value, err := ReadEnvValue(envPath, PublicEngineURLKey)
	if err != nil {
		t.Fatal(err)
	}
	if value != "https://api.example" {
		t.Fatalf("env %s = %q", PublicEngineURLKey, value)
	}

	before, err := os.ReadFile(filepath.Join(root, AgentConfigFileName))
	if err != nil {
		t.Fatal(err)
	}
	_, err = (SettingsService{Root: root}).SetPublicURLs(map[string]string{"other": "https://game.example"})
	var refusal *Refusal
	if !errors.As(err, &refusal) || refusal.Code != CodeSettingsInvalid {
		t.Fatalf("unknown role error = %v", err)
	}
	after, err := os.ReadFile(filepath.Join(root, AgentConfigFileName))
	if err != nil {
		t.Fatal(err)
	}
	if string(before) != string(after) {
		t.Fatal("a refused role changed agent.json")
	}
}

func TestSetServerURLNeedsAConfiguredEnvFile(t *testing.T) {
	root := t.TempDir()
	config := `{"listen":"127.0.0.1:8090","backend":{"binary":"/bin/x","operator_addr":"127.0.0.1:8091"}}`
	if err := os.WriteFile(filepath.Join(root, AgentConfigFileName), []byte(config), 0o600); err != nil {
		t.Fatal(err)
	}
	_, err := (SettingsService{Root: root}).SetServerURL("https://game.example")
	var refusal *Refusal
	if !errors.As(err, &refusal) || refusal.Code != CodeSettingsUnavailable {
		t.Fatalf("error = %v", err)
	}
	if !strings.Contains(refusal.Message, "no backend env file") || !strings.Contains(refusal.Message, "agent.json") {
		t.Fatalf("message = %q", refusal.Message)
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
