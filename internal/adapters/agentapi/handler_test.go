package agentapi

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
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
	generation, err := credentials.Generation()
	if err != nil {
		t.Fatal(err)
	}
	session, _, err := sessions.Login(generation)
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

func newPasswordHandler(t *testing.T) (Handler, *operatoragent.Credentials, string, *bytes.Buffer) {
	t.Helper()
	credentials := operatoragent.NewCredentials(t.TempDir())
	if err := credentials.Setup("original-password"); err != nil {
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
	buffer := &bytes.Buffer{}
	handler := Handler{
		Credentials: credentials,
		Sessions:    sessions,
		ToolLog:     operatoragent.NewToolLog(buffer, time.Now),
		Listen:      testListen,
	}
	return handler, credentials, session, buffer
}

func TestPasswordChangeRouteRefusesAndThenEndsSessions(t *testing.T) {
	handler, credentials, session, toolLog := newPasswordHandler(t)
	cases := []struct {
		name string
		body string
		code string
	}{
		{name: "wrong current", body: `{"current":"wrong-password","new":"replacement-password"}`, code: operatoragent.CodeLoginRefused},
		{name: "too short", body: `{"current":"original-password","new":"short"}`, code: operatoragent.CodePasswordTooShort},
		{name: "same", body: `{"current":"original-password","new":"original-password"}`, code: operatoragent.CodePasswordSame},
	}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			recorder := serveAgent(handler, http.MethodPost, "/agent/v1/password", session, testCase.body)
			if recorder.Code != http.StatusConflict || refusalCodeOf(t, recorder) != testCase.code {
				t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body)
			}
		})
	}

	recorder := serveAgent(handler, http.MethodPost, "/agent/v1/password", session, `{"current":"original-password","new":"replacement-password"}`)
	if recorder.Code != http.StatusOK {
		t.Fatalf("change: %d %s", recorder.Code, recorder.Body)
	}
	if strings.Contains(toolLog.String(), "original-password") || strings.Contains(toolLog.String(), "replacement-password") {
		t.Fatalf("the tool log leaked a password: %s", toolLog.String())
	}
	if !strings.Contains(toolLog.String(), `"step":"password changed"`) {
		t.Fatalf("the tool log has no password change line: %s", toolLog.String())
	}

	stale := serveAgent(handler, http.MethodGet, "/agent/v1/modules", session, "")
	if stale.Code != http.StatusUnauthorized {
		t.Fatalf("the pre-change session survived: %d %s", stale.Code, stale.Body)
	}
	oldLogin := serveAgent(handler, http.MethodPost, "/agent/v1/login", "", `{"password":"original-password"}`)
	if oldLogin.Code != http.StatusConflict {
		t.Fatalf("the old password logged in: %d %s", oldLogin.Code, oldLogin.Body)
	}
	newLogin := serveAgent(handler, http.MethodPost, "/agent/v1/login", "", `{"password":"replacement-password"}`)
	if newLogin.Code != http.StatusOK {
		t.Fatalf("the new password did not log in: %d %s", newLogin.Code, newLogin.Body)
	}
	if err := credentials.Verify("replacement-password"); err != nil {
		t.Fatalf("the stored password is not the new one: %v", err)
	}
}

func TestOfflineResetEndsTheSessionOnTheNextRequest(t *testing.T) {
	handler, credentials, session, _ := newPasswordHandler(t)
	if err := credentials.ResetPassword("offline-reset-password"); err != nil {
		t.Fatal(err)
	}
	recorder := serveAgent(handler, http.MethodGet, "/agent/v1/modules", session, "")
	if recorder.Code != http.StatusUnauthorized {
		t.Fatalf("an offline reset left the session alive: %d %s", recorder.Code, recorder.Body)
	}
}

func TestPasswordChangeRouteNeedsTheSession(t *testing.T) {
	handler, _, _, _ := newPasswordHandler(t)
	recorder := serveAgent(handler, http.MethodPost, "/agent/v1/password", "", `{"current":"original-password","new":"replacement-password"}`)
	if recorder.Code != http.StatusUnauthorized {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body)
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
	generation, err := credentials.Generation()
	if err != nil {
		t.Fatal(err)
	}
	session, _, err := sessions.Login(generation)
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

func TestBackendStartRefusedWhileMaintenanceRuns(t *testing.T) {
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

type dashboardBackendState struct{}

func (dashboardBackendState) Start(bool, string) error { return nil }
func (dashboardBackendState) Stop() error              { return nil }
func (dashboardBackendState) Status() operatoragent.BackendStatus {
	return operatoragent.BackendStatus{Running: true, PID: 7, State: "running"}
}

type dashboardVersionState struct{}

func (dashboardVersionState) Version(context.Context) (operator.VersionInfo, error) {
	commit := "abc"
	return operator.VersionInfo{GitCommit: &commit}, nil
}

type dashboardReadState struct {
	reads []string
}

func (state *dashboardReadState) Command(context.Context, operatoragent.OperatorRequest) (operatoragent.BackendResponse, error) {
	return operatoragent.BackendResponse{}, errors.New("no command expected")
}

func (state *dashboardReadState) Read(_ context.Context, name, _ string) (operatoragent.BackendResponse, error) {
	state.reads = append(state.reads, name)
	switch name {
	case "server.list":
		return operatoragent.BackendResponse{Status: 200, Body: []byte(`{"servers":[{"server_id":1,"name":"Alpha","open":true,"online_count":3}]}`)}, nil
	case "events.list":
		return operatoragent.BackendResponse{Status: 200, Body: []byte(`{"occurrences":[]}`)}, nil
	case "ota.status":
		return operatoragent.BackendResponse{Status: 200, Body: []byte(`{"active":{"code":"1.631.2","assets":null,"catalog":[]},"served":[],"misses":[]}`)}, nil
	default:
		return operatoragent.BackendResponse{Status: 404, Body: []byte(`{}`)}, nil
	}
}

func TestDashboardReadIsComposedByTheAgent(t *testing.T) {
	handler, _, session := newForwardingHandler(t)
	reads := &dashboardReadState{}
	handler.Dashboard = operatoragent.Dashboard{
		Backend:  dashboardBackendState{},
		Operator: reads,
		Version:  dashboardVersionState{},
		Now:      func() time.Time { return time.Unix(10_000, 0).UTC() },
	}
	recorder := serveAgent(handler, http.MethodGet, "/agent/v1/reads/dashboard.summary", session, "")
	if recorder.Code != http.StatusOK {
		t.Fatalf("dashboard: %d %s", recorder.Code, recorder.Body)
	}
	var summary operatoragent.DashboardSummary
	if err := json.Unmarshal(recorder.Body.Bytes(), &summary); err != nil {
		t.Fatal(err)
	}
	if !summary.Backend.Running || len(summary.Servers) != 1 || summary.Servers[0].OnlineCount != 3 || summary.Version == nil {
		t.Fatalf("summary = %+v", summary)
	}
	if len(reads.reads) != 3 {
		t.Fatalf("backend reads = %v", reads.reads)
	}
}
