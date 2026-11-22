package agentapi

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/operatorclient"
	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/application/operatoragent"
)

type backendRecorder struct {
	authorization string
	bodyBytes     int64
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
		recorder.bodyBytes = request.ContentLength
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
		Listen:      testListen,
		Guard:       &operatoragent.BackendGuard{},
	}
	return handler, recorder, session
}

const testListen = "127.0.0.1:8090"

func serveAgent(handler Handler, method, path, session, body string) *httptest.ResponseRecorder {
	request := httptest.NewRequest(method, path, strings.NewReader(body))
	request.Host = handler.Listen
	request.RemoteAddr = "127.0.0.1:5000"
	if method == http.MethodPost {
		request.Header.Set("Content-Type", "application/json")
	}
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

func paddedCommandRequest(size int) string {
	head := `{"reason":"r","semantic_key":"k","payload":"`
	tail := `"}`
	return head + strings.Repeat("a", size-len(head)-len(tail)) + tail
}

func paddedBuildRequest(size int) string {
	head := `{"lane":"`
	tail := `","version":"1.631.2"}`
	return head + strings.Repeat("a", size-len(head)-len(tail)) + tail
}

func refusalCodeOf(t *testing.T, recorder *httptest.ResponseRecorder) string {
	t.Helper()
	var refusal operatoragent.Refusal
	if err := json.Unmarshal(recorder.Body.Bytes(), &refusal); err != nil {
		t.Fatalf("body %s: %v", recorder.Body, err)
	}
	return refusal.Code
}

func TestCommandRouteBodyCap(t *testing.T) {
	handler, _, session := newForwardingHandler(t)
	oversized := serveAgent(handler, http.MethodPost, "/agent/v1/commands/ota.register_build", session, paddedCommandRequest(maxCommandBodyBytes+1))
	if oversized.Code != http.StatusRequestEntityTooLarge || refusalCodeOf(t, oversized) != operatoragent.CodeBodyTooLarge {
		t.Fatalf("oversized command: %d %s", oversized.Code, oversized.Body)
	}
	under := serveAgent(handler, http.MethodPost, "/agent/v1/commands/ota.register_build", session, paddedCommandRequest(maxCommandBodyBytes-1024))
	if under.Code != http.StatusConflict {
		t.Fatalf("under-cap command did not reach the backend: %d %s", under.Code, under.Body)
	}
	otherRoute := serveAgent(handler, http.MethodPost, "/agent/v1/ota/build", session, paddedBuildRequest(maxBodyBytes+1))
	if otherRoute.Code != http.StatusRequestEntityTooLarge || refusalCodeOf(t, otherRoute) != operatoragent.CodeBodyTooLarge {
		t.Fatalf("other route cap: %d %s", otherRoute.Code, otherRoute.Body)
	}
}

func TestCommandRouteCapFitsBackendCap(t *testing.T) {
	handler, backend, session := newForwardingHandler(t)
	atCap := serveAgent(handler, http.MethodPost, "/agent/v1/commands/ota.register_build", session, paddedCommandRequest(maxCommandBodyBytes))
	if atCap.Code != http.StatusConflict {
		t.Fatalf("body at the agent cap: %d %s", atCap.Code, atCap.Body)
	}
	if backend.bodyBytes >= operator.MaxCommandBodyBytes {
		t.Fatalf("forwarded %d bytes, backend cap %d", backend.bodyBytes, operator.MaxCommandBodyBytes)
	}
	over := serveAgent(handler, http.MethodPost, "/agent/v1/commands/ota.register_build", session, paddedCommandRequest(maxCommandBodyBytes+1))
	if over.Code != http.StatusRequestEntityTooLarge || refusalCodeOf(t, over) != operatoragent.CodeBodyTooLarge {
		t.Fatalf("one byte over the agent cap: %d %s", over.Code, over.Body)
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
	handler := Handler{Credentials: operatoragent.NewCredentials(t.TempDir()), Sessions: operatoragent.NewSessions(time.Now), Listen: testListen}
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
	handler := Handler{Credentials: operatoragent.NewCredentials(t.TempDir()), Sessions: operatoragent.NewSessions(time.Now), Listen: testListen}
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

func TestAgentAPIBrowserGuard(t *testing.T) {
	handler := Handler{Credentials: operatoragent.NewCredentials(t.TempDir()), Sessions: operatoragent.NewSessions(time.Now), Listen: testListen}
	cases := []struct {
		name        string
		host        string
		origin      string
		contentType string
		wantStatus  int
		wantCode    string
	}{
		{name: "forged host", host: "evil.example:8090", contentType: "application/json", wantStatus: http.StatusForbidden, wantCode: operatoragent.CodeForbidden},
		{name: "localhost host", host: "localhost:8090", contentType: "application/json", wantStatus: http.StatusForbidden, wantCode: operatoragent.CodeForbidden},
		{name: "origin present", host: testListen, origin: "https://evil.example", contentType: "application/json", wantStatus: http.StatusForbidden, wantCode: operatoragent.CodeForbidden},
		{name: "wrong media type", host: testListen, contentType: "text/plain", wantStatus: http.StatusUnsupportedMediaType, wantCode: operatoragent.CodeBodyInvalid},
		{name: "good request", host: testListen, contentType: "application/json; charset=utf-8", wantStatus: http.StatusOK},
	}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			request := httptest.NewRequest(http.MethodPost, "/agent/v1/setup", strings.NewReader(`{"password":"test password"}`))
			request.Host = testCase.host
			request.RemoteAddr = "127.0.0.1:5000"
			request.Header.Set("Content-Type", testCase.contentType)
			if testCase.origin != "" {
				request.Header.Set("Origin", testCase.origin)
			}
			recorder := httptest.NewRecorder()
			handler.ServeHTTP(recorder, request)
			if recorder.Code != testCase.wantStatus {
				t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body)
			}
			if testCase.wantCode == "" {
				return
			}
			var refusal operatoragent.Refusal
			if err := json.Unmarshal(recorder.Body.Bytes(), &refusal); err != nil {
				t.Fatal(err)
			}
			if refusal.Code != testCase.wantCode {
				t.Fatalf("code = %q, want %q", refusal.Code, testCase.wantCode)
			}
		})
	}
}

