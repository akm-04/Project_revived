package operatoragent_test

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"reflect"
	"strings"
	"sync"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/operatorclient"
	"gxb.local/backend/v2/internal/application/operatoragent"
)

type callRecorder struct {
	mutex sync.Mutex
	calls []string
}

func (recorder *callRecorder) add(call string) {
	recorder.mutex.Lock()
	defer recorder.mutex.Unlock()
	recorder.calls = append(recorder.calls, call)
}

func (recorder *callRecorder) snapshot() []string {
	recorder.mutex.Lock()
	defer recorder.mutex.Unlock()
	return append([]string(nil), recorder.calls...)
}

type fakeBackend struct {
	recorder *callRecorder
	tokens   []string
}

func (backend *fakeBackend) Start(closed bool, token string) error {
	name := "start:open"
	if closed {
		name = "start:closed"
	}
	backend.recorder.add(name)
	backend.tokens = append(backend.tokens, token)
	return nil
}

func (backend *fakeBackend) Stop() error {
	backend.recorder.add("stop")
	return nil
}

func (backend *fakeBackend) Status() operatoragent.BackendStatus {
	return operatoragent.BackendStatus{Running: false}
}

type fakeOperatorAPI struct {
	recorder      *callRecorder
	mutex         sync.Mutex
	applies       int
	logoutApplies int
	logoutReasons []string
	seen          map[string]bool
	refusal       bool
	logoutRefusal bool
	auth          []string
}

func (api *fakeOperatorAPI) ServeHTTP(writer http.ResponseWriter, request *http.Request) {
	api.mutex.Lock()
	api.auth = append(api.auth, request.Header.Get("Authorization"))
	api.mutex.Unlock()
	switch {
	case request.URL.Path == "/operator/v1/reads/ota.status":
		api.recorder.add("read:ota.status")
		writer.Header().Set("Content-Type", "application/json")
		_, _ = io.WriteString(writer, `{"revision":7}`)
	case request.URL.Path == "/operator/v1/commands/ota.publish":
		api.recorder.add("command:ota.publish")
		body, _ := io.ReadAll(request.Body)
		var submitted struct {
			Envelope struct {
				SemanticKey string `json:"semantic_key"`
			} `json:"envelope"`
		}
		_ = json.Unmarshal(body, &submitted)
		if api.refusal {
			writer.Header().Set("Content-Type", "application/json")
			writer.WriteHeader(http.StatusConflict)
			_, _ = io.WriteString(writer, `{"error_code":"OTA_STATE_INVALID","message":"not built"}`)
			return
		}
		api.mutex.Lock()
		defer api.mutex.Unlock()
		writer.Header().Set("Content-Type", "application/json")
		if api.seen[submitted.Envelope.SemanticKey] {
			_, _ = io.WriteString(writer, `{"replayed":true}`)
			return
		}
		api.seen[submitted.Envelope.SemanticKey] = true
		api.applies++
		_, _ = io.WriteString(writer, `{"activation_id":1,"version":"1.631.2","action":"PUBLISH"}`)
	case request.URL.Path == "/operator/v1/commands/session.logout_all":
		api.recorder.add("command:session.logout_all")
		body, _ := io.ReadAll(request.Body)
		var submitted struct {
			Envelope struct {
				SemanticKey string `json:"semantic_key"`
				Reason      string `json:"reason"`
			} `json:"envelope"`
		}
		_ = json.Unmarshal(body, &submitted)
		if api.logoutRefusal {
			writer.Header().Set("Content-Type", "application/json")
			writer.WriteHeader(http.StatusConflict)
			_, _ = io.WriteString(writer, `{"error_code":"SESSION_LOGOUT_REFUSED","message":"logout refused"}`)
			return
		}
		api.mutex.Lock()
		defer api.mutex.Unlock()
		writer.Header().Set("Content-Type", "application/json")
		if api.seen[submitted.Envelope.SemanticKey] {
			_, _ = io.WriteString(writer, `{"replayed":true}`)
			return
		}
		api.seen[submitted.Envelope.SemanticKey] = true
		api.logoutApplies++
		api.logoutReasons = append(api.logoutReasons, submitted.Envelope.Reason)
		_, _ = io.WriteString(writer, `{"revoked":2}`)
	default:
		http.NotFound(writer, request)
	}
}

