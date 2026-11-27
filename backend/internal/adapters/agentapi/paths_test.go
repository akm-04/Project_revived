package agentapi

import (
	"bytes"
	"encoding/json"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/operatoragent"
)

func pathsHandler(t *testing.T) (Handler, string, *bytes.Buffer, string) {
	t.Helper()
	root := t.TempDir()
	config := `{"listen":"127.0.0.1:8090","backend":{"operator_addr":"127.0.0.1:8091"}}`
	if err := os.WriteFile(filepath.Join(root, operatoragent.AgentConfigFileName), []byte(config), 0o600); err != nil {
		t.Fatal(err)
	}
	credentials := operatoragent.NewCredentials(t.TempDir())
	if err := credentials.Setup("test password"); err != nil {
		t.Fatal(err)
	}
	sessions := operatoragent.NewSessions(time.Now)
	generation, err := credentials.Generation()
	if err != nil {
		t.Fatal(err)
	}
	session, _, err := sessions.Login(generation)
	if err != nil {
		t.Fatal(err)
	}
	output := &bytes.Buffer{}
	handler := Handler{
		Credentials: credentials,
		Sessions:    sessions,
		Paths:       &operatoragent.PathsService{Root: root},
		ToolLog:     operatoragent.NewToolLog(output, time.Now),
		Listen:      testListen,
	}
	return handler, session, output, root
}

func TestAgentPathsSetSavesAndJournalsThePath(t *testing.T) {
	handler, session, output, root := pathsHandler(t)
	directory := t.TempDir()
	body, err := json.Marshal(map[string]any{
		"reason": "test path", "semantic_key": "path-key",
		"payload": map[string]string{"key": "stock_catalog", "path": directory},
	})
	if err != nil {
		t.Fatal(err)
	}
	recorder := serveAgent(handler, http.MethodPost, commandPrefix+"agent.paths.set", session, string(body))
	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body)
	}
	config, err := operatoragent.ReadConfig(root)
	if err != nil {
		t.Fatal(err)
	}
	if config.StockCatalog != directory {
		t.Fatalf("stock_catalog = %q", config.StockCatalog)
	}
	if !strings.Contains(output.String(), `"op":"agent.paths.set"`) || !strings.Contains(output.String(), `"step":"stock_catalog"`) {
		t.Fatalf("the operation was not journaled:\n%s", output.String())
	}
}

func TestAgentPathsSetAnswersTheValidationRefusal(t *testing.T) {
	handler, session, _, _ := pathsHandler(t)
	body := `{"reason":"bad path","semantic_key":"bad-key","payload":{"key":"stock_source","path":"relative/source"}}`
	recorder := serveAgent(handler, http.MethodPost, commandPrefix+"agent.paths.set", session, body)
	if recorder.Code != http.StatusConflict || refusalCodeOf(t, recorder) != operatoragent.CodeSettingsInvalid {
		t.Fatalf("refusal = %d %s", recorder.Code, recorder.Body)
	}
}
