package agentapi

import (
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"testing"

	"gxb.local/backend/v2/internal/application/operatoragent"
)

type recordingBackend struct {
	actions  []string
	startErr error
	running  bool
}

func (backend *recordingBackend) Start(bool, string) error {
	backend.actions = append(backend.actions, "start")
	if backend.startErr != nil {
		return backend.startErr
	}
	backend.running = true
	return nil
}

func (backend *recordingBackend) Stop() error {
	backend.actions = append(backend.actions, "stop")
	backend.running = false
	return nil
}

func (backend *recordingBackend) Status() operatoragent.BackendStatus {
	return operatoragent.BackendStatus{Running: backend.running}
}

func TestBackendRestartStopsThenStarts(t *testing.T) {
	handler, _, session := newForwardingHandler(t)
	backend := &recordingBackend{running: true}
	handler.Backend = backend
	handler.Tokens = &operatoragent.TokenHolder{}
	handler.Guard = &operatoragent.BackendGuard{}

	recorder := serveAgent(handler, http.MethodPost, backendRestartPath, session, `{}`)
	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body)
	}
	if strings.Join(backend.actions, ",") != "stop,start" {
		t.Fatalf("actions = %v", backend.actions)
	}
	var status operatoragent.BackendStatus
	if err := json.Unmarshal(recorder.Body.Bytes(), &status); err != nil || !status.Running {
		t.Fatalf("status = %+v (%v)", status, err)
	}
}

func TestBackendRestartFailureSaysTheBackendIsStopped(t *testing.T) {
	handler, _, session := newForwardingHandler(t)
	backend := &recordingBackend{running: true, startErr: errors.New("binary missing")}
	handler.Backend = backend
	handler.Tokens = &operatoragent.TokenHolder{}
	handler.Guard = &operatoragent.BackendGuard{}

	recorder := serveAgent(handler, http.MethodPost, backendRestartPath, session, `{}`)
	if recorder.Code != http.StatusConflict {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body)
	}
	var refusal operatoragent.Refusal
	if err := json.Unmarshal(recorder.Body.Bytes(), &refusal); err != nil {
		t.Fatal(err)
	}
	if refusal.Code != operatoragent.CodeBackendRestartFailed || !strings.Contains(refusal.Message, "now stopped") {
		t.Fatalf("refusal = %+v", refusal)
	}
	if strings.Join(backend.actions, ",") != "stop,start" {
		t.Fatalf("actions = %v", backend.actions)
	}
}

func TestBackendRestartRefusedWhileAnotherActionRuns(t *testing.T) {
	handler, _, session := newForwardingHandler(t)
	backend := &recordingBackend{running: true}
	handler.Backend = backend
	guard := &operatoragent.BackendGuard{}
	if !guard.TryLock() {
		t.Fatal("the guard was not free")
	}
	defer guard.Unlock()
	handler.Guard = guard

	recorder := serveAgent(handler, http.MethodPost, backendRestartPath, session, `{}`)
	if recorder.Code != http.StatusConflict {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body)
	}
	var refusal operatoragent.Refusal
	if err := json.Unmarshal(recorder.Body.Bytes(), &refusal); err != nil || refusal.Code != operatoragent.CodeBackendBusy {
		t.Fatalf("refusal = %+v (%v)", refusal, err)
	}
	if len(backend.actions) != 0 {
		t.Fatalf("a busy restart touched the backend: %v", backend.actions)
	}
}
