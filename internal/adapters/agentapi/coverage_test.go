package agentapi

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"testing"
	"time"

	appoperator "gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/application/operatoragent"
)

type coverageOperator struct{}

func (coverageOperator) Version(context.Context) (appoperator.VersionInfo, error) {
	return appoperator.VersionInfo{}, errors.New("no version expected")
}

func (coverageOperator) Command(_ context.Context, request operatoragent.OperatorRequest) (operatoragent.BackendResponse, error) {
	return operatoragent.BackendResponse{Status: http.StatusConflict, Body: []byte(`{"error_code":"OTA_STATE_INVALID","message":"not built"}`)}, nil
}

func (coverageOperator) Read(_ context.Context, name, _ string) (operatoragent.BackendResponse, error) {
	if name == "ota.status" {
		return operatoragent.BackendResponse{Status: http.StatusOK, Body: []byte(`{"revision":1}`)}, nil
	}
	return operatoragent.BackendResponse{Status: http.StatusNotFound, Body: []byte(`{"error_code":"OPERATOR_UNKNOWN_READ"}`)}, nil
}

type coverageBackend struct{}

func (coverageBackend) Start(bool, string) error { return nil }
func (coverageBackend) Stop() error              { return nil }
func (coverageBackend) Status() operatoragent.BackendStatus {
	return operatoragent.BackendStatus{Running: true, State: "running"}
}

// coverageHandler builds a handler with fakes so every route reaches its body.
func coverageHandler(t *testing.T) (Handler, string, *bytes.Buffer) {
	t.Helper()
	output := &bytes.Buffer{}
	toolLog := operatoragent.NewToolLog(output, time.Now)
	credentials := operatoragent.NewCredentials(t.TempDir())
	if err := credentials.Setup("agent password"); err != nil {
		t.Fatal(err)
	}
	generation, err := credentials.Generation()
	if err != nil {
		t.Fatal(err)
	}
	sessions := operatoragent.NewSessions(time.Now)
	token, _, err := sessions.Login(generation)
	if err != nil {
		t.Fatal(err)
	}
	operator := coverageOperator{}
	logs := &operatoragent.LogService{Directory: t.TempDir(), Operator: operator, Now: time.Now}
	handler := Handler{
		Credentials: credentials,
		Sessions:    sessions,
		Backend:     coverageBackend{},
		Operator:    operator,
		Tokens:      &operatoragent.TokenHolder{},
		Maintenance: operatoragent.Maintenance{Backend: coverageBackend{}, Operator: operator, Tokens: &operatoragent.TokenHolder{}, Operations: operatoragent.NewOperations(t.TempDir(), toolLog, time.Now), Guard: &operatoragent.BackendGuard{}},
		Operations:  operatoragent.NewOperations(t.TempDir(), toolLog, time.Now),
		ToolLog:     toolLog,
		Logs:        logs,
		Listen:      testListen,
		Guard:       &operatoragent.BackendGuard{},
	}
	return handler, token, output
}

func sampleBody(route exchangeRoute) string {
	switch route.Name {
	case "setup", "login":
		return `{"password":"coverage-secret-password"}`
	case "command":
		return `{"reason":"coverage","semantic_key":"coverage-key","payload":{"token":"payload-secret-token","ordinary":"kept"}}`
	case "ota.publish", "ota.withdraw":
		return `{"version":"1.631.2","reason":"coverage","semantic_key":"coverage-key"}`
	case "ota.build":
		return `{}`
	case "backend.start", "logout":
		return `{}`
	case "media.import_url":
		return `{"url":""}`
	case "media.upload":
		return `{"data_base64":""}`
	default:
		return ""
	}
}

// TestEveryAgentRouteWritesAToolLogLine walks the route table (C5) and proves
// every route leaves one exchange line with a status, a duration and masked
// params.
func TestEveryAgentRouteWritesAToolLogLine(t *testing.T) {
	for _, route := range exchangeRoutes {
		t.Run(route.Name+" "+route.Method, func(t *testing.T) {
			handler, token, output := coverageHandler(t)
			recorder := serveAgent(handler, route.Method, route.Sample, token, sampleBody(route))
			_ = recorder
			line := findExchangeLine(t, output.String(), route.Name)
			if line.Detail["status"] == nil {
				t.Fatalf("no status in %+v", line.Detail)
			}
			if line.Detail["duration_ms"] == nil {
				t.Fatalf("no duration in %+v", line.Detail)
			}
			if line.Detail["path"] != route.Sample {
				t.Fatalf("path = %v", line.Detail["path"])
			}
			if _, present := line.Detail["params"]; !present {
				t.Fatalf("no params in %+v", line.Detail)
			}
		})
	}
}

type recordedExchange struct {
	Level   string         `json:"level"`
	Op      string         `json:"op"`
	Step    string         `json:"step"`
	Outcome string         `json:"outcome"`
	Detail  map[string]any `json:"detail"`
}

func findExchangeLine(t *testing.T, output, name string) recordedExchange {
	t.Helper()
	for _, raw := range strings.Split(strings.TrimSpace(output), "\n") {
		var line recordedExchange
		if json.Unmarshal([]byte(raw), &line) != nil {
			continue
		}
		if line.Op == name && line.Step == "exchange" {
			return line
		}
	}
	t.Fatalf("no exchange line for %q in:\n%s", name, output)
	return recordedExchange{}
}

func TestExchangeLinesMaskSecretsAndCarryErrorCode(t *testing.T) {
	handler, token, output := coverageHandler(t)
	serveAgent(handler, http.MethodPost, loginPath, "", `{"password":"coverage-secret-password"}`)
	serveAgent(handler, http.MethodPost, commandPrefix+"ota.publish", token, sampleBody(exchangeRoute{Name: "command"}))
	log := output.String()
	for _, secret := range []string{"coverage-secret-password", "payload-secret-token"} {
		if strings.Contains(log, secret) {
			t.Fatalf("tool log leaked %q:\n%s", secret, log)
		}
	}
	if !strings.Contains(log, `"error_code":"OTA_STATE_INVALID"`) {
		t.Fatalf("the refusal code is missing:\n%s", log)
	}
	if !strings.Contains(log, `"ordinary":"kept"`) {
		t.Fatalf("non-secret params were lost:\n%s", log)
	}
}

func TestLogsClearRouteIsLocalAndNeverForwardsTheToolSource(t *testing.T) {
	handler, token, output := coverageHandler(t)
	recorder := serveAgent(handler, http.MethodPost, commandPrefix+"logs.clear", token, `{"reason":"clean","semantic_key":"clear-1","payload":{"source":"tool","scope":"all"}}`)
	if recorder.Code != http.StatusConflict || refusalCodeOf(t, recorder) != operatoragent.CodeLogToolProtected {
		t.Fatalf("clear tool = %d %s", recorder.Code, recorder.Body)
	}
	if !strings.Contains(output.String(), `"op":"command"`) {
		t.Fatalf("the exchange was not logged:\n%s", output.String())
	}
}

func TestLogsReadRouteIsServedLocally(t *testing.T) {
	handler, token, _ := coverageHandler(t)
	recorder := serveAgent(handler, http.MethodGet, readPrefix+"logs.tail?source=tool&limit=5", token, "")
	if recorder.Code != http.StatusOK {
		t.Fatalf("logs.tail = %d %s", recorder.Code, recorder.Body)
	}
	if recorder := serveAgent(handler, http.MethodGet, readPrefix+"logs.tail?source=nope", token, ""); recorder.Code != http.StatusConflict {
		t.Fatalf("bad source = %d %s", recorder.Code, recorder.Body)
	}
}