func TestAgentAPIRejectsTrailingData(t *testing.T) {
	handler := Handler{Credentials: operatoragent.NewCredentials(t.TempDir()), Sessions: operatoragent.NewSessions(time.Now), Listen: testListen}
	recorder := serveAgent(handler, http.MethodPost, "/agent/v1/setup", "", `{"password":"test password"}{"junk":1}`)
	if recorder.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body)
	}
	var refusal operatoragent.Refusal
	if err := json.Unmarshal(recorder.Body.Bytes(), &refusal); err != nil {
		t.Fatal(err)
	}
	if refusal.Code != operatoragent.CodeBodyInvalid {
		t.Fatalf("code = %q", refusal.Code)
	}
}

type fakeBuildStarter struct {
	operation operatoragent.Operation
	err       error
	calls     int
}

func (starter *fakeBuildStarter) Start(context.Context, operatoragent.BuildRequest) (operatoragent.Operation, error) {
	starter.calls++
	return starter.operation, starter.err
}

func newBuildHandler(t *testing.T) (Handler, *fakeBuildStarter, string) {
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
	starter := &fakeBuildStarter{operation: operatoragent.Operation{ID: "0123456789abcdef0123456789abcdef", State: operatoragent.OperationRunning}}
	return Handler{Credentials: credentials, Sessions: sessions, Build: starter, Listen: testListen}, starter, session
}

func TestBuildRouteAnswers202WithOperationID(t *testing.T) {
	handler, starter, session := newBuildHandler(t)
	recorder := serveAgent(handler, http.MethodPost, "/agent/v1/ota/build", session, `{"lane":"code","version":"1.631.2"}`)
	if recorder.Code != http.StatusAccepted {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body)
	}
	var started struct {
		OperationID string `json:"operation_id"`
	}
	if err := json.Unmarshal(recorder.Body.Bytes(), &started); err != nil || started.OperationID != starter.operation.ID {
		t.Fatalf("body = %s (%v)", recorder.Body, err)
	}
	if starter.calls != 1 {
		t.Fatalf("starts = %d", starter.calls)
	}
}

func TestBuildRouteRefusesWhileAnotherRuns(t *testing.T) {
	handler, starter, session := newBuildHandler(t)
	starter.err = operatoragent.Refuse(operatoragent.CodeOperationRunning, "another ota.build operation is running")
	recorder := serveAgent(handler, http.MethodPost, "/agent/v1/ota/build", session, `{"lane":"code","version":"1.631.2"}`)
	if recorder.Code != http.StatusConflict {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body)
	}
	var refusal operatoragent.Refusal
	if err := json.Unmarshal(recorder.Body.Bytes(), &refusal); err != nil || refusal.Code != operatoragent.CodeOperationRunning {
		t.Fatalf("refusal = %+v (%v)", refusal, err)
	}
}

type blockingBackend struct {
	stopped chan struct{}
	release chan struct{}
	once    sync.Once
}

func newBlockingBackend() *blockingBackend {
	return &blockingBackend{stopped: make(chan struct{}), release: make(chan struct{})}
}

func (backend *blockingBackend) Start(bool, string) error { return nil }

func (backend *blockingBackend) Stop() error {
	backend.once.Do(func() {
		close(backend.stopped)
		<-backend.release
	})
	return nil
}

func (backend *blockingBackend) Status() operatoragent.BackendStatus {
	return operatoragent.BackendStatus{}
}

type staticOperator struct{}

func (staticOperator) Command(context.Context, operatoragent.OperatorRequest) (operatoragent.BackendResponse, error) {
	return operatoragent.BackendResponse{Status: http.StatusOK, Body: []byte(`{}`)}, nil
}

func (staticOperator) Read(context.Context, string, string) (operatoragent.BackendResponse, error) {
	return operatoragent.BackendResponse{Status: http.StatusOK, Body: []byte(`{"revision":1}`)}, nil
}

