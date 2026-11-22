package agentapi

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/operatorclient"
	"gxb.local/backend/v2/internal/application/operatoragent"
)

type backendRecorder struct {
	authorization string
}

func newForwardingHandler(t *testing.T) (Handler, *backendRecorder, string) {
	t.Helper()
	credentials := operatoragent.NewCredentials(t.TempDir())
	if err := credentials.Setup("test password"); err != nil {
		t.Fatal(err)
	}
	sessions := operatoragent.NewSessions(time.Now)
	session, _, err := sessions.Login()
	if err != nil {
		t.Fatal(err)
	}
	recorder := &backendRecorder{}
	backend := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		recorder.authorization = request.Header.Get("Authorization")
		writer.Header().Set("Content-Type", "application/json")
		if strings.HasPrefix(request.URL.Path, "/operator/v1/commands/") {
			writer.WriteHeader(http.StatusConflict)
			_, _ = writer.Write([]byte(`{"error_code":"OTA_STATE_INVALID","message":"not built"}`))
			return
		}
		writer.WriteHeader(http.StatusNotFound)
		_, _ = writer.Write([]byte(`{"error_code":"OPERATOR_UNKNOWN_READ","message":"no such read"}`))
	}))
	t.Cleanup(backend.Close)
	tokens := &operatoragent.TokenHolder{}
	tokens.Set("backend-token")
	handler := Handler{
		Credentials: credentials,
		Sessions:    sessions,
		Operator:    operatorclient.New(backend.URL, tokens),
	}
	return handler, recorder, session
}

func serveAgent(handler Handler, method, path, session, body string) *httptest.ResponseRecorder {
	request := httptest.NewRequest(method, path, strings.NewReader(body))
	request.RemoteAddr = "127.0.0.1:5000"
	if session != "" {
		request.Header.Set("Authorization", "Bearer "+session)
	}
	recorder := httptest.NewRecorder()
	handler.ServeHTTP(recorder, request)
	return recorder
}

func TestForwardedCommandPassesBackendRefusal(t *testing.T) {
	handler, backend, session := newForwardingHandler(t)
	recorder := serveAgent(handler, http.MethodPost, "/agent/v1/commands/ota.publish", session, `{"reason":"release","semantic_key":"k1","payload":{"version":"1.631.2"}}`)
	if recorder.Code != http.StatusConflict {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body)
	}
	if recorder.Body.String() != `{"error_code":"OTA_STATE_INVALID","message":"not built"}` {
		t.Fatalf("body changed: %s", recorder.Body)
	}
	if backend.authorization != "Bearer backend-token" {
		t.Fatalf("the backend saw %q", backend.authorization)
	}
}

func TestForwardedReadPassesBackendNotFound(t *testing.T) {
	handler, backend, session := newForwardingHandler(t)
	recorder := serveAgent(handler, http.MethodGet, "/agent/v1/reads/gm.list?limit=5", session, "")
	if recorder.Code != http.StatusNotFound {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body)
	}
	if recorder.Body.String() != `{"error_code":"OPERATOR_UNKNOWN_READ","message":"no such read"}` {
		t.Fatalf("body changed: %s", recorder.Body)
	}
	if backend.authorization != "Bearer backend-token" {
		t.Fatalf("the backend saw %q", backend.authorization)
	}
}

func TestAgentSetupRequiredAndUnauthorized(t *testing.T) {
	handler := Handler{Credentials: operatoragent.NewCredentials(t.TempDir()), Sessions: operatoragent.NewSessions(time.Now)}
	recorder := serveAgent(handler, http.MethodGet, "/agent/v1/backend/status", "", "")
	var refusal operatoragent.Refusal
	if err := json.Unmarshal(recorder.Body.Bytes(), &refusal); err != nil {
		t.Fatal(err)
	}
	if recorder.Code != http.StatusConflict || refusal.Code != operatoragent.CodeSetupRequired {
		t.Fatalf("status = %d, refusal = %+v", recorder.Code, refusal)
	}

	if err := handler.Credentials.Setup("test password"); err != nil {
		t.Fatal(err)
	}
	recorder = serveAgent(handler, http.MethodGet, "/agent/v1/backend/status", "wrong", "")
	if recorder.Code != http.StatusUnauthorized {
		t.Fatalf("status = %d", recorder.Code)
	}
}

func TestSetupRunsOnce(t *testing.T) {
	handler := Handler{Credentials: operatoragent.NewCredentials(t.TempDir()), Sessions: operatoragent.NewSessions(time.Now)}
	first := serveAgent(handler, http.MethodPost, "/agent/v1/setup", "", `{"password":"test password"}`)
	if first.Code != http.StatusOK {
		t.Fatalf("first setup: %d %s", first.Code, first.Body)
	}
	second := serveAgent(handler, http.MethodPost, "/agent/v1/setup", "", `{"password":"again"}`)
	var refusal operatoragent.Refusal
	if err := json.Unmarshal(second.Body.Bytes(), &refusal); err != nil {
		t.Fatal(err)
	}
	if second.Code != http.StatusConflict || refusal.Code != operatoragent.CodeAlreadySetUp {
		t.Fatalf("second setup: %d %+v", second.Code, refusal)
	}
}