func newMaintenance(t *testing.T) (operatoragent.Maintenance, *fakeBackend, *fakeOperatorAPI, *httptest.Server) {
	t.Helper()
	recorder := &callRecorder{}
	api := &fakeOperatorAPI{recorder: recorder, seen: map[string]bool{}}
	server := httptest.NewServer(api)
	t.Cleanup(server.Close)
	backend := &fakeBackend{recorder: recorder}
	tokens := &operatoragent.TokenHolder{}
	operations := operatoragent.NewOperations(t.TempDir(), nil, time.Now)
	return operatoragent.Maintenance{
		Backend:    backend,
		Operator:   operatorclient.New(server.URL, tokens),
		Tokens:     tokens,
		Operations: operations,
		Guard:      &operatoragent.BackendGuard{},
	}, backend, api, server
}

func TestPublishMaintenanceOrderAndReplay(t *testing.T) {
	maintenance, backend, api, _ := newMaintenance(t)
	operation, err := maintenance.Publish(context.Background(), "1.631.2", "release", "same-key")
	if err != nil {
		t.Fatal(err)
	}
	if operation.State != operatoragent.OperationDone {
		t.Fatalf("operation = %+v", operation)
	}
	want := []string{"stop", "start:closed", "read:ota.status", "command:ota.publish", "command:session.logout_all", "stop", "start:open"}
	if got := api.recorder.snapshot(); !reflect.DeepEqual(got, want) {
		t.Fatalf("call order = %v, want %v", got, want)
	}
	if len(backend.tokens) != 2 || backend.tokens[0] == "" || backend.tokens[0] == backend.tokens[1] {
		t.Fatalf("per-start tokens = %v", backend.tokens)
	}
	for _, header := range api.auth {
		if header != "Bearer "+backend.tokens[0] {
			t.Fatalf("the maintenance calls did not carry the per-start token: %q", header)
		}
	}
	if api.applies != 1 || api.logoutApplies != 1 {
		t.Fatalf("applies publish=%d logout=%d", api.applies, api.logoutApplies)
	}
	if len(api.logoutReasons) != 1 || api.logoutReasons[0] != "ota publish 1.631.2" {
		t.Fatalf("logout reasons = %v", api.logoutReasons)
	}
	if _, err := maintenance.Publish(context.Background(), "1.631.2", "release", "same-key"); err != nil {
		t.Fatal(err)
	}
	if api.applies != 1 || api.logoutApplies != 1 {
		t.Fatalf("a replayed semantic key applied twice: publish=%d logout=%d", api.applies, api.logoutApplies)
	}
}

func TestPublishRefusalLeavesBackendClosed(t *testing.T) {
	maintenance, _, api, _ := newMaintenance(t)
	api.refusal = true
	operation, err := maintenance.Publish(context.Background(), "1.631.2", "release", "refused-key")
	var backendRefusal *operatoragent.BackendRefusal
	if !errors.As(err, &backendRefusal) || backendRefusal.Status != http.StatusConflict {
		t.Fatalf("want the backend 409 passed through, got %v", err)
	}
	if string(backendRefusal.Body) != `{"error_code":"OTA_STATE_INVALID","message":"not built"}` {
		t.Fatalf("body = %s", backendRefusal.Body)
	}
	if operation.State != operatoragent.OperationFailed || operation.FailedStep != "ota.publish" {
		t.Fatalf("operation = %+v", operation)
	}
	calls := api.recorder.snapshot()
	lastStart := ""
	for _, call := range calls {
		if strings.HasPrefix(call, "start:") {
			lastStart = call
		}
	}
	if lastStart != "start:closed" {
		t.Fatalf("the backend was not left closed: %v", calls)
	}
	for _, call := range calls {
		if call == "start:open" {
			t.Fatalf("the backend reopened after a refusal: %v", calls)
		}
	}
}