func (staticOperator) Version(context.Context) (operator.VersionInfo, error) {
	return operator.VersionInfo{Migration: 1}, nil
}

func TestBackendStartRefusedWhileMaintenanceRuns(t *testing.T) {
	credentials := operatoragent.NewCredentials(t.TempDir())
	if err := credentials.Setup("test password"); err != nil {
		t.Fatal(err)
	}
	sessions := operatoragent.NewSessions(time.Now)
	session, _, err := sessions.Login()
	if err != nil {
		t.Fatal(err)
	}
	guard := &operatoragent.BackendGuard{}
	backend := newBlockingBackend()
	tokens := &operatoragent.TokenHolder{}
	operations := operatoragent.NewOperations(t.TempDir(), nil, time.Now)
	maintenance := operatoragent.Maintenance{Backend: backend, Operator: staticOperator{}, Tokens: tokens, Operations: operations, Guard: guard}
	handler := Handler{
		Credentials: credentials,
		Sessions:    sessions,
		Backend:     backend,
		Operator:    staticOperator{},
		Tokens:      tokens,
		Maintenance: maintenance,
		Operations:  operations,
		Listen:      testListen,
		Guard:       guard,
	}

	finished := make(chan error, 1)
	go func() {
		_, runErr := maintenance.Publish(context.Background(), "1.631.2", "release", "guard-key")
		finished <- runErr
	}()
	select {
	case <-backend.stopped:
	case <-time.After(5 * time.Second):
		t.Fatal("the maintenance flow did not start")
	}

	recorder := serveAgent(handler, http.MethodPost, "/agent/v1/backend/start", session, `{}`)
	if recorder.Code != http.StatusConflict {
		t.Fatalf("a start during maintenance: status = %d, body = %s", recorder.Code, recorder.Body)
	}
	var refusal operatoragent.Refusal
	if err := json.Unmarshal(recorder.Body.Bytes(), &refusal); err != nil {
		t.Fatal(err)
	}
	if refusal.Code != operatoragent.CodeBackendBusy {
		t.Fatalf("code = %q, want %q", refusal.Code, operatoragent.CodeBackendBusy)
	}

	close(backend.release)
	select {
	case runErr := <-finished:
		if runErr != nil {
			t.Fatal(runErr)
		}
	case <-time.After(5 * time.Second):
		t.Fatal("the maintenance flow did not finish")
	}

	recorder = serveAgent(handler, http.MethodPost, "/agent/v1/backend/start", session, `{}`)
	if recorder.Code != http.StatusOK {
		t.Fatalf("a start after maintenance: status = %d, body = %s", recorder.Code, recorder.Body)
	}
}

func TestBackupRoutesUseTheAgentService(t *testing.T) {
	credentials := operatoragent.NewCredentials(t.TempDir())
	if err := credentials.Setup("test password"); err != nil {
		t.Fatal(err)
	}
	sessions := operatoragent.NewSessions(time.Now)
	session, _, err := sessions.Login()
	if err != nil {
		t.Fatal(err)
	}
	directory := t.TempDir()
	guard := &operatoragent.BackendGuard{}
	backup := &operatoragent.BackupService{
		Directory:  directory,
		Keep:       5,
		Operations: operatoragent.NewOperations(directory+"/ops", nil, time.Now),
		Guard:      guard,
		Now:        time.Now,
	}
	handler := Handler{Credentials: credentials, Sessions: sessions, Backup: backup, Listen: testListen, Guard: guard}

	listed := serveAgent(handler, http.MethodGet, "/agent/v1/backup/list", session, "")
	if listed.Code != http.StatusOK || !strings.Contains(listed.Body.String(), `"keep":5`) {
		t.Fatalf("list: %d %s", listed.Code, listed.Body)
	}

	missingReason := serveAgent(handler, http.MethodPost, "/agent/v1/backup/snapshot", session, `{"kind":"manual"}`)
	if missingReason.Code != http.StatusConflict || refusalCodeOf(t, missingReason) != operatoragent.CodeBodyInvalid {
		t.Fatalf("missing reason: %d %s", missingReason.Code, missingReason.Body)
	}

	noTools := serveAgent(handler, http.MethodPost, "/agent/v1/backup/snapshot", session, `{"reason":"manual"}`)
	if noTools.Code != http.StatusConflict || refusalCodeOf(t, noTools) != operatoragent.CodeBackupToolsMissing {
		t.Fatalf("no tools: %d %s", noTools.Code, noTools.Body)
	}

	restoreBody := serveAgent(handler, http.MethodPost, "/agent/v1/backup/restore", session, `{"reason":"r"}`)
	if restoreBody.Code != http.StatusConflict || refusalCodeOf(t, restoreBody) != operatoragent.CodeBodyInvalid {
		t.Fatalf("restore without id: %d %s", restoreBody.Code, restoreBody.Body)
	}

	wrongMethod := serveAgent(handler, http.MethodGet, "/agent/v1/backup/snapshot", session, "")
	if wrongMethod.Code != http.StatusNotFound {
		t.Fatalf("wrong method: %d %s", wrongMethod.Code, wrongMethod.Body)
	}
}
