package agentapi

import (
	"encoding/json"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"gxb.local/backend/v2/internal/application/operatoragent"
)

func settingsHandler(t *testing.T) (Handler, string, string) {
	t.Helper()
	root := t.TempDir()
	config := `{"listen":"127.0.0.1:8090","backend":{"binary":"/bin/x","operator_addr":"127.0.0.1:8091"}}`
	if err := os.WriteFile(filepath.Join(root, operatoragent.AgentConfigFileName), []byte(config), 0o600); err != nil {
		t.Fatal(err)
	}
	handler, _, session := newForwardingHandler(t)
	handler.Settings = &operatoragent.SettingsService{Root: root}
	return handler, session, root
}

func TestPublicURLsCommandTakesTheFlatRegistryForm(t *testing.T) {
	handler, session, root := settingsHandler(t)
	body := `{"reason":"test","semantic_key":"public-1","payload":{"sdk":"https://sdk.example","api":"https://api.example","assets":"https://assets.example"}}`
	recorder := serveAgent(handler, http.MethodPost, commandPrefix+"server.public_urls.set", session, body)
	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body)
	}
	config, err := operatoragent.LoadConfig(root)
	if err != nil {
		t.Fatal(err)
	}
	if config.PublicURLs[operatoragent.PublicRoleSDK] != "https://sdk.example" ||
		config.PublicURLs[operatoragent.PublicRoleAPI] != "https://api.example" ||
		config.PublicURLs[operatoragent.PublicRoleAssets] != "https://assets.example" {
		t.Fatalf("public urls = %+v", config.PublicURLs)
	}
}

func TestPublicURLsCommandRefusesAnUnknownNestedRole(t *testing.T) {
	handler, session, _ := settingsHandler(t)
	body := `{"reason":"test","semantic_key":"public-2","payload":{"public_urls":{"other":"https://game.example"}}}`
	recorder := serveAgent(handler, http.MethodPost, commandPrefix+"server.public_urls.set", session, body)
	if recorder.Code != http.StatusConflict || !strings.Contains(recorder.Body.String(), "AGENT_SETTINGS_INVALID") {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body)
	}
}

func TestCLIUsageReadAnswersTheSameTextAsTheCLI(t *testing.T) {
	handler, _, session := newForwardingHandler(t)
	recorder := serveAgent(handler, http.MethodGet, readPrefix+"agent.cli.usage", session, "")
	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body)
	}
	var usage operatoragent.CLIUsage
	if err := json.Unmarshal(recorder.Body.Bytes(), &usage); err != nil {
		t.Fatal(err)
	}
	if usage.Banner != operatoragent.CLIUsageBanner || usage.Usage != operatoragent.CLIUsageText() {
		t.Fatalf("usage = %+v", usage)
	}
	if len(usage.Commands) == 0 || usage.Commands[0].Prefix == "" || usage.Commands[0].Summary == "" {
		t.Fatalf("commands = %+v", usage.Commands)
	}
}
