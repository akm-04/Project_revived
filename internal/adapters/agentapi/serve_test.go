package agentapi

import (
	"bytes"
	"context"
	"net"
	"net/http"
	"os/exec"
	"strings"
	"sync"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/operatoragent"
)

type processBackend struct {
	command *exec.Cmd
	mutex   sync.Mutex
	running bool
	stopped chan struct{}
}

func newProcessBackend() *processBackend {
	return &processBackend{stopped: make(chan struct{})}
}

func (backend *processBackend) Start(bool, string) error {
	backend.mutex.Lock()
	defer backend.mutex.Unlock()
	backend.command = exec.Command("sleep", "30")
	if err := backend.command.Start(); err != nil {
		return err
	}
	backend.running = true
	return nil
}

func (backend *processBackend) Stop() error {
	backend.mutex.Lock()
	defer backend.mutex.Unlock()
	if backend.command == nil || !backend.running {
		return nil
	}
	_ = backend.command.Process.Kill()
	_ = backend.command.Wait()
	backend.running = false
	close(backend.stopped)
	return nil
}

func (backend *processBackend) Status() operatoragent.BackendStatus {
	backend.mutex.Lock()
	defer backend.mutex.Unlock()
	return operatoragent.BackendStatus{Running: backend.running}
}

func TestServeStopsBackendOnContextEnd(t *testing.T) {
	backend := newProcessBackend()
	if err := backend.Start(false, "token"); err != nil {
		t.Fatal(err)
	}
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	server := &http.Server{Handler: http.HandlerFunc(func(http.ResponseWriter, *http.Request) {})}
	ctx, cancel := context.WithCancel(context.Background())
	finished := make(chan error, 1)
	go func() { finished <- Serve(ctx, server, listener, backend, nil, nil) }()
	cancel()
	select {
	case serveErr := <-finished:
		if serveErr != nil {
			t.Fatal(serveErr)
		}
	case <-time.After(10 * time.Second):
		t.Fatal("the agent run did not return")
	}
	if backend.Status().Running {
		t.Fatal("the backend child survived the agent run")
	}
}

func TestServeWaitsForADetachedOperationBeforeStoppingTheChild(t *testing.T) {
	operations := operatoragent.NewOperations(t.TempDir(), nil, time.Now)
	started := make(chan struct{})
	release := make(chan struct{})
	if _, err := operations.Start(context.Background(), "backup.restore", "", nil, []operatoragent.Step{{
		Name: "blocked restore",
		Run: func(context.Context) (any, error) {
			close(started)
			<-release
			return nil, nil
		},
	}}); err != nil {
		t.Fatal(err)
	}
	backend := newProcessBackend()
	if err := backend.Start(false, "token"); err != nil {
		t.Fatal(err)
	}
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	server := &http.Server{Handler: http.HandlerFunc(func(http.ResponseWriter, *http.Request) {})}
	ctx, cancel := context.WithCancel(context.Background())
	finished := make(chan error, 1)
	go func() { finished <- Serve(ctx, server, listener, backend, operations, nil) }()
	<-started
	cancel()
	select {
	case <-backend.stopped:
		t.Fatal("the child stopped while the detached operation was still running")
	case <-time.After(100 * time.Millisecond):
	}
	close(release)
	select {
	case serveErr := <-finished:
		if serveErr != nil {
			t.Fatal(serveErr)
		}
	case <-time.After(10 * time.Second):
		t.Fatal("the agent run did not return after the operation finished")
	}
	if backend.Status().Running {
		t.Fatal("the backend child survived the agent run")
	}
}

func TestServeLogsAnOperationThatOutlivesTheShutdownBound(t *testing.T) {
	previous := operationShutdownTimeout
	operationShutdownTimeout = 20 * time.Millisecond
	t.Cleanup(func() { operationShutdownTimeout = previous })
	operations := operatoragent.NewOperations(t.TempDir(), nil, time.Now)
	release := make(chan struct{})
	var releaseOnce sync.Once
	releaseOperation := func() { releaseOnce.Do(func() { close(release) }) }
	t.Cleanup(releaseOperation)
	if _, err := operations.Start(context.Background(), "backup.restore", "", nil, []operatoragent.Step{{
		Name: "blocked restore",
		Run: func(context.Context) (any, error) {
			<-release
			return nil, nil
		},
	}}); err != nil {
		t.Fatal(err)
	}
	var output bytes.Buffer
	log := operatoragent.NewToolLog(&output, time.Now)
	backend := newProcessBackend()
	if err := backend.Start(false, "token"); err != nil {
		t.Fatal(err)
	}
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	server := &http.Server{Handler: http.HandlerFunc(func(http.ResponseWriter, *http.Request) {})}
	ctx, cancel := context.WithCancel(context.Background())
	finished := make(chan error, 1)
	go func() { finished <- Serve(ctx, server, listener, backend, operations, log) }()
	cancel()
	select {
	case serveErr := <-finished:
		if serveErr != nil {
			t.Fatal(serveErr)
		}
	case <-time.After(10 * time.Second):
		t.Fatal("the agent run did not return")
	}
	if !strings.Contains(output.String(), `"outcome":"timeout"`) {
		t.Fatalf("the shutdown bound was not logged: %s", output.String())
	}
	releaseOperation()
	waitContext, cancelWait := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancelWait()
	if err := operations.Wait(waitContext); err != nil {
		t.Fatalf("the detached operation did not finish: %v", err)
	}
}
