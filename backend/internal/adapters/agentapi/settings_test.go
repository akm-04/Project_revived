package agentapi

import (
	"encoding/json"
	"net/http"
	"os"
	"path/filepath"
	"testing"

	"gxb.local/backend/v2/internal/application/operatoragent"
)

func newSettingsHandler(t *testing.T) (Handler, *backendRecorder, string, string) {
	t.Helper()
	handler, recorder, session := newForwardingHandler(t)
	root := t.TempDir()
	envPath := filepath.Join(root, "backend.env")
	if err := os.WriteFile(envPath, []byte("# env\nGXB_PLAIN=1\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	binary := filepath.Join(root, "gxb-api")
	if err := os.WriteFile(binary, []byte("#!/bin/sh\n"), 0o755); err != nil {
		t.Fatal(err)
	}
	config, err := json.Marshal(map[string]any{
		"listen":  testListen,
		"backend": map[string]any{"binary": binary, "env_file": envPath, "operator_addr": "127.0.0.1:8091"},
	})
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, operatoragent.AgentConfigFileName), config, 0o600); err != nil {
		t.Fatal(err)
	}
	handler.Settings = &operatoragent.SettingsService{Root: root}
	return handler, recorder, root, session
}

func TestAgentSettingsAreReadAndWrittenLocally(t *testing.T) {
	handler, backend, root, session := newSettingsHandler(t)
	recorder := serveAgent(handler, http.MethodGet, "/agent/v1/reads/agent.settings", session, "")
	if recorder.Code != http.StatusOK {
		t.Fatalf("read: %d %s", recorder.Code, recorder.Body)
	}
	var values operatoragent.AgentSettingsValues
	if err := json.Unmarshal(recorder.Body.Bytes(), &values); err != nil {
		t.Fatal(err)
	}
	if values.BackendPath == "" || values.EnvFile == "" || values.ServerURL != "" {
		t.Fatalf("values = %+v", values)
	}

	appRepack := t.TempDir()
	payload, err := json.Marshal(map[string]any{"app_repack_path": appRepack})
	if err != nil {
		t.Fatal(err)
	}
	body := `{"reason":"set the APK folder","semantic_key":"settings-1","payload":` + string(payload) + `}`
	recorder = serveAgent(handler, http.MethodPost, "/agent/v1/commands/agent.settings.set", session, body)
	if recorder.Code != http.StatusOK {
		t.Fatalf("set: %d %s", recorder.Code, recorder.Body)
	}
	config, err := operatoragent.LoadConfig(root)
	if err != nil {
		t.Fatal(err)
	}
	if config.AppRepackPath != appRepack {
		t.Fatalf("app_repack_path = %q", config.AppRepackPath)
	}
	if len(backend.body) != 0 {
		t.Fatalf("a local settings command reached the backend: %s", backend.body)
	}
}

func TestServerURLSetWritesTheEnvFileAndWarnsAboutTheAPK(t *testing.T) {
	handler, _, root, session := newSettingsHandler(t)
	recorder := serveAgent(handler, http.MethodPost, "/agent/v1/commands/server.url.set", session, `{"reason":"set the URL","semantic_key":"url-1","payload":{"url":"https://game.example/"}}`)
	if recorder.Code != http.StatusOK {
		t.Fatalf("set: %d %s", recorder.Code, recorder.Body)
	}
	var reply operatoragent.ServerURLReply
	if err := json.Unmarshal(recorder.Body.Bytes(), &reply); err != nil {
		t.Fatal(err)
	}
	if reply.URL != "https://game.example" || !reply.APKRebuildRequired || !reply.RestartRequired {
		t.Fatalf("reply = %+v", reply)
	}
	config, err := operatoragent.LoadConfig(root)
	if err != nil {
		t.Fatal(err)
	}
	value, err := operatoragent.ReadEnvValue(config.Backend.EnvFile, operatoragent.PublicEngineURLKey)
	if err != nil {
		t.Fatal(err)
	}
	if value != "https://game.example" {
		t.Fatalf("env value = %q", value)
	}

	before, err := os.ReadFile(config.Backend.EnvFile)
	if err != nil {
		t.Fatal(err)
	}
	recorder = serveAgent(handler, http.MethodPost, "/agent/v1/commands/server.url.set", session, `{"reason":"bad","semantic_key":"url-2","payload":{"url":"not a url"}}`)
	if recorder.Code != http.StatusConflict {
		t.Fatalf("refusal: %d %s", recorder.Code, recorder.Body)
	}
	after, err := os.ReadFile(config.Backend.EnvFile)
	if err != nil {
		t.Fatal(err)
	}
	if string(before) != string(after) {
		t.Fatal("a refused URL changed the env file")
	}
}

// TestAgentSettingsNoLongerWritesTheBackupFolder is the finding-3 regression:
// the Backups page alone owns the snapshot folder, so the Settings command does
// not accept backup_path.
func TestAgentSettingsNoLongerWritesTheBackupFolder(t *testing.T) {
	handler, _, _, session := newSettingsHandler(t)
	body := `{"reason":"set","semantic_key":"settings-backup","payload":{"backup_path":"/srv/backups"}}`
	recorder := serveAgent(handler, http.MethodPost, "/agent/v1/commands/agent.settings.set", session, body)
	if recorder.Code != http.StatusConflict || refusalCodeOf(t, recorder) != operatoragent.CodeBodyInvalid {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body)
	}
}