// A logout failure fails the operation at that step and leaves the backend
// closed, so the operator recovers through the start path.
func TestPublishLogoutFailureLeavesBackendClosed(t *testing.T) {
	maintenance, _, api, _ := newMaintenance(t)
	api.logoutRefusal = true
	operation, err := maintenance.Publish(context.Background(), "1.631.2", "release", "logout-refused-key")
	var backendRefusal *operatoragent.BackendRefusal
	if !errors.As(err, &backendRefusal) || backendRefusal.Status != http.StatusConflict {
		t.Fatalf("want the backend 409 passed through, got %v", err)
	}
	if operation.State != operatoragent.OperationFailed || operation.FailedStep != "session.logout_all" {
		t.Fatalf("operation = %+v", operation)
	}
	calls := api.recorder.snapshot()
	lastStart := ""
	for _, call := range calls {
		if strings.HasPrefix(call, "start:") {
			lastStart = call
		}
		if call == "start:open" {
			t.Fatalf("the backend reopened after a logout failure: %v", calls)
		}
	}
	if lastStart != "start:closed" {
		t.Fatalf("the backend was not left closed: %v", calls)
	}
	want := []string{"stop", "start:closed", "read:ota.status", "command:ota.publish", "command:session.logout_all"}
	if !reflect.DeepEqual(calls, want) {
		t.Fatalf("call order = %v, want %v", calls, want)
	}
}

type liveBackend struct {
	running bool
}

func (backend *liveBackend) Start(bool, string) error {
	if backend.running {
		return operatoragent.Refuse(operatoragent.CodeBackendRunning, "one backend child at a time")
	}
	backend.running = true
	return nil
}

func (backend *liveBackend) Stop() error {
	backend.running = false
	return nil
}

func (backend *liveBackend) Status() operatoragent.BackendStatus {
	return operatoragent.BackendStatus{Running: backend.running}
}

func TestRefusedStartKeepsPreviousToken(t *testing.T) {
	tokens := &operatoragent.TokenHolder{}
	tokens.Set("previous-token")
	backend := &liveBackend{running: true}
	err := operatoragent.StartBackend(backend, tokens, false)
	var refusal *operatoragent.Refusal
	if !errors.As(err, &refusal) || refusal.Code != operatoragent.CodeBackendRunning {
		t.Fatalf("want a backend-running refusal, got %v", err)
	}
	if tokens.Get() != "previous-token" {
		t.Fatalf("the refused start replaced the live token with %q", tokens.Get())
	}

	authorization := make(chan string, 1)
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		authorization <- request.Header.Get("Authorization")
		_, _ = io.WriteString(writer, `{"revision":1}`)
	}))
	t.Cleanup(server.Close)
	response, err := operatorclient.New(server.URL, tokens).Read(context.Background(), "ota.status", "")
	if err != nil {
		t.Fatal(err)
	}
	if response.Status != http.StatusOK {
		t.Fatalf("forwarded call: status = %d", response.Status)
	}
	if got := <-authorization; got != "Bearer previous-token" {
		t.Fatalf("the forwarded call carried %q", got)
	}
}

type refusingOpenBackend struct {
	closed bool
}

func (backend *refusingOpenBackend) Start(closed bool, _ string) error {
	if closed {
		backend.closed = true
		return nil
	}
	return operatoragent.Refuse(operatoragent.CodeBackendNoAssetsRelease, "no ACTIVE assets release is published; start closed, publish an assets release, then open")
}

func (backend *refusingOpenBackend) Stop() error { return nil }

func (backend *refusingOpenBackend) Status() operatoragent.BackendStatus {
	return operatoragent.BackendStatus{}
}

// TestRestartKeepsTheNoAssetsRefusal proves a GUI restart reports the guard's
// own code and remedy instead of a generic restart failure.
func TestRestartKeepsTheNoAssetsRefusal(t *testing.T) {
	backend := &refusingOpenBackend{}
	err := operatoragent.RestartBackend(backend, &operatoragent.TokenHolder{}, false)
	var refusal *operatoragent.Refusal
	if !errors.As(err, &refusal) || refusal.Code != operatoragent.CodeBackendNoAssetsRelease {
		t.Fatalf("want the no-assets refusal, got %v", err)
	}
	if !strings.Contains(refusal.Message, "now stopped") {
		t.Fatalf("the refusal does not say the backend is stopped: %v", err)
	}
}
